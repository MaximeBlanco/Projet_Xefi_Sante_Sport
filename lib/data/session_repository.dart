import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

import '../models/gps_point.dart';
import '../models/session.dart';
import '../models/venue.dart';

class SessionRepository {
  SessionRepository(this._client);

  final SupabaseClient _client;

  Future<List<Session>> fetchUserSessions(String userId) async {
    final rows = await _client
        .from('sessions')
        .select('*, sports(*)')
        .eq('user_id', userId)
        .order('date', ascending: false)
        .order('created_at', ascending: false);
    return rows.map(Session.fromJson).toList();
  }

  /// The points column is deliberately absent from the payload: a database
  /// trigger derives it from duration_min on insert.
  Future<void> createSession({
    required String userId,
    required String sportId,
    required DateTime date,
    required int durationMin,
    double? caloriesBurned,
    bool caloriesEstimated = false,
    List<GpsPoint>? route,
    double? distanceKm,
    double? elevationGainM,
    Venue? venue,
  }) {
    return _client.from('sessions').insert({
      'user_id': userId,
      'sport_id': sportId,
      'date': _formatAsPostgresDate(date),
      'duration_min': durationMin,
      'calories_burned': caloriesBurned,
      'calories_estimated': caloriesEstimated,
      'route': route?.map((point) => point.toJson()).toList(),
      'distance_km': distanceKm,
      'elevation_gain_m': elevationGainM,
      ...?venue?.toSessionColumns(),
    });
  }

  /// The row is matched on its id alone: the delete policy already restricts
  /// it to the caller's own sessions, and repeating the filter here would only
  /// hide a mismatch behind a silent no-op.
  Future<void> deleteSession(String sessionId) {
    return _client.from('sessions').delete().eq('id', sessionId);
  }

  String _formatAsPostgresDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
