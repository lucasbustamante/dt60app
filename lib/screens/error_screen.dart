import 'dart:async';

import 'package:flutter/material.dart';

import '../services/card_reader_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_frame.dart';

class ErrorScreen extends StatefulWidget {
  const ErrorScreen({super.key});

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _standbyDelay = Duration(seconds: 10);

  Timer? _timer;
  late final AnimationController _progressController;

  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    unawaited(CardReaderService.instance.setStatusLed('red'));

    _progressController = AnimationController(
      vsync: this,
      duration: _standbyDelay,
    )..forward();

    _timer = Timer(_standbyDelay, _backToStandby);
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(CardReaderService.instance.ledOff());
    _progressController.dispose();
    super.dispose();
  }

  void _backToStandby() {
    if (!mounted || _leaving) return;

    _leaving = true;
    _timer?.cancel();
    _progressController.stop();

    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _backToStandby,
      child: AppFrame(
        activeStep: 3,
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.09),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.danger.withOpacity(0.26),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.danger,
                      size: 86,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Operação não concluída',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 40,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'A transação foi cancelada ou encontrou uma falha. Tente novamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 18,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 34),
                  _AutoReturnProgress(controller: _progressController),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                    onPressed: _backToStandby,
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Voltar ao início'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoReturnProgress extends StatelessWidget {
  const _AutoReturnProgress({
    required this.controller,
  });

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final remaining = (controller.duration!.inSeconds *
              (1 - controller.value))
              .ceil()
              .clamp(0, controller.duration!.inSeconds);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Retornando ao início em $remaining segundos',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: 1 - controller.value,
                  minHeight: 8,
                  backgroundColor: AppColors.line,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.danger,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Toque na tela para voltar agora',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}