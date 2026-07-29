import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/currency_formatter.dart';
import '../../core/format/duration_formatter.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../domain/calculations.dart';
import '../../domain/comparisons.dart';
import '../../domain/copy/corporate_memo.dart';
import '../../domain/copy/fun_facts.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/break_record.dart';
import '../../state/providers.dart';
import '../../widgets/animated_currency.dart';
import '../../widgets/fc_card.dart';
import 'dashboard_metrics.dart';
import 'widgets/break_pattern_chart.dart';
import 'widgets/category_doughnut.dart';
import 'widgets/earnings_line_chart.dart';

/// Port of `src/pages/Dashboard.jsx`: running totals, rotating fun fact,
/// corporate memo, three charts, performance metrics and comparisons.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  static const String confidential = 'CONFIDENTIAL';
  static const String title = 'YOUR QUARTERLY EARNINGS REPORT';
  static const String subtitle =
      'Internal document -- Do not distribute outside the restroom';
  static const String emptyMessage =
      'No data yet. Start tracking your breaks to see your earnings report.';
  static const String memoFrom = 'Management, Break Analytics Division';

  /// React rotated the fact every 10s behind a 400ms fade.
  static const Duration factInterval = Duration(seconds: 10);
  static const Duration factFade = Duration(milliseconds: 400);

  static const Key funFactKey = Key('dashboard_fun_fact');
  static const Key avgSessionKey = Key('dashboard_avg_session');
  static const Key longestSessionKey = Key('dashboard_longest_session');
  static const Key totalBreaksKey = Key('dashboard_total_breaks');
  static const Key mostCommonCategoryKey = Key('dashboard_most_common');

  static Key hourBucketKey(int hour) => ValueKey<String>('hour_bucket_$hour');

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _rotation;
  Timer? _fade;
  late int _factIndex;
  bool _factVisible = true;

  @override
  void initState() {
    super.initState();
    // React picked a random fact each rotation. Starting at a random index and
    // walking forward keeps the copy rotating while staying testable
    // (deviation D-110).
    _factIndex = funFacts.indexOf(randomFact());
    _rotation = Timer.periodic(DashboardScreen.factInterval, (_) => _rotate());
  }

  @override
  void dispose() {
    _rotation?.cancel();
    _fade?.cancel();
    super.dispose();
  }

  void _rotate() {
    if (!mounted) return;
    setState(() => _factVisible = false);
    _fade = Timer(DashboardScreen.factFade, () {
      if (!mounted) return;
      setState(() {
        _factIndex = (_factIndex + 1) % funFacts.length;
        _factVisible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = ref.watch(appControllerProvider);
    final List<BreakRecord> breaks = state.breaks;
    final double rate = ref.watch(perMinuteRateProvider);
    final String currency = ref.watch(currencyProvider);
    final DateTime now = ref.watch(clockProvider)();

    String money(num amount) => formatCurrency(amount, currency: currency);

    if (breaks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _Header(showSubtitle: false),
          FcCard(
            child: Text(
              DashboardScreen.emptyMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: FcColors.gray,
              ),
            ),
          ),
        ],
      );
    }

    final double lifetime = totalEarnings(breaks, rate);
    final PerformanceMetrics? metrics = performanceMetrics(breaks);
    final CorporateMemo memo = corporateMemoFor(
      earnings: lifetime,
      breakCount: breaks.length,
      avgDurationMs: metrics?.avgDurationMs ?? 0,
      formatMoney: money,
    );
    final List<Comparison> comparisons = getComparisons(lifetime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _Header(),
        const SizedBox(height: FcSpacing.l),

        // Running totals.
        Wrap(
          spacing: FcSpacing.s,
          runSpacing: FcSpacing.s,
          children: <Widget>[
            for (final (String label, double value) in <(String, double)>[
              ('TODAY', totalEarnings(todayBreaks(breaks, now: now), rate)),
              ('THIS WEEK', totalEarnings(weekBreaks(breaks, now: now), rate)),
              (
                'THIS MONTH',
                totalEarnings(monthBreaks(breaks, now: now), rate),
              ),
              ('THIS YEAR', totalEarnings(yearBreaks(breaks, now: now), rate)),
            ])
              _TotalCard(label: label, value: value, currency: currency),
            _TotalCard(
              label: 'LIFETIME EARNINGS',
              value: lifetime,
              currency: currency,
              featured: true,
            ),
          ],
        ),
        const SizedBox(height: FcSpacing.l),

        const _SectionTitle('MARKET ANALYSIS'),
        FcCard(
          child: AnimatedOpacity(
            opacity: _factVisible ? 1 : 0,
            duration: DashboardScreen.factFade,
            child: Text(
              funFacts[_factIndex],
              key: DashboardScreen.funFactKey,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: FcSpacing.l),

        const _SectionTitle('INTERNAL CORRESPONDENCE'),
        FcCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _MemoField(
                'To: Employee #${employeeNumber(breaks.length)}',
              ),
              const _MemoField('From: ${DashboardScreen.memoFrom}'),
              _MemoField('Subject: ${memo.subject}'),
              const SizedBox(height: FcSpacing.xs),
              Divider(color: FcColors.gray.withValues(alpha: 0.3), height: 1),
              const SizedBox(height: FcSpacing.xs),
              Text(memo.body, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: FcSpacing.l),

        const _SectionTitle('EARNINGS OVER TIME'),
        FcCard(
          child: EarningsLineChart(
            series: dailyEarningsSeries(breaks, rate, now: now),
            currency: currency,
          ),
        ),
        const SizedBox(height: FcSpacing.l),

        const _SectionTitle('BREAK PATTERNS'),
        FcCard(
          child: BreakPatternChart(
            counts: hourlyBreakCounts(breaks),
            bucketKeyFor: DashboardScreen.hourBucketKey,
          ),
        ),
        const SizedBox(height: FcSpacing.l),

        const _SectionTitle('CATEGORY BREAKDOWN'),
        FcCard(child: CategoryDoughnut(counts: categoryCounts(breaks))),

        if (metrics != null) ...<Widget>[
          const SizedBox(height: FcSpacing.l),
          const _SectionTitle('PERFORMANCE METRICS'),
          Wrap(
            spacing: FcSpacing.s,
            runSpacing: FcSpacing.s,
            children: <Widget>[
              _MetricCard(
                label: 'AVG SESSION LENGTH',
                value: formatDuration(metrics.avgDurationMs),
                valueKey: DashboardScreen.avgSessionKey,
              ),
              _MetricCard(
                label: 'LONGEST SESSION EVER',
                value: formatDuration(metrics.longestBreakMs),
                valueKey: DashboardScreen.longestSessionKey,
              ),
              _MetricCard(
                label: 'TOTAL BREAKS',
                value: '${metrics.totalBreaks}',
                valueKey: DashboardScreen.totalBreaksKey,
              ),
              _MetricCard(
                label: 'MOST COMMON CATEGORY',
                value: metrics.mostCommonCategory.label,
                valueKey: DashboardScreen.mostCommonCategoryKey,
              ),
            ],
          ),
        ],

        if (comparisons.isNotEmpty) ...<Widget>[
          const SizedBox(height: FcSpacing.l),
          const _SectionTitle('YOUR EARNINGS CAN BUY...'),
          Wrap(
            spacing: FcSpacing.s,
            runSpacing: FcSpacing.s,
            children: <Widget>[
              for (final Comparison c in comparisons)
                _ComparisonCard(comparison: c),
            ],
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.showSubtitle = true});

  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FcSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            DashboardScreen.confidential,
            style: FcText.mono.copyWith(
              fontSize: 11,
              letterSpacing: 2,
              color: FcColors.red,
            ),
          ),
          const SizedBox(height: FcSpacing.xxs),
          Text(
            DashboardScreen.title,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          if (showSubtitle) ...<Widget>[
            const SizedBox(height: FcSpacing.xxs),
            Text(
              DashboardScreen.subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: FcColors.gray),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FcSpacing.s),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}

class _MemoField extends StatelessWidget {
  const _MemoField(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: FcColors.gray,
    ),
  );
}

/// Cards sit in a `Wrap`, so they need an explicit width rather than `Expanded`.
const double _cardWidth = 220;

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.value,
    required this.currency,
    this.featured = false,
  });

  final String label;
  final double value;
  final String currency;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cardWidth,
      child: FcCard(
        elevated: featured,
        padding: const EdgeInsets.all(FcSpacing.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: FcSpacing.xxs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedCurrency(
                value: value,
                currency: currency,
                style: FcText.mono.copyWith(
                  fontSize: featured ? 32 : 24,
                  fontWeight: FontWeight.w700,
                  color: featured ? FcColors.gold : FcColors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cardWidth,
      child: FcCard(
        padding: const EdgeInsets.all(FcSpacing.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: FcSpacing.xxs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                key: valueKey,
                style: FcText.mono.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: FcColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.comparison});

  final Comparison comparison;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: FcCard(
        padding: const EdgeInsets.all(FcSpacing.s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              comparison.item.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: FcSpacing.xxs),
            Text(
              '${comparison.count}',
              style: FcText.mono.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: FcColors.green,
              ),
            ),
            Text(
              comparison.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: FcColors.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
