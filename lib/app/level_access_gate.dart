import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/game_primary_button.dart';
import '../features/progress/application/progress_controller.dart';
import '../services/content/world_presentation_catalog.dart';

/// Apply progression checks to deep links as well as map taps.
class LevelAccessGate extends ConsumerWidget {
  const LevelAccessGate({super.key, required this.level, required this.child});
  final int level;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressControllerProvider);
    if (!progress.isLoaded)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return FutureBuilder<WorldPresentationCatalog>(
      future: WorldPresentationCatalog.load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        final unavailable =
            snapshot.hasError || level < 1 || level > snapshot.data!.lastLevel;
        if (!unavailable && level <= progress.data.highestUnlockedLevel)
          return child;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      unavailable
                          ? Icons.explore_off_rounded
                          : Icons.lock_rounded,
                      size: 64,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      unavailable
                          ? 'Recipe unavailable'
                          : 'This recipe is still locked',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      unavailable
                          ? 'Choose a recipe from the island journey.'
                          : 'Complete earlier levels to unlock this recipe.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GamePrimaryButton(
                      label: 'Back to Journey',
                      onPressed: () => context.go('/map'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
