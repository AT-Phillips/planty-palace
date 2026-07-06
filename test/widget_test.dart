// Basic smoke test: the app boots and lands on the Spaces home screen.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planty_palace/main.dart';

void main() {
  testWidgets('App boots to the Spaces home screen', (WidgetTester tester) async {
    // Onboarding's "Skip" persists a preference - without this, the
    // shared_preferences plugin channel has no mock handler and the write
    // hangs forever in a widget test.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ThicketApp());
    await tester.pumpAndSettle();

    // Fresh installs land on onboarding first - skip it to reach Spaces.
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('My Spaces'), findsOneWidget);
  });
}
