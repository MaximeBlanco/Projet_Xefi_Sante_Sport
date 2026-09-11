import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/domain/member_level.dart';
import '../core/localization/app_locale.dart';
import '../core/theme/app_colors.dart';
import '../models/profile.dart';
import '../models/profile_stats.dart';
import 'profile_avatar.dart';
import 'xefi_logo.dart';

/// The member card: identity, standing and level, on the black the identity
/// uses for headers.
class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.profile,
    required this.stats,
    required this.onTapAvatar,
  });

  final Profile profile;
  final ProfileStats stats;
  final VoidCallback? onTapAvatar;

  String get _memberSince {
    try {
      return DateFormat('MMMM yyyy', AppLocale.french).format(profile.createdAt);
    } on Exception {
      return DateFormat('MM/yyyy').format(profile.createdAt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final level = MemberLevel.fromPoints(stats.totalPoints);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CARTE MEMBRE',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const XefiLogo(variant: XefiLogoVariant.light, height: 14),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              GestureDetector(
                onTap: onTapAvatar,
                child: ProfileAvatar(
                  name: profile.name,
                  avatarUrl: profile.avatarUrl,
                  radius: 32,
                  discColour: AppColors.primary,
                  initialsColour: AppColors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.white,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stats.favouriteSport == null
                          ? 'Aucun sport favori pour le moment'
                          : 'Sport favori · ${stats.favouriteSport!.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: AppColors.white.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _CardStat(label: 'Depuis', value: _memberSince),
              const SizedBox(width: 28),
              _CardStat(
                label: 'Série',
                value: stats.currentStreakDays == 1
                    ? '1 jour'
                    : '${stats.currentStreakDays} jours',
              ),
              const SizedBox(width: 28),
              _CardStat(label: 'Total', value: '${stats.totalPoints} pts'),
            ],
          ),
          const SizedBox(height: 18),
          _LevelBar(level: level),
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  const _CardStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: textTheme.bodySmall?.copyWith(
            fontSize: 9,
            letterSpacing: 1,
            color: AppColors.white.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.level});

  final MemberLevel level;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'NIVEAU ${level.number} · ${level.title.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                '${level.pointsToNextLevel} pts restants',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: level.progress,
              minHeight: 5,
              backgroundColor: AppColors.white.withValues(alpha: 0.14),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
