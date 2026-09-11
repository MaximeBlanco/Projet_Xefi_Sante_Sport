import 'package:flutter/material.dart';

import '../core/domain/session_duration.dart';
import '../core/theme/app_colors.dart';
import '../models/profile_stats.dart';
import '../models/weekly_health.dart';

/// The small health readings under the weekly goal.
///
/// Every one of these is derived from sessions the user actually logged. The
/// app has no step counter, no heart rate and no sleep data, so nothing here
/// pretends to: a dashboard of numbers the phone cannot measure would look
/// richer and mean nothing.
class HealthWidgets extends StatelessWidget {
  const HealthWidgets({super.key, required this.health, required this.stats});

  final WeeklyHealth health;
  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final favourite = stats.favouriteSport;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HealthTile(
                icon: Icons.calendar_today_outlined,
                label: 'Jours actifs',
                value: '${health.activeDayCount}',
                unit: '/ ${WeeklyHealth.daysPerWeek}',
                // The guidance asks for the week's minutes to be spread, not
                // piled into one session, so this reads as met or not on its
                // own terms rather than as a share of the minutes goal.
                isGood: health.isSpreadAcrossWeek,
                caption: health.isSpreadAcrossWeek
                    ? 'Bien réparti'
                    : 'À étaler sur la semaine',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HealthTile(
                icon: Icons.local_fire_department_outlined,
                label: 'Série',
                value: '${stats.currentStreakDays}',
                unit: stats.currentStreakDays > 1 ? 'jours' : 'jour',
                isGood: stats.currentStreakDays > 0,
                caption: stats.currentStreakDays > 0
                    ? 'En cours'
                    : 'À relancer',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _HealthTile(
                icon: Icons.timer_outlined,
                label: 'Séance moyenne',
                value: SessionDuration.describeMinutes(
                  stats.averageDurationMin,
                ),
                // Thirty minutes is the daily figure the weekly recommendation
                // works out to across five days.
                isGood: stats.averageDurationMin >= 30,
                caption: stats.averageDurationMin >= 30
                    ? 'Bonne durée'
                    : 'Visez 30 min',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HealthTile(
                icon: Icons.favorite_outline,
                label: 'Sport favori',
                value: favourite?.emoji ?? '—',
                isGood: favourite != null,
                caption: favourite?.label ?? 'Pas encore de séance',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HealthTile extends StatelessWidget {
  const _HealthTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isGood,
    required this.caption,
    this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final bool isGood;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: isGood
                    ? AppColors.primary
                    : AppColors.secondaryText.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryText.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                    color: AppColors.black,
                  ),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.secondaryText.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isGood
                  ? AppColors.primary
                  : AppColors.secondaryText.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
