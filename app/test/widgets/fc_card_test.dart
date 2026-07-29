import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/core/theme/colors.dart';
import 'package:fuckcorpo/core/theme/spacing.dart';
import 'package:fuckcorpo/widgets/fc_card.dart';

import '../helpers/pump_app.dart';

BoxDecoration _surfaceOf(WidgetTester tester) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find.byKey(FcCard.surfaceKey),
  );
  return box.decoration as BoxDecoration;
}

void main() {
  group('FcCard', () {
    testWidgets('standard card is slate with a subtle gray border', (
      tester,
    ) async {
      await pumpFcApp(tester, const FcCard(child: Text('TODAY')));

      expect(find.text('TODAY'), findsOneWidget);
      final BoxDecoration decoration = _surfaceOf(tester);
      expect(decoration.color, FcColors.slate);
      expect(decoration.gradient, isNull);
      expect(decoration.border!.top.color, FcColors.gray.withValues(alpha: 0.2));
    });

    testWidgets('elevated card uses the navy gradient and a gold border', (
      tester,
    ) async {
      await pumpFcApp(
        tester,
        const FcCard(elevated: true, child: Text('LIFETIME')),
      );

      final BoxDecoration decoration = _surfaceOf(tester);
      expect(decoration.color, isNull);
      expect(
        (decoration.gradient! as LinearGradient).colors,
        <Color>[FcColors.slate, FcColors.navy],
      );
      expect(decoration.border!.top.color, FcColors.gold.withValues(alpha: 0.2));
    });

    testWidgets('padding defaults to the 24pt step and is overridable', (
      tester,
    ) async {
      await pumpFcApp(tester, const FcCard(child: Text('A')));
      Padding padding = tester.widget<Padding>(
        find.descendant(
          of: find.byKey(FcCard.surfaceKey),
          matching: find.byType(Padding),
        ),
      );
      expect(padding.padding, const EdgeInsets.all(FcSpacing.m));

      await pumpFcApp(
        tester,
        const FcCard(padding: EdgeInsets.all(FcSpacing.s), child: Text('A')),
      );
      padding = tester.widget<Padding>(
        find.descendant(
          of: find.byKey(FcCard.surfaceKey),
          matching: find.byType(Padding),
        ),
      );
      expect(padding.padding, const EdgeInsets.all(FcSpacing.s));
    });

    testWidgets('is tappable when onTap is supplied', (tester) async {
      int taps = 0;
      await pumpFcApp(
        tester,
        FcCard(onTap: () => taps++, child: const Text('A')),
      );

      await tester.tap(find.text('A'));
      await tester.pump();
      expect(taps, 1);
    });
  });
}
