import 'route_point.dart';

class SportSession {
  const SportSession({
    required this.id,
    required this.sportName,
    required this.emoji,
    required this.date,
    required this.durationMin,
    this.caloriesBurned,
    this.distanceKm,
    this.route,
  });

  final String id;
  final String sportName;
  final String emoji;
  final DateTime date;
  final int durationMin;
  final double? caloriesBurned;
  final double? distanceKm;
  final List<RoutePoint>? route;

  SportSession copyWith({double? caloriesBurned}) {
    return SportSession(
      id: id,
      sportName: sportName,
      emoji: emoji,
      date: date,
      durationMin: durationMin,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      distanceKm: distanceKm,
      route: route,
    );
  }

  factory SportSession.fromMap(Map<dynamic, dynamic> map) {
    return SportSession(
      id: map['id'] as String,
      sportName: map['sportName'] as String,
      emoji: map['emoji'] as String,
      date: DateTime.parse(map['date'] as String),
      durationMin: map['durationMin'] as int,
      caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble(),
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      route: (map['route'] as List<dynamic>?)
          ?.map((point) => RoutePoint.fromMap(point as Map))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sportName': sportName,
      'emoji': emoji,
      'date': date.toIso8601String(),
      'durationMin': durationMin,
      'caloriesBurned': caloriesBurned,
      'distanceKm': distanceKm,
      'route': route?.map((point) => point.toMap()).toList(),
    };
  }
}
