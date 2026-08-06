import 'package:go_router/go_router.dart';

import '../features/gameplay/presentation/gameplay_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/level_map/presentation/level_map_screen.dart';
import '../features/level_map/presentation/pre_level_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/map', builder: (context, state) => const LevelMapScreen()),
    GoRoute(
      path: '/level/:level',
      builder: (context, state) => PreLevelScreen(
        level: int.tryParse(state.pathParameters['level'] ?? '') ?? 1,
      ),
    ),
    GoRoute(
      path: '/game/:level',
      builder: (context, state) => GameplayScreen(
        level: int.tryParse(state.pathParameters['level'] ?? '') ?? 1,
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
