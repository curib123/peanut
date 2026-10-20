import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../game/domain/content.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/game_primary_button.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../services/content/bundled_level_repository.dart';
import '../../../services/content/world_presentation_catalog.dart';
import '../../progress/application/progress_controller.dart';

class PreLevelScreen extends ConsumerStatefulWidget {
  const PreLevelScreen({super.key, required this.level});

  final int level;

  @override
  ConsumerState<PreLevelScreen> createState() => _PreLevelScreenState();
}

class _PreLevelScreenState extends ConsumerState<PreLevelScreen> {
  late Future<LevelDefinition> _levelFuture;
  late final Future<WorldPresentationCatalog> _worldFuture;

  @override
  void initState() {
    super.initState();
    _levelFuture = const BundledLevelRepository().load(widget.level);
    _worldFuture = WorldPresentationCatalog.load();
  }

  @override
  void didUpdateWidget(covariant PreLevelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _levelFuture = const BundledLevelRepository().load(widget.level);
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final save = ref.watch(progressControllerProvider).data;
    return Scaffold(
      appBar: AppBar(title: Text('Level $level')),
      body: FutureBuilder<LevelDefinition>(
        future: _levelFuture,
        builder: (context, snapshot) {
          final definition = snapshot.data;
          if (snapshot.hasError) {
            return const Center(
              child: Text('This recipe could not be loaded.'),
            );
          }
          if (definition == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return FutureBuilder<WorldPresentationCatalog>(
            future: _worldFuture,
            builder: (context, worldSnapshot) {
              final world = worldSnapshot.data?.world(definition.worldId);
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (world != null)
                    Image.asset(world.backgroundAsset, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x331B0D08), Color(0xAA2B160E)],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 20, bottom: 130),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: GlassPanel(
                            margin: const EdgeInsets.all(22),
                            padding: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                24,
                                24,
                                26,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/specials/peanut_kisses.png',
                                    height: 68,
                                    excludeFromSemantics: true,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    definition.metadata['name']?.toString() ??
                                        'Morning Recipe',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (world != null)
                                    Text(
                                      world.name,
                                      style: const TextStyle(
                                        color: Color(0xFFFFDF9D),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Semantics(
                                    label:
                                        'Best: ${save.starsFor(level)} of 3 stars',
                                    child: ExcludeSemantics(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          for (var star = 1; star <= 3; star++)
                                            Icon(
                                              star <= save.starsFor(level)
                                                  ? Icons.star_rounded
                                                  : Icons.star_outline_rounded,
                                              color: const Color(0xFFFFD76A),
                                              size: 28,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    save.bestScoreFor(level) > 0
                                        ? 'Best score ${save.bestScoreFor(level)}'
                                        : 'Your first batch awaits',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  for (final goal in definition.goals)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.coconut,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              _goalAsset(goal),
                                              width: 44,
                                              height: 44,
                                              excludeFromSemantics: true,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _goalLabel(goal),
                                                style: const TextStyle(
                                                  color: AppColors.cocoa,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _InfoPill(
                                        icon:
                                            Icons.local_fire_department_rounded,
                                        label:
                                            'Difficulty ${definition.metadata['difficulty'] ?? 1}',
                                      ),
                                      _InfoPill(
                                        icon: Icons.swap_horiz_rounded,
                                        label: '${definition.moves} moves',
                                      ),
                                      if (definition.timeLimitSeconds != null)
                                        _InfoPill(
                                          icon: Icons.timer_rounded,
                                          label:
                                              '${definition.timeLimitSeconds}s time trial',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'FRESH INGREDIENTS',
                                    style: TextStyle(
                                      color: Color(0xFFFFDF9D),
                                      fontSize: 11,
                                      letterSpacing: 1.7,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 10,
                                    runSpacing: 8,
                                    children: [
                                      for (final piece
                                          in definition.spawnWeights.keys)
                                        SizedBox(
                                          width: 100,
                                          child: Column(
                                            children: [
                                              Image.asset(
                                                'assets/images/pieces/${piece.id}.png',
                                                width: 34,
                                                height: 34,
                                                excludeFromSemantics: true,
                                              ),
                                              Text(
                                                _pieceLabel(piece.id),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (definition.tutorial.isNotEmpty) ...[
                                    const SizedBox(height: 18),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF2CF),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.lightbulb_rounded,
                                            color: AppColors.cocoa,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              definition.tutorial.first.message,
                                              textAlign: TextAlign.left,
                                              style: const TextStyle(
                                                color: AppColors.cocoa,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x002B160E), Color(0xF52B160E)],
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        minimum: const EdgeInsets.fromLTRB(22, 20, 22, 12),
                        child: Center(
                          heightFactor: 1,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: SizedBox(
                              width: double.infinity,
                              child: GamePrimaryButton(
                                label: 'Start Level',
                                icon: Icons.play_arrow_rounded,
                                onPressed: () => context.go('/game/$level'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _goalLabel(MechanicDefinition goal) {
    final target = goal.parameters['target'];
    return switch (goal.id) {
      'target_score' => 'Reach $target points',
      'collect_pieces' => 'Collect $target ${goal.parameters['pieceId']}',
      'clear_frosting' => 'Clear $target Sugar Frosting tiles',
      'break_crates' => 'Break $target Peanut Crates',
      'drop_recipe_baskets' => 'Drop $target Recipe Baskets',
      'spread_cream' => 'Spread Coconut Cream to $target tiles',
      'light_ovens' => 'Light $target Festival Ovens',
      _ => 'Complete the bakery objective',
    };
  }

  String _goalAsset(MechanicDefinition goal) => switch (goal.id) {
    'collect_pieces' =>
      'assets/images/pieces/${goal.parameters['pieceId']}.png',
    'clear_frosting' => 'assets/images/blockers/sugar_frosting.png',
    'break_crates' => 'assets/images/blockers/peanut_crate.png',
    'light_ovens' => 'assets/images/blockers/oven_stone.png',
    'spread_cream' => 'assets/images/pieces/coconut_cream.png',
    _ => 'assets/images/specials/golden_recipe_spark.png',
  };

  String _pieceLabel(String id) => switch (id) {
    'peanut' => 'Peanut',
    'egg' => 'Egg',
    'sugar_crystal' => 'Sugar crystal',
    'caramel_ribbon' => 'Caramel ribbon',
    'coconut_cream' => 'Coconut cream',
    'cocoa_crumb' => 'Cocoa crumb',
    _ => id.replaceAll('_', ' '),
  };
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE5A6),
      borderRadius: BorderRadius.circular(99),
      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10)],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: AppColors.caramel),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.cocoa,
            ),
          ),
        ),
      ],
    ),
  );
}
