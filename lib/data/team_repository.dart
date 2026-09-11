import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/team.dart';

class TeamRepository {
  TeamRepository(this._client);

  final SupabaseClient _client;

  Future<List<Team>> fetchTeams() async {
    final rows = await _client.from('teams').select().order('name');
    return rows.map(Team.fromJson).toList();
  }

  /// Creates a team and returns it.
  ///
  /// The unique index on the lowered name is what stops two teams called the
  /// same thing, so a clash surfaces as a database error rather than as two
  /// indistinguishable rows in the leaderboard.
  Future<Team> createTeam({required String name, required int colorValue}) async {
    final row = await _client
        .from('teams')
        .insert({
          'name': name.trim(),
          'color_value': Team.toDatabaseValue(colorValue),
        })
        .select()
        .single();
    return Team.fromJson(row);
  }

  /// Joins [teamId], or leaves the current team when it is null.
  Future<void> setTeam({required String userId, required String? teamId}) {
    return _client.from('profiles').update({'team_id': teamId}).eq('id', userId);
  }
}
