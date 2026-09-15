import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';
import '../models/gps_point.dart';

/// Draws a recorded route over OpenStreetMap tiles.
///
/// OSM is the one tile source that needs no key and no billing account, which
/// keeps the map working on a fresh clone the way the rest of the app does.
class RouteMap extends StatefulWidget {
  const RouteMap({
    super.key,
    required this.route,
    this.followLastPoint = false,
    this.interactive = true,
  });

  final List<GpsPoint> route;

  /// Keeps the camera on the newest fix while a session is being recorded.
  final bool followLastPoint;

  final bool interactive;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  static const String _tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _userAgent = 'com.example.monapp';
  static const double _followZoom = 16;

  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.followLastPoint || widget.route.isEmpty) return;
    if (widget.route.length == oldWidget.route.length) return;

    // The controller throws if the map is not laid out yet, and a route can
    // grow on the very frame the screen appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(_toLatLng(widget.route.last), _followZoom);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.route.isEmpty) {
      return const _RouteMapPlaceholder();
    }

    final points = widget.route.map(_toLatLng).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: points.last,
        initialZoom: _followZoom,
        initialCameraFit: points.length > 1
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(points),
                padding: const EdgeInsets.all(32),
              )
            : null,
        interactionOptions: InteractionOptions(
          flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(urlTemplate: _tileUrl, userAgentPackageName: _userAgent),
        PolylineLayer(
          polylines: [
            Polyline(
              points: points,
              strokeWidth: 5,
              color: AppColors.primary,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            _endpointMarker(points.first, AppColors.secondaryText),
            if (points.length > 1)
              _endpointMarker(points.last, AppColors.primary),
          ],
        ),
      ],
    );
  }

  Marker _endpointMarker(LatLng position, Color color) {
    return Marker(
      point: position,
      width: 18,
      height: 18,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 3),
        ),
      ),
    );
  }

  LatLng _toLatLng(GpsPoint point) => LatLng(point.lat, point.lng);
}

class _RouteMapPlaceholder extends StatelessWidget {
  const _RouteMapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black12,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            "En attente du premier point GPS…",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
