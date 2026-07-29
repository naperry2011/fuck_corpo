import 'package:flutter/foundation.dart';

/// The satirical memo shown under INTERNAL CORRESPONDENCE on the dashboard.
@immutable
class CorporateMemo {
  const CorporateMemo({required this.subject, required this.body});

  final String subject;
  final String body;
}

/// Port of `getCorporateMemo` in `src/utils/funFacts.js`.
///
/// React hard-coded a `$` in the portfolio branch. [formatMoney] is injected
/// instead so the memo honours the currency setting like every other figure
/// (deviation D-108).
CorporateMemo corporateMemoFor({
  required double earnings,
  required int breakCount,
  required num avgDurationMs,
  required String Function(num) formatMoney,
}) {
  final int avgMinutes = (avgDurationMs / 60000).round();

  if (earnings >= 100 && breakCount >= 50) {
    return const CorporateMemo(
      subject: 'RE: Outstanding Q-Performance Review',
      body:
          'Congratulations. Your bathroom earnings have exceeded projections '
          'by a significant margin. The Board recommends maintaining current '
          'strategy and exploring expansion into additional break categories. '
          'Your dedication to the cause has not gone unnoticed. A promotion to '
          'Senior Break Analyst is under consideration.',
    );
  }

  if (earnings >= 50) {
    return CorporateMemo(
      subject: 'RE: Portfolio Performance Update',
      body:
          'Your bathroom investment portfolio is performing above benchmark. '
          'Current lifetime returns of ${formatMoney(earnings)} place you in '
          'the upper quartile of break-takers. Management recommends continued '
          'hydration and strategic restroom visits to maintain momentum.',
    );
  }

  if (breakCount >= 30 && earnings < 50) {
    return CorporateMemo(
      subject: 'ADVISORY: Break Duration Optimization',
      body:
          'Our analytics department has flagged your account. While your break '
          'frequency ($breakCount sessions) is commendable, your average '
          'session duration of $avgMinutes minutes suggests room for '
          'optimization. Consider extending your sessions to maximize '
          'per-break ROI.',
    );
  }

  if (breakCount > 0 && breakCount < 10) {
    return CorporateMemo(
      subject: 'MEMO: Below-Target Break Frequency',
      body:
          'Your bathroom investment frequency is below target. With only '
          '$breakCount logged sessions, HR recommends increasing hydration to '
          'optimize break opportunities. Remember: every unlogged break is '
          'unrealized revenue. The quarterly review board expects improvement.',
    );
  }

  if (breakCount >= 10) {
    return CorporateMemo(
      subject: 'STATUS: Quarterly Compliance Report',
      body:
          'Your break activity is tracking within acceptable parameters. '
          '$breakCount sessions logged with an average duration of $avgMinutes '
          'minutes. Continue current operations. Management will issue further '
          'guidance pending annual review.',
    );
  }

  return const CorporateMemo(
    subject: 'URGENT: Unrealized Revenue Alert',
    body:
        'Our records indicate zero bathroom break transactions on your '
        'account. This represents a critical loss of potential earnings. '
        'Please initiate your first break session immediately. The market '
        'waits for no one.',
  );
}
