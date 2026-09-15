import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/domain/sport_photo.dart';
import '../models/sport.dart';

const _cardHeight = 208.0;
const _viewportFraction = 0.58;

/// A deck of sport cards the user slides through, replacing a dropdown.
///
/// A dropdown hides every option behind a tap and shows them as a list of
/// words. Sport is a visual choice, so the cards put the emblem front and
/// centre and let the neighbours peek in, which says "there are others" without
/// a second interaction. The centred card is the selection: there is no
/// separate confirm step, and therefore no unselected state to validate.
class SportCarousel extends StatefulWidget {
  const SportCarousel({
    super.key,
    required this.sports,
    required this.onSportSelected,
    this.enabled = true,
  });

  final List<Sport> sports;
  final ValueChanged<Sport> onSportSelected;
  final bool enabled;

  @override
  State<SportCarousel> createState() => _SportCarouselState();
}

class _SportCarouselState extends State<SportCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: _viewportFraction,
  );

  @override
  void initState() {
    super.initState();
    // The centred card is already the answer, so the form starts valid rather
    // than starting wrong and waiting to be corrected.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.sports.isNotEmpty) {
        widget.onSportSelected(widget.sports.first);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePageChanged(int index) {
    HapticFeedback.selectionClick();
    widget.onSportSelected(widget.sports[index]);
  }

  /// 0 at the centre, 1 a full card away or more. Before the first layout the
  /// controller has no page, and the initial card is the one that should look
  /// selected.
  double _distanceFromCentre(int index) {
    final page = _controller.positions.isEmpty || _controller.page == null
        ? _controller.initialPage.toDouble()
        : _controller.page!;
    return math.min((page - index).abs(), 1.0);
  }

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardHeight,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.sports.length,
        physics: widget.enabled
            ? const BouncingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        onPageChanged: widget.enabled ? _handlePageChanged : null,
        itemBuilder: (context, index) => AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final distance = _distanceFromCentre(index);
            return Transform.scale(
              scale: 1 - distance * 0.16,
              child: Opacity(
                opacity: 1 - distance * 0.35,
                child: _SportCard(
                  sport: widget.sports[index],
                  // Full colour only at the centre: the neighbours drain to
                  // greyscale, which both marks the selection and stops eight
                  // unrelated photographs from fighting each other.
                  colourAmount: 1 - distance,
                  onTap: widget.enabled ? () => _goTo(index) : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Photograph filling the card, with the name over a scrim.
///
/// The emoji stays as the fallback: two of the ten sports have no photograph
/// that was fit to ship, and a card with a missing image would read as broken
/// where a large emoji reads as a choice.
class _SportCard extends StatelessWidget {
  const _SportCard({
    required this.sport,
    required this.colourAmount,
    required this.onTap,
  });

  final Sport sport;
  final double colourAmount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final photo = SportPhoto.assetFor(sport.externalActivityName);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Semantics(
        button: true,
        label: sport.name,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photo != null)
                    ColorFiltered(
                      colorFilter: ColorFilter.matrix(
                        _saturationMatrix(colourAmount),
                      ),
                      child: Image.asset(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _EmojiBackdrop(emoji: sport.emoji),
                      ),
                    )
                  else
                    _EmojiBackdrop(emoji: sport.emoji),
                  const _NameScrim(),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Text(
                        sport.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              shadows: const [
                                Shadow(blurRadius: 6, color: Colors.black54),
                              ],
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiBackdrop extends StatelessWidget {
  const _EmojiBackdrop({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.black.withValues(alpha: 0.05),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 72))),
    );
  }
}

/// Keeps the name readable whatever the photograph does underneath it.
class _NameScrim extends StatelessWidget {
  const _NameScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.center,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
    );
  }
}

/// Interpolates between greyscale at 0 and the untouched image at 1, using the
/// luminance weights of the sRGB colour space so the grey keeps the perceived
/// brightness of the original.
List<double> _saturationMatrix(double amount) {
  const lumR = 0.2126;
  const lumG = 0.7152;
  const lumB = 0.0722;
  final s = amount.clamp(0.0, 1.0);
  final invR = (1 - s) * lumR;
  final invG = (1 - s) * lumG;
  final invB = (1 - s) * lumB;

  return <double>[
    invR + s,
    invG,
    invB,
    0,
    0,
    invR,
    invG + s,
    invB,
    0,
    0,
    invR,
    invG,
    invB + s,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}
