class GpsPoint {
  const GpsPoint({
    required this.lat,
    required this.lng,
    required this.altitude,
    required this.timestampMs,
  });

  factory GpsPoint.fromJson(Map<String, dynamic> json) {
    return GpsPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      altitude: (json['altitude'] as num).toDouble(),
      timestampMs: json['timestampMs'] as int,
    );
  }

  final double lat;
  final double lng;
  final double altitude;
  final int timestampMs;

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'altitude': altitude,
      'timestampMs': timestampMs,
    };
  }
}
