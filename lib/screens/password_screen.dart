import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bank_product.dart';
import '../services/card_reader_service.dart';
import '../services/journey_flow.dart';
import '../services/pinpad_keys.dart';
import '../theme/app_theme.dart';
import '../widgets/app_frame.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final FocusNode _focusNode = FocusNode();
  StreamSubscription<CardReaderEvent>? _pinpadSubscription;
  Timer? _focusTimer;
  String _pin = '';
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    unawaited(CardReaderService.instance.setStatusLed('yellow'));
    _pinpadSubscription = CardReaderService.instance.events.listen((event) {
      if (_leaving) return;
      switch (event.type) {
        case CardReaderEventType.pinpadEnter:
          _confirm();
          break;
        case CardReaderEventType.pinpadCancel:
          _cancel();
          break;
        case CardReaderEventType.pinpadClear:
          _clear();
          break;
        default:
          break;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureFocus());
    _focusTimer = Timer.periodic(
      const Duration(milliseconds: 700),
      (_) => _ensureFocus(),
    );
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    unawaited(_pinpadSubscription?.cancel());
    _focusNode.dispose();
    super.dispose();
  }

  void _ensureFocus() {
    if (!mounted || _leaving) return;
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _addNumber(String number) {
    if (_pin.length >= 4) return;

    setState(() {
      _pin += number;
    });
  }

  void _clear() {
    if (_pin.isEmpty) return;

    setState(() {
      _pin = '';
    });
  }

  void _confirm() {
    if (_pin.length != 4 || _leaving) return;
    _leaving = true;
    _focusTimer?.cancel();
    final accountStep = _accountOpeningStepArgs;
    if (accountStep != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        accountStep.nextRoute,
        (_) => false,
        arguments: accountStep.nextArguments,
      );
      return;
    }

    final session = _journeySession;
    final nextRoute = session == null
        ? JourneyFlow.successRoute
        : JourneyFlow.processingRoute;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(nextRoute, (_) => false, arguments: session);
  }

  void _cancel() {
    if (_leaving) return;
    _leaving = true;
    _focusTimer?.cancel();
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

  AccountOpeningStepArgs? get _accountOpeningStepArgs {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return arguments is AccountOpeningStepArgs ? arguments : null;
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    final label = event.character;

    if (label != null && RegExp(r'^[0-9]$').hasMatch(label)) {
      _addNumber(label);
      return;
    }

    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      _addNumber('0');
      return;
    }

    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      _addNumber('1');
      return;
    }

    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      _addNumber('2');
      return;
    }

    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      _addNumber('3');
      return;
    }

    if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      _addNumber('4');
      return;
    }

    if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      _addNumber('5');
      return;
    }

    if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      _addNumber('6');
      return;
    }

    if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      _addNumber('7');
      return;
    }

    if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
      _addNumber('8');
      return;
    }

    if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
      _addNumber('9');
      return;
    }

    if (PinpadKeys.isEnter(key)) {
      _confirm();
      return;
    }

    if (PinpadKeys.isClear(key)) {
      _clear();
      return;
    }

    if (PinpadKeys.isCancel(key)) {
      _cancel();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _ensureFocus,
          child: AppFrame(
            activeStep: 1,
            child: ResponsiveTwoPane(
              left: Padding(
                padding: const EdgeInsets.only(left: 22, right: 10),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: const InstructionPanel(
                      title: 'Digite\na senha',
                      messageSpans: [
                        TextSpan(text: 'Digite sua senha no '),
                        TextSpan(
                          text: 'teclado físico',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        TextSpan(text: '\ndo pinpad para continuar.'),
                      ],
                      helpText: 'Toque aqui para falar',
                      helpSubtitle: 'com nosso atendimento.',
                    ),
                  ),
                ),
              ),
              right: _PasswordPanel(
                pin: _pin,
                onCancel: _cancel,
                onConfirm: _confirm,
                onClear: _clear,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordPanel extends StatelessWidget {
  const _PasswordPanel({
    required this.pin,
    required this.onCancel,
    required this.onConfirm,
    required this.onClear,
  });

  final String pin;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mediaHeight = MediaQuery.sizeOf(context).height;
          final dense = mediaHeight <= 650 || constraints.maxHeight <= 440;
          final ultraDense = mediaHeight <= 460 || constraints.maxHeight <= 350;

          final iconBox = ultraDense ? 42.0 : (dense ? 58.0 : 96.0);
          final pinBox = ultraDense ? 34.0 : (dense ? 46.0 : 72.0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: const BoxDecoration(
                  color: AppColors.orangeSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: AppColors.orange,
                  size: ultraDense ? 24 : (dense ? 34 : 52),
                ),
              ),
              SizedBox(height: ultraDense ? 8 : (dense ? 12 : 26)),
              Text(
                'Digite sua senha',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: ultraDense ? 15 : (dense ? 18 : 24),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: ultraDense ? 8 : (dense ? 12 : 26)),
              _PinBoxes(
                pinLength: pin.length,
                boxSize: pinBox,
                gap: ultraDense ? 8 : (dense ? 10 : 14),
              ),
              SizedBox(height: ultraDense ? 18 : (dense ? 24 : 40)),
              _PinpadActions(
                dense: dense,
                ultraDense: ultraDense,
                pinLength: pin.length,
                onCancel: onCancel,
                onClear: onClear,
                onConfirm: onConfirm,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PinpadActions extends StatelessWidget {
  const _PinpadActions({
    required this.dense,
    required this.ultraDense,
    required this.pinLength,
    required this.onCancel,
    required this.onClear,
    required this.onConfirm,
  });

  final bool dense;
  final bool ultraDense;
  final int pinLength;
  final VoidCallback onCancel;
  final VoidCallback onClear;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = ultraDense ? 34.0 : (dense ? 42.0 : 52.0);
    final fontSize = ultraDense ? 12.0 : (dense ? 13.0 : 15.0);
    final iconSize = ultraDense ? 16.0 : (dense ? 18.0 : 21.0);
    final gap = ultraDense ? 8.0 : 12.0;

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Anula',
            icon: Icons.close,
            height: buttonHeight,
            fontSize: fontSize,
            iconSize: iconSize,
            color: AppColors.danger,
            filled: false,
            onPressed: onCancel,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _ActionButton(
            label: 'Limpa',
            icon: Icons.backspace_outlined,
            height: buttonHeight,
            fontSize: fontSize,
            iconSize: iconSize,
            color: AppColors.orange,
            filled: false,
            onPressed: pinLength == 0 ? null : onClear,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _ActionButton(
            label: 'Entra',
            icon: Icons.check,
            height: buttonHeight,
            fontSize: fontSize,
            iconSize: iconSize,
            color: AppColors.success,
            filled: true,
            onPressed: pinLength == 4 ? onConfirm : null,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.height,
    required this.fontSize,
    required this.iconSize,
    required this.color,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final double height;
  final double fontSize;
  final double iconSize;
  final Color color;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return SizedBox(
      height: height,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: iconSize),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: disabled ? AppColors.line : color,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.line,
                disabledForegroundColor: AppColors.muted,
                elevation: disabled ? 0 : 2,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: iconSize),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: disabled ? AppColors.muted : color,
                disabledForegroundColor: AppColors.muted,
                side: BorderSide(
                  color:
                      disabled ? AppColors.line : color.withValues(alpha: 0.75),
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
    );
  }
}

class _PinBoxes extends StatelessWidget {
  const _PinBoxes({
    required this.pinLength,
    required this.boxSize,
    required this.gap,
  });

  final int pinLength;
  final double boxSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < 4; index++) ...[
          _PinBox(
            filled: index < pinLength,
            active: index == pinLength && pinLength < 4,
            size: boxSize,
          ),
          if (index != 3) SizedBox(width: gap),
        ],
      ],
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({
    required this.filled,
    required this.active,
    required this.size,
  });

  final bool filled;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? AppColors.orange : AppColors.line,
          width: active ? 1.8 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: filled
            ? Container(
                width: size * 0.23,
                height: size * 0.23,
                decoration: const BoxDecoration(
                  color: AppColors.text,
                  shape: BoxShape.circle,
                ),
              )
            : AnimatedOpacity(
                duration: const Duration(milliseconds: 240),
                opacity: active ? 1 : 0,
                child: Container(
                  width: 2,
                  height: size * 0.48,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
      ),
    );
  }
}
