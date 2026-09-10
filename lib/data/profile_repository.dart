import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Profile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return Profile.fromJson(row);
  }

  Future<void> updateWeight({
    required String userId,
    required double weightKg,
  }) {
    return _client
        .from('profiles')
        .update({'weight_kg': weightKg})
        .eq('id', userId);
  }
}
