import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ranking_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ranking_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/ranking_tile.dart';
import '../../widgets/motion.dart';

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
        emptyMessage: 'Aucun classement pour le moment.\nEnregistrez une séance pour ouvrir le bal.',
        isEmpty: (rankingEntries) => rankingEntries.isEmpty,
        builder: (rankingEntries) => ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: rankingEntries.length,
          itemBuilder: (context, index) {
            final rankingEntry = rankingEntries[index];
            // From the left, in rank order: the leaderboard fills from the
            // top down, and the history enters from the opposite side so the
            // two lists never feel like the same screen.
            return SlideIn(
              fromLeft: true,
              delay: staggerFor(index),
              child: RankingTile(
                rank: index + 1,
                entry: rankingEntry,
                isCurrentUser: rankingEntry.userId == currentUserId,
              ),
            );
          },
        ),
      ),
    );
  }
}
