import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/game_primary_button.dart';
import '../../../services/content/world_presentation_catalog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<WorldPresentationCatalog>(
              future: WorldPresentationCatalog.load(),
              builder: (context, snapshot) => Image.asset(
                snapshot.data?.main.backgroundAsset ??
                    'assets/images/worlds/sunrise_adventure.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: AppColors.cream),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0x11000000), const Color(0x993A1C12)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                const Positioned(top: 18, right: 18, child: _SettingsButton()),
                Align(
                  alignment: const Alignment(0, .28),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                      decoration: BoxDecoration(
                        color: const Color(0xB33A1C12),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: const Color(0x99FFE49A),
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 24),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _BakeryMark(),
                          const SizedBox(height: 24),
                          Text(
                            'Puff & Crunch',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Island Match',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: const Color(0xFFFFD76A),
                                  letterSpacing: 2,
                                ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'A sunny bakery adventure is warming up!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 32),
                          GamePrimaryButton(
                            onPressed: () => context.push('/map'),
                            icon: Icons.play_arrow_rounded,
                            label: 'Play Adventure',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return Semantics(
      label: 'Peanut Kisses baker mascot',
      child: Container(
        width: 122,
        height: 122,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.coconut.withValues(alpha: .94),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold, width: 5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x42000000),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SvgPicture.asset(
          'assets/svg/characters/peanut_baker.svg',
          placeholderBuilder: (_) => const Icon(
            Icons.bakery_dining_rounded,
            size: 62,
            color: AppColors.caramel,
          ),
        ),
      ),
    );
  }
}
