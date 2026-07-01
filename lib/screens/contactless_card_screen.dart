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

class ContactlessCardScreen extends StatefulWidget {
  const ContactlessCardScreen({super.key});

  @override
  State<ContactlessCardScreen> createState() => _ContactlessCardScreenState();
}

class _ContactlessCardScreenState extends State<ContactlessCardScreen> {
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
          _journeySession?.product.paymentMethod ?? PaymentMethod.nfc;
      if (JourneyFlow.matchesPaymentEvent(expectedMethod, event.type)) {
        _goToNextStep();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureFocus());
    _startDetectionTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        unawaited(
          CardReaderService.instance.startDetection(
            mode: CardDetectionMode.nfc,
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
                      title: 'Aproxime\no cartão',
                      messageSpans: [
                        TextSpan(text: 'Aproxime o cartão ou celular\nno '),
                        TextSpan(
                          text: 'sensor por aproximação',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        TextSpan(text: '\ne aguarde a confirmação.'),
                      ],
                    ),
                  ),
                ),
              ),
              right: const RepaintBoundary(child: _ContactlessAnimation()),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactlessAnimation extends StatefulWidget {
  const _ContactlessAnimation();

  @override
  State<_ContactlessAnimation> createState() => _ContactlessAnimationState();
}

class _ContactlessAnimationState extends State<_ContactlessAnimation>
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
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        const designWidth = 620.0;
        const designHeight = 420.0;

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
                  final value = Curves.easeInOutCubic.transform(
                    _controller.value,
                  );

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        right: 52,
                        top: 58,
                        child: Transform.translate(
                          offset: Offset(-value * 28, 0),
                          child: Transform.rotate(
                            angle: -0.08,
                            child: const _PhoneShape(),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 58,
                        top: 105,
                        child: Transform.translate(
                          offset: Offset(value * 22, 0),
                          child: Transform.rotate(
                            angle: 0.05,
                            child: const _ContactlessCard(),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 92,
                        child: CustomPaint(
                          size: const Size(250, 220),
                          painter: _WavesPainter(progress: value),
                        ),
                      ),
                      Positioned(
                        bottom: 18,
                        child: Text(
                          'Detectou aproximação: avança para autenticação',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.text,
                            fontSize: 15,
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

class _ContactlessCard extends StatelessWidget {
  const _ContactlessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 235,
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A35), AppColors.orangeDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: const Align(
        alignment: Alignment.topRight,
        child: Icon(Icons.contactless, color: Colors.white, size: 38),
      ),
    );
  }
}

class _PhoneShape extends StatelessWidget {
  const _PhoneShape();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 245,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.text,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 26,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Icon(Icons.contactless, color: AppColors.orange, size: 54),
        ),
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  const _WavesPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..color = AppColors.orange.withValues(alpha: .32 + progress * .45);

    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 4; i++) {
      final radius = 28.0 + i * 27 + progress * 12;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 3,
        math.pi * 2 / 3,
        false,
        paint
          ..color = AppColors.orange.withValues(
            alpha: (.62 - i * .11).clamp(0.0, 1.0).toDouble(),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
