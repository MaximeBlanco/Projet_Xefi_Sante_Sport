import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/team_ranking_entry.dart';

Map<String, dynamic> row({
  Object? totalPoints = 168,
  Object? memberCount = 3,
  Object? currentRank = 1,
  Object? previousRank = 2,
}) {
  return <String, dynamic>{
    'team_id': 'team-1',
    'name': 'Les Rouges',
    'color_value': 0xFFE10600,
    'member_count': memberCount,
    'total_points': totalPoints,
    'total_duration_min': 168,
    'session_count': 2,
    'current_rank': currentRank,
    'previous_rank': previousRank,
  };
}

void main() {
  group('TeamRankingEntry.fromJson', () {
    test('reads the row the view returns', () {
      final entry = TeamRankingEntry.fromJson(row());

      expect(entry.teamId, 'team-1');
      expect(entry.name, 'Les Rouges');
      expect(entry.memberCount, 3);
      expect(entry.totalPoints, 168);
      expect(entry.colour.toARGB32(), 0xFFE10600);
    });

    test('accepts the numbers PostgREST hands back as strings', () {
      // bigint and numeric columns arrive as JSON strings, not numbers, so a
      // direct cast would throw on exactly the columns that carry the score.
      final entry = TeamRankingEntry.fromJson(
        row(totalPoints: '168', memberCount: '3'),
      );

      expect(entry.totalPoints, 168);
      expect(entry.memberCount, 3);
    });

    test('falls back rather than throwing on a missing score', () {
      final entry = TeamRankingEntry.fromJson(row(totalPoints: null));

      expect(entry.totalPoints, 0);
    });
  });

  group('movement', () {
    test('reports a climb as positive', () {
      final entry = TeamRankingEntry.fromJson(
        row(currentRank: 1, previousRank: 3),
      );

      expect(entry.rankChange, 2);
    });

    test('reports a fall as negative', () {
      final entry = TeamRankingEntry.fromJson(
        row(currentRank: 4, previousRank: 2),
      );

      expect(entry.rankChange, -2);
    });

    test('says nothing when a position is unknown', () {
      final entry = TeamRankingEntry.fromJson(row(previousRank: null));

      expect(entry.rankChange, isNull);
    });
  });

  group('the member label', () {
    test('keeps the singular for one member', () {
      expect(TeamRankingEntry.fromJson(row(memberCount: 1)).memberLabel,
          '1 membre');
    });

    test('uses the plural otherwise', () {
      expect(TeamRankingEntry.fromJson(row(memberCount: 4)).memberLabel,
          '4 membres');
    });
  });
}
