import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'home_summary_provider.dart';
import 'profile_provider.dart';
import 'ranking_provider.dart';

class SignedOutWhileEditingException implements Exception {
  const SignedOutWhileEditingException();

  @override
  String toString() => 'Votre session a expiré, reconnectez-vous.';
}

/// Owns every write to the current user's profile, so the screen stays a form
/// and the invalidations that keep the rest of the app in step live in one
/// place.
class ProfileEditingController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> renameTo(String name) {
    return _run((userId) async {
      await ref
          .read(profileRepositoryProvider)
          .updateName(userId: userId, name: name.trim());
    });
  }

  /// The weight feeds the calories call, and sign-up is the only other place
  /// it is ever captured, so a profile created before the field existed would
  /// otherwise never get calories.
  Future<bool> updateWeight(double weightKg) {
    return _run((userId) async {
      await ref
          .read(profileRepositoryProvider)
          .updateWeight(userId: userId, weightKg: weightKg);
    });
  }

  Future<bool> changeAvatar(File picture, {required DateTime pickedAt}) {
    return _run((userId) async {
      await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(userId: userId, file: picture, uploadedAt: pickedAt);
    });
  }

  Future<bool> _run(Future<void> Function(String userId) write) async {
    state = const AsyncValue<void>.loading();
    final keepAliveLink = ref.keepAlive();
    try {
      final signedInUser = ref.read(currentUserProvider);
      if (signedInUser == null) {
        state = AsyncValue<void>.error(
          const SignedOutWhileEditingException(),
          StackTrace.current,
        );
        return false;
      }

      await write(signedInUser.id);

      // The name and the picture are shown on the home screen and next to every
      // ranking row, so both have to be refetched or they keep the old value
      // until the app restarts.
      ref.invalidate(currentProfileProvider);
      ref.invalidate(globalRankingProvider);
      ref.invalidate(homeSummaryProvider);

      state = const AsyncValue<void>.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<void>.error(error, stackTrace);
      return false;
    } finally {
      keepAliveLink.close();
    }
  }
}

final profileEditingControllerProvider =
    AutoDisposeAsyncNotifierProvider<ProfileEditingController, void>(
      ProfileEditingController.new,
    );
