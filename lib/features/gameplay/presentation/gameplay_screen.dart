import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../game/domain/level_session.dart';
import '../../../game/domain/content.dart';
import '../../../game/presentation/island_match_game.dart';
import '../../../services/content/bundled_level_repository.dart';
import '../../../services/audio/game_audio_service.dart';
import '../../../services/assets/game_asset_catalog.dart';
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
    final settings = ref.read(progressControllerProvider).data.settings;
    _gameFuture = const BundledLevelRepository().load(widget.level).then((
      level,
    ) {
      return _game = IslandMatchGame(
        level: level,
        animationDuration: reducedMotion ? 0.04 : 0.18,
        reducedMotion: reducedMotion,
        audio: GameAudioService.flame(soundEnabled: settings.soundEnabled),
        haptics: GameHapticsService(enabled: settings.hapticsEnabled),
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
            Text(BundledLevelRepository.worldNameForLevel(widget.level)),
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    GameAssetCatalog.worldBackgroundForLevel(level),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x22FFF4D6), Color(0x663D1F13)],
                      ),
                    ),
                  ),
                  Semantics(
                    label: 'Playable eight by eight match board',
                    child: GameWidget(game: game),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (game.level?.tutorial.isNotEmpty == true && hud.score == 0)
          _TutorialBanner(step: game.level!.tutorial.first),
        ValueListenableBuilder<String?>(
          valueListenable: game.cascadeMessage,
          builder: (context, message, child) => message == null
              ? const SizedBox.shrink()
              : _CascadeBanner(message: message),
        ),
        if (paused)
          _StatusOverlay(
            title: 'Paused',
            primaryLabel: 'Resume',
            onPrimary: onTogglePause,
            onExit: () => context.go('/map'),
          ),
        if (hud.status == LevelStatus.won)
          _VictoryOverlay(
            title: 'Perfect Batch!',
            score: hud.score,
            movesRemaining: hud.moves,
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

class _CascadeBanner extends StatelessWidget {
  const _CascadeBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: .7, end: 1),
        duration: const Duration(milliseconds: 220),
        builder: (context, value, child) =>
            Transform.scale(scale: value, child: child),
        child: Card(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Text(message, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
      ),
    ),
  );
}

class _VictoryOverlay extends StatelessWidget {
  const _VictoryOverlay({
    required this.title,
    required this.score,
    required this.movesRemaining,
    required this.primaryLabel,
    required this.onPrimary,
  });
  final String title;
  final int score;
  final int movesRemaining;
  final String primaryLabel;
  final VoidCallback onPrimary;
  @override
  Widget build(BuildContext context) {
    final stars = score >= 10000
        ? 3
        : score >= 7000
        ? 2
        : 1;
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (index) => TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 250 + index * 170),
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: Icon(
                          index < stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFFFC43D),
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                ),
                Text('Score: $score'),
                Text(
                  '+${movesRemaining * 100} unused-move bonus',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF8E6), Color(0xFFFFE2A6)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFFBE3F), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
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
