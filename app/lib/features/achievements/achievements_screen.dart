import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/currency_formatter.dart';
import '../../core/format/duration_formatter.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../domain/achievements_catalog.dart';
import '../../domain/calculations.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/break_record.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../../state/toast_controller.dart';
import '../../widgets/fc_button.dart';
import '../../widgets/fc_card.dart';
import '../../widgets/fc_toast.dart';
import '../dashboard/dashboard_metrics.dart';
import 'earnings_statement.dart';

/// Port of `src/pages/Achievements.jsx`: the 11 badges, the shareable earnings
/// statement and the executive comparison report.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  static const String title = 'INVESTOR ACHIEVEMENTS';
  static const String subtitle = 'Your portfolio of bathroom accomplishments';
  static const String lockIcon = '\u{1F512}';
  static const String ceoFootnote =
      'Based on average Fortune 500 CEO compensation of ~\$5,000/hour '
      '(~\$83.33/min)';

  /// How long the copy button stays in its confirmed state.
  static const Duration copiedFor = Duration(seconds: 2);

  static const Key progressKey = Key('achievements_progress');
  static const Key lifetimeKey = Key('statement_lifetime');
  static const Key sessionsKey = Key('statement_sessions');
  static const Key avgDurationKey = Key('statement_avg_duration');
  static const Key topCategoryKey = Key('statement_top_category');
  static const Key ceoYouKey = Key('ceo_you');
  static const Key ceoThemKey = Key('ceo_them');
  static const Key ceoMultiplierKey = Key('ceo_multiplier');

  static Key badgeKey(String id) => ValueKey<String>('badge_$id');
  static Key badgeIconKey(String id) => ValueKey<String>('badge_icon_$id');

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  /// Badges already announced this session. Seeded from what the user already
  /// held so a revisit does not re-toast the whole wall.
  late final Set<String> _announced;
  Timer? _copyReset;
  bool _copied = false;
  bool _sweepScheduled = false;

  @override
  void initState() {
    super.initState();
    _announced = <String>{
      ...ref.read(appControllerProvider).achievements,
    };
  }

  @override
  void dispose() {
    _copyReset?.cancel();
    super.dispose();
  }

  /// Persists anything newly satisfied and announces it exactly once.
  ///
  /// React ran this inside the render effect, which is why it depended on a ref
  /// to avoid duplicate toasts. Here the guard is explicit.
  void _sweep(List<BreakRecord> breaks, double lifetimeEarned) {
    final List<String> fresh = newlyUnlocked(
      breaks: breaks,
      lifetimeEarned: lifetimeEarned,
      alreadyUnlocked: ref.read(appControllerProvider).achievements,
    );
    if (fresh.isEmpty) return;

    final AppController controller = ref.read(appControllerProvider.notifier);
    for (final String id in fresh) {
      controller.addAchievement(id);
      if (_announced.add(id)) {
        final Achievement badge = achievementsCatalog.firstWhere(
          (Achievement a) => a.id == id,
        );
        ref
            .read(toastControllerProvider.notifier)
            .show(
              'Achievement Unlocked: ${badge.name}!',
              type: FcToastType.achievement,
            );
      }
    }
  }

  Future<void> _copyStatement(String payload) async {
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    setState(() => _copied = true);
    _copyReset?.cancel();
    _copyReset = Timer(AchievementsScreen.copiedFor, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = ref.watch(appControllerProvider);
    final List<BreakRecord> breaks = state.breaks;
    final double rate = ref.watch(perMinuteRateProvider);
    final String currency = ref.watch(currencyProvider);
    final DateTime now = ref.watch(clockProvider)();

    final double lifetimeEarned = totalEarnings(breaks, rate);
    final int lifetimeDuration = totalDuration(breaks);
    final PerformanceMetrics? metrics = performanceMetrics(breaks);
    final double avgDuration = metrics?.avgDurationMs ?? 0;
    final String topCategory = metrics?.mostCommonCategory.label ?? 'N/A';

    if (!_sweepScheduled) {
      _sweepScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sweepScheduled = false;
        if (mounted) _sweep(breaks, lifetimeEarned);
      });
    }

    final int unlockedCount = achievementsCatalog
        .where((Achievement a) => state.achievements.contains(a.id))
        .length;

    String money(num amount) => formatCurrency(amount, currency: currency);

    final double ceoEarnings = ceoEarningsFor(lifetimeDuration);
    final String multiplier = ceoMultiplier(
      ceoEarnings: ceoEarnings,
      lifetimeEarned: lifetimeEarned,
    );

    final String statement = buildEarningsStatement(
      lifetimeEarned: lifetimeEarned,
      totalSessions: breaks.length,
      totalDurationMs: lifetimeDuration,
      avgDurationMs: avgDuration,
      mostCommonCategory: topCategory,
      unlockedCount: unlockedCount,
      totalAchievements: achievementsCatalog.length,
      date: now,
      formatMoney: money,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          AchievementsScreen.title,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: FcSpacing.xxs),
        Text(
          AchievementsScreen.subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: FcColors.gray),
        ),
        const SizedBox(height: FcSpacing.xxs),
        Text(
          '$unlockedCount / ${achievementsCatalog.length} unlocked',
          key: AchievementsScreen.progressKey,
          style: FcText.mono.copyWith(fontSize: 14, color: FcColors.gold),
        ),
        const SizedBox(height: FcSpacing.l),

        Wrap(
          spacing: FcSpacing.s,
          runSpacing: FcSpacing.s,
          children: <Widget>[
            for (final Achievement badge in achievementsCatalog)
              _BadgeCard(
                badge: badge,
                unlocked: state.achievements.contains(badge.id),
              ),
          ],
        ),
        const SizedBox(height: FcSpacing.xl),

        FcCard(
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'OFFICIAL EARNINGS STATEMENT',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: FcSpacing.xxs),
              Text(
                'FuckCorpo Inc.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                statementDate(now),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: FcColors.gray),
              ),
              const SizedBox(height: FcSpacing.s),
              const _Rule(),
              const SizedBox(height: FcSpacing.s),
              Text(
                'Lifetime Earnings',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                money(lifetimeEarned),
                key: AchievementsScreen.lifetimeKey,
                style: FcText.mono.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: FcColors.green,
                ),
              ),
              const SizedBox(height: FcSpacing.s),
              const _Rule(),
              const SizedBox(height: FcSpacing.s),
              _StatementRow(
                label: 'Total Sessions',
                value: '${breaks.length}',
                valueKey: AchievementsScreen.sessionsKey,
              ),
              _StatementRow(
                label: 'Average Duration',
                value: formatDuration(avgDuration),
                valueKey: AchievementsScreen.avgDurationKey,
              ),
              _StatementRow(
                label: 'Most Common Category',
                value: topCategory,
                valueKey: AchievementsScreen.topCategoryKey,
              ),
              const SizedBox(height: FcSpacing.s),
              const _Rule(),
              const SizedBox(height: FcSpacing.s),
              Text(
                'BOARD OF DIRECTORS: YOU',
                style: FcText.mono.copyWith(
                  fontSize: 14,
                  color: FcColors.gold,
                ),
              ),
              const SizedBox(height: FcSpacing.s),
              Align(
                alignment: Alignment.centerLeft,
                child: FcButton(
                  label: _copied ? 'Copied!' : 'Copy to Clipboard',
                  variant: FcButtonVariant.secondary,
                  size: FcButtonSize.sm,
                  onPressed: () => _copyStatement(statement),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FcSpacing.xl),

        FcCard(
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'EXECUTIVE COMPARISON REPORT',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Bathroom break earnings analysis',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: FcColors.gray),
              ),
              const SizedBox(height: FcSpacing.m),
              Text(
                'While you earned',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                money(lifetimeEarned),
                key: AchievementsScreen.ceoYouKey,
                style: FcText.mono.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: FcColors.green,
                ),
              ),
              Text(
                'in the bathroom...',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: FcColors.gray),
              ),
              const SizedBox(height: FcSpacing.s),
              Text(
                'VS',
                style: FcText.mono.copyWith(
                  fontSize: 16,
                  color: FcColors.gray,
                ),
              ),
              const SizedBox(height: FcSpacing.s),
              Text(
                'A Fortune 500 CEO earned',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                money(ceoEarnings),
                key: AchievementsScreen.ceoThemKey,
                style: FcText.mono.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: FcColors.gold,
                ),
              ),
              Text(
                'in the same amount of time',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: FcColors.gray),
              ),
              if (lifetimeEarned > 0) ...<Widget>[
                const SizedBox(height: FcSpacing.m),
                Text(
                  '${multiplier}x',
                  key: AchievementsScreen.ceoMultiplierKey,
                  style: FcText.mono.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: FcColors.red,
                  ),
                ),
                Text(
                  'CEO earnings multiplier',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: FcColors.gray),
                ),
              ],
              const SizedBox(height: FcSpacing.m),
              Text(
                AchievementsScreen.ceoFootnote,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: FcColors.gray),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      Divider(color: FcColors.gray.withValues(alpha: 0.3), height: 1);
}

class _StatementRow extends StatelessWidget {
  const _StatementRow({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FcSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            key: valueKey,
            style: FcText.mono.copyWith(fontSize: 16, color: FcColors.ink),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge, required this.unlocked});

  final Achievement badge;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: AchievementsScreen.badgeKey(badge.id),
      width: 180,
      child: Opacity(
        opacity: unlocked ? 1 : 0.55,
        child: FcCard(
          padding: const EdgeInsets.all(FcSpacing.s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                unlocked ? badge.icon : AchievementsScreen.lockIcon,
                key: AchievementsScreen.badgeIconKey(badge.id),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: FcSpacing.xxs),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: FcColors.gray),
              ),
              const SizedBox(height: FcSpacing.xxs),
              Text(
                unlocked ? 'UNLOCKED' : 'LOCKED',
                style: FcText.mono.copyWith(
                  fontSize: 11,
                  letterSpacing: 1,
                  color: unlocked ? FcColors.green : FcColors.gray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
