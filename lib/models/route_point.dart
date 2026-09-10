class RoutePoint {
  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestampMs,
  });

  factory RoutePoint.fromMap(Map<dynamic, dynamic> map) {
    return RoutePoint(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestampMs: map['timestampMs'] as int,
    );
  }

  final double latitude;
  final double longitude;
  final int timestampMs;

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestampMs': timestampMs,
    };
  }
}
