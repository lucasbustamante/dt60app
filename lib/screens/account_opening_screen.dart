import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/bank_product.dart';
import '../services/card_reader_service.dart';
import '../services/journey_flow.dart';
import '../theme/app_theme.dart';
import '../widgets/app_frame.dart';
import '../widgets/numeric_keyboard.dart';

const accountOpeningResumeLoading = 'account_opening_resume_loading';

enum _AccountStage {
  info,
  confirmation,
  fingerprint,
  passwordFirst,
  passwordConfirm,
  face,
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
  late final AnimationController _pulseController;
  late final AnimationController _loadingController;
  String _password = '';
  String _passwordConfirmation = '';
  String? _passwordError;
  Timer? _stageTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments == accountOpeningResumeLoading && _stage != _AccountStage.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goTo(_AccountStage.loading));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _loadingController.dispose();
    _stageTimer?.cancel();
    unawaited(CardReaderService.instance.ledOff());
    super.dispose();
  }

  void _goTo(_AccountStage next) {
    if (!mounted) return;
    _stageTimer?.cancel();
    setState(() {
      _stage = next;
      if (next != _AccountStage.passwordConfirm) _passwordError = null;
    });

    switch (next) {
      case _AccountStage.fingerprint:
        unawaited(CardReaderService.instance.setStatusLed('blue'));
        _stageTimer = Timer(
          const Duration(milliseconds: 3600),
          () => _goTo(_AccountStage.passwordFirst),
        );
        break;
      case _AccountStage.face:
        unawaited(CardReaderService.instance.setStatusLed('blue'));
        unawaited(CardReaderService.instance.startFaceLedBlink());
        _stageTimer = Timer(
          const Duration(milliseconds: 4200),
          () => _goTo(_AccountStage.loading),
        );
        break;
      case _AccountStage.loading:
        unawaited(CardReaderService.instance.playFixedLedLoading());
        _stageTimer = Timer(const Duration(seconds: 3), () => _goTo(_AccountStage.accountSuccess));
        break;
      case _AccountStage.accountSuccess:
        unawaited(CardReaderService.instance.setStatusLed('green'));
        _stageTimer = Timer(const Duration(seconds: 3), () => _goTo(_AccountStage.qr));
        break;
      case _AccountStage.info:
      case _AccountStage.confirmation:
      case _AccountStage.passwordFirst:
      case _AccountStage.passwordConfirm:
      case _AccountStage.qr:
        break;
    }
  }

  void _startCredentialFlow() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      JourneyFlow.fingerprintBiometryRoute,
      (_) => false,
      arguments: AccountOpeningStepArgs(
        title: 'Cadastramento de\nbiometria digital',
        messageStart: 'Coloque o dedo no ',
        messageHighlight: 'sensor de biometria',
        messageEnd: '\ne aguarde o cadastramento.',
        nextRoute: JourneyFlow.passwordRoute,
        nextArguments: AccountOpeningStepArgs(
          title: 'Cadastramento\nde senha',
          messageStart: 'Cadastre uma senha de ',
          messageHighlight: '4 dígitos',
          messageEnd: '\ne confirme digitando novamente.',
          panelTitle: 'Cadastre sua senha',
          requirePasswordConfirmation: true,
          nextRoute: JourneyFlow.faceBiometryRoute,
          nextArguments: const AccountOpeningStepArgs(
            title: 'Cadastramento de\nbiometria facial',
            messageStart: 'Para cadastrar sua biometria,\n',
            messageHighlight: 'posicione seu rosto',
            messageEnd: ' na moldura\ne aguarde a captura.',
            nextRoute: '/abertura-conta',
            nextArguments: accountOpeningResumeLoading,
          ),
        ),
      ),
    );
  }

  void _cancel() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      JourneyFlow.errorRoute,
      (_) => false,
      arguments: const OperationFailure(
        title: 'Abertura cancelada',
        message: 'A abertura de conta foi cancelada com segurança.',
      ),
    );
  }

  void _addDigit(int digit) {
    setState(() {
      if (_stage == _AccountStage.passwordFirst && _password.length < 4) {
        _password += digit.toString();
      } else if (_stage == _AccountStage.passwordConfirm &&
          _passwordConfirmation.length < 4) {
        _passwordConfirmation += digit.toString();
        _passwordError = null;
      }
    });
  }

  void _backspace() {
    setState(() {
      if (_stage == _AccountStage.passwordFirst && _password.isNotEmpty) {
        _password = _password.substring(0, _password.length - 1);
      } else if (_stage == _AccountStage.passwordConfirm &&
          _passwordConfirmation.isNotEmpty) {
        _passwordConfirmation = _passwordConfirmation.substring(
          0,
          _passwordConfirmation.length - 1,
        );
      }
    });
  }

  void _clearPassword() {
    setState(() {
      if (_stage == _AccountStage.passwordFirst) {
        _password = '';
      } else if (_stage == _AccountStage.passwordConfirm) {
        _passwordConfirmation = '';
        _passwordError = null;
      }
    });
  }

  void _nextPasswordStep() {
    if (_stage == _AccountStage.passwordFirst) {
      if (_password.length < 4) return;
      _goTo(_AccountStage.passwordConfirm);
      return;
    }

    if (_passwordConfirmation.length < 4) return;
    if (_passwordConfirmation != _password) {
      setState(() {
        _passwordConfirmation = '';
        _passwordError = 'As senhas não conferem. Digite novamente.';
      });
      return;
    }

    _goTo(_AccountStage.face);
  }

  @override
  Widget build(BuildContext context) {
    final step = switch (_stage) {
      _AccountStage.info => 1,
      _AccountStage.confirmation => 1,
      _AccountStage.fingerprint => 2,
      _AccountStage.passwordFirst => 2,
      _AccountStage.passwordConfirm => 2,
      _AccountStage.face => 3,
      _AccountStage.loading => 3,
      _AccountStage.accountSuccess => 3,
      _AccountStage.qr => 3,
    };

    return AppFrame(
      activeStep: step,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: _buildStage(context),
      ),
    );
  }

  Widget _buildStage(BuildContext context) {
    switch (_stage) {
      case _AccountStage.info:
        return _IntroStage(
          key: const ValueKey('info'),
          onContinue: () => _goTo(_AccountStage.confirmation),
          onCancel: _cancel,
        );
      case _AccountStage.confirmation:
        return _ConfirmationStage(
          key: const ValueKey('confirmation'),
          onConfirm: _startCredentialFlow,
          onCancel: _cancel,
        );
      case _AccountStage.fingerprint:
        return _BiometryStage(
          key: const ValueKey('fingerprint'),
          controller: _pulseController,
          icon: Icons.fingerprint,
          title: 'Cadastramento de\nbiometria digital',
          message: 'Posicione o dedo no sensor. Aguarde enquanto cadastramos sua biometria.',
        );
      case _AccountStage.passwordFirst:
        return _PasswordStage(
          key: const ValueKey('passwordFirst'),
          title: 'Cadastramento\nde senha',
          subtitle: 'Digite uma senha numérica de 4 dígitos no pinpad.',
          passwordLength: _password.length,
          canContinue: _password.length == 4,
          buttonLabel: 'Continuar',
          onNumber: _addDigit,
          onBackspace: _backspace,
          onClear: _clearPassword,
          onContinue: _nextPasswordStep,
        );
      case _AccountStage.passwordConfirm:
        return _PasswordStage(
          key: const ValueKey('passwordConfirm'),
          title: 'Confirme sua senha',
          subtitle: 'Digite novamente os 4 dígitos para confirmar.',
          passwordLength: _passwordConfirmation.length,
          canContinue: _passwordConfirmation.length == 4,
          error: _passwordError,
          buttonLabel: 'Confirmar senha',
          onNumber: _addDigit,
          onBackspace: _backspace,
          onClear: _clearPassword,
          onContinue: _nextPasswordStep,
        );
      case _AccountStage.face:
        return _BiometryStage(
          key: const ValueKey('face'),
          controller: _pulseController,
          icon: Icons.face_retouching_natural_outlined,
          title: 'Cadastramento de\nbiometria facial',
          message: 'Olhe para a câmera e mantenha o rosto centralizado enquanto fazemos a captura.',
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
          message: 'Tudo certo. Sua conta foi criada e já está pronta para uso.',
        );
      case _AccountStage.qr:
        return const _QrStage(key: ValueKey('qr'));
    }
  }
}

