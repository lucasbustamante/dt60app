import 'dart:math' as math;

import 'package:flutter/material.dart';

class DocinhoScreen extends StatefulWidget {
  const DocinhoScreen({super.key});

  @override
  State<DocinhoScreen> createState() => _DocinhoScreenState();
}

class _DocinhoScreenState extends State<DocinhoScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _sparkleController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _sparkleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _floatController,
          _sparkleController,
          _pulseController,
        ]),
        builder: (context, _) {
          final float = math.sin(_floatController.value * math.pi * 2);
          final pulse = 1 + (_pulseController.value * 0.035);

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF1C7),
                  Color(0xFFFFD6E7),
                  Color(0xFFCFF8EF),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _CandyBackgroundPainter(
                    progress: _sparkleController.value,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 7,
                          child: Transform.translate(
                            offset: Offset(0, float * 8),
                            child: Transform.scale(
                              scale: pulse,
                              child: _PhotoCard(float: float),
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          flex: 5,
                          child: _MessagePanel(
                            progress: _sparkleController.value,
                            float: float,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.float});

  final double float;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white, width: 5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A3B16).withValues(alpha: 0.24),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/docinho.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _DocinhoFallback(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.10),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12 + (float * 2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'momento docinho 🍬',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7A3B16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocinhoFallback extends StatelessWidget {
  const _DocinhoFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD77A),
            Color(0xFFFF8DB8),
            Color(0xFF8FE8D3),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.cake_outlined,
          color: Colors.white,
          size: 120,
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.progress, required this.float});

  final double progress;
  final double float;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Transform.rotate(
          angle: math.sin(progress * math.pi * 2) * 0.035,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD47A48).withValues(alpha: 0.20),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Docinho de leite',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 38,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7A3B16),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'uma tela especial, leve e animada',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9B5A28),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: const [
            _SweetChip(label: '🍮 doce'),
            _SweetChip(label: '✨ brilho'),
            _SweetChip(label: '💛 carinho'),
          ],
        ),
        SizedBox(height: 16 + (float * 4)),
        const Text(
          'Comando: /command/docinho',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF7A3B16),
          ),
        ),
      ],
    );
  }
}

class _SweetChip extends StatelessWidget {
  const _SweetChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Color(0xFF7A3B16),
        ),
      ),
    );
  }
}

class _CandyBackgroundPainter extends CustomPainter {
  const _CandyBackgroundPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;

    final items = <_DecorItem>[
      _DecorItem(0.08, 0.16, 20, const Color(0xFFFF9EBC)),
      _DecorItem(0.18, 0.78, 14, const Color(0xFFFFC35A)),
      _DecorItem(0.35, 0.10, 11, const Color(0xFF6CDCC8)),
      _DecorItem(0.58, 0.86, 19, const Color(0xFFFF9EBC)),
      _DecorItem(0.78, 0.18, 16, const Color(0xFFFFC35A)),
      _DecorItem(0.92, 0.70, 24, const Color(0xFF6CDCC8)),
      _DecorItem(0.74, 0.52, 9, const Color(0xFFFF9EBC)),
      _DecorItem(0.45, 0.72, 12, const Color(0xFFFFC35A)),
    ];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final wave = math.sin((progress * math.pi * 2) + i);
      final center = Offset(
        item.x * size.width,
        (item.y * size.height) + (wave * 10),
      );

      dotPaint.color = item.color.withValues(alpha: 0.36);
      canvas.drawCircle(center, item.radius, dotPaint);

      ringPaint.color = item.color.withValues(alpha: 0.42);
      canvas.drawCircle(center, item.radius + 7 + (wave.abs() * 4), ringPaint);
    }

    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    for (double x = -size.width; x < size.width * 2; x += 135) {
      canvas.drawLine(
        Offset(x + progress * 90, size.height + 30),
        Offset(x + 180 + progress * 90, -30),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CandyBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _DecorItem {
  const _DecorItem(this.x, this.y, this.radius, this.color);

  final double x;
  final double y;
  final double radius;
  final Color color;
}
