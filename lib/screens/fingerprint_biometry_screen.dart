import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/card_reader_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_frame.dart';

class FingerprintBiometryScreen extends StatefulWidget {
  const FingerprintBiometryScreen({super.key});

  @override
  State<FingerprintBiometryScreen> createState() => _FingerprintBiometryScreenState();
}

class _FingerprintBiometryScreenState extends State<FingerprintBiometryScreen> {
  StreamSubscription<CardReaderEvent>? _subscription;
  bool _goingToPassword = false;

  @override
  void initState() {
    super.initState();
    _subscription = CardReaderService.instance.events.listen((event) {
      if (event.type == CardReaderEventType.fingerprintDetected) {
        _goToPassword();
      }
    });
    unawaited(CardReaderService.instance.startFingerprintDetection());
  }

  @override
  void dispose() {
    unawaited(CardReaderService.instance.stopFingerprintDetection());
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _goToPassword() {
    if (!mounted || _goingToPassword) return;
    _goingToPassword = true;
    Navigator.of(context).pushNamedAndRemoveUntil('/senha', (_) => false);
  }

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
                  title: 'Biometria\ndigital',
                  messageSpans: [
                    TextSpan(text: 'Coloque o dedo no '),
                    TextSpan(
                      text: 'sensor de biometria',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    TextSpan(text: '\ne aguarde a leitura.'),
                  ],
                ),
              ),
            ),
          ),
          right: const _FingerprintAnimation(),
        ),
      );
  }
}

class _FingerprintAnimation extends StatefulWidget {
  const _FingerprintAnimation();

  @override
  State<_FingerprintAnimation> createState() => _FingerprintAnimationState();
}

class _FingerprintAnimationState extends State<_FingerprintAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        const designWidth = 560.0;
        const designHeight = 410.0;

        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: designWidth,
              height: designHeight,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final pulse = Curves.easeInOut.transform(_controller.value);
                  final scanTop = 88 + pulse * 190;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Transform.scale(
                          scale: 1 + pulse * .08 + i * .12,
                          child: Opacity(
                            opacity: (.18 - i * .045).clamp(0, 1),
                            child: Container(
                              width: 265,
                              height: 265,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.orange,
                              ),
                            ),
                          ),
                        ),
                      Container(
                        width: 285,
                        height: 285,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.orange.withOpacity(.32),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 28,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _FingerprintPainter(progress: pulse),
                        ),
                      ),
                      Positioned(
                        top: scanTop,
                        child: Container(
                          width: 230,
                          height: 5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
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
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        child: Text(
                          'Aguardando leitura digital...',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.text,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FingerprintPainter extends CustomPainter {
  const _FingerprintPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8
      ..color = AppColors.text.withOpacity(.22 + progress * .35);

    for (var i = 0; i < 8; i++) {
      final rect = Rect.fromCenter(
        center: center.translate(0, -8 + i * 2.5),
        width: 58 + i * 20,
        height: 78 + i * 26,
      );
      final start = math.pi * (.72 + i * .035);
      final sweep = math.pi * (1.55 - i * .035);
      canvas.drawArc(rect, start, sweep, false, paint);
    }

    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9
      ..color = AppColors.orange.withOpacity(.72);

    canvas.drawArc(
      Rect.fromCenter(center: center, width: 64, height: 90),
      math.pi * .78,
      math.pi * 1.42,
      false,
      corePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FingerprintPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
