import 'package:flutter/foundation.dart';

/// How a salary figure is quoted. Wire values match the React `salary.type`.
enum SalaryType {
  annual('annual'),
  hourly('hourly'),
  monthly('monthly'),
  weekly('weekly');

  const SalaryType(this.wire);

  final String wire;

  /// Unknown or absent values fall back to `annual`, matching the `default`
  /// branch of `salaryToPerMinute`.
  static SalaryType fromWire(Object? value) {
    for (final SalaryType type in SalaryType.values) {
      if (type.wire == value) return type;
    }
    return SalaryType.annual;
  }
}

@immutable
class Salary {
  const Salary({
    required this.amount,
    required this.type,
    required this.currency,
  });

  static const Salary initial = Salary(
    amount: 0,
    type: SalaryType.annual,
    currency: 'USD',
  );

  final double amount;
  final SalaryType type;
  final String currency;

  Salary copyWith({double? amount, SalaryType? type, String? currency}) =>
      Salary(
        amount: amount ?? this.amount,
        type: type ?? this.type,
        currency: currency ?? this.currency,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'amount': amount,
    'type': type.wire,
    'currency': currency,
  };

  /// Tolerant parse: anything unusable falls back to the corresponding default
  /// rather than throwing, because a bad salary should not brick the app.
  factory Salary.fromJson(Object? json) {
    if (json is! Map) return initial;
    final Object? amount = json['amount'];
    return Salary(
      amount: amount is num ? amount.toDouble() : initial.amount,
      type: SalaryType.fromWire(json['type']),
      currency: json['currency'] is String
          ? json['currency'] as String
          : initial.currency,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Salary &&
      other.amount == amount &&
      other.type == type &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, type, currency);
}
