import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/app_colors.dart';
import 'xefi_logo.dart';

/// The branded background: soft blurred colour fields and a chevron watermark.
///
/// The whole background is blurred once, as a single static layer, rather than
/// giving each card its own [BackdropFilter]. A filter per card would sample
/// the layers beneath it on every frame, which a scrolling list makes expensive
/// for an effect nobody would be able to tell apart.
///
/// Everything stays at a few percent opacity: the visual identity reserves
/// #E10600 for calls to action, and a background that read as red would take
/// that meaning away from the buttons.
class XefiBackdrop extends StatelessWidget {
  const XefiBackdrop({super.key, required this.child, this.showMark = true});

  final Widget child;
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: const _ColourFields(),
            ),
          ),
        ),
        if (showMark)
          Positioned(
            // Small enough to stay a corner ornament: at full width its
            // diagonal edge cuts straight across the content.
            top: -18,
            right: -46,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.05,
                child: SvgPicture.asset(
                  XefiLogoVariant.mark.assetPath,
                  height: 170,
                  width: 170 * XefiLogoVariant.mark.aspectRatio,
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}

class _ColourFields extends StatelessWidget {
  const _ColourFields();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        color: AppColors.white,
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -90,
              child: _Blob(
                size: 360,
                colour: AppColors.primary.withValues(alpha: 0.22),
              ),
            ),
            Positioned(
              top: 220,
              left: -140,
              child: _Blob(
                size: 300,
                colour: AppColors.secondaryText.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              bottom: -160,
              right: -60,
              child: _Blob(
                size: 320,
                colour: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.colour});

  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(shape: const CircleBorder(), color: colour),
    );
  }
}

/// A translucent surface that lifts off the blurred background.
///
/// Deliberately not a [BackdropFilter]: over a background that is already
/// blurred, a white veil plus a hairline edge reads as frosted glass, and it
/// costs a rectangle instead of a full-screen sample per card per frame.
class FrostedPanel extends StatelessWidget {
  const FrostedPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 18,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  /// Overrides the neutral veil, for a panel that should carry the accent.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tint ?? AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryText.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
