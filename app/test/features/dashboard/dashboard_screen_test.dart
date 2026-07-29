import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/data/app_repository.dart';
import 'package:fuckcorpo/domain/models/app_settings.dart';
import 'package:fuckcorpo/domain/models/app_state.dart';
import 'package:fuckcorpo/domain/models/break_category.dart';
import 'package:fuckcorpo/domain/models/break_record.dart';
import 'package:fuckcorpo/domain/models/salary.dart';
import 'package:fuckcorpo/features/dashboard/dashboard_metrics.dart';
import 'package:fuckcorpo/features/dashboard/dashboard_screen.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/memory_store.dart';
import '../../helpers/pump_app.dart';

/// Tuesday. The week therefore starts Sunday 2026-07-26.
final DateTime _now = DateTime(2026, 7, 28, 14, 30);

/// 124,800 annual over 124,800 working minutes is exactly 1.00 per minute,
/// which keeps every expected figure readable.
const Salary _salary = Salary(
  amount: 124800,
  type: SalaryType.annual,
  currency: 'USD',
);

final List<BreakRecord> _breaks = <BreakRecord>[
  BreakRecord(
    id: 'today',
    category: BreakCategory.bathroom,
    durationMs: 10 * 60000,
    timestamp: DateTime(2026, 7, 28, 9),
  ),
  BreakRecord(
    id: 'week',
    category: BreakCategory.coffeeBreak,
    durationMs: 20 * 60000,
    timestamp: DateTime(2026, 7, 26, 9),
  ),
  BreakRecord(
    id: 'month',
    category: BreakCategory.smokeBreak,
    durationMs: 30 * 60000,
    timestamp: DateTime(2026, 7, 5, 9),
  ),
  BreakRecord(
    id: 'year',
    category: BreakCategory.bathroom,
    durationMs: 40 * 60000,
    timestamp: DateTime(2026, 2, 10, 19),
  ),
];

MemoryStore _store({
  List<BreakRecord> breaks = const <BreakRecord>[],
  AppSettings? settings,
}) => MemoryStore(<String, String>{
  AppRepository.storageKey: jsonEncode(
    AppState(
      schemaVersion: AppState.currentSchemaVersion,
      salary: _salary,
      breaks: breaks,
      settings: settings ?? AppSettings.initial,
      achievements: const <String>[],
      onboarded: true,
    ).toJson(),
  ),
});

Future<void> _pump(WidgetTester tester, MemoryStore store) async {
  await pumpFcScreen(
    tester,
    const DashboardScreen(),
    store: store,
    clock: FakeClock(_now),
    surfaceSize: const Size(1100, 6000),
  );
  // Let the count-up animations land on their final values.
  await tester.pump(const Duration(milliseconds: 1600));
}

