import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_providers.dart';
import '../data/calories_service.dart';
import '../data/session_repository.dart';
import '../models/session.dart';
import 'auth_provider.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(supabaseClientProvider));
});

final caloriesServiceProvider = Provider<CaloriesService>((ref) {
  return CaloriesService(ref.watch(supabaseClientProvider));
});

final userSessionsProvider = FutureProvider<List<Session>>((ref) {
  final signedInUser = ref.watch(currentUserProvider);
  if (signedInUser == null) {
    return Future<List<Session>>.value(const <Session>[]);
  }
  return ref
      .watch(sessionRepositoryProvider)
      .fetchUserSessions(signedInUser.id);
});
