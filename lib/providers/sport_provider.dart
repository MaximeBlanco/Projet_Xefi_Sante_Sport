import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_providers.dart';
import '../data/sport_repository.dart';
import '../models/sport.dart';

final sportRepositoryProvider = Provider<SportRepository>((ref) {
  return SportRepository(ref.watch(supabaseClientProvider));
});

final sportListProvider = FutureProvider<List<Sport>>((ref) {
  return ref.watch(sportRepositoryProvider).fetchSports();
});
