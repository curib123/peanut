import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/game_primary_button.dart';
import '../../../services/content/world_presentation_catalog.dart';
import '../../progress/application/progress_controller.dart';
import '../../progress/domain/game_save_data.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressControllerProvider);
    return FutureBuilder<WorldPresentationCatalog>(
      future: WorldPresentationCatalog.load(),
      builder: (context, snapshot) => Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                snapshot.data?.main.backgroundAsset ??
                    'assets/images/worlds/sunrise_adventure.png',
                fit: BoxFit.cover,
                alignment: const Alignment(.25, -.25),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x443A2315), Color(0xF22C1D15)],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 700;
                  final compact = constraints.maxHeight < 700;
                  final welcome = _Welcome(compact: compact);
                  final details = snapshot.hasData && progress.isLoaded
                      ? _AdventureDetails(
                          catalog: snapshot.data!,
                          save: progress.data,
                        )
                      : const Text(
                          'Opening your recipe book…',
                          style: TextStyle(color: AppColors.coconut),
                        );
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 40 : 22,
                            88,
                            wide ? 40 : 22,
                            28,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1040),
                              child: wide
                                  ? Row(
                                      children: [
                                        Expanded(child: welcome),
                                        const SizedBox(width: 36),
                                        Expanded(child: details),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        welcome,
                                        const SizedBox(height: 26),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 430,
                                          ),
                                          child: details,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 22,
                        right: 22,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bakery_dining_rounded,
                              color: Color(0xFFFFD886),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'THE ISLAND BAKERY',
                                style: TextStyle(
                                  color: AppColors.coconut,
                                  fontSize: 11,
                                  letterSpacing: 1.8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton.filledTonal(
                              key: const Key('settingsButton'),
                              tooltip: 'Settings',
                              style: IconButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                backgroundColor: AppColors.cream,
                                foregroundColor: AppColors.cocoa,
                              ),
                              onPressed: () => context.push('/settings'),
                              icon: const Icon(Icons.settings_rounded),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: compact ? 128 : 184,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: const Alignment(-.8, .7),
              child: Transform.rotate(
                angle: -.2,
                child: Image.asset(
                  'assets/images/pieces/sugar_crystal.png',
                  width: compact ? 40 : 54,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            Align(
              alignment: const Alignment(.8, .7),
              child: Transform.rotate(
                angle: .18,
                child: Image.asset(
                  'assets/images/specials/peanut_kisses.png',
                  width: compact ? 46 : 64,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            Image.asset(
              'assets/images/ui/puff_crunch_logo.png',
              height: compact ? 130 : 188,
              semanticLabel: 'Puff and Crunch peanut baker',
              filterQuality: FilterQuality.high,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Puff & Crunch',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          color: AppColors.coconut,
          fontSize: compact ? 34 : 42,
          fontWeight: FontWeight.w900,
          height: 1.05,
          letterSpacing: -1.4,
          shadows: const [
            Shadow(
              color: Color(0xAA3A1C12),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Island Match',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFFFFD886),
          letterSpacing: 3,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'A little match. A lovely adventure.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.coconut,
          fontSize: 15,
          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
        ),
      ),
    ],
  );
}

class _AdventureDetails extends StatelessWidget {
  const _AdventureDetails({required this.catalog, required this.save});
  final WorldPresentationCatalog catalog;
  final GameSaveData save;

  @override
  Widget build(BuildContext context) {
    final current = save.highestUnlockedLevel.clamp(1, catalog.lastLevel);
    final world = catalog.worldForLevel(current);
    final completed = save.starsByLevel.entries.where(
      (entry) =>
          entry.key >= 1 && entry.key <= catalog.lastLevel && entry.value > 0,
    );
    final stars = completed.fold<int>(
      0,
      (total, entry) => total + entry.value.clamp(0, 3),
    );
    final finished = save.highestUnlockedLevel > catalog.lastLevel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2D5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFDA8C)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ProgressItem(
                  icon: Icons.menu_book_rounded,
                  label: '${completed.length} recipes baked',
                  color: AppColors.palm,
                ),
              ),
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: const Color(0xFFDCC8A4),
              ),
              Expanded(
                child: _ProgressItem(
                  icon: Icons.star_rounded,
                  label: '$stars stars collected',
                  color: const Color(0xFFB66F13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: const Color(0xFF245D50),
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          elevation: 6,
          shadowColor: const Color(0x55331D13),
          child: InkWell(
            onTap: () => context.push('/level/$current'),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 76,
                    child: Image.asset(
                      world.backgroundAsset,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            finished ? 'Adventure complete' : 'YOUR NEXT STOP',
                            style: const TextStyle(
                              color: Color(0xFFFFDA8C),
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            world.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppColors.coconut,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'World ${world.order} of ${catalog.worlds.length}',
                            style: const TextStyle(
                              color: Color(0xFFD1E6D6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Recipe $current',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFFFFDA8C),
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: GamePrimaryButton(
            onPressed: () => context.push('/map'),
            icon: Icons.play_arrow_rounded,
            label: 'Play Adventure',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${catalog.lastLevel} recipes · ${catalog.worlds.length} worlds · Play offline',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFFFDFB0),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProgressItem extends StatelessWidget {
  const _ProgressItem({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 4),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.cocoa,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    ],
  );
}
