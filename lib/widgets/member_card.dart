import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/domain/member_level.dart';
import '../core/localization/app_locale.dart';
import '../core/theme/app_colors.dart';
import '../models/profile.dart';
import '../models/profile_stats.dart';
import 'profile_avatar.dart';
import 'xefi_logo.dart';

/// The proportions of a bank card: ISO/IEC 7810 ID-1, 85.60 mm by 53.98 mm.
///
/// Using the real ratio rather than a rounded 1.6 is what makes the thing read
/// as a card you could put in a wallet instead of as a wide box.
const _cardAspectRatio = 85.60 / 53.98;

/// How far the card may lean, in radians.
///
/// Around seventeen degrees: enough for the light to travel across the face and
/// for the card to feel like an object, nowhere near the ninety degrees that
/// would turn it edge-on and start showing its back.
const _maximumTilt = 0.30;

/// The member card, which leans under the finger.
///
/// Every size inside is derived from the card's own height rather than fixed in
/// pixels. The card takes its height from the width it is given, so a phone and
/// a tablet hand it very different heights, and anything fixed would either
/// overflow on the small one or float in the middle of the large one.
class MemberCard extends StatefulWidget {
  const MemberCard({
    super.key,
    required this.profile,
    required this.stats,
    required this.onTapAvatar,
  });

  final Profile profile;
  final ProfileStats stats;
  final VoidCallback? onTapAvatar;

