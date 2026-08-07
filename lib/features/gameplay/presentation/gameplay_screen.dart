import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../game/domain/level_session.dart';
import '../../../game/domain/content.dart';
import '../../../game/presentation/island_match_game.dart';
import '../../../core/widgets/game_primary_button.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../services/content/bundled_level_repository.dart';
import '../../../services/content/world_presentation_catalog.dart';
import '../../../services/audio/game_audio_service.dart';
import '../../progress/application/progress_controller.dart';

class GameplayScreen extends ConsumerStatefulWidget {
  const GameplayScreen({super.key, required this.level});

  final int level;

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen> {
  late final Future<_GameplayLoad> _gameFuture;
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
    ) async {
      final presentation = (await WorldPresentationCatalog.load()).world(
        level.worldId,
      );
      final game = _game = IslandMatchGame(
        level: level,
        animationDuration: reducedMotion ? 0.04 : 0.18,
        reducedMotion: reducedMotion,
        audio: GameAudioService.flame(soundEnabled: settings.soundEnabled),
        haptics: GameHapticsService(enabled: settings.hapticsEnabled),
        onLevelEnded: _onLevelEnded,
      );
      return _GameplayLoad(game: game, presentation: presentation);
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
      body: FutureBuilder<_GameplayLoad>(
        future: _gameFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('This recipe could not be loaded.'),
            );
          }
          final loaded = snapshot.data;
          if (loaded == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _LoadedGameplay(
            game: loaded.game,
            level: widget.level,
            worldName: loaded.presentation.name,
            backgroundAsset: loaded.presentation.backgroundAsset,
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
    required this.worldName,
    required this.backgroundAsset,
    required this.paused,
    required this.onTogglePause,
  });

  final IslandMatchGame game;
  final int level;
  final String worldName;
  final String backgroundAsset;
  final bool paused;
  final VoidCallback onTogglePause;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<GameHudState>(
    valueListenable: game.hud,
    builder: (context, hud, child) => Stack(
      children: [
        Positioned.fill(child: Image.asset(backgroundAsset, fit: BoxFit.cover)),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22FFF4D6), Color(0x663D1F13)],
              ),
            ),
          ),
        ),
        Column(
          children: [
            const SizedBox(height: 94),
            _GameHud(hud: hud),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Semantics(
                    label: 'Playable eight by eight match board',
                    child: GameWidget(game: game),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: GlassPanel(
                radius: 24,
                tint: const Color(0xB83A1C12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      color: Colors.white,
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worldName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          Text(
                            'Level $level',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Pause',
                      color: Colors.white,
                      onPressed: onTogglePause,
                      icon: const Icon(Icons.pause_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
            title: hud.timeRemainingSeconds == 0
                ? 'Time Is Up'
                : 'Out of Moves',
            message: 'Try a fresh recipe.',
            primaryLabel: 'Try Again',
            onPrimary: () => context.go('/level/$level'),
            onExit: () => context.go('/map'),
          ),
      ],
    ),
  );
}

class _GameplayLoad {
  const _GameplayLoad({required this.game, required this.presentation});

  final IslandMatchGame game;
  final WorldPresentation presentation;
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
        child: GlassPanel(
          tint: Theme.of(context).colorScheme.tertiaryContainer,
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
        child: GlassPanel(
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
                GamePrimaryButton(
                  label: primaryLabel,
                  onPressed: onPrimary,
                  compact: true,
                ),
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
      child: GlassPanel(
        tint: Theme.of(context).colorScheme.primaryContainer,
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
        colors: [Color(0xD9FFF8E6), Color(0xCFFFE2A6)],
      ),
      borderRadius: BorderRadius.circular(20),
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
          hud.timeRemainingSeconds == null
              ? 'Moves: ${hud.moves}'
              : 'Moves: ${hud.moves}  •  ${_clock(hud.timeRemainingSeconds!)}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          'Score: ${hud.score}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    ),
  );

  String _clock(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
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
      child: GlassPanel(
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
              GamePrimaryButton(
                label: primaryLabel,
                onPressed: onPrimary,
                compact: true,
              ),
              if (onExit != null)
                TextButton(onPressed: onExit, child: const Text('Level Map')),
            ],
          ),
        ),
      ),
    ),
  );
}
