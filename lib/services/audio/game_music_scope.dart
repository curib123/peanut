import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/progress/application/progress_controller.dart';
import '../content/world_presentation_catalog.dart';

class GameMusicController {
  GameMusicController._();

  static final instance = GameMusicController._();
  String? _current;
  int _request = 0;

  Future<void> play(String asset, {required bool enabled}) async {
    const compileTimeTest = bool.fromEnvironment('FLUTTER_TEST');
    final runningUnderTest =
        compileTimeTest ||
        WidgetsBinding.instance.runtimeType.toString().contains(
          'TestWidgetsFlutterBinding',
        );
    if (runningUnderTest) {
      _current = enabled ? asset : null;
      return;
    }
    final request = ++_request;
    if (!enabled) {
      _current = null;
      try {
        await FlameAudio.bgm.stop();
      } catch (_) {}
      return;
    }
    if (_current == asset) return;
    try {
      await FlameAudio.bgm.stop();
      if (request != _request) return;
      await FlameAudio.bgm.play('music/$asset', volume: .34);
      if (request == _request) _current = asset;
    } catch (_) {
      if (request == _request) _current = null;
    }
  }
}

class GameMusicScope extends ConsumerStatefulWidget {
  const GameMusicScope({
    super.key,
    required this.musicAsset,
    required this.child,
  });

  final String musicAsset;
  final Widget child;

  @override
  ConsumerState<GameMusicScope> createState() => _GameMusicScopeState();
}

class _GameMusicScopeState extends ConsumerState<GameMusicScope> {
  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_sync);
  }

  @override
  void didUpdateWidget(covariant GameMusicScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.musicAsset != widget.musicAsset) unawaited(_sync());
  }

  Future<void> _sync() => GameMusicController.instance.play(
    widget.musicAsset,
    enabled: ref.read(progressControllerProvider).data.settings.musicEnabled,
  );

  @override
  Widget build(BuildContext context) {
    ref.listen(
      progressControllerProvider.select(
        (state) => state.data.settings.musicEnabled,
      ),
      (_, _) => unawaited(_sync()),
    );
    return widget.child;
  }
}

class CatalogMusicScope extends StatelessWidget {
  const CatalogMusicScope({super.key, this.level, required this.child});

  final int? level;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    )) {
      return child;
    }
    return FutureBuilder<WorldPresentationCatalog>(
      future: WorldPresentationCatalog.load(),
      builder: (context, snapshot) {
        final catalog = snapshot.data;
        if (catalog == null) return child;
        final music = level == null
            ? catalog.main.musicAsset
            : catalog.worldForLevel(level!).musicAsset;
        return GameMusicScope(musicAsset: music, child: child);
      },
    );
  }
}
