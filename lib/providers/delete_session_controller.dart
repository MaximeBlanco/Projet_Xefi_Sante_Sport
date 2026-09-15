import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ranking_provider.dart';
import 'session_provider.dart';

class DeleteSessionController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Returns whether the session is gone, so the screen can pop only on
  /// success and keep the user on the page with an error otherwise.
  Future<bool> delete(String sessionId) async {
    state = const AsyncValue<void>.loading();
    final keepAliveLink = ref.keepAlive();
    try {
      await ref.read(sessionRepositoryProvider).deleteSession(sessionId);

      // Points are the session's duration, so removing one changes the
      // leaderboard as much as the history.
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
}

final deleteSessionControllerProvider =
    AutoDisposeAsyncNotifierProvider<DeleteSessionController, void>(
  DeleteSessionController.new,
);
