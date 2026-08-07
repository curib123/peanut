import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/glass_panel.dart';
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
        padding: const EdgeInsets.all(16),
        children: [
          Text('Experience', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          GlassPanel(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingSwitch(
                  icon: Icons.volume_up_rounded,
                  title: 'Sound effects',
                  value: settings.soundEnabled,
                  onChanged: (value) => controller.updateSettings(
                    settings.copyWith(soundEnabled: value),
                  ),
                ),
                const Divider(height: 1, indent: 58),
                _SettingSwitch(
                  icon: Icons.music_note_rounded,
                  title: 'Music',
                  value: settings.musicEnabled,
                  onChanged: (value) => controller.updateSettings(
                    settings.copyWith(musicEnabled: value),
                  ),
                ),
                const Divider(height: 1, indent: 58),
                _SettingSwitch(
                  icon: Icons.vibration_rounded,
                  title: 'Haptic feedback',
                  value: settings.hapticsEnabled,
                  onChanged: (value) => controller.updateSettings(
                    settings.copyWith(hapticsEnabled: value),
                  ),
                ),
                const Divider(height: 1, indent: 58),
                _SettingSwitch(
                  icon: Icons.motion_photos_off_rounded,
                  title: 'Reduced motion',
                  subtitle: 'Uses shorter, simpler gameplay movement.',
                  value: settings.reducedMotion,
                  onChanged: (value) => controller.updateSettings(
                    settings.copyWith(reducedMotion: value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Save data', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          GlassPanel(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              leading: const Icon(Icons.restart_alt_rounded),
              title: const Text('Reset progress'),
              subtitle: const Text('Stars, scores, unlocks, and boosters'),
              onTap: () => _confirmReset(context, controller),
            ),
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
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: Icon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    value: value,
    onChanged: onChanged,
  );
}
