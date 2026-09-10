import 'dart:convert';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps the "calculate-calories" Edge Function, which is the project's
/// third-party integration (Calories Burned API).
///
/// Every failure degrades to null instead of an exception: an outage of the
/// external API must cost the calories of a session, never the session itself.
class CaloriesService {
  CaloriesService(this._client);

  static const String _functionName = 'calculate-calories';

  final SupabaseClient _client;

  Future<double?> calculateCalories({
    required String activity,
    required double weightKg,
    required int durationMin,
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
      return _extractCaloriesBurned(response.data);
    } catch (error) {
      developer.log(
        'Calories calculation unavailable',
        name: 'CaloriesService',
        error: error,
      );
      return null;
    }
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
