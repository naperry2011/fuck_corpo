import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/core/theme/colors.dart';
import 'package:fuckcorpo/widgets/fc_dropdown.dart';
import 'package:fuckcorpo/widgets/fc_switch.dart';
import 'package:fuckcorpo/widgets/fc_text_field.dart';

import '../helpers/pump_app.dart';

void main() {
  group('FcTextField', () {
    testWidgets('renders label and reports changes', (tester) async {
      String? typed;
      await pumpFcApp(
        tester,
        FcTextField(
          label: 'ANNUAL SALARY',
          onChanged: (String v) => typed = v,
        ),
      );

      expect(find.text('ANNUAL SALARY'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '65000');
      expect(typed, '65000');
    });

    testWidgets('surfaces an error message', (tester) async {
      await pumpFcApp(
        tester,
        const FcTextField(label: 'SALARY', errorText: 'Enter a number'),
      );

      expect(find.text('Enter a number'), findsOneWidget);
    });

    testWidgets('shows a prefix when supplied', (tester) async {
      await pumpFcApp(
        tester,
        const FcTextField(label: 'SALARY', prefixText: r'$'),
      );

      expect(find.text(r'$'), findsOneWidget);
    });
  });

  group('FcDropdown', () {
    testWidgets('renders the selected item and reports a new selection', (
      tester,
    ) async {
      String? picked;
      await pumpFcApp(
        tester,
        FcDropdown<String>(
          label: 'CURRENCY',
          value: 'USD',
          items: const <FcDropdownItem<String>>[
            FcDropdownItem<String>(value: 'USD', label: 'USD'),
            FcDropdownItem<String>(value: 'EUR', label: 'EUR'),
          ],
          onChanged: (String? v) => picked = v,
        ),
      );

      expect(find.text('CURRENCY'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EUR').last);
      await tester.pumpAndSettle();
      expect(picked, 'EUR');
    });
  });

  group('FcSwitch', () {
    testWidgets('renders label and toggles', (tester) async {
      bool? next;
      await pumpFcApp(
        tester,
        FcSwitch(
          label: 'Sound Effects',
          value: false,
          onChanged: (bool v) => next = v,
        ),
      );

      expect(find.text('Sound Effects'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(next, isTrue);
    });

    testWidgets('uses brand green when on', (tester) async {
      await pumpFcApp(
        tester,
        FcSwitch(label: 'Sound', value: true, onChanged: (_) {}),
      );

      final Switch widget = tester.widget<Switch>(find.byType(Switch));
      expect(widget.activeThumbColor, FcColors.green);
    });
  });
}
