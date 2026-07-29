import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/format/currency_formatter.dart';
import '../../core/format/duration_formatter.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../domain/calculations.dart';
import '../../domain/copy/fun_facts.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/break_category.dart';
import '../../domain/models/break_record.dart';
import '../../state/providers.dart';
import '../../state/timer_controller.dart';
import '../../state/toast_controller.dart';
import '../../widgets/fc_button.dart';
import '../../widgets/fc_card.dart';
import '../../widgets/fc_dropdown.dart';
import '../../widgets/fc_text_field.dart';
import '../../widgets/fc_toast.dart';
import 'widgets/break_list_item.dart';
import 'widgets/category_chip_row.dart';

/// Port of `src/pages/Timer.jsx`: live timer, quick log, today's summary,
/// recent breaks.
class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  /// React re-rendered the clock every 100ms. Elapsed time itself comes from
  /// the wall clock, so this is only a repaint cadence.
  static const Duration tickInterval = Duration(milliseconds: 100);

  /// React accepted any positive number; the 1-480 bounds were HTML attributes
  /// it never enforced. Here they are enforced and explained (deviation D-104).
  static const int minQuickMinutes = 1;
  static const int maxQuickMinutes = 480;

  static const String discardedMessage =
      'Break discarded: under one second, nothing was logged.';
  static const String invalidMinutesMessage =
      'Enter a whole number of minutes between 1 and 480.';
  static const String runningStatus = 'Earning since you stepped away...';

  static const Key clockKey = Key('timer_clock');
  static const Key earningsKey = Key('timer_earnings');
  static const Key motivationKey = Key('timer_motivation');
  static const Key quickMinutesKey = Key('quick_minutes');
  static const Key quickCategoryKey = Key('quick_category');
  static const Key quickDateKey = Key('quick_date');
  static const Key summaryCountKey = Key('summary_count');
  static const Key summaryDurationKey = Key('summary_duration');
  static const Key summaryEarningsKey = Key('summary_earnings');

  static Key categoryChipKey(BreakCategory category) =>
      ValueKey<String>('category_chip_${category.name}');

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  final TextEditingController _minutes = TextEditingController();

  Timer? _ticker;
  late BreakCategory _category;
  late BreakCategory _quickCategory;
  late DateTime _quickDate;
  String _motivation = '';

  @override
  void initState() {
    super.initState();
    final TimerController timer = ref.read(timerControllerProvider);
    // A timer restored from storage keeps its category and keeps ticking.
    _category = timer.category ?? BreakCategory.bathroom;
    _quickCategory = BreakCategory.bathroom;
    final DateTime now = ref.read(clockProvider)();
    _quickDate = DateTime(now.year, now.month, now.day);
    if (timer.isRunning) {
      _motivation = randomMotivation();
      _startTicking();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _minutes.dispose();
    super.dispose();
  }

  void _startTicking() {
    _ticker?.cancel();
    _ticker = Timer.periodic(TimerScreen.tickInterval, (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopTicking() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _toast(String message, FcToastType type) =>
      ref.read(toastControllerProvider.notifier).show(message, type: type);

  String _money(num amount) =>
      formatCurrency(amount, currency: ref.read(currencyProvider));

  void _handleToggle() {
    final TimerController timer = ref.read(timerControllerProvider);
    if (timer.isRunning) {
      final TimerStopResult result = timer.stop();
      _stopTicking();
      if (result.logged) {
        _toast(
          'Break logged! You earned ${_money(result.earnings)}',
          FcToastType.success,
        );
      } else if (result.discarded) {
        // React dropped this on the floor without a word.
        _toast(TimerScreen.discardedMessage, FcToastType.warning);
      }
      setState(() {});
    } else {
      timer.start(_category);
      setState(() => _motivation = randomMotivation());
      _startTicking();
    }
  }

  void _handleQuickLog() {
    final int? minutes = int.tryParse(_minutes.text.trim());
    if (minutes == null ||
        minutes < TimerScreen.minQuickMinutes ||
        minutes > TimerScreen.maxQuickMinutes) {
      _toast(TimerScreen.invalidMinutesMessage, FcToastType.warning);
      return;
    }

    final int durationMs = minutes * 60000;
    final double rate = ref.read(perMinuteRateProvider);
    ref
        .read(appControllerProvider.notifier)
        .addBreak(
          BreakRecord(
            id: const Uuid().v4(),
            category: _quickCategory,
            durationMs: durationMs,
            // Noon local, matching `new Date(quickDate + 'T12:00:00')`.
            timestamp: DateTime(
              _quickDate.year,
              _quickDate.month,
              _quickDate.day,
              12,
            ),
          ),
        );
    _toast(
      'Break logged! You earned ${_money(calculateEarnings(durationMs, rate))}',
      FcToastType.success,
    );
    _minutes.clear();
    setState(() {});
  }

  void _handleDelete(String id) {
    ref.read(appControllerProvider.notifier).deleteBreak(id);
    _toast('Break deleted', FcToastType.info);
  }

  Future<void> _pickDate() async {
    final DateTime now = ref.read(clockProvider)();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _quickDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) setState(() => _quickDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = ref.watch(appControllerProvider);
    final double rate = ref.watch(perMinuteRateProvider);
    final String currency = ref.watch(currencyProvider);
    final DateTime now = ref.watch(clockProvider)();
    final TimerController timer = ref.watch(timerControllerProvider);

    final bool running = timer.isRunning;
    final Duration elapsed = timer.elapsed();
    final BreakCategory activeCategory = timer.category ?? _category;

    final List<BreakRecord> today = todayBreaks(state.breaks, now: now);
    final List<BreakRecord> recent =
        (<BreakRecord>[...state.breaks]
              ..sort((BreakRecord a, BreakRecord b) =>
                  b.timestamp.compareTo(a.timestamp)))
            .take(10)
            .toList();

    String money(num amount) => formatCurrency(amount, currency: currency);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
        CategoryChipRow(
          selected: activeCategory,
          enabled: !running,
          chipKeyFor: TimerScreen.categoryChipKey,
          onSelect: (BreakCategory category) =>
              setState(() => _category = category),
        ),
        const SizedBox(height: FcSpacing.m),
        Text(
          formatDuration(elapsed.inMilliseconds),
          key: TimerScreen.clockKey,
          textAlign: TextAlign.center,
          style: FcText.mono.copyWith(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: FcColors.ink,
          ),
        ),
        const SizedBox(height: FcSpacing.xxs),
        Text(
          money(calculateEarnings(elapsed.inMilliseconds, rate)),
          key: TimerScreen.earningsKey,
          textAlign: TextAlign.center,
          style: FcText.mono.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: FcColors.green,
          ),
        ),
        const SizedBox(height: FcSpacing.m),
        Center(
          child: FcButton(
            label: running ? 'STOP & LOG' : 'START BREAK',
            variant: running
                ? FcButtonVariant.danger
                : FcButtonVariant.primary,
            size: FcButtonSize.lg,
            onPressed: _handleToggle,
          ),
        ),
        if (running) ...<Widget>[
          const SizedBox(height: FcSpacing.s),
          Text(
            TimerScreen.runningStatus,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: FcColors.gray,
            ),
          ),
          const SizedBox(height: FcSpacing.xxs),
          Text(
            _motivation,
            key: TimerScreen.motivationKey,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: FcSpacing.xl),
        const _SectionHeading('Quick Log'),
        FcCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FcTextField(
                label: 'Minutes',
                fieldKey: TimerScreen.quickMinutesKey,
                controller: _minutes,
                hintText: '15',
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onSubmitted: (_) => _handleQuickLog(),
              ),
              const SizedBox(height: FcSpacing.s),
              FcDropdown<BreakCategory>(
                key: TimerScreen.quickCategoryKey,
                label: 'Category',
                value: _quickCategory,
                items: <FcDropdownItem<BreakCategory>>[
                  for (final BreakCategory category in BreakCategory.values)
                    FcDropdownItem<BreakCategory>(
                      value: category,
                      label: '${category.emoji} ${category.label}',
                    ),
                ],
                onChanged: (BreakCategory? category) {
                  if (category != null) {
                    setState(() => _quickCategory = category);
                  }
                },
              ),
              const SizedBox(height: FcSpacing.s),
              _DateField(
                key: TimerScreen.quickDateKey,
                date: _quickDate,
                onTap: _pickDate,
              ),
              const SizedBox(height: FcSpacing.s),
              Align(
                alignment: Alignment.centerLeft,
                child: FcButton(
                  label: 'Log Break',
                  variant: FcButtonVariant.secondary,
                  onPressed: _handleQuickLog,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FcSpacing.xl),
        const _SectionHeading("Today's Summary"),
        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryCard(
                label: 'Breaks Today',
                valueKey: TimerScreen.summaryCountKey,
                value: '${today.length}',
              ),
            ),
            const SizedBox(width: FcSpacing.xs),
            Expanded(
              child: _SummaryCard(
                label: 'Time on Break',
                valueKey: TimerScreen.summaryDurationKey,
                value: formatDuration(totalDuration(today)),
              ),
            ),
            const SizedBox(width: FcSpacing.xs),
            Expanded(
              child: _SummaryCard(
                label: 'Earnings Today',
                valueKey: TimerScreen.summaryEarningsKey,
                value: money(totalEarnings(today, rate)),
                highlight: true,
              ),
            ),
          ],
        ),
        if (recent.isNotEmpty) ...<Widget>[
          const SizedBox(height: FcSpacing.xl),
          const _SectionHeading('Recent Breaks'),
          for (final BreakRecord record in recent)
            BreakListItem(
              key: ValueKey<String>('break_item_${record.id}'),
              record: record,
              perMinuteRate: rate,
              currency: currency,
              now: now,
              onDelete: () => _handleDelete(record.id),
            ),
        ],
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FcSpacing.s),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.valueKey,
    this.highlight = false,
  });

  final String label;
  final String value;
  final Key valueKey;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return FcCard(
      padding: const EdgeInsets.all(FcSpacing.s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: FcSpacing.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              key: valueKey,
              style: FcText.mono.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: highlight ? FcColors.green : FcColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({super.key, required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  String get _label =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Date', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: FcSpacing.xxs),
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(
                horizontal: FcSpacing.s,
                vertical: FcSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: FcColors.navy,
                border: Border.all(
                  color: FcColors.gray.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _label,
                      style: FcText.mono.copyWith(
                        fontSize: 16,
                        color: FcColors.ink,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: FcColors.gray,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
