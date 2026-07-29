import 'models/break_record.dart';
import 'models/salary.dart';

// Working hours assumptions, carried over verbatim from
// `src/utils/calculations.js`.
const int workHoursPerDay = 8;
const int workDaysPerWeek = 5;
const int workWeeksPerYear = 52;
const int workDaysPerYear = workDaysPerWeek * workWeeksPerYear;
const int workHoursPerYear = workDaysPerYear * workHoursPerDay;
const int workMinutesPerYear = workHoursPerYear * 60; // 124,800

/// Converts a quoted salary into dollars (or whatever currency) per working
/// minute.
double salaryToPerMinute(num amount, [SalaryType type = SalaryType.annual]) {
  final double annual = switch (type) {
    SalaryType.hourly => (amount * workHoursPerYear).toDouble(),
    SalaryType.monthly => (amount * 12).toDouble(),
    SalaryType.weekly => (amount * workWeeksPerYear).toDouble(),
    SalaryType.annual => amount.toDouble(),
  };
  return annual / workMinutesPerYear;
}

/// Earnings for a break of [durationMs] at [perMinuteRate].
double calculateEarnings(num durationMs, double perMinuteRate) =>
    (durationMs / 60000) * perMinuteRate;

/// Breaks whose timestamp falls in `[start, end)`.
///
/// React used an inclusive upper bound against an exclusive end date, which
/// double-counted a break landing exactly on midnight. Half-open is the
/// intended behavior and produces identical totals for every real timestamp.
List<BreakRecord> breaksInRange(
  List<BreakRecord> breaks,
  DateTime start,
  DateTime end,
) => breaks
    .where((b) => !b.timestamp.isBefore(start) && b.timestamp.isBefore(end))
    .toList();

List<BreakRecord> todayBreaks(List<BreakRecord> breaks, {DateTime? now}) {
  final DateTime ref = now ?? DateTime.now();
  final DateTime start = DateTime(ref.year, ref.month, ref.day);
  return breaksInRange(breaks, start, start.add(const Duration(days: 1)));
}

/// Week runs Sunday through Saturday, matching `Date.getDay()` semantics.
List<BreakRecord> weekBreaks(List<BreakRecord> breaks, {DateTime? now}) {
  final DateTime ref = now ?? DateTime.now();
  // Dart weekday is 1 (Mon) through 7 (Sun); JS getDay is 0 (Sun) through 6.
  final int daysSinceSunday = ref.weekday % 7;
  final DateTime start = DateTime(
    ref.year,
    ref.month,
    ref.day,
  ).subtract(Duration(days: daysSinceSunday));
  return breaksInRange(breaks, start, start.add(const Duration(days: 7)));
}

List<BreakRecord> monthBreaks(List<BreakRecord> breaks, {DateTime? now}) {
  final DateTime ref = now ?? DateTime.now();
  return breaksInRange(
    breaks,
    DateTime(ref.year, ref.month),
    DateTime(ref.year, ref.month + 1),
  );
}

List<BreakRecord> yearBreaks(List<BreakRecord> breaks, {DateTime? now}) {
  final DateTime ref = now ?? DateTime.now();
  return breaksInRange(breaks, DateTime(ref.year), DateTime(ref.year + 1));
}

/// Total earnings across [breaks] at [perMinuteRate].
double totalEarnings(List<BreakRecord> breaks, double perMinuteRate) =>
    breaks.fold<double>(
      0,
      (sum, b) => sum + calculateEarnings(b.durationMs, perMinuteRate),
    );

/// Total logged milliseconds across [breaks].
int totalDuration(List<BreakRecord> breaks) =>
    breaks.fold<int>(0, (sum, b) => sum + b.durationMs);

/// Relative timestamp label used in the recent-breaks list.
String timeAgo(DateTime timestamp, {DateTime? now}) {
  final int minutes = (now ?? DateTime.now())
      .difference(timestamp)
      .inMinutes;
  if (minutes < 1) return 'just now';
  if (minutes < 60) return '${minutes}m ago';
  final int hours = minutes ~/ 60;
  if (hours < 24) return '${hours}h ago';
  return '${hours ~/ 24}d ago';
}
