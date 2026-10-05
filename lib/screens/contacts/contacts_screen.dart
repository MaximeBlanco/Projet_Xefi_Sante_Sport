import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/contact.dart';
import '../../providers/contact_controller.dart';
import '../../providers/contact_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/content_width.dart';
import '../../widgets/member_row.dart';
import '../../widgets/motion.dart';
import 'contact_action.dart';
import 'member_search_screen.dart';

const _ground = Color(0xFFF4F4F6);

/// The name a member who left no name is listed under.
///
/// The join can only come back empty if the other account disappeared between
/// the two halves of the query; the row is still better than a blank line.
const _unknownMemberName = 'Membre inconnu';

/// The one way in, so the leaderboard's invitation and the app bar action land
/// on the same screen rather than on two that drift apart.
void openContactsScreen(BuildContext context) {
  Navigator.of(
    context,
  ).push<void>(MaterialPageRoute<void>(builder: (_) => const ContactsScreen()));
}

/// The accepted contacts, and the requests waiting for an answer.
///
/// Reached from the leaderboard rather than from a fifth tab: the bottom bar
/// already carries four destinations, and contacts exist to be compared with,
/// which is what the ranking screen is for.
class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acceptedContacts = ref.watch(acceptedContactsProvider);
    final pendingRequests =
        ref.watch(pendingReceivedProvider).valueOrNull ?? const <Contact>[];
    final sentRequests =
        ref.watch(pendingSentProvider).valueOrNull ?? const <Contact>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSearch(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Ajouter'),
      ),
      body: ColoredBox(
        color: _ground,
        child: ContentWidth(
          child: AsyncValueView<List<Contact>>(
            value: acceptedContacts,
            onRetry: () => ref.invalidate(contactsProvider),
            isEmpty: (contacts) =>
                contacts.isEmpty &&
                pendingRequests.isEmpty &&
                sentRequests.isEmpty,
            emptyMessage:
                'Vous n\'avez aucun contact pour le moment.\n'
                'Cherchez un collègue par son nom pour lui envoyer une '
                'demande.',
            emptyAction: FilledButton.icon(
              onPressed: () => _openSearch(context),
              icon: const Icon(Icons.search),
              label: const Text('Chercher un collègue'),
            ),
            builder: (contacts) => RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: _ContactLists(
                acceptedContacts: contacts,
                pendingRequests: pendingRequests,
                sentRequests: sentRequests,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(contactsProvider);
    try {
      await ref.read(contactsProvider.future);
    } catch (_) {
      // AsyncValueView already renders the failure and its retry button.
    }
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const MemberSearchScreen()),
    );
  }
}

class _ContactLists extends StatelessWidget {
  const _ContactLists({
    required this.acceptedContacts,
    required this.pendingRequests,
    required this.sentRequests,
  });

  final List<Contact> acceptedContacts;
  final List<Contact> pendingRequests;
  final List<Contact> sentRequests;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 96),
      children: [
        // Requests first: they are the only thing on this screen that is
        // waiting on the person reading it.
        if (pendingRequests.isNotEmpty) ...[
          const _SectionTitle('Demandes reçues'),
          for (final (index, request) in pendingRequests.indexed)
            SlideIn(
              delay: staggerFor(index),
              child: _PendingRequestRow(request: request),
            ),
          const SizedBox(height: 10),
        ],
        const _SectionTitle('Mes contacts'),
        if (acceptedContacts.isEmpty)
          const _Note(
            'Aucun contact accepté pour le moment. Acceptez une demande ou '
            'cherchez un collègue à ajouter.',
          )
        else
          for (final (index, contact) in acceptedContacts.indexed)
            SlideIn(
              delay: staggerFor(index),
              child: _ContactRow(contact: contact),
            ),
        if (sentRequests.isNotEmpty) ...[
          const SizedBox(height: 10),
          const _SectionTitle('Demandes envoyées'),
          for (final (index, request) in sentRequests.indexed)
            SlideIn(
              delay: staggerFor(index),
              child: _SentRequestRow(request: request),
            ),
        ],
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return MemberRow(
      name: contact.peer?.name ?? _unknownMemberName,
      avatarUrl: contact.peer?.avatarUrl,
      trailing: const ContactLinkBadge.accepted(),
    );
  }
}

class _SentRequestRow extends StatelessWidget {
  const _SentRequestRow({required this.request});

  final Contact request;

  @override
  Widget build(BuildContext context) {
    return MemberRow(
      name: request.peer?.name ?? _unknownMemberName,
      avatarUrl: request.peer?.avatarUrl,
      subtitle: 'N\'a pas encore répondu',
      trailing: const ContactLinkBadge.pending(),
    );
  }
}

class _PendingRequestRow extends ConsumerWidget {
  const _PendingRequestRow({required this.request});

  final Contact request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusy = ref.watch(contactControllerProvider).isLoading;

    return MemberRow(
      name: request.peer?.name ?? _unknownMemberName,
      avatarUrl: request.peer?.avatarUrl,
      subtitle: 'Souhaite vous ajouter en contact',
      trailing: FilledButton(
        onPressed: isBusy
            ? null
            : () => acceptContactRequest(
                context,
                ref,
                contactId: request.id,
                memberName: request.peer?.name ?? _unknownMemberName,
              ),
        child: const Text('Accepter'),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.secondaryText.withValues(alpha: 0.7)),
      ),
    );
  }
}
