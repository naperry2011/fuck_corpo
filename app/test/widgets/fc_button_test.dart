import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/core/theme/colors.dart';
import 'package:fuckcorpo/widgets/fc_button.dart';

import '../helpers/pump_app.dart';

BoxDecoration _surfaceOf(WidgetTester tester) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find.byKey(FcButton.surfaceKey),
  );
  return box.decoration as BoxDecoration;
}

void main() {
  group('FcButton', () {
    testWidgets('renders its label and fires onPressed', (tester) async {
      int taps = 0;
      await pumpFcApp(
        tester,
        FcButton(label: 'START BREAK', onPressed: () => taps++),
      );

      expect(find.text('START BREAK'), findsOneWidget);
      await tester.tap(find.byType(FcButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('is disabled and dimmed when onPressed is null', (
      tester,
    ) async {
      await pumpFcApp(tester, const FcButton(label: 'START BREAK'));

      expect(tester.widget<FcButton>(find.byType(FcButton)).enabled, isFalse);
      final Opacity opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(FcButton),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.5);
      await tester.tap(find.byType(FcButton));
      await tester.pump();
    });

    testWidgets('primary uses the green gradient with no border', (
      tester,
    ) async {
      await pumpFcApp(
        tester,
        FcButton(label: 'GO', onPressed: () {}),
      );

      final BoxDecoration decoration = _surfaceOf(tester);
      expect(decoration.border, isNull);
      expect(
        (decoration.gradient! as LinearGradient).colors,
        <Color>[FcColors.green, FcColors.greenDark],
      );
    });

    testWidgets('secondary is transparent with a green border', (tester) async {
      await pumpFcApp(
        tester,
        FcButton(
          label: 'GO',
          variant: FcButtonVariant.secondary,
          onPressed: () {},
        ),
      );

      final BoxDecoration decoration = _surfaceOf(tester);
      expect(decoration.gradient, isNull);
      expect(decoration.color, Colors.transparent);
      expect(decoration.border!.top.color, FcColors.green);
      expect(decoration.border!.top.width, 2);
      expect(
        tester.widget<Text>(find.text('GO')).style!.color,
        FcColors.green,
      );
    });

    testWidgets('danger uses the red gradient', (tester) async {
      await pumpFcApp(
        tester,
        FcButton(
          label: 'CLEAR',
          variant: FcButtonVariant.danger,
          onPressed: () {},
        ),
      );

      expect(
        (_surfaceOf(tester).gradient! as LinearGradient).colors.first,
        FcColors.red,
      );
    });

    testWidgets('ghost is transparent with gray label', (tester) async {
      await pumpFcApp(
        tester,
        FcButton(
          label: 'CANCEL',
          variant: FcButtonVariant.ghost,
          onPressed: () {},
        ),
      );

      final BoxDecoration decoration = _surfaceOf(tester);
      expect(decoration.gradient, isNull);
      expect(decoration.border!.top.width, 1);
      expect(
        tester.widget<Text>(find.text('CANCEL')).style!.color,
        FcColors.gray,
      );
    });

    testWidgets('sizes scale padding and font size', (tester) async {
      for (final (FcButtonSize size, double fontSize, double vertical) in <
          (FcButtonSize, double, double)
      >[
        (FcButtonSize.sm, 14, 8),
        (FcButtonSize.md, 16, 14),
        (FcButtonSize.lg, 18, 18),
      ]) {
        await pumpFcApp(
          tester,
          FcButton(label: 'GO', size: size, onPressed: () {}),
        );
        expect(tester.widget<Text>(find.text('GO')).style!.fontSize, fontSize);
        final Padding padding = tester.widget<Padding>(
          find.descendant(
            of: find.byKey(FcButton.surfaceKey),
            matching: find.byType(Padding),
          ),
        );
        expect(
          (padding.padding as EdgeInsets).vertical,
          vertical * 2,
        );
      }
    });

    testWidgets('renders a leading icon when given one', (tester) async {
      await pumpFcApp(
        tester,
        FcButton(label: 'GO', icon: Icons.play_arrow, onPressed: () {}),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });
}
