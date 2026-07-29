import 'package:flutter/material.dart';

import '../core/format/currency_formatter.dart';
import '../core/format/duration_formatter.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';
import '../domain/calculations.dart';
import '../domain/models/break_record.dart';

/// One row of the market ticker.
@immutable
class FcTickerItem {
  const FcTickerItem({
    required this.label,
    required this.value,
    required this.positive,
  });

  final String label;
  final String value;

  /// Green when true, red when false. Only `$TIME` is red, matching React.
  final bool positive;
}

/// Port of `src/components/layout/Ticker.jsx`. The item list is rendered twice
/// so the marquee wraps without a visible seam.
class FcTicker extends StatefulWidget {
  const FcTicker({super.key, required this.items, this.animate = true});

  static const Duration scrollDuration = Duration(seconds: 30);

  /// Fixed strip height, so the marquee has a bounded box to overflow inside.
  static const double rowHeight = 20;

  final List<FcTickerItem> items;

  /// Off in tests, where a repeating animation would never settle.
  final bool animate;

  /// Builds the five ticker rows from app state.
  static List<FcTickerItem> buildItems({
    required List<BreakRecord> breaks,
    required double perMinuteRate,
    String currency = 'USD',
    DateTime? now,
  }) {
    final List<BreakRecord> today = todayBreaks(breaks, now: now);
    String money(num amount) => formatCurrency(amount, currency: currency);
    return <FcTickerItem>[
      FcTickerItem(
        label: r'$EARN',
        value: money(totalEarnings(today, perMinuteRate)),
        positive: true,
      ),
      FcTickerItem(
        label: r'$TIME',
        value: formatDuration(totalDuration(today)),
        positive: false,
      ),
      FcTickerItem(
        label: r'$LIFE',
        value: money(totalEarnings(breaks, perMinuteRate)),
        positive: true,
      ),
      FcTickerItem(
        label: r'$SESS',
        value: '${breaks.length}',
        positive: true,
      ),
      FcTickerItem(
        label: r'$RATE',
        value: '${money(perMinuteRate)}/min',
        positive: true,
      ),
    ];
  }

  @override
  State<FcTicker> createState() => _FcTickerState();
}

class _FcTickerState extends State<FcTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: FcTicker.scrollDuration,
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget track = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < widget.items.length * 2; i++)
          _FcTickerCell(item: widget.items[i % widget.items.length]),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: FcColors.green.withValues(alpha: 0.08),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: FcColors.green.withValues(alpha: 0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: FcSpacing.xs),
      child: SizedBox(
        height: FcTicker.rowHeight,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: double.infinity,
            child: widget.animate
                ? AnimatedBuilder(
                    animation: _controller,
                    builder: (BuildContext context, Widget? child) =>
                        FractionalTranslation(
                          translation: Offset(-_controller.value / 2, 0),
                          child: child,
                        ),
                    child: track,
                  )
                : track,
          ),
        ),
      ),
    );
  }
}

class _FcTickerCell extends StatelessWidget {
  const _FcTickerCell({required this.item});

  final FcTickerItem item;

  @override
  Widget build(BuildContext context) {
    const TextStyle base = TextStyle(fontFamily: FcFonts.mono, fontSize: 13);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FcSpacing.s),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            item.label,
            style: base.copyWith(color: FcColors.gray),
          ),
          const SizedBox(width: FcSpacing.xs),
          Text(
            item.value,
            style: base.copyWith(
              fontWeight: FontWeight.w700,
              color: item.positive ? FcColors.green : FcColors.red,
            ),
          ),
          const SizedBox(width: FcSpacing.xs),
          Text(
            '|',
            style: base.copyWith(
              color: FcColors.gray.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
