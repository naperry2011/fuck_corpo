import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/app.dart';
import 'package:fuckcorpo/data/app_repository.dart';
import 'package:fuckcorpo/domain/models/app_settings.dart';
import 'package:fuckcorpo/domain/models/app_state.dart';
import 'package:fuckcorpo/domain/models/break_record.dart';
import 'package:fuckcorpo/domain/models/salary.dart';
import 'package:fuckcorpo/features/achievements/achievements_screen.dart';
import 'package:fuckcorpo/features/dashboard/dashboard_screen.dart';
import 'package:fuckcorpo/features/onboarding/landing_screen.dart';
import 'package:fuckcorpo/features/settings/settings_screen.dart';
import 'package:fuckcorpo/features/timer/timer_screen.dart';
import 'package:fuckcorpo/state/providers.dart';

import 'helpers/fake_clock.dart';
import 'helpers/memory_store.dart';

final DateTime _now = DateTime(2026, 7, 28, 10);

MemoryStore _onboardedStore({AppSettings? settings}) => MemoryStore(
  <String, String>{
    AppRepository.storageKey: jsonEncode(
      AppState(
        schemaVersion: AppState.currentSchemaVersion,
        salary: const Salary(
          amount: 124800,
          type: SalaryType.annual,
          currency: 'USD',
        ),
        breaks: const <BreakRecord>[],
        settings: settings ?? AppSettings.initial,
        achievements: const <String>[],
        onboarded: true,
      ).toJson(),
    ),
  },
);

Future<void> _settleRouter(WidgetTester tester) async {
  // The shell ticker intentionally animates forever, so pumpAndSettle would
  // never complete. Two deterministic pumps are enough for router redirects.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpApp(WidgetTester tester, MemoryStore store) async {
  tester.view.physicalSize = const Size(1200, 2400) * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(FakeClock(_now).call),
      ],
      child: const FuckCorpoApp(),
    ),
  );
  await _settleRouter(tester);
}

void main() {
  testWidgets('X2 not onboarded renders the landing gate, not the shell', (
    tester,
  ) async {
    await _pumpApp(tester, MemoryStore());

    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.byType(TimerScreen), findsNothing);
    // The navbar is part of the shell, which the gate replaces.
    expect(find.text('Achievements'), findsNothing);
  });

  testWidgets('X2 onboarded lands on the Timer inside the shell', (
    tester,
  ) async {
    await _pumpApp(tester, _onboardedStore());

    expect(find.byType(TimerScreen), findsOneWidget);
    expect(find.byType(LandingScreen), findsNothing);
    expect(find.textContaining('FUCKCORPO'), findsWidgets);
  });

  testWidgets('the navbar routes to Settings', (tester) async {
    await _pumpApp(tester, _onboardedStore());

    await tester.tap(find.text('Settings'));
    await _settleRouter(tester);

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('ACCOUNT SETTINGS'), findsOneWidget);
  });

  testWidgets('the navbar routes to the real Dashboard screen', (tester) async {
    await _pumpApp(tester, _onboardedStore());

    await tester.tap(find.text('Dashboard'));
    await _settleRouter(tester);

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('YOUR QUARTERLY EARNINGS REPORT'), findsOneWidget);
  });

  testWidgets('the navbar routes to the real Achievements screen', (
    tester,
  ) async {
    await _pumpApp(tester, _onboardedStore());

    await tester.tap(find.text('Achievements'));
    await _settleRouter(tester);

    expect(find.byType(AchievementsScreen), findsOneWidget);
    expect(find.text('INVESTOR ACHIEVEMENTS'), findsOneWidget);
  });

  testWidgets('S3 the stored light preference is applied at boot (BUG-003)', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      _onboardedStore(settings: AppSettings.initial.copyWith(theme: 'light')),
    );

    final BuildContext context = tester.element(find.byType(TimerScreen));
    expect(Theme.of(context).brightness, Brightness.light);
  });

  testWidgets('completing onboarding redirects into the app', (tester) async {
    final MemoryStore store = MemoryStore();
    await _pumpApp(tester, store);

    expect(find.byType(LandingScreen), findsOneWidget);

    await tester.tap(find.text('BEGIN APPLICATION'));
    await _settleRouter(tester);
    await tester.tap(find.text('CONTINUE'));
    await _settleRouter(tester);
    await tester.tap(find.text('SUBMIT FOR REVIEW'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 1200));
    await _settleRouter(tester);

    await tester.enterText(find.byType(TextField).first, '124800');
    await tester.tap(find.text('ACCEPT OFFER & BEGIN'));
    await _settleRouter(tester);

    expect(find.byType(TimerScreen), findsOneWidget);
  });
}
