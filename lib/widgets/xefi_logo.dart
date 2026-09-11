import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/app_colors.dart';

/// The official XEFI logo, taken from xefi.fr.
///
/// Two variants ship because the wordmark is near-white and disappears on the
/// light background; the red chevron is identical in both and is the exact
/// #E10600 of the brand. [XefiLogoVariant.mark] is the chevron alone, for
/// places too small for the wordmark.
enum XefiLogoVariant {
  light('assets/brand/xefi_logo.svg', 130 / 30),
  dark('assets/brand/xefi_logo_dark.svg', 130 / 30),
  mark('assets/brand/xefi_mark.svg', 31.11 / 29.12);

  const XefiLogoVariant(this.assetPath, this.aspectRatio);

  final String assetPath;
  final double aspectRatio;
}

class XefiLogo extends StatelessWidget {
  const XefiLogo({
    super.key,
    this.variant = XefiLogoVariant.dark,
    this.height = 24,
  });

  final XefiLogoVariant variant;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      variant.assetPath,
      height: height,
      width: height * variant.aspectRatio,
      semanticsLabel: 'XEFI',
    );
  }
}

/// The corporate logo locked up with the product name.
///
/// The two are separated by a rule rather than run together: XEFI is the
/// company mark and must stay untouched, while "Santé Sport" names this app.
/// The product name carries the same weight as the wordmark, which reads as
/// one brand rather than a logo with a caption stuck to it.
class XefiLockup extends StatelessWidget {
  const XefiLockup({
    super.key,
    this.variant = XefiLogoVariant.dark,
    this.logoHeight = 22,
  });

  final XefiLogoVariant variant;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    final onDarkBackground = variant == XefiLogoVariant.light;
    final color = onDarkBackground ? AppColors.white : AppColors.black;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        XefiLogo(variant: variant, height: logoHeight),
        Container(
          width: 1,
          height: logoHeight * 0.82,
          margin: EdgeInsets.symmetric(horizontal: logoHeight * 0.45),
          color: color.withValues(alpha: 0.28),
        ),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Santé '),
                // Red on the last word puts the accent at both ends of the
                // lockup, echoing the chevron on the left. This is the brand
                // mark, the one place the accent is not a call to action.
                const TextSpan(
                  text: 'Sport',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontSize: logoHeight * 0.92,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
          ),
        ),
      ],
    );
  }
}
