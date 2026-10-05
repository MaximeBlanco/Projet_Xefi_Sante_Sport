import 'package:flutter/material.dart';

/// Caps how wide a screen's content grows, and centres it.
///
/// Every screen here is laid out for a phone. Stretched to a desktop browser
/// the layouts do not break, they inflate: the member card keeps credit-card
/// proportions, so at 1440 px wide it becomes 1400 px of card and nothing else
/// fits on screen, and the three figures of the dashboard drift to opposite
/// edges of the window.
///
/// One value for every screen rather than one per screen: the app used to cap
/// its forms at 400 and leave the lists unbounded, which read as two different
/// applications depending on which tab you were on.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});

  /// Wide enough that a list does not look like a phone pasted onto a desktop,
  /// narrow enough that the member card stays a card.
  static const maxWidth = 480.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
