import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../game/presentation/island_match_game.dart';
import '../../../game/domain/level_session.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late final IslandMatchGame _game = IslandMatchGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sunrise Bakery'),
            Text('Practice Board', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          ValueListenableBuilder<GameHudState>(
            valueListenable: _game.hud,
            builder: (context, hud, child) => Container(
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
                  if (hud.status != LevelStatus.playing)
                    Text(
                      hud.status == LevelStatus.won
                          ? 'Goal complete!'
                          : 'Out of moves',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              label: 'Playable eight by eight match board',
              child: GameWidget(game: _game),
            ),
          ),
        ],
      ),
    );
  }
}
