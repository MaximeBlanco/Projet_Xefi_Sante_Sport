import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/core/theme/app_colors.dart';
import 'package:monapp/widgets/ranking_tile.dart';

import '../support/test_fixtures.dart';

Card cardOf(WidgetTester tester, String name) {
  return tester.widget<Card>(
    find.ancestor(of: find.text(name), matching: find.byType(Card)),
  );
}

Color? nameColorOf(WidgetTester tester, String name) {
  return tester.widget<Text>(find.text(name)).style?.color;
}

void main() {
  group('RankingTile', () {
    testWidgets('renders the rank, the name and the points', (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          child: RankingTile(
            rank: 1,
            entry: buildRankingEntry(name: 'Alice', totalPoints: 240),
            isCurrentUser: false,
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('240 pts'), findsOneWidget);
    });

    testWidgets('highlights the row of the signed-in user with the XEFI red',
        (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          child: RankingTile(
            rank: 3,
            entry: buildRankingEntry(name: 'Bruno'),
            isCurrentUser: true,
          ),
        ),
      );

      final card = cardOf(tester, 'Bruno');
      final border = card.shape as RoundedRectangleBorder;

      expect(border.side.color, AppColors.primary);
      expect(card.color, isNotNull);
      expect(nameColorOf(tester, 'Bruno'), AppColors.primary);
    });

    testWidgets('leaves the other rows on the neutral card style',
        (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          child: RankingTile(
            rank: 4,
            entry: buildRankingEntry(name: 'Chloé'),
            isCurrentUser: false,
          ),
        ),
      );

      final card = cardOf(tester, 'Chloé');

      expect(card.shape, isNull);
      expect(card.color, isNull);
      expect(nameColorOf(tester, 'Chloé'), AppColors.black);
    });
  });
}
