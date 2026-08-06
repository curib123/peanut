import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../game/domain/level_session.dart';
import '../../../game/presentation/island_match_game.dart';
import '../../progress/application/progress_controller.dart';

class GameplayScreen extends ConsumerStatefulWidget {
  const GameplayScreen({super.key, required this.level});

  final int level;

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen> {
  late final IslandMatchGame _game;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    final reducedMotion = ref
        .read(progressControllerProvider)
        .data
        .settings
        .reducedMotion;
    _game = IslandMatchGame(
      seed: 20260806 + widget.level,
      animationDuration: reducedMotion ? 0.04 : 0.18,
      onLevelEnded: _onLevelEnded,
    );
  }

  void _onLevelEnded(LevelStatus status, int score) {
    if (status != LevelStatus.won) return;
    final stars = score >= 10000 ? 3 : (score >= 7000 ? 2 : 1);
    ref
        .read(progressControllerProvider.notifier)
        .completeLevel(level: widget.level, score: score, stars: stars);
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _game.pauseEngine();
      } else {
        _game.resumeEngine();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sunrise Bakery'),
            Text('Level ${widget.level}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pause',
            onPressed: _togglePause,
            icon: const Icon(Icons.pause_rounded),
          ),
        ],
      ),
      body: ValueListenableBuilder<GameHudState>(
        valueListenable: _game.hud,
        builder: (context, hud, child) => Stack(
          children: [
            Column(
              children: [
                _GameHud(hud: hud),
                Expanded(
                  child: Semantics(
                    label: 'Playable eight by eight match board',
                    child: GameWidget(game: _game),
                  ),
                ),
              ],
            ),
            if (_paused)
              _StatusOverlay(
                title: 'Paused',
                primaryLabel: 'Resume',
                onPrimary: _togglePause,
                onExit: () => context.go('/map'),
              ),
            if (hud.status == LevelStatus.won)
              _StatusOverlay(
                title: 'Perfect Batch!',
                message: 'Score: ${hud.score}',
                primaryLabel: 'Level Map',
                onPrimary: () => context.go('/map'),
              ),
            if (hud.status == LevelStatus.lost)
              _StatusOverlay(
                title: 'Out of Moves',
                message: 'Try a fresh recipe.',
                primaryLabel: 'Try Again',
                onPrimary: () => context.go('/level/${widget.level}'),
                onExit: () => context.go('/map'),
              ),
          ],
        ),
      ),
    );
  }
}

class _GameHud extends StatelessWidget {
  const _GameHud({required this.hud});

  final GameHudState hud;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    color: Theme.of(context).colorScheme.surface,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Moves: ${hud.moves}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          'Score: ${hud.score}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    ),
  );
}

class _StatusOverlay extends StatelessWidget {
  const _StatusOverlay({
    required this.title,
    required this.primaryLabel,
    required this.onPrimary,
    this.message,
    this.onExit,
  });

  final String title;
  final String? message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0x99000000),
    child: Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(message!),
              ],
              const SizedBox(height: 20),
              FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
              if (onExit != null)
                TextButton(onPressed: onExit, child: const Text('Level Map')),
            ],
          ),
        ),
      ),
    ),
  );
}
