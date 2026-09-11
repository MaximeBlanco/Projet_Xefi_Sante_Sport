import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/home_summary.dart';
import '../models/ranking_entry.dart';
import 'auth_provider.dart';
import 'profile_provider.dart';
import 'ranking_provider.dart';
import 'session_provider.dart';

/// Totals come from the ranking view rather than from summing the session list
/// client-side: the view is what the leaderboard shows, so the home screen and
/// the ranking screen can never disagree about the same user's score.
final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  final signedInUser = ref.watch(currentUserProvider);
  final sessions = await ref.watch(userSessionsProvider.future);
  final ranking = await ref.watch(globalRankingProvider.future);
  final profile = await ref.watch(currentProfileProvider.future);

  final position = _positionOf(signedInUser?.id, ranking);
  final entry = position == null ? null : ranking[position - 1];

  return HomeSummary(
    displayName: profile?.name ?? entry?.name ?? 'Athlète',
    totalPoints: entry?.totalPoints ?? 0,
    sessionCount: entry?.sessionCount ?? sessions.length,
    totalDurationMin: entry?.totalDurationMin ?? 0,
    totalCaloriesBurned: entry?.totalCaloriesBurned ?? 0,
    participantCount: ranking.length,
    rank: position,
    lastSession: sessions.isEmpty ? null : sessions.first,
  );
});

/// One-based, to match how the ranking screen numbers its rows.
int? _positionOf(String? userId, List<RankingEntry> ranking) {
  if (userId == null) return null;
  final index = ranking.indexWhere((entry) => entry.userId == userId);
  return index == -1 ? null : index + 1;
}

/// Reloads every source the home screen reads, for pull-to-refresh.
Future<void> refreshHomeSummary(WidgetRef ref) async {
  ref.invalidate(userSessionsProvider);
  ref.invalidate(globalRankingProvider);
  ref.invalidate(currentProfileProvider);
  await ref.read(homeSummaryProvider.future);
}
