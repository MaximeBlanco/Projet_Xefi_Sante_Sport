import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/profile_stats.dart';
import 'package:monapp/models/session.dart';

import '../support/test_fixtures.dart';

/// Pinned so the streak, the month totals and the six-month window are asserted
/// against a fixed "today" rather than against the day the suite happens to run.
final today = DateTime(2026, 3, 20);

Session sessionOf({
  required String sportId,
  required int durationMin,
  double? caloriesBurned = 300,
  DateTime? date,
}) {
  return buildSession(
    id: '$sportId-$durationMin-${date?.day ?? 0}',
    sportId: sportId,
    durationMin: durationMin,
    points: durationMin,
    caloriesBurned: caloriesBurned,
    date: date,
    sport: buildSport(id: sportId, name: sportId, emoji: '🏃'),
  );
}

void main() {
  group('ProfileStats.fromSessions', () {
    test('reports empty stats without a session', () {
      final stats = ProfileStats.fromSessions(const <Session>[], today);

      expect(stats.hasSessions, isFalse);
      expect(stats.sessionCount, 0);
      expect(stats.averageDurationMin, 0);
      expect(stats.favouriteSport, isNull);
      expect(stats.sportBreakdown, isEmpty);
      expect(stats.currentStreakDays, 0);
    });

    test('still charts six months when there is nothing to chart', () {
      final stats = ProfileStats.fromSessions(const <Session>[], today);

      expect(stats.lastSixMonths, hasLength(ProfileStats.monthsCharted));
      expect(stats.lastSixMonths.last.month, DateTime(2026, 3));
      expect(stats.bestMonthPoints, 0);
    });

    test('totals duration, points and calories', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(sportId: 'course', durationMin: 30),
        sessionOf(sportId: 'velo', durationMin: 90),
      ], today);

      expect(stats.sessionCount, 2);
      expect(stats.totalDurationMin, 120);
      expect(stats.totalPoints, 120);
      expect(stats.totalCaloriesBurned, 600);
      expect(stats.averageDurationMin, 60);
      expect(stats.longestSessionMin, 90);
    });

    test('counts a session with unknown calories without inventing a value', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(sportId: 'course', durationMin: 30, caloriesBurned: null),
      ], today);

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
      ], today);

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
        sessionOf(sportId: 'velo', durationMin: 30, date: DateTime(2026, 2, 3)),
      ], today);

      expect(stats.firstSessionDate, DateTime(2026, 2, 3));
    });

    test('rounds the average rather than truncating it', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(sportId: 'course', durationMin: 10),
        sessionOf(sportId: 'velo', durationMin: 15),
        sessionOf(sportId: 'natation', durationMin: 20),
      ], today);

      expect(stats.averageDurationMin, 15);
    });
  });

  group('current month', () {
    test('counts only the sessions of the month in progress', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(
          sportId: 'course',
          durationMin: 30,
          date: DateTime(2026, 3, 14),
        ),
        sessionOf(
          sportId: 'velo',
          durationMin: 40,
          date: DateTime(2026, 3, 18),
        ),
        sessionOf(
          sportId: 'velo',
          durationMin: 60,
          date: DateTime(2026, 2, 20),
        ),
      ], today);

      expect(stats.monthSessionCount, 2);
      expect(stats.monthDurationMin, 70);
      expect(stats.monthPoints, 70);
      expect(stats.monthActiveDays, 2);
      expect(stats.totalDurationMin, 130);
    });

    test('counts a day trained twice as one active day', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(
          sportId: 'course',
          durationMin: 30,
          date: DateTime(2026, 3, 18),
        ),
        sessionOf(
          sportId: 'velo',
          durationMin: 40,
          date: DateTime(2026, 3, 18),
        ),
      ], today);

      expect(stats.monthSessionCount, 2);
      expect(stats.monthActiveDays, 1);
    });
  });

  group('streak', () {
    test('counts consecutive days ending today', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(
          sportId: 'course',
          durationMin: 30,
          date: DateTime(2026, 3, 18),
        ),
        sessionOf(
          sportId: 'velo',
          durationMin: 30,
          date: DateTime(2026, 3, 19),
        ),
        sessionOf(
          sportId: 'course',
          durationMin: 30,
          date: DateTime(2026, 3, 20),
        ),
      ], today);

      expect(stats.currentStreakDays, 3);
    });

    test('a day still in progress does not break the run', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(
          sportId: 'course',
          durationMin: 30,
          date: DateTime(2026, 3, 18),
        ),
        sessionOf(
          sportId: 'velo',
          durationMin: 30,
          date: DateTime(2026, 3, 19),
        ),
      ], today);

      expect(stats.currentStreakDays, 2);
    });

    test('a gap of one full day ends the run', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(
          sportId: 'course',
          durationMin: 30,
          date: DateTime(2026, 3, 17),
        ),
        sessionOf(
          sportId: 'velo',
          durationMin: 30,
          date: DateTime(2026, 3, 18),
        ),
      ], today);

      expect(stats.currentStreakDays, 0);
    });
  });

  group('records and the six-month chart', () {
    test('places each month of the window and names the best', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(
          sportId: 'course',
          durationMin: 30,
          date: DateTime(2026, 3, 14),
        ),
        sessionOf(
          sportId: 'velo',
          durationMin: 40,
          date: DateTime(2026, 3, 18),
        ),
        sessionOf(
          sportId: 'velo',
          durationMin: 90,
          date: DateTime(2026, 2, 20),
        ),
      ], today);

      final months = stats.lastSixMonths;
      expect(months, hasLength(6));
      expect(months.first.month, DateTime(2025, 10));
      expect(months.last.month, DateTime(2026, 3));
      expect(months.last.points, 70);
      expect(months[4].points, 90);
      expect(stats.bestMonthPoints, 90);
    });

    test('leaves a session older than the window out of the chart', () {
      final stats = ProfileStats.fromSessions([
        sessionOf(
          sportId: 'course',
          durationMin: 45,
          date: DateTime(2025, 6, 10),
        ),
      ], today);

      expect(stats.totalPoints, 45);
      expect(stats.bestMonthPoints, 0);
      expect(stats.lastSixMonths.every((month) => month.points == 0), isTrue);
    });

    test('takes the best calendar week, weeks starting on Monday', () {
      final stats = ProfileStats.fromSessions([
        // Saturday 14 and Sunday 15 March share the week beginning Monday 9.
        sessionOf(
          sportId: 'course',
          durationMin: 30,
          date: DateTime(2026, 3, 14),
        ),
        sessionOf(
          sportId: 'velo',
          durationMin: 40,
          date: DateTime(2026, 3, 15),
        ),
        sessionOf(
          sportId: 'course',
          durationMin: 50,
          date: DateTime(2026, 3, 18),
        ),
      ], today);

      expect(stats.bestWeekPoints, 70);
    });
  });
}
