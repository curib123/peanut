import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/game_primary_button.dart';
import '../../../core/widgets/glass_panel.dart';

/// A finite celebration: ratings and score always come from the finished level.
class VictoryCelebration extends StatefulWidget {
  const VictoryCelebration({
    super.key,
    required this.stars,
    required this.score,
    required this.movesRemaining,
    required this.reducedMotion,
    required this.onMap,
    this.onNext,
  });

  final int stars;
  final int score;
  final int movesRemaining;
  final bool reducedMotion;
  final VoidCallback onMap;
  final VoidCallback? onNext;

  @override
  State<VictoryCelebration> createState() => _VictoryCelebrationState();
}

class _VictoryCelebrationState extends State<VictoryCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebration = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
    value: widget.reducedMotion ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reducedMotion) _celebration.forward();
  }

  @override
  void didUpdateWidget(covariant VictoryCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion && !oldWidget.reducedMotion) {
      _celebration.stop();
      _celebration.value = 1;
    }
  }

  @override
  void dispose() {
    _celebration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xC21C1214),
    child: Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -.4),
                  radius: 1,
                  colors: [Color(0x665EB8A8), Color(0x002A1718)],
                ),
              ),
            ),
          ),
        ),
        if (!widget.reducedMotion)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _CelebrationConfetti(_celebration)),
              ),
            ),
          ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: AnimatedBuilder(
                  animation: _celebration,
                  builder: (context, child) {
                    final entrance = Curves.easeOutCubic.transform(
                      (_celebration.value / .38).clamp(0, 1),
                    );
                    return Opacity(
                      opacity: entrance,
                      child: Transform.translate(
                        offset: Offset(0, (1 - entrance) * 24),
                        child: child,
                      ),
                    );
                  },
                  child: GlassPanel(
                    tint: const Color(0xFFBE7B36),
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 172,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Color(0x66FFE7A2),
                                      Color(0x00FFD077),
                                    ],
                                  ),
                                ),
                                child: SizedBox(width: 220, height: 172),
                              ),
                              ExcludeSemantics(
                                child: Image.asset(
                                  'assets/images/ui/victory_trophy.png',
                                  height: 166,
                                  cacheWidth: 480,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'RECIPE COMPLETE',
                          style: TextStyle(
                            color: Color(0xFFB2E9D4),
                            fontSize: 10,
                            letterSpacing: 2.3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Perfect Batch!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: const Color(0xFFFFE2A1),
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Semantics(
                          label: '${widget.stars} of 3 stars earned',
                          child: ExcludeSemantics(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                3,
                                (index) => AnimatedBuilder(
                                  animation: _celebration,
                                  builder: (context, child) {
                                    final reveal = widget.reducedMotion
                                        ? 1.0
                                        : ((_celebration.value -
                                                      .16 -
                                                      index * .12) /
                                                  .28)
                                              .clamp(0.0, 1.0);
                                    return Transform.scale(
                                      scale:
                                          .65 +
                                          .35 *
                                              Curves.easeOutBack.transform(
                                                reveal,
                                              ),
                                      child: Opacity(
                                        opacity: reveal,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Icon(
                                    index < widget.stars
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: index < widget.stars
                                        ? const Color(0xFFFFCA59)
                                        : const Color(0xFFBFA487),
                                    size: index == 1 ? 50 : 42,
                                    shadows: index < widget.stars
                                        ? const [
                                            Shadow(
                                              color: Color(0x88D86B1D),
                                              blurRadius: 16,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x66221617),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0x44EFD198)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Score: ${widget.score}',
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Includes ${widget.movesRemaining * 100} unused-move bonus',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFE5CCA8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: GamePrimaryButton(
                            label: widget.onNext == null
                                ? 'Level Map'
                                : 'Next Recipe',
                            onPressed: widget.onNext ?? widget.onMap,
                            compact: true,
                          ),
                        ),
                        if (widget.onNext != null)
                          TextButton(
                            onPressed: widget.onMap,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFFFDF9D),
                            ),
                            child: const Text('Level Map'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _CelebrationConfetti extends CustomPainter {
  _CelebrationConfetti(this.progress) : super(repaint: progress);
  final Animation<double> progress;
  static const _colors = [
    Color(0xFFFFD173),
    Color(0xFF8DE0C1),
    Color(0xFFF7A093),
    Color(0xFFFFECCC),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final fade = ((1 - t) / .3).clamp(0.0, 1.0);
    final paint = Paint();
    for (var i = 0; i < 48; i++) {
      final seed = i * 2.399963;
      final spread = math.sin(seed);
      final x = size.width / 2 + spread * size.width * .7 * t;
      final y =
          size.height * .3 -
          math.sin(t * math.pi) * (60 + i % 7 * 18) +
          t * t * size.height * .85;
      paint.color = _colors[i % _colors.length].withValues(alpha: fade * .85);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(seed + t * 7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 4 + i % 3.0, height: 9),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationConfetti oldDelegate) =>
      oldDelegate.progress != progress;
}
