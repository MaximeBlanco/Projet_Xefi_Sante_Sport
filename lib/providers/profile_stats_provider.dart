import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/domain/stats_period.dart';
import '../models/profile_stats.dart';
import 'session_provider.dart';
import 'weekly_health_provider.dart';

/// The whole history, which is what the member card, the badges and the
/// six-month chart describe. A badge earned last year is not un-earned by
/// looking at this week.
///
/// Shares todayProvider with the weekly goal so both agree on where the current
/// day sits, and so tests can pin it.
final profileStatsProvider = Provider<AsyncValue<ProfileStats>>((ref) {
  final today = ref.watch(todayProvider);
  return ref
      .watch(userSessionsProvider)
      .whenData((sessions) => ProfileStats.fromSessions(sessions, today));
});

final statsPeriodProvider = StateProvider<StatsPeriod>((ref) {
  return StatsPeriod.allTime;
});

/// The same figures over the period the user picked, for the totals panel.
///
/// Derived synchronously from the sessions the app already holds rather than
/// awaiting them again, so switching period re-totals what is in memory instead
/// of flashing a spinner over numbers that never left.
final periodProfileStatsProvider = Provider<AsyncValue<ProfileStats>>((ref) {
  final period = ref.watch(statsPeriodProvider);
  final today = ref.watch(todayProvider);
  return ref.watch(userSessionsProvider).whenData(
        (sessions) => ProfileStats.fromSessions(
          // The same day both times: letting the filter fall back to its own
          // DateTime.now() would let the window and the totals disagree.
          period.filter(sessions, now: today),
          today,
        ),
      );
});
