import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
