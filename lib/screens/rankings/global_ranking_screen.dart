import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ranking_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ranking_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/motion.dart';
import '../../widgets/ranking_podium.dart';
import '../../widgets/ranking_tile.dart';

/// The list sits on a wash rather than on white, so the white cards read as
/// cards instead of dissolving into the page.
const _listGround = Color(0xFFF4F4F6);

class GlobalRankingScreen extends ConsumerWidget {
  const GlobalRankingScreen({super.key});

  Future<void> _refreshGlobalRanking(WidgetRef ref) async {
    ref.invalidate(globalRankingProvider);
    try {
      await ref.read(globalRankingProvider.future);
    } catch (_) {
      // AsyncValueView already renders the failure and its retry button.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalRanking = ref.watch(globalRankingProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return RefreshIndicator(
      onRefresh: () => _refreshGlobalRanking(ref),
      child: AsyncValueView<List<RankingEntry>>(
        value: globalRanking,
        onRetry: () => ref.invalidate(globalRankingProvider),
        emptyMessage:
            'Aucun classement pour le moment.\n'
            'Enregistrez une séance pour ouvrir le bal.',
        isEmpty: (rankingEntries) => rankingEntries.isEmpty,
        builder: (rankingEntries) => _Leaderboard(
          entries: rankingEntries,
          currentUserId: currentUserId,
        ),
      ),
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

    return ColoredBox(
      color: _listGround,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        // One extra row for the podium, which scrolls away with the list rather
        // than pinning a third of the screen while someone looks for their own
        // name further down.
        itemCount: entries.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return RankingPodium(
              entries: entries,
              currentUserId: currentUserId,
            );
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
      ),
    );
  }
}
