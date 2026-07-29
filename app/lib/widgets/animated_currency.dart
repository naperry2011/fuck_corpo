import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/format/currency_formatter.dart';

/// Count-up money readout. Port of `AnimatedCurrency` + `useCountUp`, including
/// the `easeOutExpo` curve and the 1500ms duration. Values are formatted
/// through [formatCurrency], so the selected currency applies here too.
class AnimatedCurrency extends StatefulWidget {
  const AnimatedCurrency({
    super.key,
    required this.value,
    this.currency = 'USD',
    this.style,
    this.duration = defaultDuration,
  });

  static const Duration defaultDuration = Duration(milliseconds: 1500);

  final num value;
  final String currency;
  final TextStyle? style;
  final Duration duration;

  @override
  State<AnimatedCurrency> createState() => _AnimatedCurrencyState();
}

class _AnimatedCurrencyState extends State<AnimatedCurrency>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.value != 0) _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCurrency oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _from = oldWidget.value.toDouble();
      _controller
        ..duration = widget.duration
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// `1 - 2^(-10t)`, matching `easeOutExpo` in `src/hooks/useCountUp.js`.
  static double easeOutExpo(double t) =>
      t == 1 ? 1 : 1 - math.pow(2, -10 * t).toDouble();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final double eased = easeOutExpo(_controller.value);
        final double current =
            _from + (widget.value.toDouble() - _from) * eased;
        return Text(
          formatCurrency(current, currency: widget.currency),
          style: widget.style,
        );
      },
    );
  }
}