  @override
  State<MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<MemberCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    // Starts settled, so the card is flat until a finger touches it.
    value: 1,
  );

  late final Animation<double> _settleCurve = CurvedAnimation(
    parent: _settle,
    curve: Curves.elasticOut,
  );

  Offset _pointerTilt = Offset.zero;
  Offset _releasedFrom = Offset.zero;
  bool _isHeld = false;

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  /// Maps where the finger is on the card to how the card leans.
  ///
  /// Absolute position rather than accumulated movement: touching the right
  /// edge tips the right edge away, which is how a physical card answers a
  /// finger, and it cannot drift out of step over a long drag.
  void _leanTowards(Offset local, Size size) {
    if (size.isEmpty) return;
    final fromCentreX = (local.dx / size.width - 0.5) * 2;
    final fromCentreY = (local.dy / size.height - 0.5) * 2;

    setState(() {
      _isHeld = true;
      _pointerTilt = Offset(
        fromCentreX.clamp(-1.0, 1.0) * _maximumTilt,
        -fromCentreY.clamp(-1.0, 1.0) * _maximumTilt,
      );
    });
    _settle.stop();
  }

  void _release() {
    if (!_isHeld) return;
    setState(() {
      _releasedFrom = _pointerTilt;
      _isHeld = false;
    });

    if (MediaQuery.disableAnimationsOf(context)) {
      _settle.value = 1;
      return;
    }
    _settle.forward(from: 0);
  }

  Offset get _tilt {
    if (_isHeld) return _pointerTilt;
    return Offset.lerp(_releasedFrom, Offset.zero, _settleCurve.value)!;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _cardAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;

          // A raw Listener rather than a GestureDetector: it reads the pointer
          // without claiming it, so the card can lean while the page underneath
          // still scrolls. Competing for the gesture would have made the one
          // widget at the top of the profile the one place you cannot scroll
          // from.
          return Listener(
            behavior: HitTestBehavior.deferToChild,
            onPointerDown: (event) => _leanTowards(event.localPosition, size),
            onPointerMove: (event) => _leanTowards(event.localPosition, size),
            onPointerUp: (_) => _release(),
            onPointerCancel: (_) => _release(),
            child: AnimatedBuilder(
              animation: _settleCurve,
              builder: (context, child) {
                final tilt = _tilt;

                return Transform(
                  alignment: Alignment.center,
                  // The perspective entry is what makes the near edge grow and
                  // the far edge shrink; without it the card merely squashes.
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0014)
                    ..rotateX(tilt.dy)
                    ..rotateY(tilt.dx),
                  child: _CardFront(
                    profile: widget.profile,
                    stats: widget.stats,
                    onTapAvatar: widget.onTapAvatar,
                    tilt: tilt,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({
    required this.profile,
    required this.stats,
    required this.onTapAvatar,
    required this.tilt,
  });

  final Profile profile;
  final ProfileStats stats;
  final VoidCallback? onTapAvatar;
  final Offset tilt;

  String get _memberSince {
    try {
      return DateFormat('MMM yyyy', AppLocale.french).format(profile.createdAt);
    } on Exception {
      return DateFormat('MM/yyyy').format(profile.createdAt);
    }
  }

  /// The head of the real account id, in the groups a card number is read in.
  ///
  /// It is not a number we made up: it is the identifier the account already
  /// has, shortened to the part a person could reasonably read out.
  String get _memberNumber {
    final compact = profile.id.replaceAll('-', '').toUpperCase();
    final head = compact.length >= 12 ? compact.substring(0, 12) : compact;
    return [
      for (var start = 0; start < head.length; start += 4)
        head.substring(start, math.min(start + 4, head.length)),
    ].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final level = MemberLevel.fromPoints(stats.totalPoints);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height * 0.075),
            // Brushed metal rather than a flat black: several stops rather than
            // two, alternating slightly lighter and darker across the diagonal,
            // which is what makes a surface read as polished instead of
            // printed. Kept close to black so it stays the identity's black.
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3A3A44),
                Color(0xFF15151A),
                Color(0xFF2E2E38),
                Color(0xFF0B0B0E),
                Color(0xFF232329),
              ],
              stops: [0, 0.28, 0.52, 0.78, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.28),
                blurRadius: 22,
                // The shadow slides the other way from the lean, which is what
                // makes the card look lifted off the page rather than printed
                // on it.
                offset: Offset(tilt.dx * -40, 10 + tilt.dy * 30),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: height * 0.085,
                  vertical: height * 0.075,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'CARTE MEMBRE',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontSize: (height * 0.047).clamp(8.0, 12.0),
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        XefiLogo(
                          variant: XefiLogoVariant.light,
                          height: (height * 0.068).clamp(11.0, 18.0),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onTapAvatar,
                          child: ProfileAvatar(
                            name: profile.name,
                            avatarUrl: profile.avatarUrl,
                            radius: (height * 0.115).clamp(16.0, 34.0),
                            discColour: AppColors.primary,
                            initialsColour: AppColors.white,
                          ),
                        ),
                        SizedBox(width: height * 0.065),
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
                                  fontSize: (height * 0.092).clamp(14.0, 24.0),
                                ),
                              ),
                              SizedBox(height: height * 0.01),
                              Text(
                                stats.favouriteSport == null
                                    ? 'Aucun sport favori pour le moment'
                                    : 'Sport favori · ${stats.favouriteSport!.label}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: (height * 0.055).clamp(9.0, 13.0),
                                  color: AppColors.white.withValues(
                                    alpha: 0.55,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _EngravedField(
                            label: 'N° MEMBRE',
                            value: _memberNumber,
                            height: height,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(width: height * 0.05),
                        _EngravedField(
                          label: 'DEPUIS',
                          value: _memberSince,
                          height: height,
                        ),
                      ],
                    ),
                    const Spacer(),
                    _LevelBar(level: level, height: height),
                  ],
                ),
              ),
              // The sheen travels with the lean, which is the cue that sells a
              // flat rectangle as something catching the light.
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(
                        (-tilt.dx / _maximumTilt) - 0.4,
                        (tilt.dy / _maximumTilt) - 0.4,
                      ),
                      end: Alignment(
                        (-tilt.dx / _maximumTilt) + 0.8,
                        (tilt.dy / _maximumTilt) + 0.8,
                      ),
                      colors: [
                        AppColors.white.withValues(alpha: 0),
                        AppColors.white.withValues(alpha: 0.05),
                        AppColors.white.withValues(alpha: 0.16),
                        AppColors.white.withValues(alpha: 0.05),
                        AppColors.white.withValues(alpha: 0),
                      ],
                      // A narrow bright band with a soft skirt: a single wide
                      // fade reads as a wash, a hard edge as a stripe, and only
                      // the band between them looks like light on metal.
                      stops: const [0.3, 0.44, 0.5, 0.56, 0.7],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A label above a value, in the flat type a card is embossed with.
class _EngravedField extends StatelessWidget {
  const _EngravedField({
    required this.label,
    required this.value,
    required this.height,
    this.letterSpacing = 0.5,
  });

  final String label;
  final String value;
  final double height;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.white.withValues(alpha: 0.38),
            fontSize: (height * 0.038).clamp(6.5, 10.0),
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: height * 0.012),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.white,
            fontSize: (height * 0.06).clamp(10.0, 16.0),
            fontWeight: FontWeight.w700,
            letterSpacing: letterSpacing,
          ),
        ),
      ],
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.level, required this.height});

  final MemberLevel level;
  final double height;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 2.5,
              height: height * 0.055,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: height * 0.035),
            Expanded(
              child: Text(
                'NIVEAU ${level.number} · ${level.title.toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                  fontSize: (height * 0.055).clamp(9.0, 14.0),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text(
              '${level.pointsToNextLevel} pts restants',
              style: textTheme.bodySmall?.copyWith(
                fontSize: (height * 0.047).clamp(8.0, 12.0),
                color: AppColors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        SizedBox(height: height * 0.04),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: level.progress,
            minHeight: (height * 0.022).clamp(3.0, 6.0),
            backgroundColor: AppColors.white.withValues(alpha: 0.14),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
