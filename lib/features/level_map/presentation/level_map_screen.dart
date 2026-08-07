import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/content/world_presentation_catalog.dart';
import '../../progress/application/progress_controller.dart';

class LevelMapScreen extends ConsumerWidget {
  const LevelMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  catalog.main.backgroundAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
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
                  padding: const EdgeInsets.fromLTRB(28, 72, 28, 80),
                  itemCount: catalog.lastLevel,
                  itemBuilder: (context, index) {
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
          );
        },
      ),
    );
  }
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
        colors: [AppColors.coral, AppColors.caramel],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFFFE7A6), width: 3),
      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12)],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.landscape_rounded, color: Colors.white),
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
                          ? const [Color(0xFFFF745C), Color(0xFFFFA83D)]
                          : const [Color(0xFFFFD65B), Color(0xFFFFA832)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF9E948B), Color(0xFF756B64)],
                    ),
              border: Border.all(
                color: current ? Colors.white : const Color(0xFFFFEDB2),
                width: current ? 4 : 3,
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
