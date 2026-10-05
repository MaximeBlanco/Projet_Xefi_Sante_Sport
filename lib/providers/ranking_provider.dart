import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_providers.dart';
import '../data/ranking_repository.dart';
import '../models/ranking_entry.dart';
import '../models/team_ranking_entry.dart';

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return RankingRepository(ref.watch(supabaseClientProvider));
});

final globalRankingProvider = FutureProvider<List<RankingEntry>>((ref) {
  return ref.watch(rankingRepositoryProvider).fetchGlobalRanking();
});

/// The leaderboard of the signed-in member and their accepted contacts.
///
/// Kept apart from [globalRankingProvider] rather than filtered out of it: the
/// ranks, and the movement since Monday, are computed inside the circle, so
/// being second of four reads as second of four and not as ninth of ten.
final contactsRankingProvider = FutureProvider<List<RankingEntry>>((ref) {
  return ref.watch(rankingRepositoryProvider).fetchContactsRanking();
});

/// The team leaderboard. Separate from the individual one on purpose: it is
/// scored only on collective sports, and most people will look at one or the
/// other, not both at once.
final teamRankingProvider = FutureProvider<List<TeamRankingEntry>>((ref) {
  return ref.watch(rankingRepositoryProvider).fetchTeamRanking();
});
