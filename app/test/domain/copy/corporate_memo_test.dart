import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/domain/copy/corporate_memo.dart';
import 'package:fuckcorpo/domain/copy/fun_facts.dart';

String _usd(num amount) => '\$${amount.toStringAsFixed(2)}';

const int _minute = 60000;

void main() {
  group('C8 fun facts', () {
    test('the catalog carries all 32 facts verbatim at the ends', () {
      expect(funFacts.length, 32);
      expect(
        funFacts.first,
        'The average American spends 30 minutes per day on the toilet. '
        "That's 182 hours per year of tax-free income potential.",
      );
      expect(
        funFacts.last,
        'Corporate profits hit record highs in 2024. Your bathroom earnings '
        'are just wealth redistribution.',
      );
    });

    test('randomFact always returns a catalog entry', () {
      for (int i = 0; i < 50; i++) {
        expect(funFacts, contains(randomFact()));
      }
    });
  });

  group('C8 corporate memo branches', () {
    CorporateMemo memo({
      double earnings = 0,
      int breakCount = 0,
      num avgDurationMs = 0,
    }) => corporateMemoFor(
      earnings: earnings,
      breakCount: breakCount,
      avgDurationMs: avgDurationMs,
      formatMoney: _usd,
    );

    test('no breaks at all', () {
      expect(memo().subject, 'URGENT: Unrealized Revenue Alert');
      expect(
        memo().body,
        'Our records indicate zero bathroom break transactions on your '
        'account. This represents a critical loss of potential earnings. '
        'Please initiate your first break session immediately. The market '
        'waits for no one.',
      );
    });

    test('high earnings and many breaks wins over every other branch', () {
      final CorporateMemo m = memo(earnings: 100, breakCount: 50);
      expect(m.subject, 'RE: Outstanding Q-Performance Review');
      expect(m.body, contains('Senior Break Analyst'));
    });

    test('high earnings alone reports the lifetime figure', () {
      final CorporateMemo m = memo(earnings: 50, breakCount: 3);
      expect(m.subject, 'RE: Portfolio Performance Update');
      expect(m.body, contains(r'lifetime returns of $50.00 place you'));
    });

    test('many short breaks get the duration advisory in whole minutes', () {
      final CorporateMemo m = memo(
        earnings: 49.99,
        breakCount: 30,
        avgDurationMs: 4.6 * _minute,
      );
      expect(m.subject, 'ADVISORY: Break Duration Optimization');
      expect(m.body, contains('(30 sessions)'));
      expect(m.body, contains('duration of 5 minutes'));
    });

    test('fewer than ten breaks get the below-target memo', () {
      final CorporateMemo m = memo(earnings: 1, breakCount: 9);
      expect(m.subject, 'MEMO: Below-Target Break Frequency');
      expect(m.body, contains('only 9 logged sessions'));
    });

    test('ten or more moderate breaks get the compliance report', () {
      final CorporateMemo m = memo(
        earnings: 1,
        breakCount: 10,
        avgDurationMs: 8 * _minute,
      );
      expect(m.subject, 'STATUS: Quarterly Compliance Report');
      expect(m.body, contains('10 sessions logged'));
      expect(m.body, contains('average duration of 8 minutes'));
    });

    test('the money figure honours the injected formatter', () {
      final CorporateMemo m = corporateMemoFor(
        earnings: 75,
        breakCount: 2,
        avgDurationMs: 0,
        formatMoney: (num a) => '€${a.toStringAsFixed(2)}',
      );
      expect(m.body, contains('€75.00'));
    });
  });
}
