import 'package:flutter/material.dart';

/// Entrance animations, one family per screen.
///
/// Each screen gets its own so that moving between tabs feels like arriving
/// somewhere rather than having the content swapped inside the same frame. The
/// motion is chosen to say something about what the screen holds:
///
/// - [RiseIn] on the home screen: figures settling into place under the score.
/// - [SlideIn] on the lists, entering from the side one after another, which is
///   how a list is read.
/// - [ScaleIn] on identity — the profile picture and the brand mark — which
///   grow from their own centre because there is a single subject.
///
/// All of them honour the system reduce-motion setting by showing the end state
/// straight away, rather than playing a shortened version of the same movement.
abstract class _Entrance extends StatefulWidget {
  const _Entrance({
    super.key,
    required this.child,
    required this.delay,
    required this.duration,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  Widget buildTransition(Animation<double> animation, Widget child);

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _eased = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _eased,
      child: widget.child,
      builder: (context, child) => widget.buildTransition(_eased, child!),
    );
  }
}

/// Fades in while rising a few pixels. The home screen's family.
class RiseIn extends _Entrance {
  const RiseIn({
    super.key,
    required super.child,
    super.delay = Duration.zero,
    super.duration = const Duration(milliseconds: 420),
    this.offset = 18,
  });

  final double offset;

  @override
  Widget buildTransition(Animation<double> animation, Widget child) {
    return Opacity(
      opacity: animation.value,
      child: Transform.translate(
        offset: Offset(0, offset * (1 - animation.value)),
        child: child,
      ),
    );
  }
}

/// Fades in while sliding sideways. The lists' family.
class SlideIn extends _Entrance {
  const SlideIn({
    super.key,
    required super.child,
    super.delay = Duration.zero,
    super.duration = const Duration(milliseconds: 380),
    this.fromLeft = false,
    this.offset = 34,
  });

  final bool fromLeft;
  final double offset;

  @override
  Widget buildTransition(Animation<double> animation, Widget child) {
    final travel = (fromLeft ? -offset : offset) * (1 - animation.value);
    return Opacity(
      opacity: animation.value,
      child: Transform.translate(offset: Offset(travel, 0), child: child),
    );
  }
}

/// Fades in while growing from its own centre. The identity family.
class ScaleIn extends _Entrance {
  const ScaleIn({
    super.key,
    required super.child,
    super.delay = Duration.zero,
    super.duration = const Duration(milliseconds: 480),
    this.from = 0.88,
  });

  final double from;

  @override
  Widget buildTransition(Animation<double> animation, Widget child) {
    return Opacity(
      opacity: animation.value,
      child: Transform.scale(
        scale: from + (1 - from) * animation.value,
        child: child,
      ),
    );
  }
}

/// Delay for the nth item of a list.
///
/// Capped so a long list does not make its last rows wait: past the cap every
/// remaining item enters together, which is invisible because they are below
/// the fold anyway.
Duration staggerFor(int index, {int step = 55, int cap = 8}) {
  return Duration(milliseconds: (index < cap ? index : cap) * step);
}

/// Counts up to [value] so a score lands rather than simply being there.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final int value;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: animate ? 0 : value, end: value),
      duration: animate ? duration : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) =>
          Text('$animatedValue', style: style),
    );
  }
}
