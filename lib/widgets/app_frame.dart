import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppFrame extends StatelessWidget {
  const AppFrame({
    super.key,
    required this.child,
    this.activeStep,
    this.showSteps = true,
  });

  final Widget child;
  final int? activeStep;
  final bool showSteps;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: false,
      body: ColoredBox(
        color: AppColors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = MediaQuery.sizeOf(context);
            final aspect = size.width / size.height;

            final miniLandscape =
                size.width >= 520 && size.height <= 460 && aspect >= 1.45;

            final isPinpadLandscape =
                size.width >= 620 && size.height <= 650 && aspect >= 1.45;

            final compact = constraints.maxWidth < 720;

            final horizontalPadding = miniLandscape
                ? 8.0
                : (isPinpadLandscape ? 12.0 : (compact ? 20.0 : 48.0));

            final topPadding = miniLandscape
                ? 0.0
                : (isPinpadLandscape ? 0.0 : (compact ? 6.0 : 10.0));

            final bottomPadding = miniLandscape
                ? 2.0
                : (isPinpadLandscape ? 3.0 : (compact ? 18.0 : 26.0));

            return SizedBox.expand(
              child: Column(
                children: [
                  _Header(activeStep: activeStep, showSteps: showSteps),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        topPadding,
                        horizontalPadding,
                        bottomPadding,
                      ),
                      child: child,
                    ),
                  ),
                  const _SecurityFooter(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ResponsiveTwoPane extends StatelessWidget {
  const ResponsiveTwoPane({
    super.key,
    required this.left,
    required this.right,
    this.leftFlex = 8,
    this.rightFlex = 12,
  });

  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        final miniLandscape = MediaQuery.sizeOf(context).height <= 460 ||
            constraints.maxHeight <= 330;
        final dense = MediaQuery.sizeOf(context).height <= 650 ||
            constraints.maxHeight <= 430;

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: leftFlex,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Align(
                      alignment: miniLandscape
                          ? Alignment.centerLeft
                          : (dense ? Alignment.topLeft : Alignment.centerLeft),
                      child: left,
                    ),
                  ),
                ),
              ),
              SizedBox(width: miniLandscape ? 8 : (dense ? 12 : 28)),
              Expanded(
                flex: rightFlex,
                child: Center(child: right),
              ),
            ],
          );
        }

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                left,
                const SizedBox(height: 30),
                Center(child: right),
              ],
            ),
          ),
        );
      },
    );
  }
}

class InstructionPanel extends StatelessWidget {
  const InstructionPanel({
    super.key,
    required this.title,
    required this.messageSpans,
    this.maxWidth = 420,
    this.helpText = 'Toque aqui',
    this.helpSubtitle,
  });

  final String title;
  final List<InlineSpan> messageSpans;
  final double maxWidth;
  final String helpText;
  final String? helpSubtitle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final miniLandscape = MediaQuery.sizeOf(context).height <= 460 ||
            constraints.maxHeight <= 330;
        final dense = MediaQuery.sizeOf(context).height <= 650 ||
            constraints.maxHeight <= 430;

        final titleStyle = (compact || dense)
            ? AppTextStyles.titleCompact.copyWith(
                fontSize: miniLandscape ? 20 : (dense ? 25 : null),
                height: miniLandscape ? 0.98 : (dense ? 1.02 : null),
              )
            : AppTextStyles.title;

        final bodyStyle = (compact || dense)
            ? AppTextStyles.bodyCompact.copyWith(
                fontSize: miniLandscape ? 11.5 : (dense ? 13 : null),
                height: miniLandscape ? 1.12 : (dense ? 1.2 : null),
              )
            : AppTextStyles.body;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle),
              SizedBox(height: miniLandscape ? 4 : (dense ? 7 : 22)),
              Container(
                width: miniLandscape ? 42 : (dense ? 54 : 72),
                height: miniLandscape ? 3 : (dense ? 4 : 6),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              SizedBox(height: miniLandscape ? 5 : (dense ? 8 : 28)),
              RichText(
                text: TextSpan(style: bodyStyle, children: messageSpans),
              ),
              if (!miniLandscape) SizedBox(height: dense ? 10 : 70),
              if (!miniLandscape)
                HelpCard(text: helpText, subtitle: helpSubtitle, dense: dense),
            ],
          ),
        );
      },
    );
  }
}

