import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/core/domain/stats_period.dart';

import '../support/test_fixtures.dart';

void main() {
  // A Wednesday, so the Monday of its week is the 9th.
  final wednesday = DateTime(2026, 9, 16, 14, 30);

  group('StatsPeriod.week', () {
    test('starts on the Monday of the current week', () {
      expect(StatsPeriod.week.startOf(wednesday), DateTime(2026, 9, 14));
    });

    test('starts on the same day when today is a Monday', () {
      final monday = DateTime(2026, 9, 14, 8);
      expect(StatsPeriod.week.startOf(monday), DateTime(2026, 9, 14));
    });

    test('keeps a session from earlier in the week', () {
      expect(
        StatsPeriod.week.includes(DateTime(2026, 9, 14), wednesday),
        isTrue,
      );
    });

    test('drops a session from the week before', () {
      expect(
        StatsPeriod.week.includes(DateTime(2026, 9, 13), wednesday),
        isFalse,
      );
    });
  });

  group('StatsPeriod.month', () {
    test('starts on the first of the current month', () {
      expect(StatsPeriod.month.startOf(wednesday), DateTime(2026, 9, 1));
    });

    test('keeps a session from earlier in the month', () {
      expect(
        StatsPeriod.month.includes(DateTime(2026, 9, 1), wednesday),
        isTrue,
      );
    });

    test('drops a session from the month before', () {
      expect(
        StatsPeriod.month.includes(DateTime(2026, 8, 31), wednesday),
        isFalse,
      );
    });
  });

  group('StatsPeriod.allTime', () {
    test('has no start', () {
      expect(StatsPeriod.allTime.startOf(wednesday), isNull);
    });

    test('keeps even a very old session', () {
      expect(
        StatsPeriod.allTime.includes(DateTime(2020, 1, 1), wednesday),
        isTrue,
      );
    });
  });

  group('StatsPeriod.filter', () {
    final sessions = [
      buildSession(id: 'today', date: DateTime(2026, 9, 16)),
      buildSession(id: 'this-week', date: DateTime(2026, 9, 14)),
      buildSession(id: 'this-month', date: DateTime(2026, 9, 2)),
      buildSession(id: 'last-month', date: DateTime(2026, 8, 20)),
    ];

    test('keeps only the sessions of the current week', () {
      final kept = StatsPeriod.week.filter(sessions, now: wednesday);

      expect(kept.map((session) => session.id), ['today', 'this-week']);
    });

    test('keeps only the sessions of the current month', () {
      final kept = StatsPeriod.month.filter(sessions, now: wednesday);

      expect(
        kept.map((session) => session.id),
        ['today', 'this-week', 'this-month'],
      );
    });

    test('keeps everything over all time', () {
      final kept = StatsPeriod.allTime.filter(sessions, now: wednesday);

      expect(kept, hasLength(4));
    });
  });
}
