import 'package:flutter/foundation.dart';

/// One priced thing the user's break earnings can buy. Price, copy and emoji
/// live together here; React split the emoji into `Dashboard.jsx`.
@immutable
class ComparisonItem {
  const ComparisonItem({
    required this.name,
    required this.unit,
    required this.plural,
    required this.price,
    required this.emoji,
  });

  final String name;
  final String unit;
  final String plural;
  final double price;
  final String emoji;
}

const List<ComparisonItem> comparisonItems = <ComparisonItem>[
  ComparisonItem(
    name: 'coffees',
    unit: 'coffee',
    plural: 'coffees',
    price: 5.50,
    emoji: '☕',
  ),
  ComparisonItem(
    name: 'burgers',
    unit: 'burger',
    plural: 'burgers',
    price: 12.00,
    emoji: '\u{1F354}',
  ),
  ComparisonItem(
    name: 'gallons of gas',
    unit: 'gallon of gas',
    plural: 'gallons of gas',
    price: 3.50,
    emoji: '⛽',
  ),
  ComparisonItem(
    name: 'streaming subscriptions',
    unit: 'month of streaming',
    plural: 'months of streaming',
    price: 15.99,
    emoji: '\u{1F4FA}',
  ),
  ComparisonItem(
    name: 'avocado toasts',
    unit: 'avocado toast',
    plural: 'avocado toasts',
    price: 14.00,
    emoji: '\u{1F951}',
  ),
  ComparisonItem(
    name: 'lottery tickets',
    unit: 'lottery ticket',
    plural: 'lottery tickets',
    price: 2.00,
    emoji: '\u{1F3B0}',
  ),
  ComparisonItem(
    name: 'tacos',
    unit: 'taco',
    plural: 'tacos',
    price: 3.50,
    emoji: '\u{1F32E}',
  ),
];

/// An affordable count of one [ComparisonItem].
@immutable
class Comparison {
  const Comparison({required this.item, required this.count});

  final ComparisonItem item;
  final int count;

  String get label => count == 1 ? item.unit : item.plural;
}

/// Every catalog item the user can afford at least one of.
List<Comparison> getComparisons(num amount) => <Comparison>[
  for (final ComparisonItem item in comparisonItems)
    if ((amount / item.price).floor() > 0)
      Comparison(item: item, count: (amount / item.price).floor()),
];