class HelpCard extends StatelessWidget {
  const HelpCard({
    super.key,
    required this.text,
    this.subtitle,
    this.dense = false,
  });

  final String text;
  final String? subtitle;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 16 : 20,
        vertical: dense ? 13 : 18,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dense ? 46 : 54,
            height: dense ? 46 : 54,
            decoration: const BoxDecoration(
              color: AppColors.orangeSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.headset_mic_outlined,
              color: AppColors.orange,
              size: dense ? 28 : 32,
            ),
          ),
          SizedBox(width: dense ? 14 : 18),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precisa de ajuda?',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: dense ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: dense ? 1 : 4),
                Text(
                  subtitle == null ? text : '$text\n$subtitle',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: dense ? 13 : 15,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.activeStep, required this.showSteps});

  final int? activeStep;
  final bool showSteps;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final miniLandscape = MediaQuery.sizeOf(context).height <= 460;
        final dense = MediaQuery.sizeOf(context).height <= 650;

        final horizontal =
            miniLandscape ? 8.0 : (dense ? 14.0 : (compact ? 22.0 : 42.0));

        final height = showSteps
            ? (miniLandscape
                ? 82.0
                : (dense ? 88.0 : (compact ? 138.0 : 122.0)))
            : (miniLandscape
                ? 46.0
                : (dense ? 58.0 : (compact ? 96.0 : 112.0)));

        return SizedBox(
          height: height,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              miniLandscape ? 2 : (dense ? 4 : (compact ? 14 : 22)),
              horizontal,
              dense ? 0 : 8,
            ),
            child: miniLandscape
                ? _wideHeader()
                : (compact ? _compactHeader() : _wideHeader()),
          ),
        );
      },
    );
  }

  Widget _wideHeader() {
    return Stack(
      children: [
        const Align(alignment: Alignment.topLeft, child: _BrandMark()),
        if (showSteps)
          Align(
            alignment: Alignment.topCenter,
            child: _ProcessSteps(activeStep: activeStep, compact: false),
          ),
        const Align(alignment: Alignment.topRight, child: _DeviceStatus()),
      ],
    );
  }

  Widget _compactHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_BrandMark(compact: true), _DeviceStatus(compact: true)],
        ),
        if (showSteps) ...[
          const SizedBox(height: 8),
          _ProcessSteps(activeStep: activeStep, compact: true),
        ],
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 48.0 : 68.0;
    final dense = MediaQuery.sizeOf(context).height <= 650;
    final miniLandscape = MediaQuery.sizeOf(context).height <= 460;
    final resolvedLogoSize = miniLandscape ? 28.0 : (dense ? 34.0 : logoSize);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: resolvedLogoSize,
          height: resolvedLogoSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.orange, AppColors.orangeDark],
            ),
            borderRadius: BorderRadius.circular(5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26FF5A00),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            'itaú',
            style: TextStyle(
              color: AppColors.white,
              fontSize: miniLandscape ? 14 : (dense ? 17 : (compact ? 24 : 34)),
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        SizedBox(width: dense ? 10 : (compact ? 10 : 16)),
        Text(
          'feito\nde\nfuturo',
          style: TextStyle(
            color: AppColors.text,
            fontSize: miniLandscape ? 9 : (dense ? 11 : (compact ? 15 : 20)),
            height: 1.02,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ProcessSteps extends StatelessWidget {
  const _ProcessSteps({required this.activeStep, required this.compact});

  final int? activeStep;
  final bool compact;

  static const _labels = ['Cartão', 'Senha', 'Biometria', 'Conclusão'];

  static const _icons = [
    Icons.credit_card_outlined,
    Icons.lock_outline,
    Icons.fingerprint,
    Icons.check,
  ];

  @override
  Widget build(BuildContext context) {
    final miniLandscape = MediaQuery.sizeOf(context).height <= 460;

    if (miniLandscape) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < _labels.length; index++) ...[
          _StepNode(
            index: index,
            activeStep: activeStep,
            icon: _icons[index],
            label: _labels[index],
            compact: compact,
          ),
          if (index != _labels.length - 1)
            Padding(
              padding: EdgeInsets.only(top: compact ? 19 : 24),
              child: _StepConnector(compact: compact),
            ),
        ],
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.activeStep,
    required this.icon,
    required this.label,
    required this.compact,
  });

  final int index;
  final int? activeStep;
  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final active = activeStep == index;
    final complete = activeStep != null && index < activeStep!;
    final miniLandscape = MediaQuery.sizeOf(context).height <= 460;
    final dense = MediaQuery.sizeOf(context).height <= 650;

    final size =
        miniLandscape ? 21.0 : (dense ? 26.0 : (compact ? 38.0 : 48.0));
    final width =
        miniLandscape ? 48.0 : (dense ? 58.0 : (compact ? 64.0 : 82.0));
    final color = active ? AppColors.orange : AppColors.muted;
    final nodeIcon = complete ? Icons.check : icon;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: active ? AppColors.orange : AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? AppColors.orange : AppColors.line,
                width: 1.2,
              ),
              boxShadow: active
                  ? const [
                      BoxShadow(
                        color: Color(0x33FF5A00),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              nodeIcon,
              color: active ? AppColors.white : color,
              size: miniLandscape ? 13 : (dense ? 17 : (compact ? 21 : 25)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? AppColors.orange : AppColors.muted,
              fontSize: miniLandscape ? 9 : (dense ? 11 : (compact ? 12 : 14)),
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dense = MediaQuery.sizeOf(context).height <= 650;

    return Container(
      width: dense ? 12 : (compact ? 18 : 48),
      height: 1.2,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _DeviceStatus extends StatefulWidget {
  const _DeviceStatus({this.compact = false});

  final bool compact;

  @override
  State<_DeviceStatus> createState() => _DeviceStatusState();
}

class _DeviceStatusState extends State<_DeviceStatus> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';

    final miniLandscape = MediaQuery.sizeOf(context).height <= 460;
    final dense = MediaQuery.sizeOf(context).height <= 650;

    final iconSize =
        miniLandscape ? 13.0 : (dense ? 16.0 : (widget.compact ? 18.0 : 24.0));

    final timeSize =
        miniLandscape ? 14.0 : (dense ? 17.0 : (widget.compact ? 19.0 : 25.0));

    final dateSize =
        miniLandscape ? 8.0 : (dense ? 9.5 : (widget.compact ? 10.5 : 13.0));

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi, color: Colors.black, size: iconSize),
              SizedBox(width: miniLandscape ? 5 : 8),
              Text(
                time,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: timeSize,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                  height: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: miniLandscape ? 1 : 3),
          Text(
            _formattedDate(_now),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontSize: dateSize,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  String _formattedDate(DateTime date) {
    const weekdays = [
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
    ];

    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    return '${date.day} de ${months[date.month - 1]}, ${weekdays[date.weekday - 1]}';
  }
}

class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final miniLandscape = MediaQuery.sizeOf(context).height <= 460;
        final dense = MediaQuery.sizeOf(context).height <= 650;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: miniLandscape ? 8 : (dense ? 14 : (compact ? 22 : 42)),
            vertical: miniLandscape ? 1 : (dense ? 3 : (compact ? 12 : 16)),
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.navy, AppColors.navySoft],
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: miniLandscape ? 2 : (dense ? 4 : 14),
            spacing: miniLandscape ? 10 : (dense ? 14 : 24),
            children: [
              _FooterItem(
                dense: dense,
                icon: Icons.verified_user_outlined,
                title: 'Ambiente seguro',
                subtitle: 'Seus dados estão protegidos.',
              ),
              _FooterItem(
                dense: dense,
                icon: Icons.lock_outline,
                title: 'LGPD',
                subtitle: 'Protegemos seus dados.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FooterItem extends StatelessWidget {
  const _FooterItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.dense = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: dense ? 160 : 320,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white, size: dense ? 18 : 36),
          SizedBox(width: dense ? 10 : 16),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: dense ? 11 : 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: dense ? 1 : 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFE6EEF8),
                    fontSize: dense ? 9 : 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
