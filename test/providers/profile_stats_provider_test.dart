import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/core/domain/stats_period.dart';
import 'package:monapp/models/session.dart';
import 'package:monapp/providers/profile_stats_provider.dart';
import 'package:monapp/providers/session_provider.dart';
import 'package:monapp/providers/weekly_health_provider.dart';

import '../support/test_fixtures.dart';

// A Friday, so the week it belongs to opens on Monday the 16th.
final _today = DateTime(2026, 3, 20);

final _sessions = <Session>[
  buildSession(
    id: 'today',
    sportId: 'course',
    durationMin: 45,
    points: 45,
    date: DateTime(2026, 3, 20),
  ),
  buildSession(
    id: 'earlier-this-month',
    sportId: 'velo',
    durationMin: 30,
    points: 30,
    date: DateTime(2026, 3, 4),
  ),
  buildSession(
    id: 'last-month',
    sportId: 'natation',
    durationMin: 60,
    points: 60,
    date: DateTime(2026, 2, 10),
  ),
];

ProviderContainer buildContainer() {
  final container = ProviderContainer(
    overrides: [
      todayProvider.overrideWithValue(_today),
      userSessionsProvider.overrideWith((ref) async => _sessions),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('periodProfileStatsProvider', () {
    test('starts on the whole history', () async {
      final container = buildContainer();
      await container.read(userSessionsProvider.future);

      expect(container.read(statsPeriodProvider), StatsPeriod.allTime);

      final stats = container.read(periodProfileStatsProvider).requireValue;
      expect(stats.sessionCount, 3);
      expect(stats.totalDurationMin, 135);
      expect(stats.totalPoints, 135);
    });

    test('keeps only the sessions since Monday for the week', () async {
      final container = buildContainer();
      await container.read(userSessionsProvider.future);

      container.read(statsPeriodProvider.notifier).state = StatsPeriod.week;

      final stats = container.read(periodProfileStatsProvider).requireValue;
      expect(stats.sessionCount, 1);
      expect(stats.totalDurationMin, 45);
    });

    test('keeps the calendar month, not a rolling thirty days', () async {
      final container = buildContainer();
      await container.read(userSessionsProvider.future);

      container.read(statsPeriodProvider.notifier).state = StatsPeriod.month;

      final stats = container.read(periodProfileStatsProvider).requireValue;
      // The 4th and the 20th, but not the 10th of February.
      expect(stats.sessionCount, 2);
      expect(stats.totalDurationMin, 75);
    });

    // The badges and the member card read the whole history, so narrowing the
    // totals to a week must not un-earn anything.
    test('leaves the all-time statistics untouched', () async {
      final container = buildContainer();
      await container.read(userSessionsProvider.future);

      container.read(statsPeriodProvider.notifier).state = StatsPeriod.week;

      expect(container.read(profileStatsProvider).requireValue.sessionCount, 3);
    });
  });
}
