import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/domain/comparisons.dart';

void main() {
  group('comparison catalog', () {
    test('has the seven React items with their prices and emoji', () {
      expect(comparisonItems, hasLength(7));
      expect(
        comparisonItems.map((c) => c.name).toList(),
        <String>[
          'coffees',
          'burgers',
          'gallons of gas',
          'streaming subscriptions',
          'avocado toasts',
          'lottery tickets',
          'tacos',
        ],
      );
      expect(comparisonItems.map((c) => c.price).toList(), <double>[
        5.50,
        12.00,
        3.50,
        15.99,
        14.00,
        2.00,
        3.50,
      ]);
      for (final ComparisonItem item in comparisonItems) {
        expect(item.emoji, isNotEmpty, reason: item.name);
      }
    });
  });

  group('getComparisons', () {
    test('returns nothing when nothing is affordable', () {
      expect(getComparisons(0), isEmpty);
      expect(getComparisons(1.99), isEmpty);
    });

    test('includes an item exactly at its price and uses the singular label', () {
      final List<Comparison> results = getComparisons(2.00);
      expect(results, hasLength(1));
      expect(results.single.count, 1);
      expect(results.single.label, 'lottery ticket');
    });

    test('uses the plural label above one', () {
      final Comparison tacos = getComparisons(7.00).firstWhere(
        (c) => c.item.name == 'tacos',
      );
      expect(tacos.count, 2);
      expect(tacos.label, 'tacos');
    });

    test('floors the count', () {
      final Comparison coffees = getComparisons(11.99).firstWhere(
        (c) => c.item.name == 'coffees',
      );
      expect(coffees.count, 2);
    });

    test('drops items priced above the amount', () {
      final List<Comparison> results = getComparisons(6.00);
      expect(
        results.map((c) => c.item.name).toList(),
        <String>['coffees', 'gallons of gas', 'lottery tickets', 'tacos'],
      );
    });
  });
}
