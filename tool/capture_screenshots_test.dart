import 'dart:io';

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/app/app.dart';
import 'package:puff_and_crunch/app/router.dart';
import 'package:puff_and_crunch/core/theme/app_theme.dart';
import 'package:puff_and_crunch/features/gameplay/presentation/gameplay_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    appRouter.go('/');
  });

  testWidgets('capture phone-sized game tour', (tester) async {
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: PuffAndCrunchApp()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/01-home.png'),
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/02-settings.png'),
    );

    appRouter.go('/map');
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/03-level-map.png'),
    );

    await tester.tap(find.byKey(const Key('level-1')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/04-pre-level.png'),
    );

    await tester.runAsync(_preloadGameSprites);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: GameplayScreen(level: 1),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 4)),
    );
    for (var frame = 0; frame < 120; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Moves: 18'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/05-gameplay.png'),
    );

    tester
        .widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.pause_rounded),
        )
        .onPressed!();
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/06-paused.png'),
    );
  });
}

Future<void> _preloadGameSprites() => Flame.images.loadAll(const [
  'pieces/peanut.png',
  'pieces/egg.png',
  'pieces/sugar_crystal.png',
  'pieces/caramel_ribbon.png',
  'pieces/coconut_cream.png',
  'pieces/cocoa_crumb.png',
  'specials/sugar_beam_horizontal.png',
  'specials/sugar_beam_vertical.png',
  'specials/golden_recipe_spark.png',
  'specials/oven_burst.png',
  'specials/peanut_spinner.png',
  'effects/match_burst_sheet.png',
]);

Future<void> _loadFonts() async {
  const materialPath = r'C:\src\flutter\bin\cache\artifacts\material_fonts\';
  final roboto = FontLoader('Roboto');
  for (final name in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ]) {
    final bytes = File('$materialPath$name').readAsBytesSync();
    roboto.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
  }
  final iconBytes = File(
    '${materialPath}materialicons-regular.otf',
  ).readAsBytesSync();
  final icons = FontLoader(
    'MaterialIcons',
  )..addFont(Future.value(ByteData.view(Uint8List.fromList(iconBytes).buffer)));
  await Future.wait([roboto.load(), icons.load()]);
}
