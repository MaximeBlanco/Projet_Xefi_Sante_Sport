import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weekly_health.dart';
import 'session_provider.dart';

/// Overridden in tests so "this week" does not move with the calendar.
final todayProvider = Provider<DateTime>((ref) => DateTime.now());

final weeklyHealthProvider = FutureProvider<WeeklyHealth>((ref) async {
  final sessions = await ref.watch(userSessionsProvider.future);
  return WeeklyHealth.fromSessions(sessions, ref.watch(todayProvider));
});
