import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_providers.dart';
import '../data/profile_repository.dart';
import '../models/profile.dart';
import 'auth_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final currentProfileProvider = FutureProvider<Profile?>((ref) {
  final signedInUser = ref.watch(currentUserProvider);
  if (signedInUser == null) {
    return Future<Profile?>.value(null);
  }
  return ref.watch(profileRepositoryProvider).fetchProfile(signedInUser.id);
});
