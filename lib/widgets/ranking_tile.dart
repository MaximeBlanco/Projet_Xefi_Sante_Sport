import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/ranking_entry.dart';
import 'profile_avatar.dart';

class RankingTile extends StatelessWidget {
  const RankingTile({
    super.key,
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
  });

  final int rank;
  final RankingEntry entry;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isCurrentUser ? AppColors.primary.withValues(alpha: 0.06) : null,
      shape: isCurrentUser
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.primary, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _RankBadge(rank: rank, isCurrentUser: isCurrentUser),
            const SizedBox(width: 12),
            ProfileAvatar(
              name: entry.name,
              avatarUrl: entry.avatarUrl,
              radius: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: isCurrentUser ? FontWeight.w800 : FontWeight.w600,
                  color: isCurrentUser ? AppColors.primary : AppColors.black,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${entry.totalPoints} pts',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isCurrentUser ? AppColors.primary : AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.isCurrentUser});

  final int rank;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: isCurrentUser
            ? AppColors.primary
            : AppColors.black.withValues(alpha: 0.06),
        shape: const CircleBorder(),
      ),
      child: Text(
        '$rank',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: isCurrentUser ? AppColors.white : AppColors.secondaryText,
        ),
      ),
    );
  }
}
