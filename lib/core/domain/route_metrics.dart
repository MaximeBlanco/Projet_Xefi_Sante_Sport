import 'dart:math' as math;

import '../../models/gps_point.dart';

/// Distance and elevation derived from a recorded GPS route.
///
/// The database stores the raw points, so these numbers are computed rather
/// than trusted from the device: a phone reports an instant speed and a running
/// odometer that both drift, while the trace itself is what the user saw.
abstract final class RouteMetrics {
  static const double earthRadiusMeters = 6371000;
  static const double metersPerKilometer = 1000;

  /// Fixes below this distance apart are treated as the device standing still.
  /// Consumer GPS jitters by a few metres even on a phone left on a table, and
  /// summing that noise over a long session invents hundreds of metres.
  static const double minimumMoveMeters = 5;

  /// Same idea vertically, where the noise is worse: altitude from GPS is
  /// roughly half as precise as the horizontal fix.
  static const double minimumClimbMeters = 3;

  static double distanceKm(List<GpsPoint> route) {
    var meters = 0.0;
    for (var i = 1; i < route.length; i++) {
      final step = _haversineMeters(route[i - 1], route[i]);
      if (step >= minimumMoveMeters) {
        meters += step;
      }
    }
    return meters / metersPerKilometer;
  }

  /// Only the climbs count, the way a running watch reports elevation gain:
  /// descending is not undoing the effort of going up.
  static double elevationGainM(List<GpsPoint> route) {
    var gain = 0.0;
    for (var i = 1; i < route.length; i++) {
      final climb = route[i].altitude - route[i - 1].altitude;
      if (climb >= minimumClimbMeters) {
        gain += climb;
      }
    }
    return gain;
  }

  /// Great-circle distance between two coordinates. Public because venue
  /// search needs the same maths on plain latitudes and longitudes, and two
  /// haversines in one codebase is one too many.
  static double metersBetween({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final deltaLat = _toRadians(toLat - fromLat);
    final deltaLng = _toRadians(toLng - fromLng);
    final fromLatRad = _toRadians(fromLat);
    final toLatRad = _toRadians(toLat);

    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.pow(math.sin(deltaLng / 2), 2) *
            math.cos(fromLatRad) *
            math.cos(toLatRad);
    return 2 * earthRadiusMeters * math.asin(math.min(1, math.sqrt(a)));
  }

  static double _haversineMeters(GpsPoint from, GpsPoint to) {
    return metersBetween(
      fromLat: from.lat,
      fromLng: from.lng,
      toLat: to.lat,
      toLng: to.lng,
    );
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
