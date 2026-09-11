import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/profile.dart';
import '../../models/ranking_entry.dart';
import '../../models/team_ranking_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/ranking_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/motion.dart';
import '../../widgets/ranking_podium.dart';
import '../../widgets/ranking_tile.dart';
import '../../widgets/team_ranking_tile.dart';
import 'team_detail_sheet.dart';

/// The list sits on a wash rather than on white, so the white cards read as
/// cards instead of dissolving into the page.
const _listGround = Color(0xFFF4F4F6);

enum _RankingScope {
  individuals('Individuel'),
  teams('Équipes');

  const _RankingScope(this.label);

  final String label;
}

class GlobalRankingScreen extends ConsumerStatefulWidget {
  const GlobalRankingScreen({super.key});

  @override
  ConsumerState<GlobalRankingScreen> createState() =>
      _GlobalRankingScreenState();
}

class _GlobalRankingScreenState extends ConsumerState<GlobalRankingScreen> {
  _RankingScope _scope = _RankingScope.individuals;

  Future<void> _refresh() async {
    ref.invalidate(globalRankingProvider);
    ref.invalidate(teamRankingProvider);
    try {
      await switch (_scope) {
        _RankingScope.individuals => ref.read(globalRankingProvider.future),
        _RankingScope.teams => ref.read(teamRankingProvider.future),
      };
    } catch (_) {
      // AsyncValueView already renders the failure and its retry button.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _listGround,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _ScopeSelector(
              current: _scope,
              onChanged: (scope) => setState(() => _scope = scope),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: KeyedSubtree(
                key: ValueKey(_scope),
                child: switch (_scope) {
                  _RankingScope.individuals => const _IndividualRanking(),
                  _RankingScope.teams => const _TeamRanking(),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({required this.current, required this.onChanged});

  final _RankingScope current;
  final ValueChanged<_RankingScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final animate = !MediaQuery.disableAnimationsOf(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final scope in _RankingScope.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(scope),
                child: AnimatedContainer(
                  duration: animate
                      ? const Duration(milliseconds: 220)
                      : Duration.zero,
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: scope == current
                        ? AppColors.black
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Semantics(
                    selected: scope == current,
                    child: Text(
                      scope.label,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scope == current
                            ? AppColors.white
                            : AppColors.secondaryText.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IndividualRanking extends ConsumerWidget {
  const _IndividualRanking();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalRanking = ref.watch(globalRankingProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return AsyncValueView<List<RankingEntry>>(
      value: globalRanking,
      onRetry: () => ref.invalidate(globalRankingProvider),
      emptyMessage:
          'Aucun classement pour le moment.\n'
          'Enregistrez une séance pour ouvrir le bal.',
      isEmpty: (rankingEntries) => rankingEntries.isEmpty,
      builder: (rankingEntries) =>
          _Leaderboard(entries: rankingEntries, currentUserId: currentUserId),
    );
  }
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.entries, required this.currentUserId});

  final List<RankingEntry> entries;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final leaderPoints = entries.first.totalPoints;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      // One extra row for the podium, which scrolls away with the list rather
      // than pinning a third of the screen while someone looks for their own
      // name further down.
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return RankingPodium(entries: entries, currentUserId: currentUserId);
        }

        final entryIndex = index - 1;
        final rankingEntry = entries[entryIndex];
        // From the left, in rank order: the leaderboard fills from the top
        // down, and the history enters from the opposite side so the two
        // lists never feel like the same screen.
        return SlideIn(
          fromLeft: true,
          delay: staggerFor(entryIndex),
          child: Padding(
            padding: EdgeInsets.only(top: entryIndex == 0 ? 12 : 0),
            child: RankingTile(
              rank: rankingEntry.currentRank ?? entryIndex + 1,
              entry: rankingEntry,
              leaderPoints: leaderPoints,
              isCurrentUser: rankingEntry.userId == currentUserId,
            ),
          ),
        );
      },
    );
  }
}

class _TeamRanking extends ConsumerWidget {
  const _TeamRanking();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamRanking = ref.watch(teamRankingProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return AsyncValueView<List<TeamRankingEntry>>(
      value: teamRanking,
      onRetry: () => ref.invalidate(teamRankingProvider),
      isEmpty: (entries) => entries.isEmpty,
      emptyMessage:
          'Aucune équipe pour le moment.\n'
          'Créez la vôtre depuis les réglages du profil.',
      builder: (entries) => _TeamLeaderboard(entries: entries, profile: profile),
    );
  }
}

class _TeamLeaderboard extends StatelessWidget {
  const _TeamLeaderboard({required this.entries, required this.profile});

  final List<TeamRankingEntry> entries;
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final leaderPoints = entries.first.totalPoints;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return const _TeamScoringNote();

        final entryIndex = index - 1;
        final entry = entries[entryIndex];
        return SlideIn(
          fromLeft: true,
          delay: staggerFor(entryIndex),
          child: TeamRankingTile(
            entry: entry,
            leaderPoints: leaderPoints,
            isMyTeam: entry.teamId == profile?.teamId,
            onTap: () => TeamDetailSheet.show(
              context,
              entry: entry,
              myTeamId: profile?.teamId,
            ),
          ),
        );
      },
    );
  }
}

/// Says what the team score counts, because it is not what people assume.
///
/// A team whose members all run alone sits on zero, and without a word of
/// explanation that reads as a bug rather than as the rule.
class _TeamScoringNote extends StatelessWidget {
  const _TeamScoringNote();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Seules les séances de sport collectif comptent : '
              'football et basket-ball.',
              style: textTheme.bodySmall?.copyWith(
                fontSize: 12,
                height: 1.35,
                color: AppColors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
