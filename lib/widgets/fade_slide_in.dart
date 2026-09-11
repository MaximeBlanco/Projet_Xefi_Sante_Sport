import 'package:flutter/material.dart';

/// Fades a widget in while it rises a few pixels, once, on first build.
///
/// Staggering a column with increasing [delay] makes a screen assemble itself
/// rather than appear all at once. The effect is deliberately small: it should
/// read as the content settling, not as a transition to sit through.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
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

    // Someone who asked the system to reduce motion gets the end state
    // immediately rather than a shorter version of the same movement.
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
      builder: (context, child) => Opacity(
        opacity: _eased.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _eased.value)),
          child: child,
        ),
      ),
    );
  }
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
      builder: (context, animatedValue, child) => Text(
        '$animatedValue',
        style: style,
      ),
    );
  }
}
