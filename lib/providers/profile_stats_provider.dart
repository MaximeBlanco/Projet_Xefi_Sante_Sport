import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile_stats.dart';
import 'session_provider.dart';

final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final sessions = await ref.watch(userSessionsProvider.future);
  return ProfileStats.fromSessions(sessions);
});
