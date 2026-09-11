import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/app_colors.dart';
import 'xefi_logo.dart';

/// The branded background: a soft red wash in one corner and an oversized
/// chevron watermark.
///
/// Both sit at a few percent opacity on purpose. The brief was a clean screen
/// where the score is the only thing competing for attention, and the visual
/// identity reserves #E10600 for calls to action — a background that reads as
/// red would take that meaning away from the buttons.
class XefiBackdrop extends StatelessWidget {
  const XefiBackdrop({super.key, required this.child, this.showMark = true});

  final Widget child;
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _CornerWash()),
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

class _CornerWash extends StatelessWidget {
  const _CornerWash();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(1.15, -1.0),
            radius: 0.85,
            colors: [
              AppColors.primary.withValues(alpha: 0.09),
              AppColors.primary.withValues(alpha: 0.015),
              AppColors.white.withValues(alpha: 0),
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
      ),
    );
  }
}
