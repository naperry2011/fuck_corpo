import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/core/format/duration_formatter.dart';

void main() {
  group('formatDuration', () {
    test('renders MM:SS below one hour', () {
      expect(formatDuration(0), '00:00');
      expect(formatDuration(1000), '00:01');
      expect(formatDuration(59 * 1000), '00:59');
      expect(formatDuration(60 * 1000), '01:00');
      expect(formatDuration(59 * 60 * 1000 + 59 * 1000), '59:59');
    });

    test('renders HH:MM:SS at or above one hour', () {
      expect(formatDuration(3600 * 1000), '01:00:00');
      expect(formatDuration(3661 * 1000), '01:01:01');
    });

    test('renders past 24 hours without wrapping', () {
      expect(formatDuration(25 * 3600 * 1000), '25:00:00');
    });

    test('truncates sub-second remainders like the React implementation', () {
      expect(formatDuration(1999), '00:01');
    });
  });
}
