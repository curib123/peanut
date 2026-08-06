import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../game/domain/content.dart';
import '../../../services/content/bundled_level_repository.dart';

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
          return Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      definition.metadata['name']?.toString() ??
                          'Morning Recipe',
                    ),
                    const SizedBox(height: 8),
                    for (final goal in definition.goals) Text(_goalLabel(goal)),
                    Text('Moves: ${definition.moves}'),
                    if (definition.tutorial.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        definition.tutorial.first.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.go('/game/$level'),
                      child: const Text('Start Level'),
                    ),
                  ],
                ),
              ),
            ),
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
      _ => 'Complete the bakery objective',
    };
  }
}
