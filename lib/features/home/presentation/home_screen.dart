import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(top: 18, right: 18, child: _SettingsButton()),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _BakeryMark(),
                    const SizedBox(height: 24),
                    Text(
                      'Puff & Crunch',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Island Match',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.caramel,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'A sunny bakery adventure is warming up!',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => context.push('/game'),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      key: const Key('settingsButton'),
      tooltip: 'Settings',
      onPressed: () => context.push('/settings'),
      icon: const Icon(Icons.settings_rounded),
    );
  }
}

class _BakeryMark extends StatelessWidget {
  const _BakeryMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: AppColors.coconut,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.bakery_dining_rounded,
        size: 62,
        color: AppColors.caramel,
      ),
    );
  }
}
