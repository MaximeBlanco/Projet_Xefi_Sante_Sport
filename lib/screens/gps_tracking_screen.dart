import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../constants/sports.dart';
import '../data/calories_api.dart';
import '../data/session_repository.dart';
import '../models/route_point.dart';
import '../models/sport_session.dart';
import '../theme/app_theme.dart';

class GpsTrackingScreen extends StatefulWidget {
  const GpsTrackingScreen({
    super.key,
    required this.sport,
    required this.repository,
    required this.weightKg,
  });

  final SportDefinition sport;
  final SessionRepository repository;
  final double? weightKg;

  @override
  State<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

class _GpsTrackingScreenState extends State<GpsTrackingScreen> {
  final _points = <RoutePoint>[];
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _startedAt;
  double _distanceKm = 0;
  bool _isSaving = false;

  bool get _isTracking => _positionSubscription != null;

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autorisation de localisation requise')),
        );
      }
      return;
    }

    setState(() {
      _points.clear();
      _distanceKm = 0;
      _startedAt = DateTime.now();
    });

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);
  }

  void _onPosition(Position position) {
    final point = RoutePoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      if (_points.isNotEmpty) {
        _distanceKm += _haversineKm(_points.last, point);
      }
      _points.add(point);
    });
  }

  double _haversineKm(RoutePoint a, RoutePoint b) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final h = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    return earthRadiusKm * 2 * atan2(sqrt(h), sqrt(1 - h));
  }

  double _degToRad(double deg) => deg * pi / 180;

  Future<void> _stopAndSave() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    final startedAt = _startedAt;
    if (startedAt == null) return;

    setState(() => _isSaving = true);

    final durationMin =
        max(1, DateTime.now().difference(startedAt).inMinutes);

    double? caloriesBurned;
    if (widget.weightKg != null) {
      caloriesBurned = await CaloriesApiClient().caloriesBurned(
        activity: widget.sport.caloriesApiActivity,
        weightKg: widget.weightKg!,
        durationMin: durationMin,
      );
    }

    final session = SportSession(
      id: '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}',
      sportName: widget.sport.name,
      emoji: widget.sport.emoji,
      date: startedAt,
      durationMin: durationMin,
      distanceKm: _distanceKm,
      route: List.of(_points),
      caloriesBurned: caloriesBurned,
    );

    await widget.repository.saveSession(session);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final latLngPoints =
        _points.map((p) => LatLng(p.latitude, p.longitude)).toList();

    return Scaffold(
      appBar: AppBar(title: Text('${widget.sport.emoji} ${widget.sport.name}')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: latLngPoints.isNotEmpty
                    ? latLngPoints.last
                    : const LatLng(48.8566, 2.3522),
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.monapp',
                ),
                if (latLngPoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: latLngPoints,
                        color: AppColors.primary,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                if (latLngPoints.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: latLngPoints.last,
                        width: 16,
                        height: 16,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Stat(label: 'Distance', value: '${_distanceKm.toStringAsFixed(2)} km'),
                    _Stat(
                      label: 'Durée',
                      value: _startedAt == null
                          ? '0 min'
                          : '${DateTime.now().difference(_startedAt!).inMinutes} min',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : _isTracking
                            ? _stopAndSave
                            : _start,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isTracking ? 'Arrêter et enregistrer' : 'Démarrer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}
