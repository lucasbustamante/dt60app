import 'dart:async';

import 'package:flutter/material.dart';

import '../models/bank_product.dart';
import '../services/card_reader_service.dart';
import '../services/journey_flow.dart';
import '../theme/app_theme.dart';
import '../widgets/app_frame.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _processingDelay = Duration(milliseconds: 2400);

  Timer? _timer;
  late final AnimationController _controller;
  ProductJourneySession? _session;
  bool _configured = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    unawaited(CardReaderService.instance.playFixedLedLoading());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_configured) return;

    _configured = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is ProductJourneySession) {
      _session = arguments;
    }

    _timer = Timer(_processingDelay, _goToSuccess);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _goToSuccess() {
    if (!mounted || _leaving) return;
    _leaving = true;
    Navigator.of(context).pushNamedAndRemoveUntil(
      JourneyFlow.successRoute,
      (_) => false,
      arguments: _session,
    );
  }

  @override
  Widget build(BuildContext context) {
    final productName = _session?.product.shortTitle;

    return AppFrame(
      activeStep: 2,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ProcessingPainter(progress: _controller.value),
                      child: child,
                    );
                  },
                  child: const Center(
                    child: Icon(
                      Icons.sync,
                      color: AppColors.orange,
                      size: 58,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Processando',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 42,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                productName == null
                    ? 'Aguarde enquanto registramos a operação.'
                    : 'Aguarde enquanto registramos a contratação de $productName.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 18,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 34),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(
                  minHeight: 8,
                  backgroundColor: AppColors.line,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessingPainter extends CustomPainter {
  const _ProcessingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 8;
    final base = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.14)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;
    final active = Paint()
      ..color = AppColors.orange
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708 + progress * 6.28318,
      1.6,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _ProcessingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
