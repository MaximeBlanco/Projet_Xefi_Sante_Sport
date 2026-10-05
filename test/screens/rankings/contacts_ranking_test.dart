import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/contact.dart';
import 'package:monapp/models/ranking_entry.dart';
import 'package:monapp/providers/auth_provider.dart';
import 'package:monapp/providers/contact_provider.dart';
import 'package:monapp/providers/ranking_provider.dart';
import 'package:monapp/screens/contacts/contacts_screen.dart';
import 'package:monapp/screens/rankings/global_ranking_screen.dart';
import 'package:monapp/widgets/ranking_podium.dart';
import 'package:monapp/widgets/ranking_tile.dart';

import '../../support/test_fixtures.dart';

/// What the company leaderboard holds: Camille is ninth of ten, which is the
/// reason the filtered one exists.
final _globalRanking = <RankingEntry>[
  buildRankingEntry(userId: 'user-9', name: 'Lucas Fontaine', totalPoints: 900),
  buildRankingEntry(userId: 'user-2', name: 'Théo Marchand', totalPoints: 300),
  buildRankingEntry(userId: 'user-1', name: 'Camille Roussel', totalPoints: 260),
];

Future<void> pumpRankingScreen(
  WidgetTester tester, {
  required List<RankingEntry> contactsRanking,
  List<Contact> contacts = const [],
}) async {
  await tester.pumpWidget(
    buildTestApp(
      overrides: [
        currentUserProvider.overrideWithValue(buildSignedInUser()),
        globalRankingProvider.overrideWith((ref) => _globalRanking),
        contactsRankingProvider.overrideWith((ref) => contactsRanking),
        contactsProvider.overrideWith((ref) => contacts),
      ],
      child: const Scaffold(body: GlobalRankingScreen()),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('Contacts'));
  await tester.pump();
}

void main() {
  group('the contacts scope of the leaderboard', () {
    // The view returns the member and their accepted contacts, and nobody else:
    // not a colleague who never answered, not one who was never asked.
    testWidgets('holds the member and their accepted contacts alone',
        (tester) async {
      await pumpRankingScreen(
        tester,
        contactsRanking: [
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
        ],
      );

      final tiles = tester.widgetList<RankingTile>(find.byType(RankingTile));

      expect(
        tiles.map((tile) => tile.entry.name),
        <String>['Théo Marchand', 'Camille Roussel'],
      );
      // Ninth of ten in the company, second of two among colleagues: the ranks
      // are the ones the filtered view computed, not the global ones.
      expect(tiles.map((tile) => tile.rank), <int>[1, 2]);
      expect(find.text('Lucas Fontaine'), findsNothing);
    });

    testWidgets('keeps the podium the other scopes use', (tester) async {
      await pumpRankingScreen(
        tester,
        contactsRanking: [
          buildRankingEntry(userId: 'user-2', name: 'Théo', currentRank: 1),
          buildRankingEntry(userId: 'user-1', name: 'Camille', currentRank: 2),
        ],
      );

      expect(find.byType(RankingPodium), findsOneWidget);
    });

    // A leaderboard of one is this scope's empty state: the view always returns
    // the member themselves, and a ranking of one measures nothing.
    testWidgets('invites to add a colleague rather than ranking one member',
        (tester) async {
      await pumpRankingScreen(
        tester,
        contactsRanking: [
          buildRankingEntry(userId: 'user-1', name: 'Camille Roussel'),
        ],
      );

      expect(find.byType(RankingTile), findsNothing);
      expect(find.textContaining('pas encore de contact'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Ajouter un collègue'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ContactsScreen), findsOneWidget);
    });

    testWidgets('leaves the individual scope untouched', (tester) async {
      await pumpRankingScreen(
        tester,
        contactsRanking: [
          buildRankingEntry(userId: 'user-1', name: 'Camille Roussel'),
        ],
      );

      await tester.tap(find.text('Individuel'));
      await tester.pump();

      expect(find.byType(RankingTile), findsNWidgets(3));
      expect(find.text('Lucas Fontaine'), findsOneWidget);
    });
  });
}
