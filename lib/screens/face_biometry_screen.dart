import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bank_product.dart';
import '../services/card_reader_service.dart';
import '../services/journey_flow.dart';
import '../theme/app_theme.dart';
import '../widgets/app_frame.dart';

class FaceBiometryScreen extends StatelessWidget {
  const FaceBiometryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final accountStep = arguments is AccountOpeningStepArgs ? arguments : null;

    return AppFrame(
      activeStep: 1,
      child: ResponsiveTwoPane(
        left: Padding(
          padding: const EdgeInsets.only(left: 22, right: 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: InstructionPanel(
                title: accountStep?.title ?? 'Biometria\nfacial',
                messageSpans: _messageSpans(accountStep),
              ),
            ),
          ),
        ),
        right: const _FaceScanner(),
      ),
    );
  }

  List<InlineSpan> _messageSpans(AccountOpeningStepArgs? accountStep) {
    if (accountStep != null && accountStep.messageHighlight != null) {
      return [
        TextSpan(text: accountStep.messageStart ?? ''),
        TextSpan(
          text: accountStep.messageHighlight,
          style: const TextStyle(
            color: AppColors.orange,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        TextSpan(text: accountStep.messageEnd ?? ''),
      ];
    }

    return const [
      TextSpan(text: 'Para sua segurança,\n'),
      TextSpan(
        text: 'posicione seu rosto',
        style: TextStyle(
          color: AppColors.orange,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      TextSpan(text: ' na moldura\ne aguarde a captura.'),
    ];
  }
}

class _FaceScanner extends StatefulWidget {
  const _FaceScanner();

  @override
  State<_FaceScanner> createState() => _FaceScannerState();
}

class _FaceScannerState extends State<_FaceScanner>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const MethodChannel _permissionChannel = MethodChannel(
    'pinpad_terminal/permissions',
  );
  late final AnimationController _scanController;
  CameraController? _cameraController;
  Future<void>? _cameraInit;
  String? _cameraError;
  String? _cameraStatus;
  Map<dynamic, dynamic>? _cameraDiagnostics;
  CameraDescription? _selectedCamera;
  bool _switchingCamera = false;
  Timer? _autoAdvanceTimer;
  ProductJourneySession? _journeySession;
  AccountOpeningStepArgs? _accountOpeningStepArgs;
  bool _autoAdvanceConfigured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat();
    unawaited(CardReaderService.instance.setStatusLed('purple'));
    unawaited(CardReaderService.instance.startFaceLedBlink());
    _cameraInit = _startCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_autoAdvanceConfigured) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is AccountOpeningStepArgs) {
      _accountOpeningStepArgs = arguments;
      _autoAdvanceConfigured = true;
      _autoAdvanceTimer = Timer(
        const Duration(milliseconds: 4200),
        _finishAccountOpeningStep,
      );
      return;
    }

    if (arguments is! ProductJourneySession) return;

    _journeySession = arguments;
    _autoAdvanceConfigured = true;
    _autoAdvanceTimer = Timer(
      const Duration(milliseconds: 4500),
      _finishProductJourney,
    );
  }

  void _finishProductJourney() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      JourneyFlow.processingRoute,
      (_) => false,
      arguments: _journeySession,
    );
  }

  void _finishAccountOpeningStep() {
    if (!mounted) return;
    final accountStep = _accountOpeningStepArgs;
    if (accountStep == null) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      accountStep.nextRoute,
      (_) => false,
      arguments: accountStep.nextArguments,
    );
  }

  Future<void> _startCamera({CameraDescription? selectedCamera}) async {
    final oldController = _cameraController;
    _cameraController = null;

    if (oldController != null) {
      try {
        if (oldController.value.isStreamingImages) {
          await oldController.stopImageStream();
        }
      } catch (_) {}
      try {
        await oldController.dispose();
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }

    if (mounted) {
      setState(() {
        _cameraError = null;
        _cameraStatus = 'Procurando câmeras...';
      });
    }

    try {
      // O plugin camera solicita a permissão durante initialize(). O canal
      // nativo é mantido apenas para compatibilidade com o terminal original.
      try {
        await _permissionChannel.invokeMethod<bool>('requestCameraPermission');
      } on MissingPluginException {
        // Projeto Flutter padrão: initialize() cuidará da permissão.
      } catch (_) {
        // Não bloqueie a câmera por falha no canal auxiliar.
      }

      final diagnostics = await _loadCameraDiagnostics();
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'Nenhuma câmera encontrada');
      }

      final orderedCameras = _orderedCameras(cameras, diagnostics);
      final frontalCameras = orderedCameras
          .where((camera) => camera.lensDirection == CameraLensDirection.front)
          .toList();
      if (frontalCameras.isEmpty) {
        throw CameraException(
          'NoFrontCamera',
          'Nenhuma câmera frontal foi encontrada neste aparelho',
        );
      }

      final camerasToTry = selectedCamera != null &&
              selectedCamera.lensDirection == CameraLensDirection.front
          ? <CameraDescription>[
              selectedCamera,
              ...frontalCameras.where((c) => c.name != selectedCamera.name),
            ]
          : frontalCameras;

      final attempts = <String>[];
      for (final camera in camerasToTry) {
        // Medium primeiro costuma ser o perfil mais compatível. Low pode
        // selecionar um stream incompatível em câmeras frontais integradas.
        for (final preset in const <ResolutionPreset>[
          ResolutionPreset.medium,
          ResolutionPreset.low,
          ResolutionPreset.high,
        ]) {
          final controller = CameraController(
            camera,
            preset,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.yuv420,
          );

          try {
            _cameraStatus =
                'Abrindo ${_cameraLabel(camera)} (${preset.name})...';
            if (mounted) setState(() {});

            await controller.initialize().timeout(const Duration(seconds: 12));
            await Future<void>.delayed(const Duration(milliseconds: 500));

            // Não confie apenas em isInitialized: neste aparelho a câmera
            // frontal inicializava, mas não entregava nenhum quadro.
            final hasFrame = await _waitForCameraFrame(controller);
            if (!hasFrame) {
              throw CameraException(
                'NoFrames',
                'A câmera abriu, mas não entregou imagem',
              );
            }

            try {
              await controller.lockCaptureOrientation(
                DeviceOrientation.landscapeLeft,
              );
            } catch (_) {}
            try {
              await controller.setFlashMode(FlashMode.off);
            } catch (_) {}

            if (!mounted) {
              await controller.dispose();
              return;
            }

            _cameraController = controller;
            _selectedCamera = camera;
            _cameraError = null;
            _cameraStatus =
                '${_cameraLabel(camera)} ativa • imagem confirmada • ${preset.name}';
            setState(() {});
            return;
          } catch (error) {
            attempts.add(
              '${camera.name}/${camera.lensDirection.name}/${preset.name}: $error',
            );
            try {
              if (controller.value.isStreamingImages) {
                await controller.stopImageStream();
              }
            } catch (_) {}
            try {
              await controller.dispose();
            } catch (_) {}
            await Future<void>.delayed(const Duration(milliseconds: 450));
          }
        }
      }

      _cameraError =
          'Nenhuma câmera entregou imagem. ${attempts.take(6).join(' | ')}';
      _cameraStatus = null;
      if (mounted) setState(() {});
    } on CameraException catch (error) {
      _cameraError = 'Câmera: ${error.code} — ${error.description ?? error}';
      _cameraStatus = null;
      if (mounted) setState(() {});
    } catch (error) {
      _cameraError = 'Erro ao iniciar câmera: $error';
      _cameraStatus = null;
      if (mounted) setState(() {});
    }
  }

  Future<bool> _waitForCameraFrame(CameraController controller) async {
    final completer = Completer<bool>();
    Timer? timeout;

    try {
      timeout = Timer(const Duration(seconds: 4), () {
        if (!completer.isCompleted) completer.complete(false);
      });

      await controller.startImageStream((CameraImage image) {
        if (!completer.isCompleted && image.width > 0 && image.height > 0) {
          completer.complete(true);
        }
      });

      final result = await completer.future;
      timeout.cancel();
      try {
        await controller.stopImageStream();
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return result;
    } catch (_) {
      timeout?.cancel();
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (_) {}
      return false;
    }
  }

  Future<Map<dynamic, dynamic>?> _loadCameraDiagnostics() async {
    try {
      final diagnostics = await _permissionChannel.invokeMethod<dynamic>(
        'getCameraDiagnostics',
      );
      if (diagnostics is Map<dynamic, dynamic>) {
        _cameraDiagnostics = diagnostics;
        return diagnostics;
      }
    } catch (_) {}
    return null;
  }

  List<CameraDescription> _orderedCameras(
    List<CameraDescription> cameras,
    Map<dynamic, dynamic>? diagnostics,
  ) {
    final nativeBest = diagnostics?['bestCameraId']?.toString();
    final sorted = [...cameras];
    sorted.sort((a, b) {
      return _cameraScore(b, nativeBest).compareTo(_cameraScore(a, nativeBest));
    });
    return sorted;
  }

  int _cameraScore(CameraDescription camera, String? nativeBest) {
    final name = camera.name.toLowerCase();
    var score = 0;
    // A biometria facial usa exclusivamente as câmeras frontais.
    if (camera.lensDirection == CameraLensDirection.front) score += 1000;
    if (name.contains('usb') ||
        name.contains('external') ||
        name.contains('uvc')) {
      score += 20;
    }
    if (nativeBest != null && camera.name == nativeBest) score += 10;
    return score;
  }

  String _formatCameraDiagnostics(Map<dynamic, dynamic>? diagnostics) {
    if (diagnostics == null) return '';

    final cameras = diagnostics['cameras'];
    final usbDevices = diagnostics['usbDevices'];
    final cameraCount = cameras is List ? cameras.length : 0;
    final usbVideoCount = usbDevices is List
        ? usbDevices
            .where((item) => item is Map && item['hasVideoInterface'] == true)
            .length
        : 0;
    final best = diagnostics['bestCameraId']?.toString();
    final externalFeature = diagnostics['hasCameraExternalFeature'] == true;

    return 'Android: $cameraCount câmera(s), USB vídeo: $usbVideoCount, externa: ${externalFeature ? 'sim' : 'não'}, preferida: ${best ?? '-'}';
  }

  String _cameraLabel(CameraDescription camera) {
    final direction = switch (camera.lensDirection) {
      CameraLensDirection.front => 'frontal',
      CameraLensDirection.back => 'traseira',
      CameraLensDirection.external => 'externa',
    };
    return '${camera.name} ($direction)';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _cameraController = null;
      unawaited(controller.dispose());
    } else if (state == AppLifecycleState.resumed && mounted) {
      setState(() {
        _cameraStatus = 'Reabrindo câmera...';
        _cameraInit = _startCamera(selectedCamera: _selectedCamera);
      });
    }
  }

  Future<void> _restartCamera() async {
    if (_switchingCamera) return;
    setState(() {
      _switchingCamera = true;
      _cameraError = null;
      _cameraStatus = 'Reiniciando e validando imagem...';
      _cameraInit = _startCamera(selectedCamera: _selectedCamera);
    });
    await _cameraInit;
    if (mounted) setState(() => _switchingCamera = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoAdvanceTimer?.cancel();
    unawaited(CardReaderService.instance.stopFaceLedBlink());
    _scanController.dispose();
    unawaited(_cameraController?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mediaHeight = MediaQuery.sizeOf(context).height;
          final miniLandscape =
              mediaHeight <= 460 || constraints.maxHeight <= 350;
          final dense = mediaHeight <= 650 || constraints.maxHeight <= 440;
          final availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : mediaHeight;

          final scannerSize = miniLandscape
              ? (availableHeight * 0.78).clamp(180.0, 245.0).toDouble()
              : (dense
                  ? (availableHeight * 0.78).clamp(220.0, 315.0).toDouble()
                  : 440.0);

          final portraitSize = scannerSize * 0.88;
          final ringSize = scannerSize * 0.98;
          final scanTopStart = scannerSize * 0.18;
          final scanTravel = scannerSize * 0.58;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: scannerSize,
                height: scannerSize,
                child: AnimatedBuilder(
                  animation: _scanController,
                  builder: (context, child) {
                    final scanTop = scanTopStart +
                        Curves.easeInOut.transform(_scanController.value) *
                            scanTravel;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size(ringSize, ringSize),
                          painter: _ScannerRingPainter(
                            progress: _scanController.value,
                          ),
                        ),
                        ClipOval(
                          child: Container(
                            width: portraitSize,
                            height: portraitSize,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7EBF1),
                              border: Border.all(
                                color: AppColors.white,
                                width: miniLandscape ? 3 : (dense ? 5 : 8),
                              ),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1F000000),
                                  blurRadius: 26,
                                  offset: Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _CameraPreviewOrFallback(
                                  cameraInit: _cameraInit,
                                  controller: _cameraController,
                                  error: _cameraError,
                                ),
                                Positioned(
                                  left: dense ? 14 : 20,
                                  right: dense ? 14 : 20,
                                  top: scanTop,
                                  child: Container(
                                    height: dense ? 3 : 4,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          AppColors.orange,
                                          Colors.transparent,
                                        ],
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x99FF5A00),
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _CornerSet(
                          scannerSize: scannerSize,
                          dense: dense,
                          mini: miniLandscape,
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: miniLandscape ? 6 : 14),
              Text(
                _cameraError == null
                    ? (_cameraStatus ??
                        'Câmera ativa - mantenha o rosto centralizado')
                    : _cameraError!,
                textAlign: TextAlign.center,
                maxLines: miniLandscape ? 2 : 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: miniLandscape ? 11 : (dense ? 13 : 16),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CameraPreviewOrFallback extends StatelessWidget {
  const _CameraPreviewOrFallback({
    required this.cameraInit,
    required this.controller,
    required this.error,
  });

  final Future<void>? cameraInit;
  final CameraController? controller;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: cameraInit,
      builder: (context, snapshot) {
        final current = controller;
        if (error == null &&
            current != null &&
            current.value.isInitialized &&
            snapshot.connectionState == ConnectionState.done) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final targetAspect =
                  constraints.maxWidth / constraints.maxHeight;
              final previewAspect = current.value.aspectRatio;
              final scale = math.max(
                previewAspect / targetAspect,
                targetAspect / previewAspect,
              );

              // O preview conserva sua proporção original e é ampliado apenas
              // o necessário para preencher a moldura, com recorte central.
              // Assim o rosto não fica estreito nem alargado.
              return ClipRect(
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: previewAspect,
                      child: CameraPreview(
                        current,
                        key: ValueKey<String>(
                          '${current.description.name}-${current.value.previewSize}',
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF3F5F8), Color(0xFFE7EBF1)],
            ),
          ),
          child: CustomPaint(painter: _FacePainter()),
        );
      },
    );
  }
}

class _CornerSet extends StatelessWidget {
  const _CornerSet({
    required this.scannerSize,
    required this.dense,
    required this.mini,
  });

  final double scannerSize;
  final bool dense;
  final bool mini;

  @override
  Widget build(BuildContext context) {
    final size = mini ? 24.0 : (dense ? 32.0 : 48.0);
    final pos = scannerSize * 0.13;
    return Stack(
      children: [
        Positioned(
          left: pos,
          top: pos,
          child: _FrameCorner(size: size),
        ),
        Positioned(
          right: pos,
          top: pos,
          child: RotatedBox(quarterTurns: 1, child: _FrameCorner(size: size)),
        ),
        Positioned(
          right: pos,
          bottom: pos,
          child: RotatedBox(quarterTurns: 2, child: _FrameCorner(size: size)),
        ),
        Positioned(
          left: pos,
          bottom: pos,
          child: RotatedBox(quarterTurns: 3, child: _FrameCorner(size: size)),
        ),
      ],
    );
  }
}

class _FrameCorner extends StatelessWidget {
  const _FrameCorner({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FrameCornerPainter()),
    );
  }
}

class _FrameCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orange
      ..strokeWidth = math.max(3, size.width * 0.09)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.72)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.72, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScannerRingPainter extends CustomPainter {
  const _ScannerRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final base = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.16)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final active = Paint()
      ..color = AppColors.orange
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius - 4, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -math.pi / 2 + progress * math.pi * 2,
      math.pi * 0.42,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _FacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFFB9C0CA)
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = const Color(0xFFD5DAE2);

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.40),
      size.width * 0.18,
      fill,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.76),
        width: size.width * 0.58,
        height: size.height * 0.42,
      ),
      math.pi,
      math.pi,
      false,
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
