import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/content/world_presentation_catalog.dart';
import '../../progress/application/progress_controller.dart';

class LevelMapScreen extends ConsumerStatefulWidget {
  const LevelMapScreen({super.key});

  @override
  ConsumerState<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends ConsumerState<LevelMapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient;
  final ScrollController _scroll = ScrollController();
  int _visibleWorld = 0;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _scroll.addListener(_trackWorld);
  }

  void _trackWorld() {
    final next = (_scroll.offset / 2200).floor().clamp(0, 5);
    if (next != _visibleWorld) setState(() => _visibleWorld = next);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_trackWorld)
      ..dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final save = ref.watch(progressControllerProvider).data;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Island Recipe Journey'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<WorldPresentationCatalog>(
        future: WorldPresentationCatalog.load(),
        builder: (context, snapshot) {
          final catalog = snapshot.data;
          if (catalog == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final visibleWorld =
              catalog.worlds[_visibleWorld.clamp(0, catalog.worlds.length - 1)];
          final availableWorld = catalog.worldForLevel(
            save.highestUnlockedLevel.clamp(1, catalog.lastLevel),
          );
          final visibleLastLevel = availableWorld.lastLevel;
          return TickerMode(
            enabled: !save.settings.reducedMotion,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 900),
                    child: SizedBox.expand(
                      key: ValueKey(visibleWorld.id),
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_ambient, _scroll]),
                        builder: (context, child) {
                          final phase = _ambient.value * math.pi * 2;
                          final parallax = _scroll.hasClients
                              ? -(_scroll.offset % 2200) * .018
                              : 0.0;
                          return Transform.translate(
                            offset: Offset(
                              math.sin(phase) * 7,
                              parallax + math.cos(phase) * 5,
                            ),
                            child: Transform.scale(scale: 1.13, child: child),
                          );
                        },
                        child: Image.asset(
                          visibleWorld.backgroundAsset,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _ambient,
                      builder: (context, child) => CustomPaint(
                        painter: _AmbientPainter(
                          progress: _ambient.value,
                          seed: visibleWorld.order,
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x33000000), Color(0x99562C18)],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(28, 72, 28, 80),
                    itemCount: visibleLastLevel + 1,
                    itemBuilder: (context, index) {
                      if (index == visibleLastLevel) {
                        return _SecretCloud(
                          animation: _ambient,
                          finalWorld: visibleLastLevel == catalog.lastLevel,
                        );
                      }
                      final level = index + 1;
                      final world = catalog.worldForLevel(level);
                      final unlocked = level <= save.highestUnlockedLevel;
                      final stars = save.starsFor(level);
                      return Column(
                        children: [
                          if (level == world.firstLevel)
                            _WorldRibbon(name: world.name, number: world.order),
                          SizedBox(
                            height: 108,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: index.isEven ? 56 : 132,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 7,
                                    decoration: BoxDecoration(
                                      color: const Color(0xCCFFE3A0),
                                      borderRadius: BorderRadius.circular(99),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: index.isEven
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: _LevelNode(
                                    level: level,
                                    stars: stars,
                                    unlocked: unlocked,
                                    current: level == save.highestUnlockedLevel,
                                    onPressed: unlocked
                                        ? () => context.push('/level/$level')
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
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

class _SecretCloud extends StatelessWidget {
  const _SecretCloud({required this.animation, required this.finalWorld});

  final Animation<double> animation;
  final bool finalWorld;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final phase = animation.value * math.pi * 2;
      return Transform.translate(
        offset: Offset(math.sin(phase) * 12, math.cos(phase) * 5),
        child: child,
      );
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          const Icon(Icons.cloud_rounded, color: Color(0xE8FFFFFF), size: 116),
          Transform.translate(
            offset: const Offset(0, -56),
            child: const Icon(
              Icons.lock_rounded,
              color: AppColors.cocoa,
              size: 30,
            ),
          ),
          Text(
            finalWorld
                ? 'The island summit awaits'
                : 'A secret world is hidden above',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
            ),
          ),
          if (!finalWorld)
            const Text(
              'Complete this world to clear the clouds',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
        ],
      ),
    ),
  );
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter({required this.progress, required this.seed});

  final double progress;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..color = const Color(0x72FFE9A1);
    for (var index = 0; index < 22; index++) {
      final x = ((index * 83 + seed * 47) % 100) / 100 * size.width;
      final origin = ((index * 137 + seed * 31) % 100) / 100;
      final speed = .16 + (index % 4) * .035;
      final y = ((origin - progress * speed) % 1) * size.height;
      final pulse = .72 + math.sin(progress * math.pi * 2 + index) * .28;
      canvas.drawCircle(Offset(x, y), (1.8 + index % 3) * pulse, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.seed != seed;
}

class _WorldRibbon extends StatelessWidget {
  const _WorldRibbon({required this.name, required this.number});
  final String name;
  final int number;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 18, top: 8),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xE8F06B55), Color(0xE8D9822B)],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12)],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_worldIcon(number), color: Colors.white),
        const SizedBox(width: 10),
        Text(
          'World $number  •  $name',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );

  IconData _worldIcon(int world) => switch (world) {
    1 => Icons.bakery_dining_rounded,
    2 => Icons.park_rounded,
    3 => Icons.cloud_rounded,
    4 => Icons.sailing_rounded,
    5 => Icons.local_fire_department_rounded,
    _ => Icons.auto_awesome_rounded,
  };
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.current,
    required this.onPressed,
  });
  final int level;
  final int stars;
  final bool unlocked;
  final bool current;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    label: unlocked ? 'Level $level, $stars stars' : 'Level $level, locked',
    button: true,
    child: SizedBox(
      width: 94,
      height: 94,
      child: Material(
        key: Key('level-$level'),
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unlocked
                  ? LinearGradient(
                      colors: current
                          ? const [Color(0xE8FF745C), Color(0xE8FFA83D)]
                          : const [Color(0xD9FFD65B), Color(0xD9FFA832)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xC99E948B), Color(0xC9756B64)],
                    ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  unlocked ? Icons.cookie_rounded : Icons.lock_rounded,
                  color: unlocked ? AppColors.cocoa : Colors.white70,
                  size: 24,
                ),
                Text(
                  '$level',
                  style: TextStyle(
                    color: unlocked ? AppColors.cocoa : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (index) => Icon(
                      index < stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 14,
                      color: index < stars ? Colors.white : Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
