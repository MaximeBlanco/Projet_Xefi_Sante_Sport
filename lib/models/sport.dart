class Sport {
  const Sport({
    required this.id,
    required this.name,
    required this.emoji,
    required this.pointsPerUnit,
    required this.isGpsTrackable,
    required this.met,
    this.wgerId,
    this.externalActivityName,
  });

  factory Sport.fromJson(Map<String, dynamic> json) {
    return Sport(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      pointsPerUnit: _parseNumber(json['points_per_unit'])?.toInt() ?? 1,
      wgerId: _parseNumber(json['wger_id'])?.toInt(),
      isGpsTrackable: json['is_gps_trackable'] as bool? ?? false,
      externalActivityName: json['external_activity_name'] as String?,
      met: _parseNumber(json['met'])?.toDouble() ?? defaultMet,
    );
  }

  /// Mirrors the database default, so a sport inserted without a MET still
  /// produces a plausible estimate instead of no calories at all.
  static const double defaultMet = 5;

  final String id;
  final String name;
  final String emoji;
  final int pointsPerUnit;
  final int? wgerId;
  final bool isGpsTrackable;
  final String? externalActivityName;
  final double met;
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
