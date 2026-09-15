import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/ranking_entry.dart';
import 'package:monapp/models/team_ranking_entry.dart';
import 'package:monapp/providers/auth_provider.dart';
import 'package:monapp/providers/ranking_provider.dart';
import 'package:monapp/screens/rankings/global_ranking_screen.dart';
import 'package:monapp/widgets/ranking_podium.dart';
import 'package:monapp/widgets/ranking_tile.dart';
import 'package:monapp/widgets/team_ranking_tile.dart';

import '../../support/test_fixtures.dart';

void main() {
  group('GlobalRankingScreen', () {
    testWidgets('numbers the rows from 1 and highlights the signed-in user',
        (tester) async {
      final ranking = <RankingEntry>[
        buildRankingEntry(userId: 'user-1', name: 'Alice', totalPoints: 300),
        buildRankingEntry(userId: 'user-2', name: 'Bruno', totalPoints: 200),
        buildRankingEntry(userId: 'user-3', name: 'Chloé', totalPoints: 100),
      ];

      await tester.pumpWidget(
        buildTestAppWithScaffold(
          overrides: [
            globalRankingProvider.overrideWith((ref) => ranking),
            currentUserProvider.overrideWithValue(
              buildSignedInUser(id: 'user-2'),
            ),
          ],
          child: const GlobalRankingScreen(),
        ),
      );
      await tester.pump();

      final tiles = tester.widgetList<RankingTile>(find.byType(RankingTile));

      expect(tiles.map((tile) => tile.rank), <int>[1, 2, 3]);
      expect(
        tiles.map((tile) => tile.entry.name),
        <String>['Alice', 'Bruno', 'Chloé'],
      );
      final highlighted = tiles.where((tile) => tile.isCurrentUser);

      expect(highlighted.map((tile) => tile.entry.userId), <String>['user-2']);

      // Every row measures itself against the leader, so the bars are
      // comparable rather than each scaled to its own maximum.
      expect(
        tiles.map((tile) => tile.leaderPoints).toSet(),
        <int>{ranking.first.totalPoints},
      );
      expect(find.byType(RankingPodium), findsOneWidget);
    });

    testWidgets('shows the French empty state when nobody scored yet',
        (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          overrides: [
            globalRankingProvider.overrideWith((ref) => const <RankingEntry>[]),
            currentUserProvider.overrideWithValue(null),
          ],
          child: const GlobalRankingScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(RankingTile), findsNothing);
      expect(find.textContaining('Aucun classement'), findsOneWidget);
    });

    testWidgets('switches to the team leaderboard and back', (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          overrides: [
            globalRankingProvider.overrideWith(
              (ref) => [buildRankingEntry(userId: 'user-1', name: 'Alice')],
            ),
            teamRankingProvider.overrideWith(
              (ref) => [
                buildTeamRankingEntry(name: 'Les Rouges', totalPoints: 168),
                buildTeamRankingEntry(
                  teamId: 'team-2',
                  name: 'Agence Lyon',
                  totalPoints: 120,
                  currentRank: 2,
                ),
              ],
            ),
            currentUserProvider.overrideWithValue(null),
          ],
          child: const GlobalRankingScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(RankingTile), findsOneWidget);

      await tester.tap(find.text('Équipes'));
      await tester.pump();

      expect(find.byType(TeamRankingTile), findsNWidgets(2));
      expect(find.text('Les Rouges'), findsOneWidget);
      expect(find.byType(RankingTile), findsNothing);
      // A team of solo runners scores zero, which without a word reads as a
      // bug rather than as the rule.
      expect(find.textContaining('sport collectif'), findsOneWidget);

      await tester.tap(find.text('Individuel'));
      await tester.pump();

      expect(find.byType(RankingTile), findsOneWidget);
      expect(find.byType(TeamRankingTile), findsNothing);
    });

    testWidgets('points at the settings when no team exists yet',
        (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          overrides: [
            globalRankingProvider.overrideWith(
              (ref) => [buildRankingEntry(userId: 'user-1', name: 'Alice')],
            ),
            teamRankingProvider.overrideWith(
              (ref) => const <TeamRankingEntry>[],
            ),
            currentUserProvider.overrideWithValue(null),
          ],
          child: const GlobalRankingScreen(),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Équipes'));
      await tester.pump();

      expect(find.textContaining('Aucune équipe'), findsOneWidget);
      expect(find.byType(TeamRankingTile), findsNothing);
    });
  });
}
