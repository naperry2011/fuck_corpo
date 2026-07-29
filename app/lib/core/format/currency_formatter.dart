import 'package:intl/intl.dart';

/// The single currency seam for the app. Every money figure routes through
/// here, which is what makes the currency setting actually apply (BUG-002) and
/// what gives JPY its correct zero-decimal rendering (BUG-009).
String formatCurrency(num amount, {String currency = 'USD'}) {
  final NumberFormat format = NumberFormat.simpleCurrency(
    locale: 'en_US',
    name: currency,
  );
  return format.format(amount);
}

/// Number of fraction digits `intl` uses for [currency]. Exposed so chart tick
/// callbacks and text fields can agree with [formatCurrency].
int currencyDecimalDigits(String currency) =>
    NumberFormat.simpleCurrency(locale: 'en_US', name: currency).decimalDigits ??
    2;
