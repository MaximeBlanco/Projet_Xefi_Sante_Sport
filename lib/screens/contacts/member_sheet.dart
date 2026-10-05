import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/member_summary.dart';
import '../../models/ranking_entry.dart';
import '../../widgets/profile_avatar.dart';
import 'contact_action.dart';

/// Opens a leaderboard row onto the member behind it.
///
/// It carries what the row already showed — name, rank, points — and the one
/// thing that can be done about a colleague who is not a contact yet. Nothing
/// more: a member who has not accepted you owes you no detail, and what an
/// accepted contact shares is a later screen's business.
Future<void> showMemberSheet(
  BuildContext context, {
  required RankingEntry entry,
  required int rank,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _MemberSheet(entry: entry, rank: rank),
  );
}

/// French abbreviates only the first place differently, and "1e" reads as a
/// typo to anyone who would otherwise not have noticed the rank at all.
String _frenchOrdinal(int rank) => rank == 1 ? '1er' : '${rank}e';

class _MemberSheet extends StatelessWidget {
  const _MemberSheet({required this.entry, required this.rank});

  final RankingEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileAvatar(
              name: entry.name,
              avatarUrl: entry.avatarUrl,
              radius: 32,
              onDarkChip: true,
            ),
            const SizedBox(height: 12),
            Text(
              entry.name,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 4),
            Text(
              '${_frenchOrdinal(rank)} au classement · '
              '${entry.totalPoints} points',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryText.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 18),
            ContactAction(
              member: MemberSummary(
                id: entry.userId,
                name: entry.name,
                avatarUrl: entry.avatarUrl,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
