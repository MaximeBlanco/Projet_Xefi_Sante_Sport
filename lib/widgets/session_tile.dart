import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/domain/session_duration.dart';
import '../core/localization/app_locale.dart';
import '../core/theme/app_colors.dart';
import '../models/session.dart';

const String _unknownSportName = 'Sport inconnu';
const String _missingValuePlaceholder = '—';

/// [DateFormat] throws when the French locale data has not been loaded by the
/// app entry point, so the tile degrades to a numeric date instead of failing.
DateFormat _buildSessionDateFormat() {
  try {
    return DateFormat('EEE d MMMM', AppLocale.french);
  } on Exception {
    return DateFormat('dd/MM/yyyy');
  }
}

final DateFormat _sessionDateFormat = _buildSessionDateFormat();

class SessionTile extends StatelessWidget {
  const SessionTile({
    super.key,
    required this.session,
    this.margin,
    this.onTap,
  });

  final Session session;

  /// Lists own their own gutter, so a screen that already pads its content
  /// passes [EdgeInsets.zero] rather than inheriting a second inset.
  final EdgeInsetsGeometry? margin;

  final VoidCallback? onTap;

  bool get _hasRoute => (session.route?.length ?? 0) > 1;

  /// The "≈" marks a value the app worked out itself from the sport's MET
  /// because the calories provider could not answer, so an estimate never
  /// passes for a measured figure.
  String get _caloriesLabel {
    final caloriesBurned = session.caloriesBurned;
    if (caloriesBurned == null) return _missingValuePlaceholder;
    final rounded = '${caloriesBurned.round()} kcal';
    return session.caloriesEstimated ? '≈ $rounded' : rounded;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final distanceKm = session.distanceKm;
    final venue = session.venue;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryText.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      // Transparent so the card keeps its own white and its shadow, and the ink
      // still lands above that white instead of under it.
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _sessionDateFormat
                                .format(session.date)
                                .toUpperCase(),
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText.withValues(
                                alpha: 0.65,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (session.sport != null) ...[
                                Text(
                                  session.sport!.emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  session.sport?.name ?? _unknownSportName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _PointsPill(points: session.points),
                        if (_hasRoute) ...[
                          const SizedBox(height: 8),
                          Icon(
                            Icons.map_outlined,
                            size: 18,
                            color: AppColors.secondaryText.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.black.withValues(alpha: 0.06),
                ),
                const SizedBox(height: 14),
                // Wrapped rather than a fixed row: a third metric appears only
                // on GPS-tracked sessions, and three of them do not fit a
                // narrow screen side by side.
                Wrap(
                  spacing: 28,
                  runSpacing: 12,
                  children: [
                    _Metric(
                      value: SessionDuration.describeMinutes(
                        session.durationMin,
                      ),
                      label: 'Durée',
                    ),
                    _Metric(value: _caloriesLabel, label: 'Dépense'),
                    if (distanceKm != null)
                      _Metric(
                        value: '${distanceKm.toStringAsFixed(2)} km',
                        label: 'Distance',
                      ),
                  ],
                ),
                // On its own line: a venue name is the one value here that can
                // be long, and beside the metrics it truncated to "La bulle …".
                if (venue != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 15,
                        color: AppColors.secondaryText.withValues(alpha: 0.65),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          venue.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PointsPill extends StatelessWidget {
  const _PointsPill({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '+$points pts',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

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
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: textTheme.bodySmall?.copyWith(
            fontSize: 10,
            letterSpacing: 0.8,
            color: AppColors.secondaryText.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}
