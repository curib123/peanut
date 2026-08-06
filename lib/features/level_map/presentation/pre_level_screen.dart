import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PreLevelScreen extends StatelessWidget {
  const PreLevelScreen({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Level $level')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flag_rounded, size: 56),
                const SizedBox(height: 16),
                const Text('Goal: Reach 5,000 points'),
                const Text('Moves: 20'),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/game/$level'),
                  child: const Text('Start Level'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
