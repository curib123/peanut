import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/game_primary_button.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../services/content/world_presentation_catalog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 700;
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
                      colors: [
                        const Color(0x11000000),
                        const Color(0x993A1C12),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Stack(
                  children: [
                    Align(
                      alignment: const Alignment(0, .28),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 68, bottom: 12),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: GlassPanel(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  28,
                                  24,
                                  26,
                                ),
                                radius: 32,
                                tint: const Color(0xCC3A1C12),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _BakeryMark(extent: compact ? 96 : 154),
                                    SizedBox(height: compact ? 12 : 24),
                                    Text(
                                      'Puff & Crunch',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontSize: compact ? 32 : null,
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: const Color(0xFFFFD76A),
                                            letterSpacing: 2,
                                          ),
                                    ),
                                    const SizedBox(height: 18),
                                    if (!compact)
                                      const Text(
                                        'A sunny bakery adventure is warming up!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    if (!compact) const SizedBox(height: 18),
                                    if (!compact)
                                      const Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 10,
                                        runSpacing: 8,
                                        children: [
                                          _FeatureChip(
                                            icon: Icons.route_rounded,
                                            label: '120 levels',
                                          ),
                                          _FeatureChip(
                                            icon: Icons.public_rounded,
                                            label: '6 worlds',
                                          ),
                                          _FeatureChip(
                                            icon: Icons.auto_awesome_rounded,
                                            label: 'Play offline',
                                          ),
                                        ],
                                      ),
                                    if (compact)
                                      const Text(
                                        '120 levels · 6 worlds · Play offline',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFFFFDF9D),
                                          fontSize: 13,
                                        ),
                                      ),
                                    SizedBox(height: compact ? 20 : 32),
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
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 18,
                      right: 18,
                      child: _SettingsButton(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFFFD76A), size: 17),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
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
  const _BakeryMark({this.extent = 154});
  final double extent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Puff and Crunch peanut baker logo',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: .92, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Image.asset(
          'assets/images/ui/puff_crunch_logo.png',
          width: extent,
          height: extent,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
