import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/team.dart';
import '../models/team_join_request.dart';

class TeamRepository {
  TeamRepository(this._client);

  final SupabaseClient _client;

  Future<List<Team>> fetchTeams() async {
    final rows = await _client.from('teams').select().order('name');
    return rows.map(Team.fromJson).toList();
  }

  /// Creates a team, joins it, and records its owner.
  ///
  /// The creator is the owner, and so the person who approves everyone else.
  /// They are also put straight in: the profile policy lets somebody set their
  /// team to one they created, without asking themselves for permission.
  Future<Team> createTeam({
    required String userId,
    required String name,
    required int colorValue,
  }) async {
    final row = await _client
        .from('teams')
        .insert({
          'name': name.trim(),
          'color_value': Team.toDatabaseValue(colorValue),
          'created_by': userId,
        })
        .select()
        .single();
    return Team.fromJson(row);
  }

  /// Leaves the current team. Nobody needs permission to walk out.
  Future<void> leaveTeam({required String userId}) {
    return _client.from('profiles').update({'team_id': null}).eq('id', userId);
  }

  /// Asks to join, which the team's owner then accepts or declines.
  ///
  /// Upserted on the pair so asking twice replaces the earlier ask rather than
  /// failing on the unique constraint, which is what re-applying after a
  /// refusal has to do.
  Future<void> requestToJoin({
    required String userId,
    required String teamId,
  }) {
    return _client.from('team_join_requests').upsert({
      'team_id': teamId,
      'user_id': userId,
      'status': 'pending',
      'decided_at': null,
    }, onConflict: 'team_id,user_id');
  }

  Future<void> withdrawRequest({required String requestId}) {
    return _client.from('team_join_requests').delete().eq('id', requestId);
  }

  /// Every request the signed-in user has made. RLS keeps this to their own.
  Future<List<TeamJoinRequest>> fetchMyRequests({required String userId}) async {
    final rows = await _client
        .from('team_join_requests')
        .select('*, team:teams!team_id(name)')
        .eq('user_id', userId);
    return rows.map(TeamJoinRequest.fromJson).toList();
  }

  /// The requests waiting on the signed-in user, as the owner of a team.
  ///
  /// No filter on the team is needed: the select policy already limits this to
  /// teams they own, and adding one here would duplicate the rule in a second
  /// place that could drift from it.
  Future<List<TeamJoinRequest>> fetchRequestsToDecide() async {
    final rows = await _client
        .from('team_join_requests')
        .select('*, applicant:profiles!user_id(name, avatar_url)')
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return rows.map(TeamJoinRequest.fromJson).toList();
  }

  /// Accepting is what puts the applicant in the team; the database trigger
  /// does that, because the owner may not write another person's profile.
  Future<void> decide({
    required String requestId,
    required bool accepted,
  }) {
    return _client
        .from('team_join_requests')
        .update({'status': accepted ? 'accepted' : 'declined'})
        .eq('id', requestId);
  }
}
