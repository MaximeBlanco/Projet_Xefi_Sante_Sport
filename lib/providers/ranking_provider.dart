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

/// The team leaderboard. Separate from the individual one on purpose: it is
/// scored only on collective sports, and most people will look at one or the
/// other, not both at once.
final teamRankingProvider = FutureProvider<List<TeamRankingEntry>>((ref) {
  return ref.watch(rankingRepositoryProvider).fetchTeamRanking();
});
