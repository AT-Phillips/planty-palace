import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:planty_palace/screens/account_screen.dart';
import 'package:planty_palace/screens/add_edit_plant_screen.dart';
import 'package:planty_palace/screens/main_shell.dart';
import 'package:planty_palace/screens/propagations_screen.dart';
import 'package:planty_palace/screens/species_detail_screen.dart';
import 'package:planty_palace/services/perenual_service.dart';
import 'package:planty_palace/screens/care_screen.dart';
import 'package:planty_palace/screens/guides_screen.dart';
import 'package:planty_palace/screens/plant_detail_screen.dart';
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

  testWidgets('Plant detail - light', (tester) async {
    await renderScreen(
      tester,
      PlantDetailScreen(plant: samplePlants().first),
      'plant_detail_light',
    );
  });

  testWidgets('Guides - light', (tester) async {
    await renderScreen(tester, const GuidesScreen(), 'guides_light');
  });

  testWidgets('Account and settings - light', (tester) async {
    await renderScreen(tester, const AccountScreen(), 'account_light');
  });

  testWidgets('Care - failed load shows a retryable error', (tester) async {
    installFakeRepositories(plantRepository: FakePlantRepository.failing());
    await renderScreen(tester, const CareScreen(), 'care_error');
  });

  testWidgets('My Plants - empty collection', (tester) async {
    installFakeRepositories(
      plantRepository: FakePlantRepository(plants: [], gardens: []),
    );
    await renderScreen(tester, const MyPlantsScreen(), 'my_plants_empty');
  });

  testWidgets('Main shell - nav bar over the hub', (tester) async {
    await renderScreen(tester, const MainShell(), 'shell_light');
  });

  testWidgets('Add plant form', (tester) async {
    await renderScreen(
      tester,
      const AddEditPlantScreen(gardenId: 'g1'),
      'add_plant_light',
    );
  });

  testWidgets('Species detail', (tester) async {
    await renderScreen(
      tester,
      SpeciesDetailScreen(
        species: PerenualSpeciesDetail(
          scientificName: 'Monstera deliciosa',
          commonName: 'Swiss Cheese Plant',
          imageUrl: null,
          wateringIntervalDays: 7,
          careInstructions:
              'Bright indirect light. Let the top few centimetres of soil dry '
              'out between waterings, then water thoroughly.',
        ),
      ),
      'species_detail_light',
    );
  });

  testWidgets('Propagations list', (tester) async {
    await renderScreen(
      tester,
      const PropagationsScreen(),
      'propagations_light',
    );
  });

  testWidgets('Care at large accessibility text', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            devicePixelRatio: 3.0,
            textScaler: TextScaler.linear(1.8),
          ),
          child: const CareScreen(),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/care_large_text.png'),
    );
  });

  testWidgets('Spaces hub - all caught up', (tester) async {
    // Every schedule freshly satisfied, so the panel shows its calm state
    // rather than the coral "needs care" treatment.
    installFakeRepositories(
      plantRepository: FakePlantRepository(plants: caughtUpPlants()),
    );
    await renderScreen(tester, const SpacesScreen(), 'spaces_caught_up');
  });
}
