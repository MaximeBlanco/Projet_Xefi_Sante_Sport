import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile_stats.dart';
import 'session_provider.dart';
import 'weekly_health_provider.dart';

final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final sessions = await ref.watch(userSessionsProvider.future);
  // Shares todayProvider with the weekly goal so both agree on where the
  // current day sits, and so tests can pin it.
  return ProfileStats.fromSessions(sessions, ref.watch(todayProvider));
});
