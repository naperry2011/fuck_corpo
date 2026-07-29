import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../dashboard_metrics.dart';

/// EARNINGS OVER TIME. Translation of the Chart.js line config in
/// `Dashboard.jsx`: green stroke, 10% green fill, smoothed, 4pt points.
class EarningsLineChart extends StatelessWidget {
  const EarningsLineChart({
    super.key,
    required this.series,
    required this.currency,
  });

  static const double curveSmoothness = 0.3;

  final List<DailyEarnings> series;
  final String currency;

  double get _maxY {
    final double peak = series
        .map((DailyEarnings d) => d.amount)
        .reduce((double a, double b) => a > b ? a : b);
    return peak <= 0 ? 1 : peak * 1.2;
  }

  /// Whole-currency ticks. React printed full two-decimal figures here, which
  /// crowds the axis at Flutter's tick density (deviation D-111).
  String _tick(double value) => NumberFormat.compactSimpleCurrency(
    locale: 'en_US',
    name: currency,
    decimalDigits: 0,
  ).format(value);

  @override
  Widget build(BuildContext context) {
    final TextStyle tickStyle = FcText.mono.copyWith(
      fontSize: 10,
      color: FcColors.gray,
    );

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: _maxY,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (double _) => FlLine(
              color: FcColors.gray.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (double value, TitleMeta meta) => Text(
                  _tick(value),
                  style: tickStyle,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int index = value.round();
                  if (index < 0 || index >= series.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      series[index].label,
                      textAlign: TextAlign.center,
                      style: tickStyle.copyWith(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              isCurved: true,
              curveSmoothness: curveSmoothness,
              color: FcColors.green,
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true,
                color: FcColors.green.withValues(alpha: 0.1),
              ),
              dotData: FlDotData(
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 4,
                  color: FcColors.green,
                  strokeWidth: 0,
                ),
              ),
              spots: <FlSpot>[
                for (int i = 0; i < series.length; i++)
                  FlSpot(i.toDouble(), series[i].amount),
              ],
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }
}
