import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_event.dart';

class EventRepository {
  EventRepository(this._client);

  /// Enough to fill the home carousel without pulling a year of fixtures.
  static const _limit = 10;

  final SupabaseClient _client;

  Future<List<AppEvent>> fetchUpcoming() async {
    final rows = await _client
        .from('upcoming_events')
        .select()
        .order('starts_at')
        .limit(_limit);
    return rows.map(AppEvent.fromJson).toList();
  }
}
