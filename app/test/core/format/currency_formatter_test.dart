import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/core/format/currency_formatter.dart';

void main() {
  group('formatCurrency', () {
    test('formats USD with two decimals', () {
      expect(formatCurrency(1234.56), r'$1,234.56');
      expect(formatCurrency(0), r'$0.00');
      expect(formatCurrency(0.5, currency: 'USD'), r'$0.50');
    });

    test('formats EUR and GBP with their symbols', () {
      expect(formatCurrency(1234.56, currency: 'EUR'), '€1,234.56');
      expect(formatCurrency(1234.56, currency: 'GBP'), '£1,234.56');
    });

    test('formats CAD and AUD with the amount intact', () {
      expect(formatCurrency(1234.56, currency: 'CAD'), contains('1,234.56'));
      expect(formatCurrency(1234.56, currency: 'AUD'), contains('1,234.56'));
    });

    test('formats JPY with zero decimals (fixes BUG-009)', () {
      expect(formatCurrency(1234.56, currency: 'JPY'), '¥1,235');
      expect(formatCurrency(0, currency: 'JPY'), '¥0');
    });

    test('handles negative amounts', () {
      expect(formatCurrency(-5), r'-$5.00');
    });

    test('falls back to the code for an unknown currency', () {
      expect(formatCurrency(1234.56, currency: 'XYZ'), contains('1,234.56'));
    });
  });
}
