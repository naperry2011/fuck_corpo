import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/core/theme/colors.dart';
import 'package:fuckcorpo/widgets/fc_navbar.dart';

import '../helpers/pump_app.dart';

void main() {
  group('FcNavbar', () {
    testWidgets('renders the brand and the four destinations', (tester) async {
      await pumpFcApp(
        tester,
        FcNavbar(currentIndex: 0, onSelect: (_) {}),
        surfaceSize: const Size(1280, 800),
      );

      expect(find.text(r'$'), findsOneWidget);
      expect(find.text('FUCKCORPO'), findsOneWidget);
      for (final String label in <String>[
        'Timer',
        'Dashboard',
        'Achievements',
        'Settings',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(fcNavDestinations.map((FcNavDestination d) => d.route).toList(), <
        String
      >['/', '/dashboard', '/achievements', '/settings']);
    });

    testWidgets('highlights only the active destination', (tester) async {
      await pumpFcApp(
        tester,
        FcNavbar(currentIndex: 2, onSelect: (_) {}),
        surfaceSize: const Size(1280, 800),
      );

      expect(
        tester.widget<Text>(find.text('Achievements')).style!.color,
        FcColors.green,
      );
      expect(
        tester.widget<Text>(find.text('Timer')).style!.color,
        isNot(FcColors.green),
      );
    });

    testWidgets('reports the tapped destination index', (tester) async {
      int? selected;
      await pumpFcApp(
        tester,
        FcNavbar(currentIndex: 0, onSelect: (int i) => selected = i),
        surfaceSize: const Size(1280, 800),
      );

      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(selected, 3);
    });

    testWidgets('drops the brand and shows icons only on narrow screens', (
      tester,
    ) async {
      await pumpFcApp(
        tester,
        FcNavbar(currentIndex: 0, onSelect: (_) {}),
        surfaceSize: const Size(360, 800),
      );

      expect(find.text('FUCKCORPO'), findsNothing);
      expect(find.byIcon(fcNavDestinations.first.icon), findsOneWidget);
    });
  });
}
