import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NumericKeyboard extends StatelessWidget {
  const NumericKeyboard({
    super.key,
    required this.onNumber,
    required this.onBackspace,
    required this.onClear,
    this.buttonSize = 68,
    this.rowGap = 14,
  });

  final ValueChanged<int> onNumber;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final double buttonSize;
  final double rowGap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        children: [
          _KeyboardRow(
            buttonSize: buttonSize,
            children: [
              _KeyboardButton(
                label: '1',
                buttonSize: buttonSize,
                onTap: () => onNumber(1),
              ),
              _KeyboardButton(
                label: '2',
                buttonSize: buttonSize,
                onTap: () => onNumber(2),
              ),
              _KeyboardButton(
                label: '3',
                buttonSize: buttonSize,
                onTap: () => onNumber(3),
              ),
            ],
          ),
          SizedBox(height: rowGap),
          _KeyboardRow(
            buttonSize: buttonSize,
            children: [
              _KeyboardButton(
                label: '4',
                buttonSize: buttonSize,
                onTap: () => onNumber(4),
              ),
              _KeyboardButton(
                label: '5',
                buttonSize: buttonSize,
                onTap: () => onNumber(5),
              ),
              _KeyboardButton(
                label: '6',
                buttonSize: buttonSize,
                onTap: () => onNumber(6),
              ),
            ],
          ),
          SizedBox(height: rowGap),
          _KeyboardRow(
            buttonSize: buttonSize,
            children: [
              _KeyboardButton(
                label: '7',
                buttonSize: buttonSize,
                onTap: () => onNumber(7),
              ),
              _KeyboardButton(
                label: '8',
                buttonSize: buttonSize,
                onTap: () => onNumber(8),
              ),
              _KeyboardButton(
                label: '9',
                buttonSize: buttonSize,
                onTap: () => onNumber(9),
              ),
            ],
          ),
          SizedBox(height: rowGap),
          _KeyboardRow(
            buttonSize: buttonSize,
            children: [
              _KeyboardButton(
                semanticLabel: 'Apagar último dígito',
                icon: Icons.backspace_outlined,
                buttonSize: buttonSize,
                onTap: onBackspace,
              ),
              _KeyboardButton(
                label: '0',
                buttonSize: buttonSize,
                onTap: () => onNumber(0),
              ),
              _KeyboardButton(
                label: 'Limpar',
                compactText: true,
                buttonSize: buttonSize,
                onTap: onClear,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyboardRow extends StatelessWidget {
  const _KeyboardRow({required this.children, required this.buttonSize});

  final List<Widget> children;
  final double buttonSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final child in children)
          child is _KeyboardButton && child.buttonSize == buttonSize
              ? child
              : SizedBox(width: buttonSize, height: buttonSize, child: child),
      ],
    );
  }
}

class _KeyboardButton extends StatelessWidget {
  const _KeyboardButton({
    this.label,
    this.icon,
    this.semanticLabel,
    required this.onTap,
    this.compactText = false,
    this.buttonSize = 68,
  });

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback onTap;
  final bool compactText;
  final double buttonSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: Material(
        color: AppColors.white,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.line, width: 1.2),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: Center(
              child: icon == null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label ?? '',
                          maxLines: 1,
                          style: TextStyle(
                            color:
                                compactText ? AppColors.orange : Colors.black,
                            fontSize: compactText
                                ? buttonSize * 0.22
                                : buttonSize * 0.38,
                            fontWeight:
                                compactText ? FontWeight.w700 : FontWeight.w400,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    )
                  : Icon(icon, color: AppColors.text, size: buttonSize * 0.36),
            ),
          ),
        ),
      ),
    );
  }
}
