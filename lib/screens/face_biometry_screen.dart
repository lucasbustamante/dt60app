import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bank_product.dart';
import '../services/card_reader_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_frame.dart';

class FaceBiometryScreen extends StatelessWidget {
  const FaceBiometryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      activeStep: 2,
      child: ResponsiveTwoPane(
        left: Padding(
          padding: const EdgeInsets.only(left: 22, right: 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: const InstructionPanel(
                title: 'Biometria\nfacial',
                messageSpans: [
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
                ],
              ),
            ),
          ),
        ),
        right: const _FaceScanner(),
      ),
    );
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
  Timer? _autoAdvanceTimer;
  ProductJourneySession? _journeySession;
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
      '/sucesso',
      (_) => false,
      arguments: _journeySession,
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

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _cameraError = 'Nenhuma câmera encontrada';
        return;
      }

      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.external,
        orElse: () => cameras.firstWhere(
          (item) =>
              item.name.toLowerCase().contains('usb') ||
              item.name.toLowerCase().contains('external'),
          orElse: () => cameras.firstWhere(
            (item) => item.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          ),
        ),
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      _cameraController = controller;
      await controller.initialize();
      if (mounted) setState(() {});
    } catch (error) {
      _cameraError = error.toString();
      if (mounted) setState(() {});
    }
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
                    ? 'Câmera ativa • mantenha o rosto centralizado'
                    : 'Câmera indisponível • verifique a permissão',
                textAlign: TextAlign.center,
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
