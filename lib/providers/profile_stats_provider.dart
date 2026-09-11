import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/domain/stats_period.dart';
import '../models/profile_stats.dart';
import 'session_provider.dart';

final statsPeriodProvider = StateProvider<StatsPeriod>((ref) {
  return StatsPeriod.allTime;
});

/// Derived synchronously from the sessions the app already holds rather than
/// awaiting them again, so switching period re-totals what is in memory instead
/// of flashing a spinner over numbers that never left.
final profileStatsProvider = Provider<AsyncValue<ProfileStats>>((ref) {
  final period = ref.watch(statsPeriodProvider);
  return ref.watch(userSessionsProvider).whenData(
        (sessions) => ProfileStats.fromSessions(period.filter(sessions)),
      );
});
