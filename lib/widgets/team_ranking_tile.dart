import 'package:flutter/material.dart';

import '../core/domain/session_duration.dart';
import '../core/theme/app_colors.dart';
import '../models/team_ranking_entry.dart';
import 'team_avatar.dart';

/// One team in the team leaderboard.
///
/// Closer to a list row than to the individual tile: the photograph and the
/// rank are what find your team, and the whole row opens its roster.
class TeamRankingTile extends StatelessWidget {
  const TeamRankingTile({
    super.key,
    required this.entry,
    required this.leaderPoints,
    required this.isMyTeam,
    this.onTap,
  });

  final TeamRankingEntry entry;
  final int leaderPoints;
  final bool isMyTeam;

  /// Opens the roster. A standing invites the question of who is in the team,
  /// and the row is the only place to ask it from.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rank = entry.currentRank;
    final share = leaderPoints <= 0
        ? 0.0
        : (entry.totalPoints / leaderPoints).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMyTeam
              ? AppColors.primary
              : AppColors.black.withValues(alpha: 0.06),
          width: isMyTeam ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      rank == null ? '—' : '$rank',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isMyTeam
                            ? AppColors.primary
                            : AppColors.secondaryText.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  _MovementBadge(change: entry.rankChange),
                  const SizedBox(width: 10),
                  TeamAvatar(
                    name: entry.name,
                    colour: entry.colour,
                    imageUrl: entry.imageUrl,
                    radius: 21,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isMyTeam
                                ? AppColors.primary
                                : AppColors.secondaryText,
                          ),
                        ),
                        Text(
                          '${entry.memberLabel} · '
                          '${SessionDuration.describeMinutes(entry.totalDurationMin)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: AppColors.secondaryText.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${entry.totalPoints}',
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 20,
                          color: isMyTeam ? AppColors.primary : AppColors.black,
                        ),
                      ),
                      Text(
                        'POINTS',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          letterSpacing: 1,
                          color: AppColors.secondaryText.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: share.toDouble(),
                  minHeight: 5,
                  backgroundColor: AppColors.black.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isMyTeam ? AppColors.primary : entry.colour,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementBadge extends StatelessWidget {
  const _MovementBadge({required this.change});

  final int? change;

  @override
  Widget build(BuildContext context) {
    final places = change;
    if (places == null || places == 0) {
      return const SizedBox(width: 30);
    }

    final isClimb = places > 0;
    return SizedBox(
      width: 30,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isClimb ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            size: 16,
            color: isClimb ? const Color(0xFF1B7F5C) : AppColors.primary,
          ),
          Text(
            '${places.abs()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isClimb ? const Color(0xFF1B7F5C) : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
