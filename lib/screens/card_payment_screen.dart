import 'dart:async';

import 'package:flutter/material.dart';

import '../models/bank_product.dart';
import '../services/card_reader_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_frame.dart';

class CardPaymentScreen extends StatefulWidget {
  const CardPaymentScreen({super.key});

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  StreamSubscription<CardReaderEvent>? _cardSubscription;
  Timer? _startDetectionTimer;
  bool _goingToPassword = false;

  @override
  void initState() {
    super.initState();
    unawaited(CardReaderService.instance.setStatusLed('blue'));
    _cardSubscription = CardReaderService.instance.events.listen((event) {
      if (event.type == CardReaderEventType.icInserted ||
          event.type == CardReaderEventType.magSwiped ||
          event.type == CardReaderEventType.nfcApproached) {
        _goToPassword();
      }
    });
    _startDetectionTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) unawaited(CardReaderService.instance.startDetection());
    });
  }

  @override
  void dispose() {
    _startDetectionTimer?.cancel();
    unawaited(CardReaderService.instance.stopDetection());
    unawaited(_cardSubscription?.cancel());
    super.dispose();
  }

  Future<void> _goToPassword() async {
    if (!mounted || _goingToPassword) return;
    _goingToPassword = true;
    final session = _journeySession;

    await CardReaderService.instance.stopDetection();
    await CardReaderService.instance.playFixedLedLoading();
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/senha', (_) => false, arguments: session);
  }

  ProductJourneySession? get _journeySession {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return arguments is ProductJourneySession ? arguments : null;
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      activeStep: 0,
      child: ResponsiveTwoPane(
        left: Padding(
          padding: const EdgeInsets.only(left: 22, right: 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: const InstructionPanel(
                title: 'Passe\no cartão',
                messageSpans: [
                  TextSpan(
                    text:
                        'Aproxime, insira ou passe o cartão\nna leitora com a ',
                  ),
                  TextSpan(
                    text: 'tarja voltada para baixo.',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        right: const RepaintBoundary(child: _SwipeCardAnimation()),
      ),
    );
  }
}

class _SwipeCardAnimation extends StatefulWidget {
  const _SwipeCardAnimation();

  @override
  State<_SwipeCardAnimation> createState() => _SwipeCardAnimationState();
}

class _SwipeCardAnimationState extends State<_SwipeCardAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;

        const designWidth = 620.0;
        const designHeight = 390.0;

        return SizedBox(
          width: constraints.maxWidth,
          height: availableHeight,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: designWidth,
              height: designHeight,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final slide = Curves.easeInOut.transform(_controller.value);

                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 26,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _AnimatedChevron(delay: 0, progress: slide),
                            _AnimatedChevron(delay: 0.15, progress: slide),
                            _AnimatedChevron(delay: 0.3, progress: slide),
                          ],
                        ),
                      ),
                      const Positioned(
                        top: 92,
                        left: 70,
                        right: 70,
                        child: _ReaderSlot(),
                      ),
                      Positioned(
                        left: 98 + (slide * 24),
                        top: 135 + (slide * 8),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateX(-0.12)
                            ..rotateZ(-0.018),
                          child: const _OrangeCard(),
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

class _AnimatedChevron extends StatelessWidget {
  const _AnimatedChevron({required this.delay, required this.progress});

  final double delay;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final value = ((progress + delay) % 1.0);

    return Opacity(
      opacity: 0.28 + value * 0.72,
      child: Transform.translate(
        offset: Offset(value * 8, 0),
        child: const Icon(
          Icons.chevron_right,
          color: AppColors.orange,
          size: 42,
        ),
      ),
    );
  }
}

class _ReaderSlot extends StatelessWidget {
  const _ReaderSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2B1307), Colors.black],
          ),
          borderRadius: BorderRadius.circular(7),
          boxShadow: const [
            BoxShadow(
              color: Color(0xAAFF5A00),
              blurRadius: 14,
              offset: Offset(0, -1),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrangeCard extends StatelessWidget {
  const _OrangeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 425,
      height: 265,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF7A00), Color(0xFFFF6200), AppColors.orangeDark],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFFFC39A), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3A000000),
            blurRadius: 28,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _CardPatternPainter())),
          const Positioned(
            left: 42,
            top: 34,
            child: Text(
              'Itaú',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const Positioned(left: 44, top: 118, child: _Chip()),
          const Positioned(
            right: 36,
            bottom: 28,
            child: Text(
              'VISA',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE49A), Color(0xFFD5A83E), Color(0xFFB88725)],
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Color(0xFF7A5A1F), width: 1),
      ),
      child: CustomPaint(painter: _ChipLinesPainter()),
    );
  }
}

class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()..color = Colors.white.withValues(alpha: 0.075);
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.16),
      74,
      linePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.88),
      115,
      linePaint,
    );

    for (var x = size.width * 0.58; x < size.width - 18; x += 14) {
      for (var y = size.height * 0.22; y < size.height - 38; y += 14) {
        canvas.drawCircle(Offset(x, y), 2.1, circlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF74521D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final softPaint = Paint()
      ..color = const Color(0xFF74521D).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final centerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 30,
        height: 24,
      ),
      const Radius.circular(5),
    );

    canvas.drawRRect(centerRect, linePaint);

    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      softPaint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      softPaint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width * 0.24, size.height * 0.25),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.76, size.height * 0.25),
      Offset(size.width, size.height * 0.25),
      linePaint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.24, size.height * 0.75),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.76, size.height * 0.75),
      Offset(size.width, size.height * 0.75),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
