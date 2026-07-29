import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../domain/models/break_category.dart';

/// CATEGORY BREAKDOWN doughnut plus the bottom legend.
///
/// Every wedge takes its color from [BreakCategory], so all five categories are
/// visually distinct (BUG-005 / deviation D-005).
class CategoryDoughnut extends StatelessWidget {
  const CategoryDoughnut({super.key, required this.counts});

  final Map<BreakCategory, int> counts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 52,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(enabled: false),
              sections: <PieChartSectionData>[
                for (final MapEntry<BreakCategory, int> entry
                    in counts.entries)
                  PieChartSectionData(
                    value: entry.value.toDouble(),
                    color: entry.key.color,
                    radius: 48,
                    showTitle: false,
                    borderSide: const BorderSide(
                      color: FcColors.navy,
                      width: 2,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: FcSpacing.s),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: FcSpacing.s,
          runSpacing: FcSpacing.xs,
          children: <Widget>[
            for (final MapEntry<BreakCategory, int> entry in counts.entries)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: entry.key.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: FcSpacing.xxs),
                  Text(
                    '${entry.key.label} ${entry.value}',
                    style: FcText.mono.copyWith(
                      fontSize: 12,
                      color: FcColors.ink,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
