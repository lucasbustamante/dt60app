import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/card_reader_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_frame.dart';

enum _AccountStage {
  info,
  fingerprintCollect,
  fingerprintSuccess,
  loading,
  accountSuccess,
  qr,
}

class AccountOpeningScreen extends StatefulWidget {
  const AccountOpeningScreen({super.key});

  @override
  State<AccountOpeningScreen> createState() => _AccountOpeningScreenState();
}

class _AccountOpeningScreenState extends State<AccountOpeningScreen>
    with TickerProviderStateMixin {
  _AccountStage _stage = _AccountStage.info;
  Timer? _timer;
  late final AnimationController _fingerController;
  late final AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _fingerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _scheduleNext(const Duration(seconds: 7), _AccountStage.fingerprintCollect);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fingerController.dispose();
    _loadingController.dispose();
    unawaited(CardReaderService.instance.ledOff());
    super.dispose();
  }

  void _scheduleNext(Duration duration, _AccountStage next) {
    _timer?.cancel();
    _timer = Timer(duration, () => _goTo(next));
  }

  void _goTo(_AccountStage next) {
    if (!mounted) return;
    setState(() => _stage = next);

    switch (next) {
      case _AccountStage.info:
        _scheduleNext(const Duration(seconds: 7), _AccountStage.fingerprintCollect);
        break;
      case _AccountStage.fingerprintCollect:
        unawaited(CardReaderService.instance.setStatusLed('blue'));
        _scheduleNext(const Duration(seconds: 5), _AccountStage.fingerprintSuccess);
        break;
      case _AccountStage.fingerprintSuccess:
        unawaited(CardReaderService.instance.setStatusLed('green'));
        _scheduleNext(const Duration(seconds: 2), _AccountStage.loading);
        break;
      case _AccountStage.loading:
        unawaited(CardReaderService.instance.playFixedLedLoading());
        _scheduleNext(const Duration(seconds: 4), _AccountStage.accountSuccess);
        break;
      case _AccountStage.accountSuccess:
        unawaited(CardReaderService.instance.setStatusLed('green'));
        _scheduleNext(const Duration(seconds: 5), _AccountStage.qr);
        break;
      case _AccountStage.qr:
        _timer?.cancel();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      activeStep: _stage == _AccountStage.qr ? 3 : 1,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _buildStage(context),
      ),
    );
  }

  Widget _buildStage(BuildContext context) {
    switch (_stage) {
      case _AccountStage.info:
        return const _CenteredMessage(
          key: ValueKey('info'),
          icon: Icons.assignment_outlined,
          title: 'Abertura de conta',
          message: 'Forneça as informações solicitadas pelo atendente.\nVamos iniciar sua abertura de conta com segurança.',
        );
      case _AccountStage.fingerprintCollect:
        return _FingerprintStage(
          key: const ValueKey('fingerprintCollect'),
          controller: _fingerController,
          success: false,
        );
      case _AccountStage.fingerprintSuccess:
        return _FingerprintStage(
          key: const ValueKey('fingerprintSuccess'),
          controller: _fingerController,
          success: true,
        );
      case _AccountStage.loading:
        return _LoadingStage(
          key: const ValueKey('loading'),
          controller: _loadingController,
        );
      case _AccountStage.accountSuccess:
        return const _CenteredMessage(
          key: ValueKey('accountSuccess'),
          icon: Icons.check_circle_outline,
          iconColor: AppColors.success,
          title: 'Conta aberta com sucesso',
          message: 'Tudo certo. Sua conta foi criada e agora vamos finalizar a criação da senha pelo celular.',
        );
      case _AccountStage.qr:
        return const _QrStage(key: ValueKey('qr'));
    }
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor = AppColors.orange,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height <= 460;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 96 : 126,
                height: compact ? 96 : 126,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .1),
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor.withValues(alpha: .28)),
                ),
                child: Icon(icon, color: iconColor, size: compact ? 56 : 76),
              ),
              SizedBox(height: compact ? 18 : 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: compact ? 34 : 46,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: compact ? 17 : 21,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FingerprintStage extends StatelessWidget {
  const _FingerprintStage({
    super.key,
    required this.controller,
    required this.success,
  });

  final AnimationController controller;
  final bool success;

  @override
  Widget build(BuildContext context) {
    return ResponsiveTwoPane(
      left: Padding(
        padding: const EdgeInsets.only(left: 22, right: 10),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: InstructionPanel(
              title: success ? 'Digital\ncoletada' : 'Coleta\nde digital',
              messageSpans: success
                  ? const [
                      TextSpan(text: 'Digital coletada com '),
                      TextSpan(
                        text: 'sucesso',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(text: '.\nAguarde a validação.'),
                    ]
                  : const [
                      TextSpan(text: 'Agora vamos coletar sua '),
                      TextSpan(
                        text: 'digital',
                        style: TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(text: '.\nMantenha o dedo no sensor.'),
                    ],
            ),
          ),
        ),
      ),
      right: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final pulse = Curves.easeInOut.transform(controller.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Transform.scale(
                    scale: 1 + pulse * .08 + i * .12,
                    child: Opacity(
                      opacity: (.18 - i * .045).clamp(0, 1),
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: success ? AppColors.success : AppColors.orange,
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: 265,
                  height: 265,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (success ? AppColors.success : AppColors.orange)
                          .withValues(alpha: .32),
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
                  child: Icon(
                    success ? Icons.check_circle : Icons.fingerprint,
                    color: success ? AppColors.success : AppColors.orange,
                    size: 150,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoadingStage extends StatelessWidget {
  const _LoadingStage({super.key, required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) => CustomPaint(
                painter: _SpinnerPainter(progress: controller.value),
                child: child,
              ),
              child: const Center(
                child: Icon(Icons.sync, color: AppColors.orange, size: 58),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Criando sua conta',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 42,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Aguarde enquanto validamos as informações e concluímos a abertura.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 19,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 30),
          const SizedBox(
            width: 420,
            child: LinearProgressIndicator(
              minHeight: 8,
              backgroundColor: AppColors.line,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 8;
    final base = Paint()
      ..color = AppColors.orange.withValues(alpha: .14)
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
      -math.pi / 2 + progress * math.pi * 2,
      1.55,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _QrStage extends StatelessWidget {
  const _QrStage({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height <= 460;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Finalize pelo celular',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: compact ? 32 : 44,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Aponte a câmera do celular para o QR Code.\nNa tela do celular, vamos dar sequência na abertura de conta e criar sua senha numérica.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: compact ? 16 : 20,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/',
                              (route) => false,
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Concluir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 22 : 30,
                          vertical: compact ? 14 : 18,
                        ),
                        textStyle: TextStyle(
                          fontSize: compact ? 16 : 20,
                          fontWeight: FontWeight.w900,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 18 : 34),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 24,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/abertura_conta_qr.png',
                  width: compact ? 220 : 300,
                  height: compact ? 220 : 300,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechBadge extends StatelessWidget {
  const _TechBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 18,
        vertical: compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.orangeSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withValues(alpha: .22)),
      ),
      child: const Text(
        'Tecnologias usadas: atendimento assistido, biometria digital, validação simulada, QR Code e criação de senha numérica no celular.',
        style: TextStyle(
          color: AppColors.text,
          fontSize: 15,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
