import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/weekly_health.dart';

import '../support/test_fixtures.dart';

// Thursday 10 September 2026. Its week runs Monday the 7th to Sunday the 13th.
final thursday = DateTime(2026, 9, 10);

void main() {
  group('WeeklyHealth.startOfWeekFor', () {
    test('starts the week on Monday', () {
      expect(WeeklyHealth.startOfWeekFor(thursday), DateTime(2026, 9, 7));
    });

    test('keeps Monday itself as the start', () {
      expect(
        WeeklyHealth.startOfWeekFor(DateTime(2026, 9, 7)),
        DateTime(2026, 9, 7),
      );
    });

    test('puts Sunday at the end of its own week, not the start of the next',
        () {
      expect(
        WeeklyHealth.startOfWeekFor(DateTime(2026, 9, 13)),
        DateTime(2026, 9, 7),
      );
    });

    test('drops the time so a late session still lands on its day', () {
      expect(
        WeeklyHealth.startOfWeekFor(DateTime(2026, 9, 10, 23, 45)),
        DateTime(2026, 9, 7),
      );
    });
  });

  group('WeeklyHealth.fromSessions', () {
    test('counts only what falls inside the current week', () {
      final health = WeeklyHealth.fromSessions([
        buildSession(id: 'a', date: DateTime(2026, 9, 8), durationMin: 40),
        // Sunday before the week started.
        buildSession(id: 'b', date: DateTime(2026, 9, 6), durationMin: 90),
        // Monday of the following week.
        buildSession(id: 'c', date: DateTime(2026, 9, 14), durationMin: 90),
      ], thursday);

      expect(health.activeMinutes, 40);
    });

    test('includes both boundary days of the week', () {
      final health = WeeklyHealth.fromSessions([
        buildSession(id: 'a', date: DateTime(2026, 9, 7), durationMin: 30),
        buildSession(id: 'b', date: DateTime(2026, 9, 13), durationMin: 30),
      ], thursday);

      expect(health.activeMinutes, 60);
      expect(health.activeDayCount, 2);
    });

    test('adds up several sessions on the same day as one active day', () {
      final health = WeeklyHealth.fromSessions([
        buildSession(id: 'a', date: DateTime(2026, 9, 8), durationMin: 30),
        buildSession(id: 'b', date: DateTime(2026, 9, 8), durationMin: 45),
      ], thursday);

      expect(health.activeMinutes, 75);
      expect(health.activeDayCount, 1);
    });

    test('reports an empty week without failing', () {
      final health = WeeklyHealth.fromSessions([], thursday);

      expect(health.activeMinutes, 0);
      expect(health.progress, 0);
      expect(health.activeDayCount, 0);
      expect(health.remainingMinutes, WeeklyHealth.goalMinutes);
      expect(health.isGoalReached, isFalse);
    });
  });

  group('WeeklyHealth goal', () {
    test('caps progress once the goal is passed', () {
      final health = WeeklyHealth.fromSessions([
        buildSession(id: 'a', date: DateTime(2026, 9, 8), durationMin: 400),
      ], thursday);

      expect(health.progress, 1);
      expect(health.isGoalReached, isTrue);
      expect(health.remainingMinutes, 0);
    });

    test('separates reaching the goal from spreading it out', () {
      final inOneGo = WeeklyHealth.fromSessions([
        buildSession(id: 'a', date: DateTime(2026, 9, 8), durationMin: 160),
      ], thursday);
      expect(inOneGo.isGoalReached, isTrue);
      expect(inOneGo.isSpreadAcrossWeek, isFalse);

      final spread = WeeklyHealth.fromSessions([
        buildSession(id: 'a', date: DateTime(2026, 9, 7), durationMin: 55),
        buildSession(id: 'b', date: DateTime(2026, 9, 9), durationMin: 55),
        buildSession(id: 'c', date: DateTime(2026, 9, 11), durationMin: 55),
      ], thursday);
      expect(spread.isGoalReached, isTrue);
      expect(spread.isSpreadAcrossWeek, isTrue);
    });

    test('places each session on the right weekday, Monday first', () {
      final health = WeeklyHealth.fromSessions([
        buildSession(id: 'a', date: DateTime(2026, 9, 7), durationMin: 20),
        buildSession(id: 'b', date: DateTime(2026, 9, 13), durationMin: 35),
      ], thursday);

      expect(health.minutesPerWeekday.first, 20);
      expect(health.minutesPerWeekday.last, 35);
      expect(health.isDayActive(0), isTrue);
      expect(health.isDayActive(1), isFalse);
      expect(health.isDayActive(6), isTrue);
    });
  });
}
