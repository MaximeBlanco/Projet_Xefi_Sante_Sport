import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/contact_repository.dart';
import 'auth_provider.dart';
import 'contact_provider.dart';
import 'ranking_provider.dart';

/// What to put in front of a member when an action did not go through.
///
/// A refusal the repository worded is shown as it stands; anything else is a
/// failure the person can only retry, and the Postgres wording would tell them
/// nothing they could act on.
String contactFailureMessage(Object? error) {
  if (error is ContactException) return error.message;
  return 'Action impossible pour le moment, réessayez.';
}

class ContactController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Returns whether the request left, so the screen can confirm it or keep the
  /// member where they are with the reason it did not.
  Future<bool> sendRequest(String memberId) {
    return _run((repository, signedInUserId) {
      return repository.sendRequest(
        requesterId: signedInUserId,
        addresseeId: memberId,
      );
    });
  }

  Future<bool> acceptRequest(String contactId) {
    return _run((repository, _) => repository.acceptRequest(contactId));
  }

  Future<bool> _run(
    Future<void> Function(ContactRepository repository, String signedInUserId)
    action,
  ) async {
    state = const AsyncValue<void>.loading();
    final keepAliveLink = ref.keepAlive();
    try {
      final signedInUser = ref.read(currentUserProvider);
      if (signedInUser == null) {
        throw const ContactException(
          'Vous devez être connecté pour gérer vos contacts.',
        );
      }

      await action(ref.read(contactRepositoryProvider), signedInUser.id);

      // An accepted link changes who the filtered leaderboard counts, which is
      // the whole point of adding somebody.
      ref.invalidate(contactsProvider);
      ref.invalidate(contactsRankingProvider);
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

final contactControllerProvider =
    AutoDisposeAsyncNotifierProvider<ContactController, void>(
      ContactController.new,
    );
