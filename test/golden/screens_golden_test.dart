import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:planty_palace/screens/care_screen.dart';
import 'package:planty_palace/screens/my_plants_screen.dart';
import 'package:planty_palace/screens/spaces_screen.dart';
import 'package:planty_palace/styles/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_repositories.dart';

/// Renders each main screen at phone size and writes a PNG, so the design can
/// actually be *looked at* rather than only reasoned about from code. Run
/// with `flutter test --update-goldens` to regenerate after a design change.
///
/// These are deliberately not asserted against pixel-exact baselines in CI -
/// fonts differ between machines. Their value is the rendered artefact.
void main() {
  setUpAll(() {
    // Google Fonts would try to fetch over the network here; without this it
    // logs a failure per style and falls back anyway.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installFakeRepositories();
  });

  tearDown(clearFakeRepositories);

  Future<void> renderScreen(
    WidgetTester tester,
    Widget screen,
    String name, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532); // iPhone 14 Pro
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme:
            brightness == Brightness.dark
                ? AppTheme.darkTheme()
                : AppTheme.lightTheme(),
        home: screen,
      ),
    );
    // Deliberately not pumpAndSettle: the overdue pulse and the loading
    // shimmer repeat forever, so settling never completes. Pumping a fixed
    // span instead lands past the entrance and progress animations while the
    // repeating ones sit at a consistent point in their cycle.
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/$name.png'),
    );
  }

  testWidgets('Spaces hub - light', (tester) async {
    await renderScreen(tester, const SpacesScreen(), 'spaces_light');
  });

  testWidgets('Spaces hub - dark', (tester) async {
    await renderScreen(
      tester,
      const SpacesScreen(),
      'spaces_dark',
      brightness: Brightness.dark,
    );
  });

  testWidgets('Care - light', (tester) async {
    await renderScreen(tester, const CareScreen(), 'care_light');
  });

  testWidgets('Care - dark', (tester) async {
    await renderScreen(
      tester,
      const CareScreen(),
      'care_dark',
      brightness: Brightness.dark,
    );
  });

  testWidgets('My Plants grid - light', (tester) async {
    await renderScreen(tester, const MyPlantsScreen(), 'my_plants_light');
  });

  testWidgets('Spaces hub - all caught up', (tester) async {
    // Every plant recently watered, so the panel shows its calm state rather
    // than the coral "needs care" treatment.
    installFakeRepositories(
      plantRepository: FakePlantRepository(
        plants: [
          for (final plant in samplePlants())
            plant.copyWith(lastWatered: daysAgo(0)),
        ],
      ),
    );
    await renderScreen(tester, const SpacesScreen(), 'spaces_caught_up');
  });
}
