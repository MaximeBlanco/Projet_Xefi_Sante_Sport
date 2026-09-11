import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/core/domain/route_metrics.dart';
import 'package:monapp/models/gps_point.dart';

GpsPoint point(double lat, double lng, {double altitude = 100}) {
  return GpsPoint(lat: lat, lng: lng, altitude: altitude, timestampMs: 0);
}

void main() {
  group('RouteMetrics.distanceKm', () {
    test('is zero for a route that never started', () {
      expect(RouteMetrics.distanceKm(const []), 0);
      expect(RouteMetrics.distanceKm([point(45.75, 4.85)]), 0);
    });

    // One degree of latitude is ~111.2 km everywhere, which makes a north-south
    // leg the one segment whose length can be asserted without a map.
    test('measures a known north-south leg', () {
      final distance = RouteMetrics.distanceKm([
        point(45.750, 4.850),
        point(45.759, 4.850),
      ]);

      expect(distance, closeTo(1.0, 0.01));
    });

    test('adds up the legs of a multi-point route', () {
      final distance = RouteMetrics.distanceKm([
        point(45.750, 4.850),
        point(45.759, 4.850),
        point(45.768, 4.850),
      ]);

      expect(distance, closeTo(2.0, 0.02));
    });

    test('ignores the jitter of a device standing still', () {
      // Roughly a metre apart, well under what a consumer GPS can resolve.
      final distance = RouteMetrics.distanceKm([
        point(45.750000, 4.850000),
        point(45.750009, 4.850000),
        point(45.750000, 4.850000),
        point(45.750009, 4.850000),
      ]);

      expect(distance, 0);
    });
  });

  group('RouteMetrics.elevationGainM', () {
    test('sums the climbs and ignores the descents', () {
      final gain = RouteMetrics.elevationGainM([
        point(45.750, 4.850, altitude: 100),
        point(45.751, 4.850, altitude: 150),
        point(45.752, 4.850, altitude: 120),
        point(45.753, 4.850, altitude: 170),
      ]);

      expect(gain, closeTo(100, 0.001));
    });

    test('is zero on a flat route', () {
      final gain = RouteMetrics.elevationGainM([
        point(45.750, 4.850, altitude: 100),
        point(45.751, 4.850, altitude: 100),
      ]);

      expect(gain, 0);
    });

    test('ignores altitude noise below the GPS resolution', () {
      final gain = RouteMetrics.elevationGainM([
        point(45.750, 4.850, altitude: 100),
        point(45.751, 4.850, altitude: 101),
        point(45.752, 4.850, altitude: 100),
        point(45.753, 4.850, altitude: 101.5),
      ]);

      expect(gain, 0);
    });
  });
}
