import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/widgets/animated_currency.dart';

import '../helpers/pump_app.dart';

void main() {
  group('AnimatedCurrency', () {
    testWidgets('counts up from zero and settles on the exact value', (
      tester,
    ) async {
      await pumpFcApp(tester, const AnimatedCurrency(value: 128.4));

      expect(find.text(r'$0.00'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 750));
      expect(find.text(r'$128.40'), findsNothing);
      await tester.pump(const Duration(milliseconds: 750));
      expect(find.text(r'$128.40'), findsOneWidget);
    });

    testWidgets('respects the selected currency', (tester) async {
      await pumpFcApp(
        tester,
        const AnimatedCurrency(value: 10, currency: 'EUR'),
      );
      await tester.pump(AnimatedCurrency.defaultDuration);

      expect(find.text('€10.00'), findsOneWidget);
    });

    testWidgets('JPY renders without decimals', (tester) async {
      await pumpFcApp(
        tester,
        const AnimatedCurrency(value: 1200, currency: 'JPY'),
      );
      await tester.pump(AnimatedCurrency.defaultDuration);

      expect(find.text('¥1,200'), findsOneWidget);
    });

    testWidgets('animates from the previous value when it changes', (
      tester,
    ) async {
      await pumpFcApp(tester, const AnimatedCurrency(value: 100));
      await tester.pump(AnimatedCurrency.defaultDuration);
      expect(find.text(r'$100.00'), findsOneWidget);

      await pumpFcApp(tester, const AnimatedCurrency(value: 200));
      await tester.pump();
      expect(find.text(r'$0.00'), findsNothing);
      await tester.pump(AnimatedCurrency.defaultDuration);
      expect(find.text(r'$200.00'), findsOneWidget);
    });

    testWidgets('applies the supplied text style', (tester) async {
      await pumpFcApp(
        tester,
        const AnimatedCurrency(
          value: 1,
          style: TextStyle(fontSize: 42, color: Color(0xFF00B559)),
        ),
      );
      await tester.pump(AnimatedCurrency.defaultDuration);

      expect(
        tester.widget<Text>(find.text(r'$1.00')).style!.fontSize,
        42,
      );
    });
  });
}
