import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/widgets/focus_timer_card.dart';

void main() {
  testWidgets('FocusTimerCard renders and actions are tappable', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<int> remaining = ValueNotifier<int>(1500);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusTimerCard(
            remainingSecondsListenable: remaining,
            durationMinutes: 25,
            isRunning: false,
            onDurationChanged: (_) {},
            onStartPause: () {},
            onReset: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Focus Timer'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();

    remaining.dispose();
  });
}
