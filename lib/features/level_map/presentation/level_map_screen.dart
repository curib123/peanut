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
  late final Future<WorldPresentationCatalog> _catalogFuture;
  final ScrollController _scroll = ScrollController();
  int _visibleWorld = 0;
  int _currentLevel = 1;
  int? _restoredLevel;
  bool _restoreQueued = false;
  _JourneyLayout? _journey;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _catalogFuture = WorldPresentationCatalog.load();
    _scroll.addListener(_trackWorld);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAmbient();
  }

  void _syncAmbient() {
    final enabled =
        !ref.read(progressControllerProvider).data.settings.reducedMotion &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled && !_ambient.isAnimating) {
      _ambient.repeat();
    } else if (!enabled && _ambient.isAnimating) {
      _ambient.stop();
    }
  }

  void _trackWorld() {
    final journey = _journey;
    if (journey == null || !_scroll.hasClients) return;
    final next = journey.worldAt(
      _scroll.offset + _scroll.position.viewportDimension / 2,
    );
    if (next != _visibleWorld) setState(() => _visibleWorld = next);
  }

  void _restoreCurrentLevel() {
    if (_restoredLevel == _currentLevel || _restoreQueued) return;
    _restoreQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreQueued = false;
      if (!mounted || !_scroll.hasClients) return;
      _restoredLevel = _currentLevel;
      _goToCurrentLevel(animate: false);
    });
  }

  void _goToCurrentLevel({bool animate = true}) {
    final journey = _journey;
    if (journey == null || !_scroll.hasClients) return;
    final target =
        (journey.nodeCenter(_currentLevel) -
                _scroll.position.viewportDimension / 2)
            .clamp(0.0, _scroll.position.maxScrollExtent);
    final reducedMotion =
        ref.read(progressControllerProvider).data.settings.reducedMotion ||
        MediaQuery.disableAnimationsOf(context);
    if (animate && !reducedMotion) {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scroll.jumpTo(target);
    }
    _trackWorld();
  }

  Future<void> _openLevel(int level) async {
    await context.push('/level/$level');
    if (mounted) _goToCurrentLevel(animate: false);
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
    final progress = ref.watch(progressControllerProvider);
    final save = progress.data;
    ref.listen(progressControllerProvider, (_, _) => _syncAmbient());
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Island Recipe Journey',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        titleTextStyle: Theme.of(
          context,
        ).appBarTheme.titleTextStyle?.copyWith(color: Colors.white),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Current level',
            onPressed: () => _goToCurrentLevel(),
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: FutureBuilder<WorldPresentationCatalog>(
        future: _catalogFuture,
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
          _currentLevel = save.highestUnlockedLevel.clamp(1, catalog.lastLevel);
          final motionEnabled =
              !save.settings.reducedMotion &&
              !MediaQuery.disableAnimationsOf(context);
          return LayoutBuilder(
            builder: (context, constraints) {
              final journey = _JourneyLayout(
                context,
                catalog: catalog,
                lastLevel: visibleLastLevel,
                contentWidth:
                    constraints.maxWidth -
                    MediaQuery.paddingOf(context).horizontal -
                    56,
              );
              _journey = journey;
              if (progress.isLoaded) _restoreCurrentLevel();
              return TickerMode(
                enabled: motionEnabled,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: motionEnabled
                            ? const Duration(milliseconds: 900)
                            : Duration.zero,
                        child: SizedBox.expand(
                          key: ValueKey(visibleWorld.id),
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_ambient, _scroll]),
                            builder: (context, child) {
                              final phase = motionEnabled
                                  ? _ambient.value * math.pi * 2
                                  : 0.0;
                              final parallax =
                                  _scroll.hasClients && motionEnabled
                                  ? -(_scroll.offset -
                                                journey
                                                    .worldStarts[_visibleWorld])
                                            .clamp(
                                              0.0,
                                              journey.worldExtent(
                                                _visibleWorld,
                                              ),
                                            ) *
                                        .018
                                  : 0.0;
                              return Transform.translate(
                                offset: Offset(
                                  math.sin(phase) * 7,
                                  parallax + math.cos(phase) * 5,
                                ),
                                child: Transform.scale(
                                  scale: 1.13,
                                  child: child,
                                ),
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
                        itemExtentBuilder: (index, _) =>
                            index < journey.itemExtents.length
                            ? journey.itemExtents[index]
                            : null,
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
                                SizedBox(
                                  height: journey.ribbonExtents[world.id],
                                  width: double.infinity,
                                  child: _WorldRibbon(
                                    name: world.name,
                                    number: world.order,
                                  ),
                                ),
                              SizedBox(
                                height: 108,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      left: 20,
                                      right: 20,
                                      top: -8,
                                      bottom: -8,
                                      child: IgnorePointer(
                                        child: Transform.flip(
                                          flipX: index.isOdd,
                                          child: Image.asset(
                                            'assets/images/worlds/level_road_segment.png',
                                            fit: BoxFit.fill,
                                            filterQuality: FilterQuality.high,
                                            semanticLabel: 'Golden bakery road',
                                          ),
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
                                        current: level == _currentLevel,
                                        onPressed: unlocked
                                            ? () => _openLevel(level)
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
          );
        },
      ),
    );
  }
}

class _JourneyLayout {
  _JourneyLayout(
    BuildContext context, {
    required this.catalog,
    required this.lastLevel,
    required double contentWidth,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double textHeight(String text, TextStyle style, double width) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textScaler: scaler,
        textDirection: direction,
      )..layout(maxWidth: math.max(1, width));
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final ribbonStyle = _ribbonTextStyle(context);
    for (final world in catalog.worlds) {
      ribbonExtents[world.id] =
          50 +
          math.max(
            24,
            textHeight(
              _worldLabel(world.order, world.name),
              ribbonStyle,
              contentWidth - 74,
            ),
          );
    }
    var offset = 80.0;
    final levelExtents = <double>[];
    for (var level = 1; level <= catalog.lastLevel; level++) {
      final world = catalog.worldForLevel(level);
      final first = level == world.firstLevel;
      if (first) worldStarts.add(offset);
      _nodeCenters.add(offset + 54);
      final extent = 108.0 + (first ? ribbonExtents[world.id]! : 0.0);
      levelExtents.add(extent);
      offset += extent;
    }
    _pathEnd = offset;
    final finalWorld = lastLevel == catalog.lastLevel;
    final cloudTitleStyle = Theme.of(context).textTheme.titleMedium!.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
    );
    final cloudExtent =
        234 +
        textHeight(_cloudTitle(finalWorld), cloudTitleStyle, contentWidth) +
        (finalWorld
            ? 0
            : textHeight(
                'Complete this world to clear the clouds',
                Theme.of(context).textTheme.bodyMedium!,
                contentWidth,
              ));
    itemExtents = [...levelExtents.take(lastLevel), cloudExtent];
  }

  final WorldPresentationCatalog catalog;
  final int lastLevel;
  final Map<String, double> ribbonExtents = {};
  final List<double> worldStarts = [];
  final List<double> _nodeCenters = [];
  late final double _pathEnd;
  late final List<double> itemExtents;

  double nodeCenter(int level) => _nodeCenters[level - 1];

  int worldAt(double offset) {
    var index = 0;
    for (var next = 1; next < worldStarts.length; next++) {
      if (catalog.worlds[next].firstLevel > lastLevel ||
          offset < worldStarts[next]) {
        break;
      }
      index = next;
    }
    return index;
  }

  double worldExtent(int index) =>
      (index + 1 < worldStarts.length ? worldStarts[index + 1] : _pathEnd) -
      worldStarts[index];
}

String _cloudTitle(bool finalWorld) =>
    finalWorld ? 'The island summit awaits' : 'A secret world is hidden above';

String _worldLabel(int number, String name) => 'World $number  \u2022  $name';

TextStyle _ribbonTextStyle(BuildContext context) => Theme.of(context)
    .textTheme
    .titleMedium!
    .copyWith(color: Colors.white, fontWeight: FontWeight.w900);

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
            _cloudTitle(finalWorld),
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
        Flexible(
          child: Text(
            _worldLabel(number, name),
            style: _ribbonTextStyle(context),
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: ColorFiltered(
                    colorFilter: unlocked
                        ? const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          )
                        : const ColorFilter.matrix(<double>[
                            .34,
                            .34,
                            .34,
                            0,
                            0,
                            .34,
                            .34,
                            .34,
                            0,
                            0,
                            .34,
                            .34,
                            .34,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]),
                    child: Image.asset(
                      'assets/images/ui/round_button.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        unlocked ? (current ? 'GO' : 'LEVEL') : 'LOCKED',
                        style: TextStyle(
                          color: unlocked ? AppColors.cocoa : Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                      Text(
                        '$level',
                        style: TextStyle(
                          color: unlocked ? AppColors.cocoa : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        '${List.filled(stars, '*').join()}${List.filled(3 - stars, '-').join()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          height: .9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
