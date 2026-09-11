import 'package:characters/characters.dart';

class RankingEntry {
  const RankingEntry({
    required this.userId,
    required this.name,
    required this.totalPoints,
    required this.totalDurationMin,
    required this.totalCaloriesBurned,
    required this.sessionCount,
    this.avatarUrl,
    this.currentRank,
    this.previousRank,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      totalPoints: _parseNumber(json['total_points'])?.toInt() ?? 0,
      totalDurationMin: _parseNumber(json['total_duration_min'])?.toInt() ?? 0,
      totalCaloriesBurned:
          _parseNumber(json['total_calories_burned'])?.toDouble() ?? 0,
      sessionCount: _parseNumber(json['session_count'])?.toInt() ?? 0,
      avatarUrl: json['avatar_url'] as String?,
      currentRank: _parseNumber(json['current_rank'])?.toInt(),
      previousRank: _parseNumber(json['previous_rank'])?.toInt(),
    );
  }

  final String userId;
  final String name;
  final int totalPoints;
  final int totalDurationMin;
  final double totalCaloriesBurned;
  final int sessionCount;
  final String? avatarUrl;

  /// Position in the leaderboard, ties sharing a place.
  final int? currentRank;

  /// Position as of the start of this week, recomputed from session dates
  /// rather than read from a snapshot nobody stores.
  final int? previousRank;

  /// Places gained since Monday: positive is a climb, negative a fall, null
  /// while either position is unknown.
  int? get rankChange {
    final now = currentRank;
    final before = previousRank;
    if (now == null || before == null) return null;
    return before - now;
  }

  /// The first initials, for an avatar with no picture.
  String get initials {
    final words = name.trim().split(RegExp(r'[\s@._-]+'))
      ..removeWhere((word) => word.isEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.characters.take(2).toString().toUpperCase();
    }
    return (words.first.characters.first + words[1].characters.first)
        .toUpperCase();
  }

  /// The name as the podium shows it, where there is only room for one word.
  String get shortName => name.trim().split(RegExp(r'[\s@]')).first;
}

/// PostgREST returns a numeric or bigint column either as a JSON number or as
/// a string depending on the column type, so numbers are never cast directly.
num? _parseNumber(Object? value) {
  if (value is num) {
    return value;
  }
  if (value is String) {
    return num.tryParse(value);
  }
  return null;
}
