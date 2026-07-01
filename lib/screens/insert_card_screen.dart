import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bank_product.dart';
import '../services/card_reader_service.dart';
import '../services/journey_flow.dart';
import '../services/pinpad_keys.dart';
import '../theme/app_theme.dart';
import '../widgets/app_frame.dart';

class InsertCardScreen extends StatefulWidget {
  const InsertCardScreen({super.key});

  @override
  State<InsertCardScreen> createState() => _InsertCardScreenState();
}

class _InsertCardScreenState extends State<InsertCardScreen> {
  final FocusNode _focusNode = FocusNode();
  StreamSubscription<CardReaderEvent>? _cardSubscription;
  Timer? _startDetectionTimer;
  bool _goingToNextStep = false;

  @override
  void initState() {
    super.initState();
    unawaited(CardReaderService.instance.setStatusLed('blue'));
    _cardSubscription = CardReaderService.instance.events.listen((event) {
      if (event.type == CardReaderEventType.pinpadCancel) {
        unawaited(_cancelOperation());
        return;
      }

      final expectedMethod =
          _journeySession?.product.paymentMethod ?? PaymentMethod.chip;
      if (JourneyFlow.matchesPaymentEvent(expectedMethod, event.type)) {
        _goToNextStep();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureFocus());
    _startDetectionTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        unawaited(
          CardReaderService.instance.startDetection(
            mode: CardDetectionMode.chip,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _startDetectionTimer?.cancel();
    unawaited(CardReaderService.instance.stopDetection());
    unawaited(_cardSubscription?.cancel());
    _focusNode.dispose();
    super.dispose();
  }

  void _ensureFocus() {
    if (!mounted || _goingToNextStep) return;
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  Future<void> _goToNextStep() async {
    if (!mounted || _goingToNextStep) return;
    _goingToNextStep = true;
    final session = _journeySession;

    await CardReaderService.instance.stopDetection();
    await CardReaderService.instance.playFixedLedLoading();
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    final nextRoute = session == null
        ? JourneyFlow.passwordRoute
        : JourneyFlow.authenticationRouteFor(
            session.product.authenticationMethod,
          );
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(nextRoute, (_) => false, arguments: session);
  }

  Future<void> _cancelOperation() async {
    if (!mounted || _goingToNextStep) return;
    _goingToNextStep = true;
    _startDetectionTimer?.cancel();
    await CardReaderService.instance.stopDetection();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      JourneyFlow.errorRoute,
      (_) => false,
      arguments: OperationFailure.cancelled(_journeySession),
    );
  }

  ProductJourneySession? get _journeySession {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return arguments is ProductJourneySession ? arguments : null;
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent || _goingToNextStep) return;
    if (PinpadKeys.isCancel(event.logicalKey)) {
      unawaited(_cancelOperation());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_cancelOperation());
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _ensureFocus,
          child: AppFrame(
            activeStep: 0,
            child: ResponsiveTwoPane(
              left: Padding(
                padding: const EdgeInsets.only(left: 22, right: 10),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: const InstructionPanel(
                      title: 'Insira o cartão\n(com chip)',
                      messageSpans: [
                        TextSpan(text: 'Insira o cartão na leitora\ncom o '),
                        TextSpan(
                          text: 'chip voltado para cima',
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
              right: const RepaintBoundary(child: _InsertCardAnimation()),
            ),
          ),
        ),
      ),
    );
  }
}

class _InsertCardAnimation extends StatefulWidget {
  const _InsertCardAnimation();

  @override
  State<_InsertCardAnimation> createState() => _InsertCardAnimationState();
}

class _InsertCardAnimationState extends State<_InsertCardAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
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
        const designHeight = 430.0;

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
                  final value = Curves.easeInOutCubic.transform(
                    _controller.value,
                  );

                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 10,
                        child: Column(
                          children: [
                            const Icon(
                              Icons.credit_card_outlined,
                              color: AppColors.orange,
                              size: 34,
                            ),
                            Transform.translate(
                              offset: Offset(0, value * 7),
                              child: const Icon(
                                Icons.arrow_upward,
                                color: AppColors.orange,
                                size: 38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Positioned(
                        top: 96,
                        left: 72,
                        right: 72,
                        child: _InsertSlot(),
                      ),
                      Positioned(
                        top: 125 - value * 26,
                        left: 145,
                        child: Transform(
                          alignment: Alignment.topCenter,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateX(-0.10)
                            ..rotateZ(math.pi / 80),
                          child: const _InsertCard(),
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

class _InsertSlot extends StatelessWidget {
  const _InsertSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF331303), Colors.black],
          ),
          borderRadius: BorderRadius.circular(7),
          boxShadow: const [
            BoxShadow(
              color: Color(0xAAFF5A00),
              blurRadius: 13,
              offset: Offset(0, -1),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsertCard extends StatelessWidget {
  const _InsertCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      height: 460,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF7A00), Color(0xFFFF6200), AppColors.orangeDark],
        ),
        borderRadius: BorderRadius.circular(20),
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
            top: 34,
            left: 34,
            child: Text(
              'Itaú',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: Center(child: _InsertChip()),
          ),
          const Positioned(
            right: 30,
            bottom: 32,
            child: Text(
              'VISA',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 38,
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

class _InsertChip extends StatelessWidget {
  const _InsertChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 76,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE49A), Color(0xFFD5A83E), Color(0xFFB88725)],
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Color(0xFF7A5A1F), width: 1),
      ),
      child: CustomPaint(painter: _ChipPainter()),
    );
  }
}

class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.62),
      130,
      linePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.85),
      158,
      linePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.48, size.height * 1.02),
      132,
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChipPainter extends CustomPainter {
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
        height: 36,
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
      Offset(0, size.height * 0.24),
      Offset(size.width * 0.28, size.height * 0.24),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.72, size.height * 0.24),
      Offset(size.width, size.height * 0.24),
      linePaint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.76),
      Offset(size.width * 0.28, size.height * 0.76),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.72, size.height * 0.76),
      Offset(size.width, size.height * 0.76),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.26, 0),
      Offset(size.width * 0.26, size.height * 0.22),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.74, 0),
      Offset(size.width * 0.74, size.height * 0.22),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.26, size.height * 0.78),
      Offset(size.width * 0.26, size.height),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.74, size.height * 0.78),
      Offset(size.width * 0.74, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
