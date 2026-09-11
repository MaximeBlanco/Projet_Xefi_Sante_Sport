import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/domain/sport_photo.dart';
import '../core/localization/app_locale.dart';
import '../core/theme/app_colors.dart';
import '../models/app_event.dart';

/// One upcoming event, as a photographic card.
///
/// The picture carries the card. A list of dated rows is what a calendar looks
/// like; something people are meant to want to turn up to has to look like an
/// invitation, so the sport's own photograph fills the card and the text sits
/// on a scrim over it.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.now});

  final AppEvent event;

  /// Passed in rather than read from the clock, so the countdown can be pinned
  /// in tests and every card on screen agrees on what "today" is.
  final DateTime now;

  static const width = 264.0;
  static const height = 188.0;

  String get _dateLabel {
    try {
      return DateFormat('EEE d MMM · HH:mm', AppLocale.french)
          .format(event.startsAt)
          .toUpperCase();
    } on Exception {
      return DateFormat('dd/MM · HH:mm').format(event.startsAt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final photo = SportPhoto.assetFor(event.externalActivityName);
    final countdown = event.countdownLabel(now);

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.black,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo != null)
            Image.asset(
              photo,
              fit: BoxFit.cover,
              // A missing asset must not take the card down with it; the
              // gradient below is a complete background on its own.
              errorBuilder: (context, error, stackTrace) =>
                  _KindBackdrop(kind: event.kind),
            )
          else
            _KindBackdrop(kind: event.kind),
          // Dark at the bottom where the text is, clear at the top where the
          // photograph is worth seeing.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.black.withValues(alpha: 0.15),
                  AppColors.black.withValues(alpha: 0.55),
                  AppColors.black.withValues(alpha: 0.92),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Chip(
                      label: event.kind.label.toUpperCase(),
                      background: AppColors.primary,
                      foreground: AppColors.white,
                    ),
                    const Spacer(),
                    if (countdown != null)
                      _Chip(
                        label: countdown.toUpperCase(),
                        background: AppColors.white.withValues(alpha: 0.18),
                        foreground: AppColors.white,
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  _dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 6),
                if (event.isFixture)
                  _Fixture(event: event)
                else
                  Text(
                    event.location ?? event.sportName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: AppColors.white.withValues(alpha: 0.65),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The two sides of a fixture, each with its team colour.
class _Fixture extends StatelessWidget {
  const _Fixture({required this.event});

  final AppEvent event;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Flexible(
          child: _Side(
            name: event.homeTeamName!,
            colour: event.homeTeamColour ?? AppColors.primary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            'VS',
            style: textTheme.bodySmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        Flexible(
          child: _Side(
            name: event.awayTeamName!,
            colour: event.awayTeamColour ?? AppColors.white,
          ),
        ),
      ],
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.name, required this.colour});

  final String name;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}

/// The background for an event with no photograph of its own.
///
/// The gaming nights are the case that matters: there is no licensed photo of a
/// CS match to bundle, and a grey box would make the one non-sport event on the
/// screen look like a failure to load.
class _KindBackdrop extends StatelessWidget {
  const _KindBackdrop({required this.kind});

  final EventKind kind;

  static const _gamingColours = [Color(0xFF1B1035), Color(0xFF3B1A5C)];
  static const _defaultColours = [Color(0xFF1C1C22), AppColors.black];

  @override
  Widget build(BuildContext context) {
    final isGaming = kind == EventKind.gaming;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isGaming ? _gamingColours : _defaultColours,
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(
          colour: (isGaming ? AppColors.primary : AppColors.white).withValues(
            alpha: 0.13,
          ),
        ),
        child: Align(
          alignment: const Alignment(0.75, -0.45),
          child: Icon(
            isGaming ? Icons.sports_esports : Icons.event_outlined,
            size: 64,
            color: AppColors.white.withValues(alpha: 0.16),
          ),
        ),
      ),
    );
  }
}

/// A faint diagonal grid, so a flat gradient still has something to catch.
class _GridPainter extends CustomPainter {
  const _GridPainter({required this.colour});

  static const _spacing = 22.0;

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colour
      ..strokeWidth = 1;

    for (var x = -size.height; x < size.width; x += _spacing) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.colour != colour;
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 9,
          letterSpacing: 0.9,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}
