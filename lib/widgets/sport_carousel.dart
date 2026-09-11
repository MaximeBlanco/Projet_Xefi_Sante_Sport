import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
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
          builder: (context, child) => _ScaledByDistance(
            controller: _controller,
            index: index,
            child: child!,
          ),
          child: _SportCard(
            sport: widget.sports[index],
            onTap: widget.enabled ? () => _goTo(index) : null,
          ),
        ),
      ),
    );
  }
}

/// Shrinks and fades a card the further it sits from the centre, so the choice
/// reads without a border or a tick mark.
class _ScaledByDistance extends StatelessWidget {
  const _ScaledByDistance({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Before the first layout the controller has no page, and the initial page
    // is the one that should look selected.
    final page = controller.positions.isEmpty || controller.page == null
        ? controller.initialPage.toDouble()
        : controller.page!;
    final distance = math.min((page - index).abs(), 1.0);

    return Transform.scale(
      scale: 1 - distance * 0.16,
      child: Opacity(opacity: 1 - distance * 0.45, child: child),
    );
  }
}

class _SportCard extends StatelessWidget {
  const _SportCard({required this.sport, required this.onTap});

  final Sport sport;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Semantics(
        button: true,
        label: sport.name,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.black.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(sport.emoji, style: const TextStyle(fontSize: 72)),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    sport.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
