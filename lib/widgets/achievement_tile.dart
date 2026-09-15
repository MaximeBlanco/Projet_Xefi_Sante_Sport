import 'package:flutter/material.dart';

import '../core/domain/achievement.dart';
import '../core/theme/app_colors.dart';

/// One badge, earned or still to earn.
///
/// A locked badge is shown rather than hidden, and shows how far off it is: a
/// badge nobody can see is not a goal, it is a surprise, and a list of grey
/// tiles with real numbers on them is what makes the next one worth chasing.
class AchievementTile extends StatelessWidget {
  const AchievementTile({super.key, required this.progress});

  final AchievementProgress progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEarned = progress.isEarned;
    final achievement = progress.achievement;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEarned ? AppColors.black : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEarned
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.black.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isEarned
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : AppColors.black.withValues(alpha: 0.05),
                ),
                // Drained of colour rather than swapped for a padlock: the
                // badge stays recognisable, so earning it reads as the same
                // thing lighting up.
                child: _Emoji(achievement.emoji, isEarned: isEarned),
              ),
              const Spacer(),
              if (isEarned)
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            achievement.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isEarned ? AppColors.white : AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            achievement.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 11,
              height: 1.3,
              color: isEarned
                  ? AppColors.white.withValues(alpha: 0.55)
                  : AppColors.secondaryText.withValues(alpha: 0.55),
            ),
          ),
          const Spacer(),
          if (isEarned)
            // The earned tile would otherwise sit half empty next to a locked
            // one carrying a bar and a count, which reads as a tile missing
            // something rather than as a tile that is finished.
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 13,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  'Débloqué',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.primary,
                  ),
                ),
              ],
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress.progress,
                minHeight: 4,
                backgroundColor: AppColors.black.withValues(alpha: 0.07),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${progress.value} / ${achievement.target}',
              style: textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryText.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Emoji extends StatelessWidget {
  const _Emoji(this.emoji, {required this.isEarned});

  final String emoji;
  final bool isEarned;

  @override
  Widget build(BuildContext context) {
    final glyph = Text(emoji, style: const TextStyle(fontSize: 19));
    if (isEarned) return glyph;

    return Opacity(
      opacity: 0.45,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0, 0, 0, 1, 0, //
        ]),
        child: glyph,
      ),
    );
  }
}
