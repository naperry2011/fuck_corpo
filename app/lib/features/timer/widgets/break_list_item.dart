import 'package:flutter/material.dart';

import '../../../core/format/currency_formatter.dart';
import '../../../core/format/duration_formatter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../domain/calculations.dart';
import '../../../domain/models/break_record.dart';
import '../../../widgets/fc_card.dart';

/// One row of `.recent-breaks-list`: emoji, category, time ago, duration,
/// earnings, delete.
class BreakListItem extends StatelessWidget {
  const BreakListItem({
    super.key,
    required this.record,
    required this.perMinuteRate,
    required this.currency,
    required this.now,
    required this.onDelete,
  });

  final BreakRecord record;
  final double perMinuteRate;
  final String currency;
  final DateTime now;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FcSpacing.xs),
      child: FcCard(
        padding: const EdgeInsets.symmetric(
          horizontal: FcSpacing.s,
          vertical: FcSpacing.xs,
        ),
        child: Row(
          children: <Widget>[
            Text(record.category.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: FcSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    record.category.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    timeAgo(record.timestamp, now: now),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  formatDuration(record.durationMs),
                  style: FcText.mono.copyWith(
                    fontSize: 14,
                    color: FcColors.ink,
                  ),
                ),
                Text(
                  formatCurrency(
                    calculateEarnings(record.durationMs, perMinuteRate),
                    currency: currency,
                  ),
                  style: FcText.mono.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FcColors.green,
                  ),
                ),
              ],
            ),
            IconButton(
              key: ValueKey<String>('break_delete_${record.id}'),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              color: FcColors.gray,
              tooltip: 'Delete ${record.category.label} break',
            ),
          ],
        ),
      ),
    );
  }
}
