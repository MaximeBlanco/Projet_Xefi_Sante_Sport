import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/domain/route_metrics.dart';
import '../data/location_tracker.dart';
import '../models/gps_point.dart';

final locationTrackerProvider = Provider<LocationTracker>((ref) {
  return const LocationTracker();
});

class RouteTrackingState {
  const RouteTrackingState({
    this.route = const [],
    this.isTracking = false,
    this.startedAt,
    this.stoppedAt,
    this.errorMessage,
  });

  final List<GpsPoint> route;
  final bool isTracking;
  final DateTime? startedAt;
  final DateTime? stoppedAt;
  final String? errorMessage;

  bool get hasRoute => route.length > 1;

  double get distanceKm => RouteMetrics.distanceKm(route);

  double get elevationGainM => RouteMetrics.elevationGainM(route);

  /// Wall-clock time rather than the span between the first and last fix: the
  /// first fix can take a while to arrive, and that wait is part of the session.
  Duration get elapsed {
    final startedAt = this.startedAt;
    if (startedAt == null) return Duration.zero;
    return (stoppedAt ?? DateTime.now()).difference(startedAt);
  }

  RouteTrackingState copyWith({
    List<GpsPoint>? route,
    bool? isTracking,
    DateTime? startedAt,
    DateTime? stoppedAt,
    String? errorMessage,
    bool clearError = false,
    bool clearStoppedAt = false,
  }) {
    return RouteTrackingState(
      route: route ?? this.route,
      isTracking: isTracking ?? this.isTracking,
      startedAt: startedAt ?? this.startedAt,
      stoppedAt: clearStoppedAt ? null : (stoppedAt ?? this.stoppedAt),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class RouteTrackingController extends AutoDisposeNotifier<RouteTrackingState> {
  StreamSubscription<GpsPoint>? _subscription;

  @override
  RouteTrackingState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const RouteTrackingState();
  }

  Future<void> start() async {
    final tracker = ref.read(locationTrackerProvider);
    try {
      await tracker.ensurePermitted();
    } on LocationUnavailableException catch (error) {
      state = state.copyWith(errorMessage: error.message, isTracking: false);
      return;
    }

    await _subscription?.cancel();
    state = const RouteTrackingState().copyWith(
      isTracking: true,
      startedAt: DateTime.now(),
      clearError: true,
      clearStoppedAt: true,
    );

    _subscription = tracker.watchPosition().listen(
      (point) => state = state.copyWith(route: [...state.route, point]),
      onError: (_) => state = state.copyWith(
        errorMessage: 'Le signal GPS a été perdu, le parcours est incomplet.',
      ),
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    state = state.copyWith(isTracking: false, stoppedAt: DateTime.now());
  }
}

final routeTrackingControllerProvider =
    AutoDisposeNotifierProvider<RouteTrackingController, RouteTrackingState>(
  RouteTrackingController.new,
);
