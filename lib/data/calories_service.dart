import 'dart:convert';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

/// How many calories a session burned, and whether that number came from the
/// external provider or from the local MET formula.
class CaloriesEstimate {
  const CaloriesEstimate({required this.kcal, required this.isLocalEstimate});

  final double kcal;
  final bool isLocalEstimate;
}

/// Wraps the "calculate-calories" Edge Function, which is the project's
/// third-party integration (Calories Burned API).
///
/// Every failure falls back to the MET formula instead of propagating: an
/// outage of the external API, or a stack running without an API key at all,
/// must cost the accuracy of the calories, never the session itself.
class CaloriesService {
  CaloriesService(this._client);

  static const String _functionName = 'calculate-calories';
  static const int _minutesPerHour = 60;

  final SupabaseClient _client;

  Future<CaloriesEstimate> calculateCalories({
    required String activity,
    required double weightKg,
    required int durationMin,
    required double met,
  }) async {
    try {
      final response = await _client.functions.invoke(
        _functionName,
        body: {
          'activity': activity,
          'weightKg': weightKg,
          'durationMin': durationMin,
        },
      );
      final caloriesBurned = _extractCaloriesBurned(response.data);
      if (caloriesBurned != null) {
        return CaloriesEstimate(kcal: caloriesBurned, isLocalEstimate: false);
      }
      developer.log(
        'Calories provider answered without a usable value',
        name: 'CaloriesService',
      );
    } catch (error) {
      developer.log(
        'Calories provider unavailable, falling back to the MET formula',
        name: 'CaloriesService',
        error: error,
      );
    }

    return CaloriesEstimate(
      kcal: _estimateFromMet(
        met: met,
        weightKg: weightKg,
        durationMin: durationMin,
      ),
      isLocalEstimate: true,
    );
  }

  double _estimateFromMet({
    required double met,
    required double weightKg,
    required int durationMin,
  }) {
    return met * weightKg * (durationMin / _minutesPerHour);
  }

  double? _extractCaloriesBurned(Object? payload) {
    final decoded = payload is String ? _decodeJsonOrKeepRaw(payload) : payload;
    if (decoded is Map) {
      return _parseAsDouble(
        decoded['caloriesBurned'] ?? decoded['calories_burned'],
      );
    }
    return _parseAsDouble(decoded);
  }

  Object? _decodeJsonOrKeepRaw(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return raw;
    }
  }

  double? _parseAsDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
