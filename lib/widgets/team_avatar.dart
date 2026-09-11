import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A team's photograph, or its colour and initials while it has none.
///
/// The colour is kept as the fallback rather than dropped: a team that has not
/// uploaded anything still needs to be told apart at a glance, and a row of
/// identical grey placeholders would be worse than the dots this replaces.
class TeamAvatar extends StatelessWidget {
  const TeamAvatar({
    super.key,
    required this.name,
    required this.colour,
    this.imageUrl,
    this.radius = 20,
    this.ringColour,
  });

  final String name;
  final Color colour;
  final String? imageUrl;
  final double radius;

  /// Drawn around the photo, for the row that is the reader's own team.
  final Color? ringColour;

  String get _initials {
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((word) => word.isEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final word = words.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final url = imageUrl;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colour,
        border: ringColour == null
            ? null
            : Border.all(color: ringColour!, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? _Initials(initials: _initials, radius: radius)
          : Image.network(
              url,
              fit: BoxFit.cover,
              // A photo that will not load leaves the colour and initials
              // showing rather than a broken-image glyph.
              errorBuilder: (context, error, stackTrace) =>
                  _Initials(initials: _initials, radius: radius),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const SizedBox.shrink(),
            ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.radius});

  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: radius * 0.78,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
        ),
      ),
    );
  }
}
