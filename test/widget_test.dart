import 'package:daily_compass/game/compass_logic.dart';
import 'package:daily_compass/game/models.dart';
import 'package:daily_compass/game/storage.dart';
import 'package:daily_compass/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loader shows the brand, then the menu CTA', (tester) async {
    await tester.pumpWidget(const DailyCompassApp());
    await tester.pump();

    expect(find.text('DAILY COMPASS'), findsOneWidget);
    expect(find.text('START ROUTINE'), findsNothing);

    // Hold past the splash timer, then let the entry animation settle.
    await tester.pump(const Duration(milliseconds: 8100));
    await tester.pumpAndSettle();

    expect(find.text('START ROUTINE'), findsOneWidget);
    expect(find.text('COMPASS'), findsOneWidget);
  });

  testWidgets('menu -> game -> result reaches the replay CTA', (tester) async {
    await tester.pumpWidget(const DailyCompassApp());
    await tester.pump(const Duration(milliseconds: 8100));
    await tester.pumpAndSettle();

    await tester.tap(find.text('START ROUTINE'));
    await tester.pumpAndSettle();
    expect(find.text('TAP A STEP TO CHECK IT IN'), findsOneWidget);

    await tester.tap(find.text('GO TO BALANCE'));
    await tester.pumpAndSettle();
    expect(find.text('START AGAIN'), findsOneWidget);
    expect(find.text('BACK TO COMPASS'), findsOneWidget);

    await tester.tap(find.text('BACK TO COMPASS'));
    await tester.pumpAndSettle();
    expect(find.text('START ROUTINE'), findsOneWidget);
  });

  test('seeded routine steps are mutable', () {
    final routine = CompassStorage.instance.loadRoutine(RoutineKind.morning);
    expect(routine.steps, isNotEmpty);
    // A const literal seed would throw here.
    expect(() => routine.steps.removeAt(0), returnsNormally);
  });

  test('balance rewards an even day over a lopsided one', () {
    RoutineStep step(String id, StepCategory c, bool done) =>
        RoutineStep(id: id, title: id, category: c, done: done);

    final even = <RoutineStep>[
      step('a', StepCategory.mind, true),
      step('b', StepCategory.body, true),
      step('c', StepCategory.home, true),
      step('d', StepCategory.focus, true),
    ];
    final lopsided = <RoutineStep>[
      step('a', StepCategory.mind, true),
      step('b', StepCategory.body, false),
      step('c', StepCategory.home, false),
      step('d', StepCategory.focus, false),
    ];

    expect(CompassLogic.balanceScore(even), 100);
    expect(CompassLogic.balanceScore(lopsided), lessThan(50));
  });

  test('needle rests pointing north on an untouched day', () {
    final fill = CompassLogic.fillByCategory(const <RoutineStep>[]);
    final vector = CompassLogic.imbalanceVector(fill);
    expect(vector, Offset.zero);
    expect(CompassLogic.needleLean(vector), 0.0);
  });
}
