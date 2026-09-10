import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_providers.dart';
import '../data/ranking_repository.dart';
import '../models/ranking_entry.dart';

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return RankingRepository(ref.watch(supabaseClientProvider));
});

final globalRankingProvider = FutureProvider<List<RankingEntry>>((ref) {
  return ref.watch(rankingRepositoryProvider).fetchGlobalRanking();
});
