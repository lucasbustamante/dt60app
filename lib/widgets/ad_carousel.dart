import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AdKind { bag, pet, health, card }

class AdContent {
  const AdContent({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.callToAction,
    required this.icon,
    required this.primary,
    required this.secondary,
    required this.features,
    this.price,
  });

  final AdKind kind;
  final String title;
  final String subtitle;
  final String callToAction;
  final IconData icon;
  final Color primary;
  final Color secondary;
  final List<String> features;
  final String? price;
}

class AdCarousel extends StatefulWidget {
  const AdCarousel({super.key});

  @override
  State<AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<AdCarousel> {
  static const int _initialPage = 1000;

  final PageController _controller = PageController(
    initialPage: _initialPage,
    viewportFraction: 0.62,
  );

  int _currentPage = _initialPage;
  Timer? _timer;

  static const List<AdContent> _ads = [
    AdContent(
      kind: AdKind.bag,
      title: 'Seguro\nBolsa Protegida',
      subtitle: 'Proteção para seus pertences dentro e fora de casa.',
      callToAction: 'Saiba mais',
      icon: Icons.work_outline,
      primary: AppColors.orange,
      secondary: AppColors.orangeDark,
      features: [
        'Cobertura nacional',
        'Assistência 24h',
        'Cancele quando quiser',
      ],
      price: 'R\$ 8,90/mês',
    ),
    AdContent(
      kind: AdKind.pet,
      title: 'Seguro\nPet Itaú',
      subtitle: 'Cuidado veterinário, exames e apoio para seu melhor amigo.',
      callToAction: 'Contratar',
      icon: Icons.pets_outlined,
      primary: Color(0xFFFF7A1A),
      secondary: Color(0xFFFF4C00),
      features: [
        'Assistência veterinária',
        'Reembolso consultas',
        'Cobertura nacional',
      ],
      price: 'R\$ 29,90/mês',
    ),
    AdContent(
      kind: AdKind.health,
      title: 'Saúde\nItaú',
      subtitle: 'Consultas, exames e descontos para cuidar de você.',
      callToAction: 'Ver opções',
      icon: Icons.favorite_border,
      primary: Color(0xFF0F766E),
      secondary: Color(0xFF14B8A6),
      features: [
        'Consultas online',
        'Descontos em exames',
        'Rede de farmácias',
      ],
      price: 'A partir de R\$ 19,90',
    ),
    AdContent(
      kind: AdKind.card,
      title: 'Cartão com\nmais controle',
      subtitle: 'Controle seus gastos, limites e segurança direto no app.',
      callToAction: 'Conhecer',
      icon: Icons.credit_card_outlined,
      primary: AppColors.navy,
      secondary: Color(0xFF14395F),
      features: ['Senha protegida', 'Avisos em tempo real', 'Limite ajustável'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _nextPage());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (!_controller.hasClients) return;

    _controller.animateToPage(
      _currentPage + 1,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  int _realIndex(int index) => index % _ads.length;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final maxHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 430.0;

        final height = maxHeight
            .clamp(compact ? 255.0 : 270.0, compact ? 390.0 : 405.0)
            .toDouble();

        return SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            clipBehavior: Clip.none,
            allowImplicitScrolling: true,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            itemBuilder: (context, index) {
              final ad = _ads[_realIndex(index)];

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double page = _currentPage.toDouble();

                  if (_controller.hasClients &&
                      _controller.position.haveDimensions &&
                      _controller.page != null) {
                    page = _controller.page!;
                  }

                  final distance = (page - index).abs().clamp(0.0, 1.0);
                  final active = distance < 0.45;

                  final scale = active ? 1.0 : 0.88;
                  final opacity = active ? 1.0 : 0.48;
                  final blur = active ? 0.0 : 0.8;

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: blur,
                          sigmaY: blur,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: _AdCard(ad: ad),
              );
            },
          ),
        );
      },
    );
  }
}

class _AdCard extends StatelessWidget {
  const _AdCard({required this.ad});

  final AdContent ad;

  @override
  Widget build(BuildContext context) {
    switch (ad.kind) {
      case AdKind.bag:
        return _OrangeFeatureCard(ad: ad);
      case AdKind.pet:
        return _SplitBenefitsCard(ad: ad);
      case AdKind.health:
        return _HealthCard(ad: ad);
      case AdKind.card:
        return _ControlCard(ad: ad);
    }
  }
}

class _OrangeFeatureCard extends StatelessWidget {
  const _OrangeFeatureCard({required this.ad});

