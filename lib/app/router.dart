import 'package:go_router/go_router.dart';

import 'level_access_gate.dart';

import '../features/gameplay/presentation/gameplay_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/level_map/presentation/level_map_screen.dart';
import '../features/level_map/presentation/pre_level_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../services/audio/game_music_scope.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/home',
      builder: (context, state) => const CatalogMusicScope(child: HomeScreen()),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) =>
          const CatalogMusicScope(child: LevelMapScreen()),
    ),
    GoRoute(
      path: '/level/:level',
      builder: (context, state) {
        final level = int.tryParse(state.pathParameters['level'] ?? '') ?? -1;
        return LevelAccessGate(
          level: level,
          child: CatalogMusicScope(
            level: level,
            child: PreLevelScreen(level: level),
          ),
        );
      },
    ),
    GoRoute(
      path: '/game/:level',
      builder: (context, state) {
        final level = int.tryParse(state.pathParameters['level'] ?? '') ?? -1;
        return LevelAccessGate(
          level: level,
          child: CatalogMusicScope(
            level: level,
            child: GameplayScreen(level: level),
          ),
        );
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
