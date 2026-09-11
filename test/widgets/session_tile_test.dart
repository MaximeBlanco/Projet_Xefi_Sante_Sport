import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:monapp/core/domain/venue_kind.dart';
import 'package:monapp/models/venue.dart';
import 'package:monapp/widgets/session_tile.dart';

import '../support/test_fixtures.dart';

const String _emDashPlaceholder = '\u2014';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('SessionTile', () {
    testWidgets('shows a dash instead of 0 when the calories are unknown',
        (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          child: SessionTile(session: buildSession(caloriesBurned: null)),
        ),
      );

      expect(find.text('$_emDashPlaceholder kcal'), findsOneWidget);
      expect(find.text('0 kcal'), findsNothing);
    });

    testWidgets('rounds the calories returned by the external API',
        (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          child: SessionTile(session: buildSession(caloriesBurned: 412.4)),
        ),
      );

      expect(find.text('412 kcal'), findsOneWidget);
      expect(find.text('$_emDashPlaceholder kcal'), findsNothing);
    });

    testWidgets('marks a locally estimated value so it cannot pass for a '
        'measured one', (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          child: SessionTile(
            session: buildSession(
              caloriesBurned: 367.5,
              caloriesEstimated: true,
            ),
          ),
        ),
      );

      expect(find.text('≈ 368 kcal'), findsOneWidget);
      expect(find.text('368 kcal'), findsNothing);
    });

    testWidgets('shows the sport, the French date, the duration and the points',
        (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          child: SessionTile(
            session: buildSession(
              date: DateTime(2026, 3, 14),
              durationMin: 45,
              points: 45,
            ),
          ),
        ),
      );

      expect(find.text('Course à pied'), findsOneWidget);
      expect(find.text('🏃'), findsOneWidget);
      expect(find.text('14 mars 2026'), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('45 pts'), findsOneWidget);
    });

    testWidgets('degrades gracefully when the sport was not embedded',
        (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          child: SessionTile(
            session: buildSession(withEmbeddedSport: false),
          ),
        ),
      );

      expect(find.text('Sport inconnu'), findsOneWidget);
    });

    // Regression: the venue used to share the date's line under a maxLines of
    // one, so "La bulle yoga" reached the history as "La bulle …".
    testWidgets('shows the venue name in full', (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          child: SessionTile(
            session: buildSession(
              venue: const Venue(
                name: 'La bulle yoga',
                osmId: 'node/5475245725',
                kind: VenueKind.fitnessCentre,
              ),
            ),
          ),
        ),
      );

      expect(find.text('La bulle yoga'), findsOneWidget);
    });

    testWidgets('shows no venue row for a session recorded without one',
        (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(child: SessionTile(session: buildSession())),
      );

      expect(find.byIcon(Icons.place_outlined), findsNothing);
    });
  });
}
