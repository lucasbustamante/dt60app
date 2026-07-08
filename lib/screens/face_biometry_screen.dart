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
    with SingleTickerProviderStateMixin {
  static const MethodChannel _permissionChannel = MethodChannel(
    'pinpad_terminal/permissions',
  );
  late final AnimationController _scanController;
  CameraController? _cameraController;
  Future<void>? _cameraInit;
  String? _cameraError;
  String? _cameraStatus;
  Map<dynamic, dynamic>? _cameraDiagnostics;
  Timer? _autoAdvanceTimer;
  ProductJourneySession? _journeySession;
  AccountOpeningStepArgs? _accountOpeningStepArgs;
  bool _autoAdvanceConfigured = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _startCamera() async {
    try {
      final granted = await _permissionChannel.invokeMethod<bool>(
            'requestCameraPermission',
          ) ??
          false;
      if (!granted) {
        _cameraError = 'Permissão da câmera negada';
        if (mounted) setState(() {});
        return;
      }

      final diagnostics = await _loadCameraDiagnostics();
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _cameraError =
            'Nenhuma câmera encontrada. ${_formatCameraDiagnostics(diagnostics)}';
        if (mounted) setState(() {});
        return;
      }

      final orderedCameras = _orderedCameras(cameras, diagnostics);
      final attempts = <String>[];

      for (final camera in orderedCameras) {
        for (final preset in const [
          ResolutionPreset.low,
          ResolutionPreset.medium,
        ]) {
          final controller = CameraController(
            camera,
            preset,
            enableAudio: false,
          );

          try {
            await controller.initialize().timeout(const Duration(seconds: 6));
            _cameraController = controller;
            _cameraError = null;
            _cameraStatus =
                'Câmera ${camera.name} ativa (${camera.lensDirection.name}, ${preset.name})';
            if (mounted) setState(() {});
            return;
          } catch (error) {
            attempts.add(
              '${camera.name}/${camera.lensDirection.name}/${preset.name}: $error',
            );
            await controller.dispose();
          }
        }
      }

      _cameraError =
          'Não foi possível abrir a câmera. Tentativas: ${attempts.take(4).join(' | ')}. ${_formatCameraDiagnostics(diagnostics)}';
      if (mounted) setState(() {});
    } catch (error) {
      _cameraError =
          'Erro ao iniciar câmera: $error. ${_formatCameraDiagnostics(_cameraDiagnostics)}';
      if (mounted) setState(() {});
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
    if (nativeBest != null && camera.name == nativeBest) score += 120;
    if (camera.lensDirection == CameraLensDirection.external) score += 100;
    if (name.contains('usb') ||
        name.contains('external') ||
        name.contains('uvc')) {
      score += 80;
    }
    if (camera.lensDirection == CameraLensDirection.front) score += 40;
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

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    unawaited(CardReaderService.instance.stopFaceLedBlink());
    _scanController.dispose();
    unawaited(_cameraController?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 470),
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
              ? (availableHeight * 0.66).clamp(150.0, 205.0).toDouble()
              : (dense
                  ? (availableHeight * 0.68).clamp(190.0, 255.0).toDouble()
                  : 390.0);

          final portraitSize = scannerSize * 0.82;
          final ringSize = scannerSize * 0.92;
          final scanTopStart = scannerSize * 0.23;
          final scanTravel = scannerSize * 0.5;

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
          return FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: current.value.previewSize?.height ?? 240,
              height: current.value.previewSize?.width ?? 240,
              child: CameraPreview(current),
            ),
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
    final pos = scannerSize * 0.18;
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
