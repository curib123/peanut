import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sound, music, haptics, and reduced-motion controls arrive in Phase 5.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
