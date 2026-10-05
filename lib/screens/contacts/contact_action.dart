import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/member_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contact_controller.dart';
import '../../providers/contact_provider.dart';

const _acceptedColour = Color(0xFF1E9E5A);

/// Asks for a link and reports the outcome where the member is standing.
///
/// The messenger is taken before the call so the result is still announced if
/// the row that triggered it has gone — accepting a request rebuilds the list
/// it was in.
Future<void> sendContactRequest(
  BuildContext context,
  WidgetRef ref,
  MemberSummary member,
) async {
  final messenger = ScaffoldMessenger.of(context);

  final wasSent = await ref
      .read(contactControllerProvider.notifier)
      .sendRequest(member.id);

  messenger.showSnackBar(
    SnackBar(
      content: Text(
        wasSent
            ? 'Demande envoyée à ${member.name}.'
            : contactFailureMessage(ref.read(contactControllerProvider).error),
      ),
    ),
  );
}

Future<void> acceptContactRequest(
  BuildContext context,
  WidgetRef ref, {
  required String contactId,
  required String memberName,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  final wasAccepted = await ref
      .read(contactControllerProvider.notifier)
      .acceptRequest(contactId);

  messenger.showSnackBar(
    SnackBar(
      content: Text(
        wasAccepted
            ? '$memberName fait maintenant partie de vos contacts.'
            : contactFailureMessage(ref.read(contactControllerProvider).error),
      ),
    ),
  );
}

/// What one member offers, given the link that already exists with them.
///
/// The four states are the four a link can be in, which is why a second request
/// cannot be sent from here: once a request exists the button is no longer one.
/// The database refuses the duplicate anyway; this is only what makes the
/// refusal unnecessary.
class ContactAction extends ConsumerWidget {
  const ContactAction({super.key, required this.member});

  final MemberSummary member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(contactLinkProvider(member.id));
    final signedInUserId = ref.watch(currentUserProvider)?.id;
    final isBusy = ref.watch(contactControllerProvider).isLoading;

    if (link == null) {
      return FilledButton(
        onPressed: isBusy
            ? null
            : () => sendContactRequest(context, ref, member),
        child: const Text('Ajouter'),
      );
    }

    if (link.isAccepted) {
      return const ContactLinkBadge.accepted();
    }

    if (signedInUserId != null && !link.wasSentBy(signedInUserId)) {
      return FilledButton(
        onPressed: isBusy
            ? null
            : () => acceptContactRequest(
                context,
                ref,
                contactId: link.id,
                memberName: member.name,
              ),
        child: const Text('Accepter'),
      );
    }

    return const ContactLinkBadge.pending();
  }
}

/// A link that is not an action: there is nothing to press on somebody already
/// added, nor on a request whose answer belongs to the other member.
class ContactLinkBadge extends StatelessWidget {
  const ContactLinkBadge._({
    required this.icon,
    required this.label,
    required this.colour,
  });

  const ContactLinkBadge.accepted()
    : this._(
        icon: Icons.check_circle,
        label: 'Contact',
        colour: _acceptedColour,
      );

  const ContactLinkBadge.pending()
    : this._(
        icon: Icons.hourglass_empty,
        label: 'En attente',
        colour: AppColors.secondaryText,
      );

  final IconData icon;
  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colour),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontWeight: FontWeight.w700, color: colour),
        ),
      ],
    );
  }
}
