import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gps_point.dart';
import '../models/sport.dart';
import 'auth_provider.dart';
import 'profile_provider.dart';
import 'ranking_provider.dart';
import 'session_provider.dart';

class SignedInUserRequiredException implements Exception {
  const SignedInUserRequiredException();

  @override
  String toString() => 'Vous devez être connecté pour enregistrer une séance.';
}

class RecordSessionController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> submit({
    required Sport sport,
    required DateTime date,
    required int durationMin,
    List<GpsPoint>? route,
    double? distanceKm,
    double? elevationGainM,
  }) async {
    state = const AsyncValue<void>.loading();
    final keepAliveLink = ref.keepAlive();
    try {
      final signedInUser = ref.read(currentUserProvider);
      if (signedInUser == null) {
        state = AsyncValue<void>.error(
          const SignedInUserRequiredException(),
          StackTrace.current,
        );
        return false;
      }

      // No weight means neither the provider nor the MET formula has anything to
      // work with, so the session is stored without calories rather than with a
      // fabricated number.
      final weightKg = await _readCurrentProfileWeightKg();
      final calories = weightKg == null
          ? null
          : await ref.read(caloriesServiceProvider).calculateCalories(
              activity: sport.externalActivityName ?? sport.name,
              weightKg: weightKg,
              durationMin: durationMin,
              met: sport.met,
            );

      await ref.read(sessionRepositoryProvider).createSession(
            userId: signedInUser.id,
            sportId: sport.id,
            date: date,
            durationMin: durationMin,
            caloriesBurned: calories?.kcal,
            caloriesEstimated: calories?.isLocalEstimate ?? false,
            route: route,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
          );

      ref.invalidate(userSessionsProvider);
      ref.invalidate(globalRankingProvider);
      state = const AsyncValue<void>.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<void>.error(error, stackTrace);
      return false;
    } finally {
      keepAliveLink.close();
    }
  }

  Future<double?> _readCurrentProfileWeightKg() async {
    try {
      final profile = await ref.read(currentProfileProvider.future);
      return profile?.weightKg;
    } catch (_) {
      return null;
    }
  }
}

final recordSessionControllerProvider =
    AutoDisposeAsyncNotifierProvider<RecordSessionController, void>(
  RecordSessionController.new,
);
