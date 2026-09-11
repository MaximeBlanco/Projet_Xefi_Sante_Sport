import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/core/theme/app_colors.dart';
import 'package:monapp/widgets/ranking_tile.dart';

import '../support/test_fixtures.dart';

BoxDecoration decorationOf(WidgetTester tester, String name) {
  final container = tester.widget<Container>(
    find
        .ancestor(of: find.text(name), matching: find.byType(Container))
        .first,
  );
  return container.decoration! as BoxDecoration;
}

Color? nameColorOf(WidgetTester tester, String name) {
  return tester.widget<Text>(find.text(name)).style?.color;
}

Future<void> pumpTile(
  WidgetTester tester, {
  required String name,
  int rank = 1,
  int totalPoints = 240,
  bool isCurrentUser = false,
  int? currentRank,
  int? previousRank,
  int? leaderPoints,
}) {
  return tester.pumpWidget(
    buildTestAppWithScaffold(
      child: RankingTile(
        rank: rank,
        entry: buildRankingEntry(
          name: name,
          totalPoints: totalPoints,
          currentRank: currentRank,
          previousRank: previousRank,
        ),
        isCurrentUser: isCurrentUser,
        leaderPoints: leaderPoints,
      ),
    ),
  );
}

void main() {
  group('RankingTile', () {
    testWidgets('renders the rank, the name and the score', (tester) async {
      await pumpTile(tester, name: 'Alice', rank: 1, totalPoints: 240);

      expect(find.text('1'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('240'), findsOneWidget);
      expect(find.text('POINTS'), findsOneWidget);
    });

    testWidgets('highlights the row of the signed-in user with the XEFI red',
        (tester) async {
      await pumpTile(tester, name: 'Bruno', rank: 3, isCurrentUser: true);

      expect(decorationOf(tester, 'Bruno').border, isNotNull);
      expect(nameColorOf(tester, 'Bruno'), AppColors.primary);
    });

    testWidgets('leaves the other rows unbordered', (tester) async {
      await pumpTile(tester, name: 'Chloé', rank: 4);

      expect(decorationOf(tester, 'Chloé').border, isNull);
      expect(nameColorOf(tester, 'Chloé'), AppColors.black);
    });

    group('movement since Monday', () {
      testWidgets('shows the places gained when the user climbed',
          (tester) async {
        await pumpTile(
          tester,
          name: 'Alice',
          currentRank: 2,
          previousRank: 5,
        );

        expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows the places lost without a minus sign', (tester) async {
        await pumpTile(
          tester,
          name: 'Alice',
          currentRank: 4,
          previousRank: 1,
        );

        expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows a dash when the position held', (tester) async {
        await pumpTile(
          tester,
          name: 'Alice',
          currentRank: 2,
          previousRank: 2,
        );

        expect(find.text('–'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
        expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
      });

      testWidgets('shows nothing at all when the movement is unknown',
          (tester) async {
        // Absent is not the same as unchanged, so no dash either.
        await pumpTile(tester, name: 'Alice');

        expect(find.text('–'), findsNothing);
        expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
        expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
      });
    });

    testWidgets('draws the score as a share of the leader', (tester) async {
      await pumpTile(
        tester,
        name: 'Alice',
        totalPoints: 120,
        leaderPoints: 240,
      );

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0.5);
    });

    testWidgets('hides the bar when there is no leader to compare against',
        (tester) async {
      await pumpTile(tester, name: 'Alice');

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });
}
