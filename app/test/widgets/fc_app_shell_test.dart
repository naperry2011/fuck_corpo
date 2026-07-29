import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/core/theme/spacing.dart';
import 'package:fuckcorpo/widgets/fc_app_shell.dart';
import 'package:fuckcorpo/widgets/fc_navbar.dart';
import 'package:fuckcorpo/widgets/fc_ticker.dart';

import '../helpers/pump_app.dart';

const List<FcTickerItem> _items = <FcTickerItem>[
  FcTickerItem(label: r'$EARN', value: r'$1.00', positive: true),
];

Future<void> _pumpShell(WidgetTester tester, Size size) => pumpFcApp(
  tester,
  FcAppShell(
    currentIndex: 0,
    onSelect: (_) {},
    tickerItems: _items,
    animateTicker: false,
    child: const Text('BODY'),
  ),
  surfaceSize: size,
);

void main() {
  group('FcAppShell', () {
    testWidgets('composes navbar, ticker and body', (tester) async {
      await _pumpShell(tester, const Size(1280, 900));

      expect(find.byType(FcNavbar), findsOneWidget);
      expect(find.byType(FcTicker), findsOneWidget);
      expect(find.text('BODY'), findsOneWidget);
    });

    testWidgets('clamps content to the 1200pt container on wide screens', (
      tester,
    ) async {
      await _pumpShell(tester, const Size(1440, 900));

      expect(
        tester.getSize(find.byKey(FcAppShell.contentKey)).width,
        FcLayout.contentWidth,
      );
    });

    testWidgets('content fills the viewport below the container width', (
      tester,
    ) async {
      await _pumpShell(tester, const Size(768, 900));

      expect(tester.getSize(find.byKey(FcAppShell.contentKey)).width, 768);
    });

    testWidgets('nav sits above the ticker on desktop and below it on mobile', (
      tester,
    ) async {
      await _pumpShell(tester, const Size(1280, 900));
      expect(
        tester.getTopLeft(find.byType(FcNavbar)).dy <
            tester.getTopLeft(find.byType(FcTicker)).dy,
        isTrue,
      );

      await _pumpShell(tester, const Size(360, 800));
      expect(
        tester.getTopLeft(find.byType(FcNavbar)).dy >
            tester.getTopLeft(find.byType(FcTicker)).dy,
        isTrue,
      );
    });
  });
}
