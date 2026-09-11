import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/gps_point.dart';

/// Raised when tracking cannot start. The message is written for the user, so
/// the screen shows it as-is instead of inventing its own wording.
class LocationUnavailableException implements Exception {
  const LocationUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Wraps geolocator so the rest of the app only ever sees [GpsPoint].
class LocationTracker {
  const LocationTracker();

  /// Sampling every 5 metres rather than on a timer: a runner stopped at a red
  /// light should not pile up hundreds of identical points.
  static const int _distanceFilterMeters = 5;

  /// Android reads the GPS hardware directly instead of going through the fused
  /// provider of Play Services. Fused is the better default indoors, but this
  /// feature only ever runs outdoors with a clear sky, where raw GPS is what
  /// fused would fall back to anyway — and it keeps the emulator usable, since
  /// `adb emu geo fix` feeds the platform provider and never the fused one.
  static LocationSettings get _settings {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: _distanceFilterMeters,
        forceLocationManager: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: _distanceFilterMeters,
    );
  }

  /// Throws [LocationUnavailableException] when the user or the device refuses.
  Future<void> ensurePermitted() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailableException(
        'Activez la localisation de votre appareil pour suivre un parcours.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationUnavailableException(
        "L'accès à la position est bloqué. Autorisez-le dans les réglages de "
        "votre téléphone pour suivre un parcours.",
      );
    }

    if (permission == LocationPermission.denied) {
      throw const LocationUnavailableException(
        "Sans accès à votre position, le parcours ne peut pas être suivi.",
      );
    }
  }

  Stream<GpsPoint> watchPosition() {
    return Geolocator.getPositionStream(locationSettings: _settings)
        .map(_toGpsPoint);
  }

  GpsPoint _toGpsPoint(Position position) {
    return GpsPoint(
      lat: position.latitude,
      lng: position.longitude,
      altitude: position.altitude,
      timestampMs: position.timestamp.millisecondsSinceEpoch,
    );
  }
}
