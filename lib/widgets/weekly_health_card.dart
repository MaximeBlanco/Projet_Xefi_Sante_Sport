import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/weekly_health.dart';

const _ringSize = 72.0;
const _ringStroke = 7.0;
const _weekdayInitials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// The weekly health goal, shown next to the competitive score.
class WeeklyHealthCard extends StatelessWidget {
  const WeeklyHealthCard({super.key, required this.health});

  final WeeklyHealth health;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GoalRing(health: health),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Objectif santé',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _headline,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                _WeekDots(health: health),
                const SizedBox(height: 8),
                Text(
                  'OMS : 150 à 300 min par semaine, réparties sur plusieurs jours',
                  style: textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _headline {
    if (health.isGoalReached) {
      return health.isSpreadAcrossWeek
          ? 'Objectif atteint, et bien réparti sur la semaine.'
          : 'Objectif atteint. Répartissez sur plus de jours la prochaine fois.';
    }
    if (health.activeMinutes == 0) {
      return 'Aucune séance cette semaine pour le moment.';
    }
    return 'Encore ${health.remainingMinutes} min cette semaine.';
  }
}

class _GoalRing extends StatelessWidget {
  const _GoalRing({required this.health});

  final WeeklyHealth health;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: animate ? 0 : health.progress,
        end: health.progress,
      ),
      duration: animate ? const Duration(milliseconds: 900) : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => SizedBox(
        width: _ringSize,
        height: _ringSize,
        child: CustomPaint(
          painter: _RingPainter(progress: progress),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${health.activeMinutes}',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontSize: 20, height: 1),
                ),
                Text(
                  '/ ${WeeklyHealth.goalMinutes}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - _ringStroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.black.withValues(alpha: 0.08);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary;

    canvas.drawCircle(center, radius, track);
    if (progress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Seven dots, Monday first: the shape of the week at a glance, which a single
/// total cannot show.
class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.health});

  final WeeklyHealth health;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        for (var index = 0; index < WeeklyHealth.daysPerWeek; index++)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: ShapeDecoration(
                    shape: const CircleBorder(),
                    color: health.isDayActive(index)
                        ? AppColors.primary
                        : AppColors.black.withValues(alpha: 0.12),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _weekdayInitials[index],
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: health.isDayActive(index)
                        ? AppColors.black
                        : AppColors.secondaryText,
                    fontWeight: health.isDayActive(index)
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
