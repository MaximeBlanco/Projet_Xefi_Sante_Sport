import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/session_duration.dart';
import '../../core/theme/app_colors.dart';
import '../../models/home_summary.dart';
import '../../providers/home_summary_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/session_tile.dart';
import '../../widgets/xefi_backdrop.dart';
import '../sessions/record_session_screen.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  void _openRecordSession(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (context) => const RecordSessionScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(homeSummaryProvider);

    return RefreshIndicator(
      onRefresh: () => refreshHomeSummary(ref),
      child: AsyncValueView<HomeSummary>(
        value: summary,
        onRetry: () => ref.invalidate(homeSummaryProvider),
        builder: (data) => XefiBackdrop(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            children: [
              FadeSlideIn(child: _Greeting(name: data.greetingName)),
              const SizedBox(height: 40),
              FadeSlideIn(
                delay: const Duration(milliseconds: 90),
                child: _PointsHeadline(summary: data),
              ),
              const SizedBox(height: 40),
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: _StatsRow(summary: data),
              ),
              const SizedBox(height: 40),
              FadeSlideIn(
                delay: const Duration(milliseconds: 270),
                child: ElevatedButton(
                  onPressed: () => _openRecordSession(context),
                  child: const Text('Enregistrer une séance'),
                ),
              ),
              if (data.lastSession != null)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 360),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      const _SectionLabel('Dernière séance'),
                      const SizedBox(height: 12),
                      SessionTile(
                        session: data.lastSession!,
                        margin: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bonjour', style: textTheme.bodyLarge),
        const SizedBox(height: 2),
        Text(
          name,
          style: textTheme.headlineMedium?.copyWith(fontSize: 30),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// The score is the one number the whole app is about, so it is the only thing
/// on screen allowed to be large.
class _PointsHeadline extends StatelessWidget {
  const _PointsHeadline({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AnimatedCounter(
              value: summary.totalPoints,
              style: textTheme.headlineLarge?.copyWith(
                fontSize: 68,
                height: 1,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('points', style: textTheme.bodyLarge),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (summary.rankLabel != null)
          _RankBadge(
            rankLabel: summary.rankLabel!,
            participantCount: summary.participantCount,
          )
        else
          Text(
            'Enregistrez une séance pour entrer au classement.',
            style: textTheme.bodyMedium,
          ),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rankLabel, required this.participantCount});

  final String rankLabel;
  final int participantCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: const ShapeDecoration(
        color: AppColors.primary,
        shape: StadiumBorder(),
      ),
      child: Text(
        '$rankLabel sur $participantCount',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Stat(
            value: '${summary.sessionCount}',
            label: summary.sessionCount > 1 ? 'séances' : 'séance',
          ),
        ),
        const _StatDivider(),
        Expanded(
          child: _Stat(
            value: SessionDuration.describeMinutes(summary.totalDurationMin),
            label: 'de sport',
          ),
        ),
        const _StatDivider(),
        Expanded(
          child: _Stat(
            value: summary.hasCaloriesData
                ? '${summary.totalCaloriesBurned.round()}'
                : '—',
            label: 'kcal',
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(fontSize: 22),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.black.withValues(alpha: 0.10),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
    );
  }
}
