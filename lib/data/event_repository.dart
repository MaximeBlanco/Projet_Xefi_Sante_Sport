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
        // Ascending has to be said: the client's order() defaults to
        // descending, which put the furthest-off event first and the next one
        // last, the wrong way round for a list of what is coming up.
        .order('starts_at', ascending: true)
        .limit(_limit);
    return rows.map(AppEvent.fromJson).toList();
  }
}
