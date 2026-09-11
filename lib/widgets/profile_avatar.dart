import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The user's picture, falling back to their initials.
///
/// The fallback is not decoration: an avatar is optional, the network can fail,
/// and a broken image icon in a leaderboard row reads as a bug rather than as
/// "no picture yet".
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 24,
    this.highlighted = false,
    this.onDarkChip = false,
    this.discColour,
    this.initialsColour,
  });

  final String name;
  final String? avatarUrl;
  final double radius;
  final bool highlighted;

  /// Draws the initials white on a dark disc, for the leaderboard rows where a
  /// pale chip would disappear into the white card behind it.
  final bool onDarkChip;

  /// Explicit colours, for grounds the two presets do not cover — the podium
  /// sits on black, where the default near-black disc and dark-navy initials
  /// both vanish.
  final Color? discColour;
  final Color? initialsColour;

  String get _initials {
    final words = name.trim().split(RegExp(r'[\s@._-]+'))
      ..removeWhere((word) => word.isEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.characters.take(2).toString().toUpperCase();
    }
    return (words.first.characters.first + words[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final background =
        discColour ??
        (highlighted
            ? AppColors.primary
            : onDarkChip
            ? AppColors.secondaryText
            : AppColors.black.withValues(alpha: 0.06));
    final foreground =
        initialsColour ??
        (highlighted || onDarkChip ? AppColors.white : AppColors.secondaryText);

    final initials = Text(
      _initials,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontSize: radius * 0.7,
        fontWeight: FontWeight.w800,
        color: foreground,
      ),
    );

    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: background,
        shape: const CircleBorder(),
      ),
      // ClipOval rather than CircleAvatar's foregroundImage: it makes the crop
      // and the fit explicit, and it leaves room for an error builder, which
      // that API has none of — a deleted or unreachable picture would
      // otherwise leave a blank disc with no hint of why.
      child: (url == null || url.isEmpty)
          ? initials
          : ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => initials,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : initials,
              ),
            ),
    );
  }
}