String _textAt(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

void main() {
  group('D1 empty state', () {
    testWidgets('shows the confidential header and the no-data card', (
      tester,
    ) async {
      await _pump(tester, _store());

      expect(find.text('CONFIDENTIAL'), findsOneWidget);
      expect(find.text('YOUR QUARTERLY EARNINGS REPORT'), findsOneWidget);
      expect(
        find.text(
          'No data yet. Start tracking your breaks to see your earnings '
          'report.',
        ),
        findsOneWidget,
      );
      // None of the populated sections render.
      expect(find.text('MARKET ANALYSIS'), findsNothing);
      expect(find.text('PERFORMANCE METRICS'), findsNothing);
    });
  });

  group('D2 header', () {
    testWidgets('carries the confidential mark, title and subtitle', (
      tester,
    ) async {
      await _pump(tester, _store(breaks: _breaks));

      expect(find.text('CONFIDENTIAL'), findsOneWidget);
      expect(find.text('YOUR QUARTERLY EARNINGS REPORT'), findsOneWidget);
      expect(
        find.text(
          'Internal document -- Do not distribute outside the restroom',
        ),
        findsOneWidget,
      );
    });
  });

  group('D3 running totals', () {
    testWidgets('today, week, month, year and lifetime all resolve', (
      tester,
    ) async {
      await _pump(tester, _store(breaks: _breaks));

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('THIS MONTH'), findsOneWidget);
      expect(find.text('THIS YEAR'), findsOneWidget);
      expect(find.text('LIFETIME EARNINGS'), findsOneWidget);

      expect(find.text(r'$10.00'), findsOneWidget);
      expect(find.text(r'$30.00'), findsOneWidget);
      expect(find.text(r'$60.00'), findsOneWidget);
      // This year and lifetime are both 100.00.
      expect(find.text(r'$100.00'), findsNWidgets(2));
    });

    testWidgets('the currency setting applies to the totals', (tester) async {
      await _pump(
        tester,
        _store(
          breaks: _breaks,
          settings: AppSettings.initial.copyWith(currency: 'EUR'),
        ),
      );

      expect(find.text(r'$10.00'), findsNothing);
      expect(find.textContaining('10.00'), findsWidgets);
      expect(find.textContaining('€'), findsWidgets);
    });
  });

  group('D4 market analysis', () {
    testWidgets('renders a fun fact and rotates it after ten seconds', (
      tester,
    ) async {
      await _pump(tester, _store(breaks: _breaks));

      expect(find.text('MARKET ANALYSIS'), findsOneWidget);
      final String first = _textAt(tester, DashboardScreen.funFactKey);
      expect(first, isNotEmpty);

      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 500));

      expect(_textAt(tester, DashboardScreen.funFactKey), isNot(first));
    });
  });

  group('D5 corporate memo', () {
    testWidgets('addresses the padded employee number and shows the memo', (
      tester,
    ) async {
      await _pump(tester, _store(breaks: _breaks));

      expect(find.text('INTERNAL CORRESPONDENCE'), findsOneWidget);
      expect(find.text('To: Employee #01004'), findsOneWidget);
      expect(
        find.text('From: Management, Break Analytics Division'),
        findsOneWidget,
      );
      // 100.00 lifetime with 4 breaks lands on the portfolio branch.
      expect(
        find.text('Subject: RE: Portfolio Performance Update'),
        findsOneWidget,
      );
      expect(
        find.textContaining(r'lifetime returns of $100.00'),
        findsOneWidget,
      );
    });
  });

  group('D6 / D7 / D8 charts', () {
    testWidgets('the three chart sections are titled and labelled', (
      tester,
    ) async {
      await _pump(tester, _store(breaks: _breaks));

      expect(find.text('EARNINGS OVER TIME'), findsOneWidget);
      expect(find.text('BREAK PATTERNS'), findsOneWidget);
      expect(find.text('CATEGORY BREAKDOWN'), findsOneWidget);

      // 24 hour buckets, labelled 12AM through 11PM.
      for (int hour = 0; hour < 24; hour++) {
        expect(
          find.byKey(DashboardScreen.hourBucketKey(hour)),
          findsOneWidget,
          reason: 'hour bucket $hour is missing',
        );
      }
      expect(find.text('12AM'), findsOneWidget);
      expect(find.text('11PM'), findsOneWidget);

      // The doughnut legend names every category present, with its count.
      expect(find.text('Bathroom 2'), findsOneWidget);
      expect(find.text('Coffee Break 1'), findsOneWidget);
      expect(find.text('Smoke Break 1'), findsOneWidget);
      expect(find.text('Mental Health Moment 0'), findsNothing);
    });
  });

  group('D9 performance metrics and comparisons', () {
    testWidgets('the four metric cards report the derived figures', (
      tester,
    ) async {
      await _pump(tester, _store(breaks: _breaks));

      expect(find.text('PERFORMANCE METRICS'), findsOneWidget);
      expect(find.text('AVG SESSION LENGTH'), findsOneWidget);
      expect(find.text('LONGEST SESSION EVER'), findsOneWidget);
      expect(find.text('TOTAL BREAKS'), findsOneWidget);
      expect(find.text('MOST COMMON CATEGORY'), findsOneWidget);

      // 100 minutes over 4 breaks is 25:00; the longest is 40:00.
      expect(_textAt(tester, DashboardScreen.avgSessionKey), '25:00');
      expect(_textAt(tester, DashboardScreen.longestSessionKey), '40:00');
      expect(_textAt(tester, DashboardScreen.totalBreaksKey), '4');
      expect(
        _textAt(tester, DashboardScreen.mostCommonCategoryKey),
        'Bathroom',
      );
    });

    testWidgets('the comparison cards list what the lifetime total buys', (
      tester,
    ) async {
      await _pump(tester, _store(breaks: _breaks));

      expect(find.text('YOUR EARNINGS CAN BUY...'), findsOneWidget);
      // 100.00 buys 18 coffees at 5.50 and 8 burgers at 12.00.
      expect(find.text('18'), findsOneWidget);
      expect(find.text('coffees'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('burgers'), findsOneWidget);
    });

    testWidgets('a lifetime total under the cheapest item hides the section', (
      tester,
    ) async {
      await _pump(
        tester,
        _store(
          breaks: <BreakRecord>[
            BreakRecord(
              id: 'tiny',
              category: BreakCategory.bathroom,
              durationMs: 60000,
              timestamp: DateTime(2026, 7, 28, 9),
            ),
          ],
        ),
      );

      expect(find.text('YOUR EARNINGS CAN BUY...'), findsNothing);
    });
  });

  group('metrics helper agreement', () {
    test('the screen and the helper agree on the employee number', () {
      expect(employeeNumber(_breaks.length), '01004');
    });
  });
}
