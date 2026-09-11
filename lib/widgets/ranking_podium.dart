import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/ranking_entry.dart';
import 'profile_avatar.dart';

const _firstBlockHeight = 96.0;
const _secondBlockHeight = 68.0;
const _thirdBlockHeight = 54.0;
const _slant = 14.0;

/// The top three, on the black ground the identity uses for headers.
///
/// Second sits left and third right of the winner, which is how a podium is
/// read, and the block heights carry the order so the shape says who won before
/// any number is read.
class RankingPodium extends StatelessWidget {
  const RankingPodium({
    super.key,
    required this.entries,
    required this.currentUserId,
  });

  /// The full ranking; only the first three are used.
  final List<RankingEntry> entries;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final first = entries.elementAtOrNull(0);
    final second = entries.elementAtOrNull(1);
    final third = entries.elementAtOrNull(2);

    if (first == null) return const SizedBox.shrink();

    return ColoredBox(
      color: AppColors.black,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _PodiumPlace(
                entry: second,
                place: 2,
                blockHeight: _secondBlockHeight,
                blockColour: AppColors.white.withValues(alpha: 0.10),
                avatarRadius: 30,
                slantUpToTheRight: true,
                isCurrentUser: second?.userId == currentUserId,
              ),
            ),
            Expanded(
              child: _PodiumPlace(
                entry: first,
                place: 1,
                blockHeight: _firstBlockHeight,
                blockColour: AppColors.primary,
                avatarRadius: 38,
                wearsCrown: true,
                slantUpToTheRight: true,
                isCurrentUser: first.userId == currentUserId,
              ),
            ),
            Expanded(
              child: _PodiumPlace(
                entry: third,
                place: 3,
                blockHeight: _thirdBlockHeight,
                blockColour: AppColors.white.withValues(alpha: 0.10),
                avatarRadius: 30,
                slantUpToTheRight: false,
                isCurrentUser: third?.userId == currentUserId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({
    required this.entry,
    required this.place,
    required this.blockHeight,
    required this.blockColour,
    required this.avatarRadius,
    required this.slantUpToTheRight,
    required this.isCurrentUser,
    this.wearsCrown = false,
  });

  /// Null while fewer than three people have entered the ranking: the block is
  /// dropped rather than shown empty, so a two-person leaderboard does not
  /// display a podium step nobody is standing on.
  final RankingEntry? entry;
  final int place;
  final double blockHeight;
  final Color blockColour;
  final double avatarRadius;
  final bool slantUpToTheRight;
  final bool isCurrentUser;
  final bool wearsCrown;

  @override
  Widget build(BuildContext context) {
    final person = entry;
    if (person == null) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (wearsCrown)
          const Icon(Icons.emoji_events, color: AppColors.primary, size: 18)
        else
          const SizedBox(height: 18),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isCurrentUser || wearsCrown
                ? Border.all(color: AppColors.primary, width: 3)
                : null,
          ),
          padding: const EdgeInsets.all(2),
          child: ProfileAvatar(
            name: person.name,
            avatarUrl: person.avatarUrl,
            radius: avatarRadius,
            highlighted: wearsCrown,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          person.shortName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${person.totalPoints}',
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ClipPath(
          clipper: _SlantedTopClipper(upToTheRight: slantUpToTheRight),
          child: Container(
            height: blockHeight,
            color: blockColour,
            alignment: Alignment.center,
            padding: EdgeInsets.only(top: _slant),
            child: Text(
              '$place',
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.white,
                fontSize: 26,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Angles the top edge of a block so the three steps lean into each other
/// instead of reading as three flat bars.
class _SlantedTopClipper extends CustomClipper<Path> {
  const _SlantedTopClipper({required this.upToTheRight});

  final bool upToTheRight;

  @override
  Path getClip(Size size) {
    final path = Path();
    if (upToTheRight) {
      path.moveTo(0, _slant);
      path.lineTo(size.width, 0);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, _slant);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_SlantedTopClipper oldClipper) =>
      oldClipper.upToTheRight != upToTheRight;
}
