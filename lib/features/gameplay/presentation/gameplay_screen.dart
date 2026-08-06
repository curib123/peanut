import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../game/presentation/island_match_game.dart';

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
      body: Semantics(
        label: 'Playable eight by eight match board',
        child: GameWidget(game: _game),
      ),
    );
  }
}
