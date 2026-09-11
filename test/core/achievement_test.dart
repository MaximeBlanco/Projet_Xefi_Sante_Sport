import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/core/domain/achievement.dart';
import 'package:monapp/models/profile_stats.dart';
import 'package:monapp/models/session.dart';

import '../support/test_fixtures.dart';

final _today = DateTime(2026, 3, 20);

ProfileStats statsFrom(List<Session> sessions) =>
    ProfileStats.fromSessions(sessions, _today);

Session sessionOn(
  DateTime date, {
  String sportId = 'course',
  int durationMin = 30,
}) {
  return buildSession(
    id: '$sportId-${date.month}-${date.day}-$durationMin',
    sportId: sportId,
    durationMin: durationMin,
    points: durationMin,
    date: date,
    sport: buildSport(id: sportId, name: sportId),
  );
}

AchievementProgress progressOf(ProfileStats stats, String id) =>
    Achievements.evaluate(stats).firstWhere((e) => e.achievement.id == id);

void main() {
  group('the catalogue', () {
    test('gives every badge a unique id', () {
      final ids = Achievements.all.map((a) => a.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('asks for something on every badge', () {
      for (final achievement in Achievements.all) {
        expect(
          achievement.target,
          greaterThan(0),
          reason: '${achievement.id} would be earned by doing nothing',
        );
      }
    });

    test('scores every badge, earned or not', () {
      final scored = Achievements.evaluate(statsFrom(const []));
      expect(scored, hasLength(Achievements.all.length));
    });
  });

  group('a brand new account', () {
    test('has earned nothing', () {
      final stats = statsFrom(const []);

      expect(Achievements.earnedCount(stats), 0);
      expect(
        Achievements.evaluate(stats).every((entry) => !entry.isEarned),
        isTrue,
      );
    });

    test('still sees how far off the first badge is', () {
      final first = progressOf(statsFrom(const []), 'first-session');

      expect(first.value, 0);
      expect(first.remaining, 1);
      expect(first.progress, 0);
    });
  });

  group('earning', () {
    test('a single session takes the first badge', () {
      final stats = statsFrom([sessionOn(DateTime(2026, 3, 20))]);

      expect(progressOf(stats, 'first-session').isEarned, isTrue);
      expect(progressOf(stats, 'ten-sessions').isEarned, isFalse);
    });

    test('a run of days takes the streak badges it reaches', () {
      final stats = statsFrom([
        for (var day = 14; day <= 20; day++) sessionOn(DateTime(2026, 3, day)),
      ]);

      expect(progressOf(stats, 'three-day-streak').isEarned, isTrue);
      expect(progressOf(stats, 'seven-day-streak').isEarned, isTrue);
      expect(progressOf(stats, 'thirty-day-streak').isEarned, isFalse);
      expect(progressOf(stats, 'thirty-day-streak').value, 7);
    });

    test('different sports count once each, however often practised', () {
      final stats = statsFrom([
        sessionOn(DateTime(2026, 3, 18), sportId: 'course'),
        sessionOn(DateTime(2026, 3, 19), sportId: 'course'),
        sessionOn(DateTime(2026, 3, 20), sportId: 'velo'),
      ]);

      expect(progressOf(stats, 'three-sports').value, 2);
      expect(progressOf(stats, 'three-sports').isEarned, isFalse);
    });

    test('the longest session alone decides the endurance badges', () {
      final stats = statsFrom([
        sessionOn(DateTime(2026, 3, 19), durationMin: 20),
        sessionOn(DateTime(2026, 3, 20), durationMin: 75),
      ]);

      expect(progressOf(stats, 'one-hour-session').isEarned, isTrue);
      expect(progressOf(stats, 'two-hour-session').isEarned, isFalse);
      // Not the total: two half-hours are not an hour-long session.
      expect(progressOf(stats, 'one-hour-session').value, 75);
    });
  });

  group('ordering', () {
    test('puts what is earned first', () {
      final stats = statsFrom([sessionOn(DateTime(2026, 3, 20))]);
      final scored = Achievements.evaluate(stats);

      final firstLockedIndex = scored.indexWhere((entry) => !entry.isEarned);
      expect(
        scored.take(firstLockedIndex).every((entry) => entry.isEarned),
        isTrue,
      );
    });

    test('leads the locked ones with the closest to being earned', () {
      final stats = statsFrom([
        for (var day = 12; day <= 20; day++) sessionOn(DateTime(2026, 3, day)),
      ]);
      final locked = Achievements.evaluate(
        stats,
      ).where((entry) => !entry.isEarned).toList();

      for (var index = 1; index < locked.length; index++) {
        expect(
          locked[index - 1].progress,
          greaterThanOrEqualTo(locked[index].progress),
        );
      }
    });
  });
}
