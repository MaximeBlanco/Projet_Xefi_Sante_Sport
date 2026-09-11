import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/gps_point.dart';
import '../../models/sport.dart';
import '../../providers/route_tracking_controller.dart';
import '../../widgets/route_map.dart';

/// What a finished tracking session hands back to the record form.
class TrackedRoute {
  const TrackedRoute({
    required this.route,
    required this.durationMin,
    required this.distanceKm,
    required this.elevationGainM,
  });

  final List<GpsPoint> route;
  final int durationMin;
  final double distanceKm;
  final double elevationGainM;
}

class TrackRouteScreen extends ConsumerStatefulWidget {
  const TrackRouteScreen({super.key, required this.sport});

  final Sport sport;

  @override
  ConsumerState<TrackRouteScreen> createState() => _TrackRouteScreenState();
}

class _TrackRouteScreenState extends ConsumerState<TrackRouteScreen> {
  Timer? _chronoTicker;

  @override
  void initState() {
    super.initState();
    // The elapsed time is derived from wall-clock, so the screen has to repaint
    // itself: no new GPS point arrives while the user stands still.
    _chronoTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _chronoTicker?.cancel();
    super.dispose();
  }

  String _formatElapsed(Duration elapsed) {
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    if (elapsed.inHours == 0) return '$minutes:$seconds';
    return '${elapsed.inHours}:$minutes:$seconds';
  }

  void _finish(RouteTrackingState tracking) {
    // A session the user actually ran for 40 seconds is still a session, and
    // the database rejects a duration of zero.
    final durationMin = math.max(1, (tracking.elapsed.inSeconds / 60).round());

    Navigator.of(context).pop(
      TrackedRoute(
        route: tracking.route,
        durationMin: durationMin,
        distanceKm: tracking.distanceKm,
        elevationGainM: tracking.elevationGainM,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(routeTrackingControllerProvider);
    final controller = ref.read(routeTrackingControllerProvider.notifier);
    final hasFinished = !tracking.isTracking && tracking.stoppedAt != null;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.sport.emoji} ${widget.sport.name}')),
      body: Column(
        children: [
          Expanded(
            child: RouteMap(
              route: tracking.route,
              followLastPoint: tracking.isTracking,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tracking.errorMessage != null) ...[
                    Text(
                      tracking.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _TrackingStat(
                        label: 'Temps',
                        value: _formatElapsed(tracking.elapsed),
                      ),
                      _TrackingStat(
                        label: 'Distance',
                        value: '${tracking.distanceKm.toStringAsFixed(2)} km',
                      ),
                      _TrackingStat(
                        label: 'D+',
                        value: '${tracking.elevationGainM.round()} m',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (tracking.isTracking)
                    ElevatedButton.icon(
                      onPressed: controller.stop,
                      icon: const Icon(Icons.stop),
                      label: const Text('Arrêter'),
                    )
                  else if (hasFinished)
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _finish(tracking),
                          icon: const Icon(Icons.check),
                          label: const Text('Utiliser ce parcours'),
                        ),
                        TextButton(
                          onPressed: controller.start,
                          child: const Text('Recommencer'),
                        ),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: controller.start,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Démarrer'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingStat extends StatelessWidget {
  const _TrackingStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}
