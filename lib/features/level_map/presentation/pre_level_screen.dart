import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../game/domain/content.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/game_primary_button.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../services/content/bundled_level_repository.dart';
import '../../../services/content/world_presentation_catalog.dart';

class PreLevelScreen extends StatelessWidget {
  const PreLevelScreen({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Level $level')),
      body: FutureBuilder<LevelDefinition>(
        future: const BundledLevelRepository().load(level),
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
            future: WorldPresentationCatalog.load(),
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
                  Center(
                    child: GlassPanel(
                      margin: const EdgeInsets.all(22),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFE2A0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bakery_dining_rounded,
                                size: 38,
                                color: AppColors.caramel,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              definition.metadata['name']?.toString() ??
                                  'Morning Recipe',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            if (world != null) Text(world.name),
                            const SizedBox(height: 18),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final goal in definition.goals)
                                  _InfoPill(
                                    icon: Icons.flag_rounded,
                                    label: _goalLabel(goal),
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
                                    const Icon(Icons.lightbulb_rounded),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        definition.tutorial.first.message,
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            GamePrimaryButton(
                              label: 'Start Level',
                              icon: Icons.play_arrow_rounded,
                              onPressed: () => context.go('/game/$level'),
                            ),
                          ],
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