class _IntroStage extends StatelessWidget {
  const _IntroStage({super.key, required this.onContinue, required this.onCancel});

  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height <= 460;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_outlined, color: AppColors.orange, size: compact ? 70 : 92),
              SizedBox(height: compact ? 16 : 24),
              Text(
                'Abertura de conta',
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
                'Forneça as informações solicitadas pelo colaborador. Em seguida, confira os dados antes de continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: compact ? 17 : 21,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: compact ? 20 : 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continuar'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmationStage extends StatelessWidget {
  const _ConfirmationStage({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  static const _data = <({String label, String value})>[
    (label: 'Nome', value: 'Lucas'),
    (label: 'Sobrenome', value: 'Bustamante'),
    (label: 'CPF', value: '***.456.789-**'),
    (label: 'Data de nascimento', value: '12/04/1995'),
    (label: 'E-mail', value: 'lucas.bustamante@email.com'),
    (label: 'Celular', value: '(11) 98765-4321'),
    (label: 'Endereço', value: 'Av. Eng. Luís Carlos Berrini, 1400'),
    (label: 'Cidade/UF', value: 'São Paulo/SP'),
    (label: 'CEP', value: '04571-000'),
    (label: 'Tipo de conta', value: 'Conta corrente individual'),
    (label: 'Pacote', value: 'Serviços essenciais'),
    (label: 'Canal de abertura', value: 'Atendimento assistido'),
  ];

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height <= 460;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight - 24
            : MediaQuery.sizeOf(context).height - 120;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 900, maxHeight: maxHeight),
              child: Container(
                padding: EdgeInsets.all(compact ? 12 : 18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirmação de dados',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: compact ? 24 : 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Confira as informações abaixo antes de prosseguir.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: compact ? 13 : 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(right: 10),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final item in _data)
                                _DataTile(
                                  label: item.label,
                                  value: item.value,
                                  compact: compact,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onConfirm,
                            icon: const Icon(Icons.check),
                            label: const Text('Confirmar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onCancel,
                            icon: const Icon(Icons.close),
                            label: const Text('Cancelar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DataTile extends StatelessWidget {
  const _DataTile({required this.label, required this.value, required this.compact});

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 250 : 270,
      child: Container(
        padding: EdgeInsets.all(compact ? 10 : 13),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: compact ? 11.5 : 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BiometryStage extends StatelessWidget {
  const _BiometryStage({
    super.key,
    required this.controller,
    required this.icon,
    required this.title,
    required this.message,
  });

  final AnimationController controller;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height <= 460;
    return ResponsiveTwoPane(
      left: Padding(
        padding: const EdgeInsets.only(left: 22, right: 10),
        child: Center(
          child: InstructionPanel(
            title: title,
            messageSpans: [
              TextSpan(text: '$message\n'),
              const TextSpan(
                text: 'Processo seguro e assistido.',
                style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
      right: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final pulse = Curves.easeInOut.transform(controller.value);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: 1 + pulse * .12,
                        child: Container(
                          width: compact ? 150 : 230,
                          height: compact ? 150 : 230,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.orange.withValues(alpha: .14),
                          ),
                        ),
                      ),
                      Container(
                        width: compact ? 150 : 230,
                        height: compact ? 150 : 230,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.orange.withValues(alpha: .32), width: 2),
                          boxShadow: const [
                            BoxShadow(color: Color(0x26000000), blurRadius: 28, offset: Offset(0, 18)),
                          ],
                        ),
                        child: Icon(icon, color: AppColors.orange, size: compact ? 86 : 132),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: compact ? 16 : 24),
              Text(
                'Capturando...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: compact ? 18 : 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordStage extends StatelessWidget {
  const _PasswordStage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.passwordLength,
    required this.canContinue,
    required this.buttonLabel,
    required this.onNumber,
    required this.onBackspace,
    required this.onClear,
    required this.onContinue,
    this.error,
  });

  final String title;
  final String subtitle;
  final int passwordLength;
  final bool canContinue;
  final String buttonLabel;
  final ValueChanged<int> onNumber;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onContinue;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height <= 460;
    return ResponsiveTwoPane(
      left: Padding(
        padding: const EdgeInsets.only(left: 22, right: 10),
        child: Center(
          child: InstructionPanel(
            title: title,
            messageSpans: [TextSpan(text: subtitle)],
          ),
        ),
      ),
      right: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 4; i++)
                    Container(
                      width: compact ? 18 : 24,
                      height: compact ? 18 : 24,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: i < passwordLength ? AppColors.orange : AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.orange, width: 1.5),
                      ),
                    ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)),
              ],
              SizedBox(height: compact ? 14 : 20),
              NumericKeyboard(
                buttonSize: compact ? 48 : 62,
                rowGap: compact ? 8 : 12,
                onNumber: onNumber,
                onBackspace: onBackspace,
                onClear: onClear,
              ),
              SizedBox(height: compact ? 12 : 18),
              ElevatedButton.icon(
                onPressed: canContinue ? onContinue : null,
                icon: const Icon(Icons.arrow_forward),
                label: Text(buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
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
              Icon(icon, color: iconColor, size: compact ? 76 : 108),
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

class _LoadingStage extends StatelessWidget {
  const _LoadingStage({super.key, required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height <= 460;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: compact ? 110 : 150,
            height: compact ? 110 : 150,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) => CustomPaint(
                painter: _SpinnerPainter(progress: controller.value),
                child: child,
              ),
              child: const Center(child: Icon(Icons.sync, color: AppColors.orange, size: 58)),
            ),
          ),
          SizedBox(height: compact ? 18 : 28),
          Text(
            'Finalizando abertura',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: compact ? 32 : 42,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Aguarde enquanto validamos as informações cadastradas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: compact ? 16 : 19, height: 1.35),
          ),
          const SizedBox(height: 28),
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
                      'Baixe o Super App',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: compact ? 32 : 44,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Aponte a câmera do celular para o QR Code e baixe o Super App para acessar sua nova conta.',
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
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Concluir'),
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
                    BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 14)),
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
