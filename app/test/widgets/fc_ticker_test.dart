import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/core/theme/colors.dart';
import 'package:fuckcorpo/domain/models/break_category.dart';
import 'package:fuckcorpo/domain/models/break_record.dart';
import 'package:fuckcorpo/widgets/fc_ticker.dart';

import '../helpers/pump_app.dart';

void main() {
  final DateTime now = DateTime(2026, 7, 28, 14);
  final List<BreakRecord> breaks = <BreakRecord>[
    BreakRecord(
      id: 'a',
      category: BreakCategory.bathroom,
      durationMs: 600000, // 10 min today
      timestamp: DateTime(2026, 7, 28, 9),
    ),
    BreakRecord(
      id: 'b',
      category: BreakCategory.smokeBreak,
      durationMs: 300000, // 5 min, last month
      timestamp: DateTime(2026, 6, 2, 9),
    ),
  ];

  group('FcTicker.buildItems', () {
    test('produces the five ticker rows in order', () {
      final List<FcTickerItem> items = FcTicker.buildItems(
        breaks: breaks,
        perMinuteRate: 1,
        now: now,
      );

      expect(
        items.map((FcTickerItem i) => i.label).toList(),
        <String>[r'$EARN', r'$TIME', r'$LIFE', r'$SESS', r'$RATE'],
      );
      expect(items[0].value, r'$10.00');
      expect(items[1].value, '10:00');
      expect(items[2].value, r'$15.00');
      expect(items[3].value, '2');
      expect(items[4].value, r'$1.00/min');
    });

    test(r'only $TIME is negative', () {
      final List<FcTickerItem> items = FcTicker.buildItems(
        breaks: breaks,
        perMinuteRate: 1,
        now: now,
      );

      expect(
        items.map((FcTickerItem i) => i.positive).toList(),
        <bool>[true, false, true, true, true],
      );
    });

    test('formats money in the selected currency', () {
      final List<FcTickerItem> items = FcTicker.buildItems(
        breaks: breaks,
        perMinuteRate: 1,
        currency: 'EUR',
        now: now,
      );

      expect(items[0].value, '€10.00');
      expect(items[4].value, '€1.00/min');
    });
  });

  group('FcTicker widget', () {
    testWidgets('renders each item twice for a seamless loop', (tester) async {
      await pumpFcApp(
        tester,
        FcTicker(
          items: FcTicker.buildItems(
            breaks: breaks,
            perMinuteRate: 1,
            now: now,
          ),
          animate: false,
        ),
      );

      for (final String label in <String>[
        r'$EARN',
        r'$TIME',
        r'$LIFE',
        r'$SESS',
        r'$RATE',
      ]) {
        expect(find.text(label), findsNWidgets(2));
      }
      expect(find.text(r'$10.00'), findsNWidgets(2));
    });

    testWidgets('colors positive values green and negative red', (tester) async {
      await pumpFcApp(
        tester,
        const FcTicker(
          items: <FcTickerItem>[
            FcTickerItem(label: r'$EARN', value: r'$1.00', positive: true),
            FcTickerItem(label: r'$TIME', value: '01:00', positive: false),
          ],
          animate: false,
        ),
      );

      expect(
        tester.widget<Text>(find.text(r'$1.00').first).style!.color,
        FcColors.green,
      );
      expect(
        tester.widget<Text>(find.text('01:00').first).style!.color,
        FcColors.red,
      );
    });
  });
}
