// Basic smoke test: the app boots and lands on the Gardens home screen.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:planty_palace/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App boots to the Gardens home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ThicketApp());
    await tester.pumpAndSettle();

    expect(find.text('My Gardens'), findsOneWidget);
  });
}
