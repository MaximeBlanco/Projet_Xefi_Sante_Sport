import 'gps_point.dart';
import 'sport.dart';

class Session {
  const Session({
    required this.id,
    required this.userId,
    required this.sportId,
    required this.date,
    required this.durationMin,
    required this.points,
    required this.createdAt,
    this.caloriesBurned,
    this.distanceKm,
    this.elevationGainM,
    this.route,
    this.sport,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    final embeddedSport = json['sports'];
    return Session(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sportId: json['sport_id'] as String,
      date: DateTime.parse(json['date'] as String),
      durationMin: _parseNumber(json['duration_min'])?.toInt() ?? 0,
      points: _parseNumber(json['points'])?.toInt() ?? 0,
      caloriesBurned: _parseNumber(json['calories_burned'])?.toDouble(),
      distanceKm: _parseNumber(json['distance_km'])?.toDouble(),
      elevationGainM: _parseNumber(json['elevation_gain_m'])?.toDouble(),
      route: (json['route'] as List<dynamic>?)
          ?.map((point) => GpsPoint.fromJson(point as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      sport: embeddedSport is Map<String, dynamic>
          ? Sport.fromJson(embeddedSport)
          : null,
    );
  }

  final String id;
  final String userId;
  final String sportId;
  final DateTime date;
  final int durationMin;
  final int points;
  final double? caloriesBurned;
  final double? distanceKm;
  final double? elevationGainM;
  final List<GpsPoint>? route;
  final DateTime createdAt;
  final Sport? sport;
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
