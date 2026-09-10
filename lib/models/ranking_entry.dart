class RankingEntry {
  const RankingEntry({
    required this.userId,
    required this.name,
    required this.totalPoints,
    required this.totalDurationMin,
    required this.totalCaloriesBurned,
    required this.sessionCount,
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
    );
  }

  final String userId;
  final String name;
  final int totalPoints;
  final int totalDurationMin;
  final double totalCaloriesBurned;
  final int sessionCount;
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
