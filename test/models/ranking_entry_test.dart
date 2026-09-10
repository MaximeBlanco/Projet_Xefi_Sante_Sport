import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/ranking_entry.dart';

void main() {
  group('RankingEntry.fromJson', () {
    test('reads the columns exposed by the rankings_global view', () {
      final entry = RankingEntry.fromJson(<String, dynamic>{
        'user_id': 'user-1',
        'name': 'Alice',
        'total_points': 240,
        'total_duration_min': 240,
        'total_calories_burned': 1830.5,
        'session_count': 4,
      });

      expect(entry.userId, 'user-1');
      expect(entry.name, 'Alice');
      expect(entry.totalPoints, 240);
      expect(entry.totalDurationMin, 240);
      expect(entry.totalCaloriesBurned, 1830.5);
      expect(entry.sessionCount, 4);
    });

    test('accepts the aggregates serialized as strings', () {
      final entry = RankingEntry.fromJson(<String, dynamic>{
        'user_id': 'user-2',
        'name': 'Bruno',
        'total_points': '240',
        'total_duration_min': '240',
        'total_calories_burned': '1830.5',
        'session_count': '4',
      });

      expect(entry.totalPoints, 240);
      expect(entry.totalDurationMin, 240);
      expect(entry.totalCaloriesBurned, 1830.5);
      expect(entry.sessionCount, 4);
    });

    test('treats null aggregates as zero', () {
      final entry = RankingEntry.fromJson(<String, dynamic>{
        'user_id': 'user-3',
        'name': 'Chloé',
        'total_points': null,
        'total_duration_min': null,
        'total_calories_burned': null,
        'session_count': null,
      });

      expect(entry.totalPoints, 0);
      expect(entry.totalDurationMin, 0);
      expect(entry.totalCaloriesBurned, 0);
      expect(entry.sessionCount, 0);
    });
  });
}
