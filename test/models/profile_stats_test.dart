import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/profile_stats.dart';
import 'package:monapp/models/session.dart';

import '../support/test_fixtures.dart';

Session sessionOf({
  required String sportId,
  required int durationMin,
  double? caloriesBurned = 300,
  double? distanceKm,
  DateTime? date,
}) {
  return buildSession(
    id: '$sportId-$durationMin-${date?.day ?? 0}',
    sportId: sportId,
    durationMin: durationMin,
    points: durationMin,
    caloriesBurned: caloriesBurned,
    distanceKm: distanceKm,
    date: date,
    sport: buildSport(id: sportId, name: sportId, emoji: '🏃'),
  );
}

void main() {
  group('ProfileStats.fromSessions', () {
    test('reports empty stats without a session', () {
      final stats = ProfileStats.fromSessions(const <Session>[]);

      expect(stats.hasSessions, isFalse);
      expect(stats.sessionCount, 0);
      expect(stats.averageDurationMin, 0);
      expect(stats.favouriteSport, isNull);
      expect(stats.sportBreakdown, isEmpty);
    });

    test('totals duration, points and calories', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(sportId: 'course', durationMin: 30),
        sessionOf(sportId: 'velo', durationMin: 90),
      ]);

      expect(stats.sessionCount, 2);
      expect(stats.totalDurationMin, 120);
      expect(stats.totalPoints, 120);
      expect(stats.totalCaloriesBurned, 600);
      expect(stats.averageDurationMin, 60);
      expect(stats.longestSessionMin, 90);
    });

    test('counts a session with unknown calories without inventing a value',
        () {
      final stats = ProfileStats.fromSessions([
        sessionOf(sportId: 'course', durationMin: 30, caloriesBurned: null),
      ]);

      expect(stats.sessionCount, 1);
      expect(stats.totalCaloriesBurned, 0);
      expect(stats.hasCaloriesData, isFalse);
    });

    test('ranks the favourite sport by time, not by session count', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(sportId: 'course', durationMin: 10),
        sessionOf(sportId: 'course', durationMin: 10),
        sessionOf(sportId: 'course', durationMin: 10),
        sessionOf(sportId: 'velo', durationMin: 120),
      ]);

      expect(stats.favouriteSport?.sportId, 'velo');
      expect(stats.sportBreakdown.first.totalDurationMin, 120);
      expect(stats.sportBreakdown.last.sessionCount, 3);
    });

    test('keeps the earliest date as the starting point', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(
          sportId: 'course',
          durationMin: 30,
          date: DateTime(2026, 5, 20),
        ),
        sessionOf(
          sportId: 'velo',
          durationMin: 30,
          date: DateTime(2026, 2, 3),
        ),
      ]);

      expect(stats.firstSessionDate, DateTime(2026, 2, 3));
    });

    test('rounds the average rather than truncating it', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(sportId: 'course', durationMin: 10),
        sessionOf(sportId: 'velo', durationMin: 15),
        sessionOf(sportId: 'yoga', durationMin: 20),
      ]);

      expect(stats.averageDurationMin, 15);
    });

    test('adds up the distance of the GPS-tracked sessions', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(sportId: 'course', durationMin: 30, distanceKm: 5.2),
        sessionOf(sportId: 'velo', durationMin: 60, distanceKm: 18.4),
      ]);

      expect(stats.totalDistanceKm, closeTo(23.6, 0.001));
    });

    test('ignores the sessions that were never tracked', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(sportId: 'course', durationMin: 30, distanceKm: 5.0),
        sessionOf(sportId: 'natation', durationMin: 45),
      ]);

      expect(stats.totalDistanceKm, 5.0);
    });

    // A month of swimming is not a month of zero kilometres, so the tile is
    // left out rather than showing a distance nobody covered.
    test('leaves the distance absent when nothing was tracked', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(sportId: 'natation', durationMin: 45),
      ]);

      expect(stats.totalDistanceKm, isNull);
    });
  });
}
