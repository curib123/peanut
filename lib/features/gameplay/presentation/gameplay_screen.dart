import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../game/domain/level_session.dart';
import '../../../game/domain/content.dart';
import '../../../game/domain/objectives.dart';
import '../../../game/presentation/island_match_game.dart';
import '../../../core/widgets/game_primary_button.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../services/content/bundled_level_repository.dart';
import '../../../services/content/world_presentation_catalog.dart';
import '../../../services/audio/game_audio_service.dart';
import '../../progress/application/progress_controller.dart';
import 'victory_celebration.dart';

class GameplayScreen extends ConsumerStatefulWidget {
  const GameplayScreen({super.key, required this.level});

  final int level;

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen>
    with WidgetsBindingObserver {
  late final Future<_GameplayLoad> _gameFuture;
  IslandMatchGame? _game;
  bool _paused = false;
  late final ProgressController _progress;
  late final int _highestUnlockedAtStart;
  final GlobalKey _boardKey = GlobalKey(debugLabel: 'live-game-board');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progress = ref.read(progressControllerProvider.notifier);
    _highestUnlockedAtStart = ref
        .read(progressControllerProvider)
        .data
        .highestUnlockedLevel;
    final reducedMotion = ref
        .read(progressControllerProvider)
        .data
        .settings
        .reducedMotion;
    final settings = ref.read(progressControllerProvider).data.settings;
    _gameFuture = const BundledLevelRepository().load(widget.level).then((
      level,
    ) async {
      final catalog = await WorldPresentationCatalog.load();
      final presentation = catalog.world(level.worldId);
      final game = _game = IslandMatchGame(
        level: level,
        animationDuration: reducedMotion ? 0.04 : 0.18,
        reducedMotion: reducedMotion,
        audio: GameAudioService.flame(soundEnabled: settings.soundEnabled),
        haptics: GameHapticsService(enabled: settings.hapticsEnabled),
        onLevelEnded: _onLevelEnded,
      );
      return _GameplayLoad(
        game: game,
        presentation: presentation,
        lastLevel: catalog.lastLevel,
      );
    });
  }

  void _onLevelEnded(LevelStatus status, int score) {
    if (status != LevelStatus.won || widget.level > _highestUnlockedAtStart) {
      return;
    }
    final stars = _game?.level?.starsForCompletedScore(score) ?? 1;
    unawaited(
      _progress.completeLevel(level: widget.level, score: score, stars: stars),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !_paused && mounted) {
      _togglePause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      final game = _game;
      if (game == null) return;
      if (_paused) {
        if (game.isActive) game.boardComponent.clearHint();
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
            boardKey: _boardKey,
            game: loaded.game,
            level: widget.level,
            lastLevel: loaded.lastLevel,
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
    required this.boardKey,
    required this.game,
    required this.level,
    required this.lastLevel,
    required this.worldName,
    required this.backgroundAsset,
    required this.paused,
    required this.onTogglePause,
  });

  final IslandMatchGame game;
  final GlobalKey boardKey;
  final int level;
  final int lastLevel;
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
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: GlassPanel(
                      radius: 22,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Back',
                            color: Colors.white,
                            onPressed: () => context.canPop()
                                ? context.pop()
                                : context.go('/map'),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  worldName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFFFDF9D),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  'Level $level',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Pause',
                            color: Colors.white,
                            onPressed: hud.status == LevelStatus.playing
                                ? onTogglePause
                                : null,
                            icon: const Icon(Icons.pause_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final board = Semantics(
                          label:
                              'Playable ${game.board.rows} by ${game.board.columns} match board',
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: game.board.columns / game.board.rows,
                              child: GameWidget(key: boardKey, game: game),
                            ),
                          ),
                        );
                        final tutorial =
                            game.level?.tutorial.isNotEmpty == true &&
                                hud.score == 0
                            ? _TutorialBanner(step: game.level!.tutorial.first)
                            : const SizedBox.shrink();
                        if (constraints.maxWidth >
                            constraints.maxHeight * 1.4) {
                          return Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      _GameHud(hud: hud),
                                      _RecipeGoals(goals: hud.goals),
                                      tutorial,
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(flex: 3, child: board),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _GameHud(hud: hud),
                            _RecipeGoals(goals: hud.goals),
                            Expanded(child: board),
                            tutorial,
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: game.cascadeMessage,
          builder: (context, message, child) => message == null
              ? const SizedBox.shrink()
              : _CascadeBanner(message: message),
        ),
        if (paused)
          _StatusOverlay(
            title: 'Paused',
            message: 'Your recipe will wait for you.',
            primaryLabel: 'Resume',
            onPrimary: onTogglePause,
            onExit: () => context.go('/map'),
          ),
        if (hud.status == LevelStatus.won)
          VictoryCelebration(
            stars: game.level?.starsForCompletedScore(hud.score) ?? 1,
            reducedMotion: game.reducedMotion,
            score: hud.score,
            movesRemaining: hud.moves,
            onMap: () => context.go('/map'),
            onNext: level < lastLevel
                ? () => context.go('/level/${level + 1}')
                : null,
          ),
        if (hud.status == LevelStatus.lost)
          _StatusOverlay(
            title: hud.timeRemainingSeconds == 0
                ? 'Time Is Up'
                : 'Out of Moves',
            message:
                'A fresh batch, a new strategy. Give this recipe another try.',
            primaryLabel: 'Try Again',
            onPrimary: () => context.go('/level/$level'),
            onExit: () => context.go('/map'),
          ),
      ],
    ),
  );
}

