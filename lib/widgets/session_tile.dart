import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/localization/app_locale.dart';
import '../core/theme/app_colors.dart';
import '../models/session.dart';

const String _unknownSportEmoji = '🏅';
const String _unknownSportName = 'Sport inconnu';
const String _missingValuePlaceholder = '—';

/// [DateFormat] throws when the French locale data has not been loaded by the
/// app entry point, so the tile degrades to a numeric date instead of failing.
DateFormat _buildSessionDateFormat() {
  try {
    return DateFormat('dd MMMM yyyy', AppLocale.french);
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
  final VoidCallback? onTap;

  bool get _hasRoute => (session.route?.length ?? 0) > 1;

  /// Lists own their own gutter, so a screen that already pads its content
  /// passes [EdgeInsets.zero] rather than inheriting a second inset.
  final EdgeInsetsGeometry? margin;

  /// The "≈" marks a value the app computed itself from the sport's MET because
  /// the calories provider could not answer, so it never passes for a measured one.
  String get _caloriesLabel {
    final caloriesBurned = session.caloriesBurned;
    if (caloriesBurned == null) {
      return '$_missingValuePlaceholder kcal';
    }
    final rounded = '${caloriesBurned.round()} kcal';
    return session.caloriesEstimated ? '≈ $rounded' : rounded;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sport = session.sport;
    final distanceKm = session.distanceKm;

    return Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sport?.emoji ?? _unknownSportEmoji,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sport?.name ?? _unknownSportName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _sessionDateFormat.format(session.date),
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        _SessionMetric(
                          icon: Icons.schedule,
                          label: '${session.durationMin} min',
                        ),
                        _SessionMetric(
                          icon: Icons.local_fire_department_outlined,
                          label: _caloriesLabel,
                        ),
                        if (distanceKm != null)
                          _SessionMetric(
                            icon: Icons.route_outlined,
                            label: '${distanceKm.toStringAsFixed(2)} km',
                          ),
                        // Last, and on its own line when it has to be: a venue
                        // name is the one value here that can be long, and
                        // squeezing it next to the date truncated it to
                        // "La bulle …".
                        if (session.venue != null)
                          _SessionMetric(
                            icon: Icons.place_outlined,
                            label: session.venue!.name,
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
                  _PointsBadge(points: session.points),
                  if (_hasRoute) ...[
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.map_outlined,
                      size: 18,
                      color: AppColors.secondaryText,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionMetric extends StatelessWidget {
  const _SessionMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const ShapeDecoration(
        color: AppColors.black,
        shape: StadiumBorder(),
      ),
      child: Text(
        '$points pts',
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}