  final AdContent ad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ad.primary, ad.secondary],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -4,
            bottom: -4,
            child: _ShieldProductIcon(icon: ad.icon, size: 96, compact: true),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: AppColors.white,
                size: 28,
              ),
              const SizedBox(height: 10),
              Text(
                ad.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 19,
                  height: 1.02,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 7),
              SizedBox(
                width: 180,
                child: Text(
                  ad.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    height: 1.18,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _LightCta(label: ad.callToAction),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitBenefitsCard extends StatelessWidget {
  const _SplitBenefitsCard({required this.ad});

  final AdContent ad;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(color: AppColors.white),
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ad.primary, ad.secondary],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
              child: Center(
                child: _ShieldProductIcon(
                  icon: ad.icon,
                  size: 90,
                  compact: true,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 13,
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(ad.icon, color: AppColors.orange, size: 25),
                  const SizedBox(height: 6),
                  Text(
                    ad.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15.5,
                      height: 1.02,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final feature in ad.features) _FeatureRow(text: feature),
                  const Spacer(),
                  if (ad.price != null) _PriceLine(price: ad.price!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.ad});

  final AdContent ad;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(color: AppColors.white),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: ad.secondary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [ad.primary, ad.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_outlined,
                        color: AppColors.white,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cuidado diário',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ad.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  ad.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 19,
                    height: 0.98,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  ad.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 11,
                    height: 1.12,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 7),
                _SimpleBenefit(
                  icon: Icons.video_call_outlined,
                  text: 'Consultas online',
                  color: ad.primary,
                ),
                const SizedBox(height: 4),
                _SimpleBenefit(
                  icon: Icons.receipt_long_outlined,
                  text: 'Descontos em exames',
                  color: ad.primary,
                ),
                const SizedBox(height: 4),
                _SimpleBenefit(
                  icon: Icons.local_pharmacy_outlined,
                  text: 'Rede de farmácias',
                  color: ad.primary,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ad.price ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ad.primary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    _SmallSolidButton(
                      label: ad.callToAction,
                      color: ad.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({required this.ad});

  final AdContent ad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: _cardDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ad.primary, ad.secondary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Controle pelo app',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _MiniCreditCard(),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            ad.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 19,
              height: 0.98,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            ad.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE6EEF8),
              fontSize: 11,
              height: 1.12,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          _CardBenefit(
            icon: Icons.lock_outline,
            title: 'Senha protegida',
            subtitle: 'Seguro',
          ),
          const SizedBox(height: 4),
          _CardBenefit(
            icon: Icons.notifications_active_outlined,
            title: 'Avisos em tempo real',
            subtitle: 'Na hora',
          ),
          const SizedBox(height: 4),
          _CardBenefit(
            icon: Icons.tune_outlined,
            title: 'Limite ajustável',
            subtitle: 'Controle',
          ),
        ],
      ),
    );
  }
}

class _SimpleBenefit extends StatelessWidget {
  const _SimpleBenefit({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 27,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.4,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBenefit extends StatelessWidget {
  const _CardBenefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 10.3,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE6EEF8),
              fontSize: 8.4,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCreditCard extends StatelessWidget {
  const _MiniCreditCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 35,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.credit_card_outlined, color: AppColors.white, size: 15),
          Spacer(),
          Row(
            children: [
              _CardLine(width: 16),
              SizedBox(width: 4),
              _CardLine(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardLine extends StatelessWidget {
  const _CardLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _SmallSolidButton extends StatelessWidget {
  const _SmallSolidButton({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({Color? color, Gradient? gradient}) {
  return BoxDecoration(
    color: color,
    gradient: gradient,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0x16000000)),
    boxShadow: const [
      BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 8)),
    ],
  );
}

class _ShieldProductIcon extends StatelessWidget {
  const _ShieldProductIcon({
    required this.icon,
    this.compact = false,
    this.size = 145,
  });

  final IconData icon;
  final bool compact;
  final double size;

  @override
  Widget build(BuildContext context) {
    final innerSize = compact ? 44.0 : 60.0;
    final iconSize = compact ? 27.0 : 39.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            color: AppColors.white.withValues(alpha: 0.88),
            size: size,
          ),
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.17),
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.white.withValues(alpha: 0.50)),
            ),
            child: Icon(icon, color: AppColors.white, size: iconSize),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.orange,
            size: 15,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 10.2,
                height: 1.08,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.price});

  final String price;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: AppColors.line),
        const SizedBox(height: 5),
        const Text(
          'A partir de',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 9,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          price,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.orange,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _LightCta extends StatelessWidget {
  const _LightCta({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.orange,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
