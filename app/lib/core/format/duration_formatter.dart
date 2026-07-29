/// Formats a millisecond duration as `HH:MM:SS` when it reaches an hour, and
/// `MM:SS` otherwise. Port of `formatDuration` in `src/utils/calculations.js`.
String formatDuration(num milliseconds) {
  final int totalSeconds = (milliseconds ~/ 1000);
  final int hours = totalSeconds ~/ 3600;
  final int minutes = (totalSeconds % 3600) ~/ 60;
  final int seconds = totalSeconds % 60;
  String pad(int n) => n.toString().padLeft(2, '0');
  if (hours > 0) return '${pad(hours)}:${pad(minutes)}:${pad(seconds)}';
  return '${pad(minutes)}:${pad(seconds)}';
}
