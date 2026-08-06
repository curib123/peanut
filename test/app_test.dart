import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/app/app.dart';

void main() {
  testWidgets('home screen presents the game identity', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PuffAndCrunchApp()));

    expect(find.text('Puff & Crunch'), findsOneWidget);
    expect(find.text('Island Match'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('settings route opens and returns home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PuffAndCrunchApp()));

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Puff & Crunch'), findsOneWidget);
  });

  testWidgets('play opens the Flame gameplay route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PuffAndCrunchApp()));

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sunrise Bakery'), findsOneWidget);
    expect(find.text('Practice Board'), findsOneWidget);
    expect(find.text('Moves: 20'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);
  });
}
