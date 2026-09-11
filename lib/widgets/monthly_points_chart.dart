import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/localization/app_locale.dart';
import '../core/theme/app_colors.dart';
import '../models/profile_stats.dart';

const _chartHeight = 96.0;

/// Points per month over the charted window, the current month in red.
///
/// Bars are drawn as a share of the best month rather than against a fixed
/// scale, so a quiet half-year still reads as a shape instead of six stubs.
class MonthlyPointsChart extends StatelessWidget {
  const MonthlyPointsChart({super.key, required this.months, required this.best});

  final List<MonthlyPoints> months;
  final int best;

  String _label(DateTime month) {
    try {
      return DateFormat('MMM', AppLocale.french).format(month);
    } on Exception {
      return '${month.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var index = 0; index < months.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _Bar(
                      points: months[index].points,
                      best: best,
                      isCurrentMonth: index == months.length - 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var index = 0; index < months.length; index++)
              Expanded(
                child: Text(
                  _label(months[index].month),
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: index == months.length - 1
                        ? AppColors.primary
                        : AppColors.secondaryText.withValues(alpha: 0.7),
                    fontWeight: index == months.length - 1
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.points,
    required this.best,
    required this.isCurrentMonth,
  });

  static const _minimumVisibleHeight = 6.0;

  final int points;
  final int best;
  final bool isCurrentMonth;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    // A month with no points keeps a sliver so the column still reads as a
    // month that happened, rather than as a gap in the chart.
    final share = best <= 0 ? 0.0 : points / best;
    final target = _minimumVisibleHeight +
        (_chartHeight - _minimumVisibleHeight) * share;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: animate ? 0 : target, end: target),
      duration: animate
          ? const Duration(milliseconds: 700)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, height, child) => Align(
        alignment: Alignment.bottomCenter,
        child: Semantics(
          label: '$points points',
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: isCurrentMonth
                  ? AppColors.primary
                  : AppColors.black.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}
