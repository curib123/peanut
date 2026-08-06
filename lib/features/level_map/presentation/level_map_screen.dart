import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../progress/application/progress_controller.dart';

class LevelMapScreen extends ConsumerWidget {
  const LevelMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(progressControllerProvider).data;
    return Scaffold(
      appBar: AppBar(title: const Text('Sunrise Bakery')),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          final level = index + 1;
          final unlocked = level <= save.highestUnlockedLevel;
          final stars = save.starsFor(level);
          return FilledButton.tonal(
            key: Key('level-$level'),
            onPressed: unlocked ? () => context.push('/level/$level') : null,
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(8)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(unlocked ? Icons.cookie_rounded : Icons.lock_rounded),
                Text('$level', style: Theme.of(context).textTheme.titleLarge),
                Text(stars == 0 ? '—' : '${'★' * stars}${'☆' * (3 - stars)}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
