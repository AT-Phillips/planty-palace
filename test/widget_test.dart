// Basic smoke test: the app boots and lands on the Spaces home screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:planty_palace/main.dart';

void main() {
  testWidgets('App boots to the Spaces home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ThicketApp());
    await tester.pumpAndSettle();

    expect(find.text('My Spaces'), findsOneWidget);
  });
}
