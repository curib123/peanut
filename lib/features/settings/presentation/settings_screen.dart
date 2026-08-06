import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../progress/application/progress_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(progressControllerProvider).data.settings;
    final controller = ref.read(progressControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SettingSwitch(
            title: 'Sound effects',
            value: settings.soundEnabled,
            onChanged: (value) => controller.updateSettings(
              settings.copyWith(soundEnabled: value),
            ),
          ),
          _SettingSwitch(
            title: 'Music',
            value: settings.musicEnabled,
            onChanged: (value) => controller.updateSettings(
              settings.copyWith(musicEnabled: value),
            ),
          ),
          _SettingSwitch(
            title: 'Haptic feedback',
            value: settings.hapticsEnabled,
            onChanged: (value) => controller.updateSettings(
              settings.copyWith(hapticsEnabled: value),
            ),
          ),
          _SettingSwitch(
            title: 'Reduced motion',
            subtitle: 'Uses shorter, simpler gameplay movement.',
            value: settings.reducedMotion,
            onChanged: (value) => controller.updateSettings(
              settings.copyWith(reducedMotion: value),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restart_alt_rounded),
            title: const Text('Reset progress'),
            subtitle: const Text('Stars, scores, unlocks, and boosters'),
            onTap: () => _confirmReset(context, controller),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    ProgressController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.reset();
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    value: value,
    onChanged: onChanged,
  );
}
