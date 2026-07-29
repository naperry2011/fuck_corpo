import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../dashboard_metrics.dart';

/// BREAK PATTERNS: 24 horizontal bars, one per hour of the day.
///
/// Chart.js drew this with `indexAxis: 'y'`. `fl_chart` has no horizontal bar
/// mode, so the bars are laid out natively (deviation D-109). The data, the
/// 12-hour AM/PM labels and the green fill are unchanged, and every hour label
/// is real selectable text rather than canvas paint.
class BreakPatternChart extends StatelessWidget {
  const BreakPatternChart({
    super.key,
    required this.counts,
    required this.bucketKeyFor,
  });

  final List<int> counts;
  final Key Function(int hour) bucketKeyFor;

  int get _peak =>
      counts.fold<int>(0, (int max, int c) => c > max ? c : max);

  @override
  Widget build(BuildContext context) {
    final int peak = _peak;
    final TextStyle labelStyle = FcText.mono.copyWith(
      fontSize: 10,
      color: FcColors.gray,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int hour = 0; hour < counts.length; hour++)
          Padding(
            key: bucketKeyFor(hour),
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 44,
                  child: Text(hourLabel(hour), style: labelStyle),
                ),
                Expanded(
                  child: Semantics(
                    label:
                        '${hourLabel(hour)}: ${counts[hour]} '
                        '${counts[hour] == 1 ? 'break' : 'breaks'}',
                    child: _Bar(
                      fraction: peak == 0 ? 0 : counts[hour] / peak,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: FcColors.gray.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0, 1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FcColors.green.withValues(alpha: 0.6),
            border: Border.all(color: FcColors.green),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
