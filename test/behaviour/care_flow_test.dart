import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:planty_palace/screens/care_screen.dart';
import 'package:planty_palace/screens/my_plants_screen.dart';
import 'package:planty_palace/screens/spaces_screen.dart';
import 'package:planty_palace/styles/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planty_palace/widgets/primitives.dart';

import '../support/fake_repositories.dart';

/// Behaviour tests for the main care flows.
///
/// These drive the real screens against in-memory repositories, so they cover
/// what the goldens cannot: that tapping things changes both the UI and the
/// data, that filters filter, and that a failed load offers a way back.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakePlantRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = installFakeRepositories();
  });

  tearDown(clearFakeRepositories);

  /// Pumps a fixed span rather than settling: the overdue pulse and the
  /// loading shimmer repeat forever, so pumpAndSettle would never return.
  Future<void> advance(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme(), home: screen),
    );
    await advance(tester);
  }

  group('Care', () {
    testWidgets('groups plants by urgency', (tester) async {
      await pumpScreen(tester, const CareScreen());

      // Two overdue (Fiddle Leaf Fig, Pilea), one due today (Monstera), and
      // two with nothing pending (Snake Plant, and the unscheduled ZZ Plant).
      expect(find.text('OVERDUE · 2'), findsOneWidget);
      expect(find.text('TODAY · 1'), findsOneWidget);
      expect(find.text('UPCOMING · 2'), findsOneWidget);
    });

    testWidgets('watering a plant writes once and updates the row', (
      tester,
    ) async {
      await pumpScreen(tester, const CareScreen());
      // Pilea's only schedule is watering, so its row is the one the water
      // button can actually resolve.
      expect(find.text('Overdue by 1 day'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text('Pilea'),
            matching: find.byType(AppRow),
          ),
          matching: find.byIcon(Icons.water_drop_rounded),
        ),
      );
      await advance(tester);

      expect(repository.calls, ['markCare:p4:water']);
      // The row re-renders from memory - no refetch, and the overdue line is
      // gone because the plant was just watered.
      expect(find.text('Overdue by 1 day'), findsNothing);
    });

    testWidgets('the overdue filter hides everything else', (tester) async {
      await pumpScreen(tester, const CareScreen());
      expect(find.text('Snake Plant'), findsOneWidget);

      await tester.tap(find.text('Overdue only'));
      await advance(tester);

      expect(find.text('Fiddle Leaf Fig'), findsOneWidget);
      expect(find.text('Pilea'), findsOneWidget);
      expect(find.text('Snake Plant'), findsNothing);
      expect(find.text('ZZ Plant'), findsNothing);
    });

    testWidgets('search narrows the list', (tester) async {
      await pumpScreen(tester, const CareScreen());

      await tester.enterText(find.byType(TextField).first, 'monst');
      await advance(tester);

      expect(find.text('Monstera'), findsOneWidget);
      expect(find.text('Fiddle Leaf Fig'), findsNothing);
    });

    testWidgets('a bulk action commits as one batched write', (tester) async {
      await pumpScreen(tester, const CareScreen());

      // Long-press enters selection mode; a second tap adds to it.
      await tester.longPress(find.text('Fiddle Leaf Fig'));
      await advance(tester);
      await tester.tap(find.text('Pilea'));
      await advance(tester);
      expect(find.text('2 selected'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.water_drop_rounded).last);
      await advance(tester);

      // One bulk call for the whole selection, not one per plant - this is
      // the write-amplification fix the repository batch exists for.
      expect(repository.calls, ['markCareBulk:2:water']);
    });

    testWidgets('a failed load offers a retry that recovers', (tester) async {
      final failing = FakePlantRepository.failing();
      repository = installFakeRepositories(plantRepository: failing);
      await pumpScreen(tester, const CareScreen());

      expect(find.text('Could not load'), findsOneWidget);

      // Recover the backend, then retry from the error view.
      failing.shouldFail = false;
      failing.plants = samplePlants();
      await tester.tap(find.text('Try again'));
      await advance(tester);

      expect(find.text('Could not load'), findsNothing);
      expect(find.text('Fiddle Leaf Fig'), findsOneWidget);
    });

    testWidgets('an empty collection explains itself', (tester) async {
      installFakeRepositories(
        plantRepository: FakePlantRepository(plants: [], gardens: []),
      );
      await pumpScreen(tester, const CareScreen());

      expect(find.text('Nothing to water yet'), findsOneWidget);
    });
  });

  group('Spaces hub', () {
    testWidgets('surfaces what needs care today', (tester) async {
      await pumpScreen(tester, const SpacesScreen());

      expect(find.text('3 plants need care'), findsOneWidget);
      // The label names the kind that is actually due - the Fiddle Leaf Fig
      // is listed for feeding, not watering.
      expect(find.text('Feed · overdue by 10 days'), findsOneWidget);
      expect(find.text('Water · overdue by 1 day'), findsOneWidget);
      // 2 already done today (from the care log) out of 5 total.
      expect(find.text('2/5'), findsOneWidget);
    });

    testWidgets('the panel action performs the care that is actually due', (
      tester,
    ) async {
      await pumpScreen(tester, const SpacesScreen());
      expect(find.text('Feed · overdue by 10 days'), findsOneWidget);

      // The Fiddle Leaf Fig row carries a feed icon, not a water drop,
      // because feeding is what is overdue on it.
      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text('Fiddle Leaf Fig'),
            matching: find.byType(AppRow),
          ),
          matching: find.byIcon(Icons.eco_outlined),
        ),
      );
      await advance(tester);

      expect(repository.calls, contains('markCare:p1:feed'));
      // Feeding clears the feeding line, but this plant is also overdue for
      // water - so the row stays and re-labels itself rather than vanishing
      // and being put straight back by the reload.
      expect(find.text('Feed · overdue by 10 days'), findsNothing);
      expect(find.text('Water · overdue by 5 days'), findsOneWidget);
      expect(find.text('3 plants need care'), findsOneWidget);
    });

    testWidgets('a fully cared-for plant leaves the panel', (tester) async {
      await pumpScreen(tester, const SpacesScreen());

      // Pilea only needs water, so watering it resolves it completely.
      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text('Pilea'),
            matching: find.byType(AppRow),
          ),
          matching: find.byIcon(Icons.water_drop_outlined),
        ),
      );
      await advance(tester);

      expect(find.text('Pilea'), findsNothing);
      expect(find.text('2 plants need care'), findsOneWidget);
    });

    testWidgets('counts Spaces without a query per Space', (tester) async {
      await pumpScreen(tester, const SpacesScreen());

      // Derived from the single hub snapshot, so these must match the sample
      // data exactly: 3 plants in the Living Room, 2 in the Bedroom.
      expect(find.text('3 plants'), findsOneWidget);
      expect(find.text('2 plants'), findsOneWidget);
      expect(find.text('Living Room'), findsOneWidget);
    });

    testWidgets('shows the calm state when nothing is due', (tester) async {
      installFakeRepositories(
        plantRepository: FakePlantRepository(plants: caughtUpPlants()),
      );
      await pumpScreen(tester, const SpacesScreen());

      expect(find.text('All caught up'), findsOneWidget);
    });
  });

  group('My Plants', () {
    testWidgets('an empty Space invites the first plant', (tester) async {
      installFakeRepositories(
        plantRepository: FakePlantRepository(plants: [], gardens: []),
      );
      await pumpScreen(tester, const MyPlantsScreen());

      expect(find.text('No plants yet'), findsOneWidget);
      expect(find.text('Add a Plant'), findsOneWidget);
    });

    testWidgets('renders every plant as a tile', (tester) async {
      await pumpScreen(tester, const MyPlantsScreen());

      expect(find.text('Fiddle Leaf Fig'), findsOneWidget);
      expect(find.text('Ficus lyrata'), findsOneWidget);
      expect(find.text('ZZ Plant'), findsOneWidget);
    });

    testWidgets('search filters the grid', (tester) async {
      await pumpScreen(tester, const MyPlantsScreen());

      await tester.enterText(find.byType(TextField).first, 'zz');
      await advance(tester);

      expect(find.text('ZZ Plant'), findsOneWidget);
      expect(find.text('Monstera'), findsNothing);
    });
  });
}
