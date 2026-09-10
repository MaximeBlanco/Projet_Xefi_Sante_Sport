import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sport.dart';

class SportRepository {
  SportRepository(this._client);

  final SupabaseClient _client;

  Future<List<Sport>> fetchSports() async {
    final rows = await _client
        .from('sports')
        .select()
        .order('name', ascending: true);
    return rows.map(Sport.fromJson).toList();
  }
}
