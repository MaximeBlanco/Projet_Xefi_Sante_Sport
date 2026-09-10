import 'dart:convert';

import 'package:http/http.dart' as http;

/// Calories Burned API (api-ninjas.com) — free key, no credit card.
/// https://api-ninjas.com/api/caloriesburned
///
/// No backend in this app, so the key lives on the phone. Get a free key at
/// https://api-ninjas.com and set it below. Left empty, calorie calculation
/// is simply skipped — the rest of the app still works.
const caloriesApiKey = String.fromEnvironment('CALORIES_API_KEY');

class CaloriesApiClient {
  Future<double?> caloriesBurned({
    required String activity,
    required double weightKg,
    required int durationMin,
  }) async {
    if (caloriesApiKey.isEmpty) return null;

    final weightLbs = weightKg * 2.20462;
    final uri = Uri.parse(
      'https://api.api-ninjas.com/v1/caloriesburned'
      '?activity=$activity&weight=${weightLbs.round()}&duration=$durationMin',
    );

    final response = await http
        .get(uri, headers: {'X-Api-Key': caloriesApiKey})
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return null;

    final results = jsonDecode(response.body) as List;
    if (results.isEmpty) return null;

    return (results.first['total_calories'] as num).toDouble();
  }
}
