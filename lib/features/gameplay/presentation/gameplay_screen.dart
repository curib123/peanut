import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../game/domain/level_session.dart';
import '../../../game/domain/content.dart';
import '../../../game/presentation/island_match_game.dart';
import '../../../services/content/bundled_level_repository.dart';
import '../../progress/application/progress_controller.dart';

class GameplayScreen extends ConsumerStatefulWidget {
  const GameplayScreen({super.key, required this.level});

  final int level;

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen> {
  late final Future<IslandMatchGame> _gameFuture;
  IslandMatchGame? _game;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    final reducedMotion = ref
        .read(progressControllerProvider)
        .data
        .settings
        .reducedMotion;
    _gameFuture = const BundledLevelRepository().load(widget.level).then((
      level,
    ) {
      return _game = IslandMatchGame(
        level: level,
        animationDuration: reducedMotion ? 0.04 : 0.18,
        onLevelEnded: _onLevelEnded,
      );
    });
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
      final game = _game;
      if (game == null) return;
      if (_paused) {
        game.pauseEngine();
      } else {
        game.resumeEngine();
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
      body: FutureBuilder<IslandMatchGame>(
        future: _gameFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('This recipe could not be loaded.'),
            );
          }
          final game = snapshot.data;
          if (game == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _LoadedGameplay(
            game: game,
            level: widget.level,
            paused: _paused,
            onTogglePause: _togglePause,
          );
        },
      ),
    );
  }
}

class _LoadedGameplay extends StatelessWidget {
  const _LoadedGameplay({
    required this.game,
    required this.level,
    required this.paused,
    required this.onTogglePause,
  });

  final IslandMatchGame game;
  final int level;
  final bool paused;
  final VoidCallback onTogglePause;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<GameHudState>(
    valueListenable: game.hud,
    builder: (context, hud, child) => Stack(
      children: [
        Column(
          children: [
            _GameHud(hud: hud),
            Expanded(
              child: Semantics(
                label: 'Playable eight by eight match board',
                child: GameWidget(game: game),
              ),
            ),
          ],
        ),
        if (game.level?.tutorial.isNotEmpty == true && hud.score == 0)
          _TutorialBanner(step: game.level!.tutorial.first),
        if (paused)
          _StatusOverlay(
            title: 'Paused',
            primaryLabel: 'Resume',
            onPrimary: onTogglePause,
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
            onPrimary: () => context.go('/level/$level'),
            onExit: () => context.go('/map'),
          ),
      ],
    ),
  );
}

class _TutorialBanner extends StatelessWidget {
  const _TutorialBanner({required this.step});
  final TutorialStep step;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 20,
    right: 20,
    bottom: 18,
    child: IgnorePointer(
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_rounded),
              const SizedBox(width: 10),
              Expanded(child: Text(step.message)),
            ],
          ),
        ),
      ),
    ),
  );
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
