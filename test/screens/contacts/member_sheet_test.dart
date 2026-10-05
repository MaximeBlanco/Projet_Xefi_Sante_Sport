import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/contact.dart';
import 'package:monapp/models/ranking_entry.dart';
import 'package:monapp/providers/auth_provider.dart';
import 'package:monapp/providers/contact_provider.dart';
import 'package:monapp/providers/ranking_provider.dart';
import 'package:monapp/screens/rankings/global_ranking_screen.dart';

import '../../support/test_fixtures.dart';

final _ranking = <RankingEntry>[
  buildRankingEntry(
    userId: 'user-2',
    name: 'Théo Marchand',
    totalPoints: 300,
    currentRank: 1,
  ),
  buildRankingEntry(
    userId: 'user-1',
    name: 'Camille Roussel',
    totalPoints: 260,
    currentRank: 2,
  ),
];

Future<void> pumpLeaderboard(
  WidgetTester tester, {
  List<Contact> contacts = const [],
}) async {
  await tester.pumpWidget(
    buildTestApp(
      overrides: [
        currentUserProvider.overrideWithValue(buildSignedInUser()),
        globalRankingProvider.overrideWith((ref) => _ranking),
        contactsProvider.overrideWith((ref) => contacts),
      ],
      child: const Scaffold(body: GlobalRankingScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  group('the member behind a leaderboard row', () {
    // FR-002: a colleague is added from the leaderboard, which is where you
    // find out who is worth measuring yourself against.
    testWidgets('opens on a name, a rank, a score and the way to add them',
        (tester) async {
      await pumpLeaderboard(tester);

      await tester.tap(find.text('Théo Marchand'));
      await tester.pumpAndSettle();

      expect(find.textContaining('1er au classement'), findsOneWidget);
      expect(find.textContaining('300 points'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Ajouter'), findsOneWidget);
    });

    testWidgets('says so rather than offering to add an existing contact',
        (tester) async {
      await pumpLeaderboard(tester, contacts: [buildContact()]);

      await tester.tap(find.text('Théo Marchand'));
      await tester.pumpAndSettle();

      expect(find.text('Contact'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Ajouter'), findsNothing);
    });

    // One's own row leads nowhere: the profile tab is one tap away and holds
    // more than this sheet ever could.
    testWidgets('does not open on the signed-in member', (tester) async {
      await pumpLeaderboard(tester);

      await tester.tap(find.text('Camille Roussel'));
      await tester.pumpAndSettle();

      expect(find.textContaining('au classement'), findsNothing);
    });
  });
}
