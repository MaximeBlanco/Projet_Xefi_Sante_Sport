import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/home_summary.dart';
import 'package:monapp/providers/home_summary_provider.dart';
import 'package:monapp/screens/home/home_dashboard_screen.dart';

import '../../support/test_fixtures.dart';

HomeSummary buildSummary({
  String displayName = 'Maxime Lenormand',
  int totalPoints = 222,
  int sessionCount = 4,
  int? rank = 2,
  int participantCount = 6,
  bool withLastSession = true,
  double totalCaloriesBurned = 1855,
}) {
  return HomeSummary(
    displayName: displayName,
    totalPoints: totalPoints,
    sessionCount: sessionCount,
    totalDurationMin: 222,
    totalCaloriesBurned: totalCaloriesBurned,
    participantCount: participantCount,
    rank: rank,
    lastSession: withLastSession ? buildSession() : null,
  );
}

Widget buildScreen(HomeSummary summary) {
  return buildTestApp(
    overrides: [homeSummaryProvider.overrideWith((ref) => summary)],
    child: const Scaffold(body: HomeDashboardScreen()),
  );
}

void main() {
  group('HomeDashboardScreen', () {
    testWidgets('greets the user and leads with the score', (tester) async {
      await tester.pumpWidget(buildScreen(buildSummary()));
      await tester.pump();

      expect(find.text('Bonjour'), findsOneWidget);
      expect(find.text('Maxime'), findsOneWidget);
      expect(find.text('222'), findsOneWidget);
      expect(find.text('points'), findsOneWidget);
    });

    testWidgets('shows the rank against the field', (tester) async {
      await tester.pumpWidget(buildScreen(buildSummary()));
      await tester.pump();

      expect(find.text('2e sur 6'), findsOneWidget);
    });

    testWidgets('invites a new account in rather than showing a rank',
        (tester) async {
      await tester.pumpWidget(
        buildScreen(
          buildSummary(rank: null, sessionCount: 0, withLastSession: false),
        ),
      );
      await tester.pump();

      expect(find.text('2e sur 6'), findsNothing);
      expect(
        find.text('Enregistrez une séance pour entrer au classement.'),
        findsOneWidget,
      );
    });

    testWidgets('offers the primary action', (tester) async {
      await tester.pumpWidget(buildScreen(buildSummary()));
      await tester.pump();

      expect(
        find.widgetWithText(ElevatedButton, 'Enregistrer une séance'),
        findsOneWidget,
      );
    });

    testWidgets('hides the last-session block when there is none',
        (tester) async {
      await tester.pumpWidget(
        buildScreen(buildSummary(withLastSession: false)),
      );
      await tester.pump();

      expect(find.text('DERNIÈRE SÉANCE'), findsNothing);
    });

    testWidgets('shows a dash rather than 0 kcal when none were measured',
        (tester) async {
      await tester.pumpWidget(
        buildScreen(buildSummary(totalCaloriesBurned: 0)),
      );
      await tester.pump();

      expect(find.text('—'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('agrees with the singular when only one session exists',
        (tester) async {
      await tester.pumpWidget(buildScreen(buildSummary(sessionCount: 1)));
      await tester.pump();

      expect(find.text('séance'), findsOneWidget);
      expect(find.text('séances'), findsNothing);
    });
  });
}
