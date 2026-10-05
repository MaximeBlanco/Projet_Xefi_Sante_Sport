import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ranking_entry.dart';
import '../models/team_ranking_entry.dart';

class RankingRepository {
  RankingRepository(this._client);

  final SupabaseClient _client;

  Future<List<RankingEntry>> fetchGlobalRanking() async {
    final rows = await _client
        .from('rankings_global')
        .select()
        .order('total_points', ascending: false);
    return rows.map(RankingEntry.fromJson).toList();
  }

  /// The same figures as the global leaderboard, narrowed to the caller and
  /// their accepted contacts.
  ///
  /// The view takes no argument: it reads `auth.uid()` itself, so the circle it
  /// returns cannot be widened by asking it differently.
  Future<List<RankingEntry>> fetchContactsRanking() async {
    final rows = await _client
        .from('rankings_contacts')
        .select()
        .order('total_points', ascending: false);
    return rows.map(RankingEntry.fromJson).toList();
  }

  /// The team leaderboard, scored on collective sports only.
  Future<List<TeamRankingEntry>> fetchTeamRanking() async {
    final rows = await _client
        .from('rankings_teams')
        .select()
        .order('total_points', ascending: false);
    return rows.map(TeamRankingEntry.fromJson).toList();
  }
}
