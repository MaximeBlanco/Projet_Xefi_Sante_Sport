import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_providers.dart';
import '../data/contact_repository.dart';
import '../models/contact.dart';
import '../models/member_summary.dart';
import 'auth_provider.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(ref.watch(supabaseClientProvider));
});

/// Every link the signed-in member is part of, accepted or not.
///
/// The lists below are cuts of this one rather than queries of their own, so
/// accepting a request moves somebody from one to the other in a single frame
/// instead of leaving them in both until the slower call lands.
final contactsProvider = FutureProvider<List<Contact>>((ref) {
  final signedInUser = ref.watch(currentUserProvider);
  if (signedInUser == null) {
    return Future<List<Contact>>.value(const <Contact>[]);
  }
  return ref.watch(contactRepositoryProvider).fetchContacts(signedInUser.id);
});

final acceptedContactsProvider = Provider<AsyncValue<List<Contact>>>((ref) {
  return ref.watch(contactsProvider).whenData((contacts) {
    return [
      for (final contact in contacts)
        if (contact.isAccepted) contact,
    ];
  });
});

/// The requests waiting for an answer from the signed-in member.
///
/// Only the ones they received: a request they sent is pending too, but it is
/// not theirs to accept.
final pendingReceivedProvider = Provider<AsyncValue<List<Contact>>>((ref) {
  final signedInUserId = ref.watch(currentUserProvider)?.id;
  return ref.watch(contactsProvider).whenData((contacts) {
    return [
      for (final contact in contacts)
        if (contact.isPending && !contact.wasSentBy(signedInUserId ?? ''))
          contact,
    ];
  });
});

/// The requests the signed-in member is waiting on an answer for.
///
/// Shown rather than hidden: without them, somebody who has asked three people
/// and heard back from nobody would be told they have no contacts and invited
/// to go and ask again.
final pendingSentProvider = Provider<AsyncValue<List<Contact>>>((ref) {
  final signedInUserId = ref.watch(currentUserProvider)?.id;
  return ref.watch(contactsProvider).whenData((contacts) {
    return [
      for (final contact in contacts)
        if (contact.isPending && contact.wasSentBy(signedInUserId ?? ''))
          contact,
    ];
  });
});

/// The link with one given member, or null when there is none.
///
/// What a member's row offers — add, wait, or nothing — follows from this, so
/// the answer comes from the list already loaded rather than from a query per
/// row.
final contactLinkProvider = Provider.family<Contact?, String>((ref, memberId) {
  final signedInUserId = ref.watch(currentUserProvider)?.id;
  if (signedInUserId == null) return null;

  final contacts = ref.watch(contactsProvider).valueOrNull;
  if (contacts == null) return null;

  for (final contact in contacts) {
    if (contact.peerIdFor(signedInUserId) == memberId) return contact;
  }
  return null;
});

final memberSearchProvider = FutureProvider.autoDispose
    .family<List<MemberSummary>, String>((ref, query) {
      final signedInUser = ref.watch(currentUserProvider);
      if (signedInUser == null) {
        return Future<List<MemberSummary>>.value(const <MemberSummary>[]);
      }
      return ref
          .watch(contactRepositoryProvider)
          .searchMembers(query: query, excludingUserId: signedInUser.id);
    });
