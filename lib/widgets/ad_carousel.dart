import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AdBanner {
  const AdBanner({required this.assetPath, required this.semanticLabel});

  final String assetPath;
  final String semanticLabel;
}

class AdCarousel extends StatefulWidget {
  const AdCarousel({super.key});

  @override
  State<AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<AdCarousel> {
  static const int _initialPage = 1600;

  final PageController _controller = PageController(
    initialPage: _initialPage,
    viewportFraction: 0.86,
  );

  int _currentPage = _initialPage;
  Timer? _timer;

  static const List<AdBanner> _ads = [
    AdBanner(
      assetPath: 'assets/images/ads/seguranca_digital.png',
      semanticLabel: 'Segurança digital',
    ),
    AdBanner(
      assetPath: 'assets/images/ads/protecao_golpes.png',
      semanticLabel: 'Proteção contra golpes',
    ),
    AdBanner(
      assetPath: 'assets/images/ads/cartao_aproximacao.png',
      semanticLabel: 'Uso do cartão por aproximação',
    ),
    AdBanner(
      assetPath: 'assets/images/ads/cartao_virtual.png',
      semanticLabel: 'Cartão virtual',
    ),
    AdBanner(
      assetPath: 'assets/images/ads/pix_seguro.png',
      semanticLabel: 'Pix seguro',
    ),
    AdBanner(
      assetPath: 'assets/images/ads/dicas_financeiras.png',
      semanticLabel: 'Dicas financeiras',
    ),
    AdBanner(
      assetPath: 'assets/images/ads/seguro_pet.png',
      semanticLabel: 'Seguro Pet',
    ),
    AdBanner(
      assetPath: 'assets/images/ads/seguro_saude.png',
      semanticLabel: 'Seguro Saúde',
    ),
    AdBanner(
      assetPath: 'assets/images/ads/bolsa_protegida.png',
      semanticLabel: 'Bolsa Protegida',
    ),
    AdBanner(
      assetPath: 'assets/images/ads/protecao_residencial.png',
      semanticLabel: 'Proteção residencial',
    ),
    AdBanner(
      assetPath: 'assets/images/ads/assistencia_veicular.png',
      semanticLabel: 'Assistência veicular',
    ),
    AdBanner(
      assetPath: 'assets/images/ads/investimentos.png',
      semanticLabel: 'Investimentos',
    ),
    AdBanner(
      assetPath: 'assets/images/ads/programa_beneficios.png',
      semanticLabel: 'Programa de benefícios',
    ),
    AdBanner(
      assetPath: 'assets/images/ads/cashback.png',
      semanticLabel: 'Cashback',
    ),
    AdBanner(
      assetPath: 'assets/images/ads/educacao_financeira.png',
      semanticLabel: 'Educação financeira',
    ),
    AdBanner(
      assetPath: 'assets/images/ads/atualizacoes_banco.png',
      semanticLabel: 'Atualizações do banco',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _nextPage());
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
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  int _realIndex(int index) => index % _ads.length;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 390.0;
        final height = maxHeight.clamp(220.0, 430.0).toDouble();

        return SizedBox(
          height: height,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  clipBehavior: Clip.none,
                  allowImplicitScrolling: true,
                  onPageChanged: (page) => setState(() => _currentPage = page),
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
                        final scale = active ? 1.0 : 0.92;
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: child,
                              ),
                            ),
                          ),
                        );
                      },
                      child: _BannerImage(ad: ad),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              _CarouselDots(
                itemCount: _ads.length,
                activeIndex: _realIndex(_currentPage),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.ad});

  final AdBanner ad;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.asset(
            ad.assetPath,
            fit: BoxFit.cover,
            semanticLabel: ad.semanticLabel,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.orangeSoft,
                alignment: Alignment.center,
                child: Text(
                  ad.semanticLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({required this.itemCount, required this.activeIndex});

  final int itemCount;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 5,
      runSpacing: 5,
      children: [
        for (var index = 0; index < itemCount; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            width: index == activeIndex ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: index == activeIndex
                  ? AppColors.orange
                  : AppColors.orange.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}
