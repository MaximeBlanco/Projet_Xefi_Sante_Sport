import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/session_duration.dart';
import '../../core/theme/app_colors.dart';
import '../../models/team_member.dart';
import '../../models/team_ranking_entry.dart';
import '../../providers/team_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/team_avatar.dart';

/// Who is in a team, opened by tapping its row in the leaderboard.
///
/// The standing answers "which team is ahead"; the obvious next question is
/// who that is, and until now the app had no answer to it anywhere.
class TeamDetailSheet extends ConsumerWidget {
  const TeamDetailSheet({super.key, required this.entry, this.myTeamId});

  final TeamRankingEntry entry;
  final String? myTeamId;

  static Future<void> show(
    BuildContext context, {
    required TeamRankingEntry entry,
    String? myTeamId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => TeamDetailSheet(entry: entry, myTeamId: myTeamId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final members = ref.watch(teamMembersProvider(entry.teamId));
    final isMyTeam = entry.teamId == myTeamId;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                TeamAvatar(
                  name: entry.name,
                  colour: entry.colour,
                  imageUrl: entry.imageUrl,
                  radius: 30,
                  ringColour: isMyTeam ? AppColors.primary : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.headlineMedium?.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.currentRank == null
                            ? entry.memberLabel
                            : '${entry.currentRank}e · ${entry.memberLabel}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.totalPoints}',
                      style: textTheme.headlineMedium?.copyWith(
                        fontSize: 26,
                        color: AppColors.primary,
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Score d\'équipe : uniquement les séances de sport collectif, '
                'soit ${SessionDuration.describeMinutes(entry.totalDurationMin)} '
                'cumulées. Les points de chacun ci-dessous comptent tout leur sport.',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.35,
                  color: AppColors.secondaryText.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: AsyncValueView<List<TeamMember>>(
              value: members,
              onRetry: () =>
                  ref.invalidate(teamMembersProvider(entry.teamId)),
              isEmpty: (list) => list.isEmpty,
              emptyMessage: 'Personne dans cette équipe pour le moment.',
              builder: (list) => ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                itemCount: list.length,
                itemBuilder: (context, index) =>
                    _MemberRow(member: list[index], position: index + 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.position});

  final TeamMember member;
  final int position;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$position',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryText.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(width: 6),
          ProfileAvatar(
            name: member.name,
            avatarUrl: member.avatarUrl,
            radius: 19,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                    if (member.isOwner) ...[
                      const SizedBox(width: 6),
                      // The owner decides who else gets in, so saying which one
                      // they are is what tells a newcomer whose answer to wait
                      // for.
                      const _OwnerChip(),
                    ],
                  ],
                ),
                Text(
                  member.sessionCount == 1
                      ? '1 séance'
                      : '${member.sessionCount} séances',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.secondaryText.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${member.totalPoints} pts',
            style: textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerChip extends StatelessWidget {
  const _OwnerChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        'RESPONSABLE',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 8,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