class _GameplayLoad {
  const _GameplayLoad({
    required this.game,
    required this.presentation,
    required this.lastLevel,
  });

  final IslandMatchGame game;
  final WorldPresentation presentation;
  final int lastLevel;
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

class _TutorialBanner extends StatelessWidget {
  const _TutorialBanner({required this.step});
  final TutorialStep step;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
    child: GlassPanel(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_rounded, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              step.message,
              style: const TextStyle(fontSize: 13, color: Color(0xFFFFE9BD)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GameHud extends StatelessWidget {
  const _GameHud({required this.hud});
  final GameHudState hud;

  @override
  Widget build(BuildContext context) => GlassPanel(
    radius: 20,
    margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metric(
                'Moves: ${hud.moves}',
                hud.moves <= 5
                    ? const Color(0xFFFFA19B)
                    : const Color(0xFFFFD87B),
                Alignment.centerLeft,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _metric(
                'Score: ${hud.score}',
                Colors.white,
                Alignment.centerRight,
              ),
            ),
          ],
        ),
        if (hud.timeRemainingSeconds != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: hud.timeRemainingSeconds! <= 10
                    ? const Color(0xFFFFA19B)
                    : const Color(0xFF9EE9EF),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Time: ${_clock(hud.timeRemainingSeconds!)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: hud.timeRemainingSeconds! <= 10
                        ? const Color(0xFFFFA19B)
                        : const Color(0xFF9EE9EF),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _metric(String label, Color color, Alignment alignment) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: alignment,
    child: Text(
      label,
      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: color),
    ),
  );

  String _clock(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class _RecipeGoals extends StatelessWidget {
  const _RecipeGoals({required this.goals});
  final List<GameGoalProgress> goals;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) return const SizedBox.shrink();
    return GlassPanel(
      radius: 20,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECIPE GOALS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
              color: Color(0xFFFFD87B),
            ),
          ),
          const SizedBox(height: 7),
          for (final goal in goals)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Semantics(
                label: '${_label(goal)}: ${goal.progress} of ${goal.target}',
                child: Row(
                  children: [
                    Icon(
                      goal.isComplete
                          ? Icons.check_circle_rounded
                          : _icon(goal.kind),
                      size: 20,
                      color: goal.isComplete
                          ? const Color(0xFF9FE5B5)
                          : const Color(0xFFFFD87B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _label(goal),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${goal.progress} / ${goal.target}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFFFDF9D),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: goal.progress / goal.target,
                              minHeight: 4,
                              backgroundColor: const Color(0x40FFFFFF),
                              color: goal.isComplete
                                  ? const Color(0xFF9FE5B5)
                                  : const Color(0xFFFFCB65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _label(GameGoalProgress goal) => switch (goal.kind) {
    GoalKind.targetScore => 'Bake points',
    GoalKind.collectPieces =>
      'Collect ${goal.pieceKind?.id.replaceAll('_', ' ') ?? 'ingredients'}',
    GoalKind.clearFrosting => 'Clear frosting',
    GoalKind.breakCrates => 'Break peanut crates',
    GoalKind.dropRecipeBaskets => 'Drop recipe baskets',
    GoalKind.spreadCream => 'Spread coconut cream',
    GoalKind.lightOvens => 'Light festival ovens',
  };

  IconData _icon(GoalKind kind) => switch (kind) {
    GoalKind.targetScore => Icons.auto_awesome_rounded,
    GoalKind.collectPieces => Icons.bakery_dining_rounded,
    GoalKind.clearFrosting => Icons.layers_rounded,
    GoalKind.breakCrates => Icons.inventory_2_rounded,
    GoalKind.dropRecipeBaskets => Icons.shopping_basket_rounded,
    GoalKind.spreadCream => Icons.water_drop_rounded,
    GoalKind.lightOvens => Icons.local_fire_department_rounded,
  };
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassPanel(
            padding: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFAA7241), Color(0xFF5C3026)],
                      ),
                      border: Border.all(color: const Color(0x99FFD994)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x44501810),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ExcludeSemantics(
                      child: Icon(
                        title == 'Paused'
                            ? Icons.coffee_rounded
                            : Icons.menu_book_rounded,
                        color: const Color(0xFFFFE4AC),
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFFFFDF9D),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFE9D4BE),
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  GamePrimaryButton(
                    label: primaryLabel,
                    onPressed: onPrimary,
                    compact: true,
                  ),
                  if (onExit != null)
                    TextButton(
                      onPressed: onExit,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFFDF9D),
                      ),
                      child: const Text('Level Map'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
