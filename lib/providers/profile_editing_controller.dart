import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
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

  /// Records what the member lets their contacts read.
  ///
  /// The switch is only the choice: the database is what withholds a session or
  /// a route from another account, so nothing here guards anything.
  Future<bool> setSharing(
    SharingPreference preference, {
    required bool isOpen,
  }) {
    return _run(
      (userId) async {
        await ref
            .read(profileRepositoryProvider)
            .updateSharing(
              userId: userId,
              preference: preference,
              isOpen: isOpen,
            );
      },
      // A sharing switch moves what *other* accounts may read; the member's own
      // home screen and ranking row show exactly the same figures either way.
      refreshesHomeAndRanking: false,
    );
  }

  Future<bool> changeAvatar(XFile picture, {required DateTime pickedAt}) {
    return _run((userId) async {
      await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(userId: userId, file: picture, uploadedAt: pickedAt);
    });
  }

  /// Deletes the account and everything attached to it.
  ///
  /// Unlike the edits, nothing is invalidated afterwards: the sign-out inside
  /// swaps the whole tree for the login screen, and refetching a profile that
  /// no longer exists would only race that teardown with a doomed query.
  Future<bool> deleteAccount() async {
    state = const AsyncValue<void>.loading();
    final keepAliveLink = ref.keepAlive();
    try {
      if (ref.read(currentUserProvider) == null) {
        state = AsyncValue<void>.error(
          const SignedOutWhileEditingException(),
          StackTrace.current,
        );
        return false;
      }

      await ref.read(authRepositoryProvider).deleteAccount();

      state = const AsyncValue<void>.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<void>.error(error, stackTrace);
      return false;
    } finally {
      keepAliveLink.close();
    }
  }

  Future<bool> _run(
    Future<void> Function(String userId) write, {
    bool refreshesHomeAndRanking = true,
  }) async {
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

      ref.invalidate(currentProfileProvider);
      // The name and the picture are shown on the home screen and next to every
      // ranking row, so both have to be refetched or they keep the old value
      // until the app restarts.
      if (refreshesHomeAndRanking) {
        ref.invalidate(globalRankingProvider);
        ref.invalidate(homeSummaryProvider);
      }

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
