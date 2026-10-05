import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/contact.dart';
import '../models/member_summary.dart';

/// A refusal in the words of the person who hit it, rather than the Postgres
/// error behind it.
class ContactException implements Exception {
  const ContactException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ContactRepository {
  ContactRepository(this._client);

  /// Both sides of the link, joined on the column rather than on the foreign
  /// key's generated name, which a later migration could rename without anyone
  /// noticing here.
  static const _columnsWithBothMembers =
      '*, requester:profiles!requester_id(id, name, avatar_url), '
      'addressee:profiles!addressee_id(id, name, avatar_url)';

  /// Long enough to find someone in a company of this size, short enough that
  /// a single letter does not return the whole directory.
  static const _searchResultLimit = 20;

  static const _uniqueViolation = '23505';
  static const _checkViolation = '23514';

  final SupabaseClient _client;

  /// Every link [userId] is part of, in both directions and both states.
  ///
  /// One query rather than one per list: the contacts screen shows the accepted
  /// ones and the requests side by side, and two round trips could disagree
  /// with each other for as long as the second one is in flight.
  Future<List<Contact>> fetchContacts(String userId) async {
    final rows = await _client
        .from('contacts')
        .select(_columnsWithBothMembers)
        .or('requester_id.eq.$userId,addressee_id.eq.$userId')
        .order('created_at', ascending: false);
    return rows.map((row) => Contact.fromJson(row, viewerId: userId)).toList();
  }

  Future<void> sendRequest({
    required String requesterId,
    required String addresseeId,
  }) async {
    if (requesterId == addresseeId) {
      throw const ContactException(
        'Vous ne pouvez pas vous ajouter vous-même.',
      );
    }

    final existingLink = await _linkBetween(requesterId, addresseeId);
    if (existingLink != null) {
      throw ContactException(
        existingLink.isAccepted
            ? 'Vous êtes déjà en contact avec ce membre.'
            : 'Une demande est déjà en cours avec ce membre.',
      );
    }

    try {
      await _client.from('contacts').insert({
        'requester_id': requesterId,
        'addressee_id': addresseeId,
        'status': ContactStatus.pending.name,
      });
    } on PostgrestException catch (error) {
      // The read above cannot see a request the other side sent a second ago.
      // The unique index can, and this is where it answers — which is also why
      // the check is not left to the client alone.
      if (error.code == _uniqueViolation) {
        throw const ContactException(
          'Une demande est déjà en cours avec ce membre.',
        );
      }
      if (error.code == _checkViolation) {
        throw const ContactException(
          'Vous ne pouvez pas vous ajouter vous-même.',
        );
      }
      rethrow;
    }
  }

  Future<void> acceptRequest(String contactId) {
    return _client
        .from('contacts')
        .update({'status': ContactStatus.accepted.name})
        .eq('id', contactId);
  }

  /// Members whose display name contains [query], the sender excepted.
  ///
  /// The search is on the name alone: the e-mail address is not something the
  /// app puts on screen, and matching on it would turn the directory into a way
  /// of confirming who holds which address.
  Future<List<MemberSummary>> searchMembers({
    required String query,
    required String excludingUserId,
  }) async {
    final searchedName = query.trim();
    if (searchedName.isEmpty) return const <MemberSummary>[];

    final rows = await _client
        .from('profiles')
        .select('id, name, avatar_url')
        .ilike('name', '%$searchedName%')
        .neq('id', excludingUserId)
        .order('name')
        .limit(_searchResultLimit);
    return rows.map(MemberSummary.fromJson).toList();
  }

  Future<Contact?> _linkBetween(String memberId, String otherMemberId) async {
    final row = await _client
        .from('contacts')
        .select()
        .or(
          'and(requester_id.eq.$memberId,addressee_id.eq.$otherMemberId),'
          'and(requester_id.eq.$otherMemberId,addressee_id.eq.$memberId)',
        )
        .limit(1)
        .maybeSingle();
    return row == null ? null : Contact.fromJson(row);
  }
}
