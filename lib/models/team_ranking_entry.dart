import 'package:flutter/material.dart';

/// One row of the team leaderboard, as the `rankings_teams` view returns it.
///
/// The points here are not the sum of the members' points: only sessions in a
/// collective sport count, so a team of keen solo runners scores zero until
/// somebody plays a match. That is deliberate, and the screen says so.
class TeamRankingEntry {
  const TeamRankingEntry({
    required this.teamId,
    required this.name,
    required this.colorValue,
    required this.memberCount,
    required this.totalPoints,
    required this.totalDurationMin,
    required this.sessionCount,
    this.currentRank,
    this.previousRank,
    this.imageUrl,
  });

  factory TeamRankingEntry.fromJson(Map<String, dynamic> json) {
    return TeamRankingEntry(
      teamId: json['team_id'] as String,
      name: json['name'] as String,
      colorValue: _parseNumber(json['color_value'])?.toInt() ?? 0xFFE10600,
      memberCount: _parseNumber(json['member_count'])?.toInt() ?? 0,
      totalPoints: _parseNumber(json['total_points'])?.toInt() ?? 0,
      totalDurationMin: _parseNumber(json['total_duration_min'])?.toInt() ?? 0,
      sessionCount: _parseNumber(json['session_count'])?.toInt() ?? 0,
      currentRank: _parseNumber(json['current_rank'])?.toInt(),
      previousRank: _parseNumber(json['previous_rank'])?.toInt(),
      imageUrl: json['image_url'] as String?,
    );
  }

  final String teamId;
  final String name;
  final int colorValue;
  final int memberCount;
  final int totalPoints;
  final int totalDurationMin;
  final int sessionCount;

  /// The team photograph, or null while it has none and the colour stands in.
  final String? imageUrl;

  /// Position in the team leaderboard, ties sharing a place.
  final int? currentRank;

  /// Position as of the start of this week, recomputed from session dates
  /// rather than read from a snapshot nobody stores.
  final int? previousRank;

  Color get colour => Color(colorValue);

  String get memberLabel =>
      memberCount == 1 ? '1 membre' : '$memberCount membres';

  /// Places gained since Monday: positive is a climb, negative a fall, null
  /// while either position is unknown.
  int? get rankChange {
    final now = currentRank;
    final before = previousRank;
    if (now == null || before == null) return null;
    return before - now;
  }
}

num? _parseNumber(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}
