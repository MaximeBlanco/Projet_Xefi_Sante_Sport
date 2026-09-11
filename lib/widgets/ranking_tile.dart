import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/ranking_entry.dart';
import 'profile_avatar.dart';

const _climbColour = Color(0xFF1E9E5A);

class RankingTile extends StatelessWidget {
  const RankingTile({
    super.key,
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
    this.leaderPoints,
  });

  final int rank;
  final RankingEntry entry;
  final bool isCurrentUser;

  /// The top score, so each bar reads as a share of the lead rather than as a
  /// number nobody can place. Null hides the bar.
  final int? leaderPoints;

  double get _share {
    final leader = leaderPoints;
    if (leader == null || leader <= 0) return 0;
    return (entry.totalPoints / leader).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryText.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: textTheme.titleMedium?.copyWith(
                color: isCurrentUser
                    ? AppColors.primary
                    : AppColors.secondaryText.withValues(alpha: 0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 34, child: _MovementBadge(change: entry.rankChange)),
          ProfileAvatar(
            name: entry.name,
            avatarUrl: entry.avatarUrl,
            radius: 18,
            onDarkChip: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCurrentUser ? AppColors.primary : AppColors.black,
                  ),
                ),
                if (leaderPoints != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: _share,
                      minHeight: 5,
                      backgroundColor: AppColors.black.withValues(alpha: 0.07),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCurrentUser
                            ? AppColors.primary
                            : AppColors.secondaryText.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalPoints}',
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 19,
                  color: isCurrentUser ? AppColors.primary : AppColors.black,
                ),
              ),
              Text(
                'POINTS',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  color: AppColors.secondaryText.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Places gained or lost since Monday.
///
/// A dash rather than a blank when nothing moved, so the column reads as "no
/// change" instead of as missing data — and nothing at all when the movement is
/// genuinely unknown, which is not the same thing.
class _MovementBadge extends StatelessWidget {
  const _MovementBadge({required this.change});

  final int? change;

  @override
  Widget build(BuildContext context) {
    final movement = change;
    final textStyle = Theme.of(context).textTheme.bodySmall;

    if (movement == null) return const SizedBox.shrink();

    if (movement == 0) {
      return Text(
        '–',
        style: textStyle?.copyWith(
          color: AppColors.secondaryText.withValues(alpha: 0.45),
        ),
      );
    }

    final hasClimbed = movement > 0;
    final colour = hasClimbed ? _climbColour : AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasClimbed ? Icons.arrow_drop_up : Icons.arrow_drop_down,
          size: 18,
          color: colour,
        ),
        Text(
          '${movement.abs()}',
          style: textStyle?.copyWith(color: colour, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
