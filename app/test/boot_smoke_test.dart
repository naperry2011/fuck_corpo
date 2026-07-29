import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/app.dart';
import 'package:fuckcorpo/core/theme/colors.dart';
import 'package:fuckcorpo/data/app_repository.dart';
import 'package:fuckcorpo/domain/models/app_settings.dart';
import 'package:fuckcorpo/domain/models/app_state.dart';
import 'package:fuckcorpo/domain/models/break_record.dart';
import 'package:fuckcorpo/domain/models/salary.dart';
import 'package:fuckcorpo/features/timer/timer_screen.dart';
import 'package:fuckcorpo/state/providers.dart';

import 'helpers/fake_clock.dart';
import 'helpers/memory_store.dart';

/// A session that has already been through onboarding, so the router lands on
/// the Timer rather than the gate.
MemoryStore _onboardedStore() => MemoryStore(<String, String>{
  AppRepository.storageKey: jsonEncode(
    const AppState(
      schemaVersion: AppState.currentSchemaVersion,
      salary: Salary(
        amount: 124800,
        type: SalaryType.annual,
        currency: 'USD',
      ),
      breaks: <BreakRecord>[],
      settings: AppSettings.initial,
      achievements: <String>[],
      onboarded: true,
    ).toJson(),
  ),
});

void main() {
  testWidgets('app boots into the Timer route inside the themed shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(_onboardedStore()),
          clockProvider.overrideWithValue(
            FakeClock(DateTime(2026, 7, 28, 10)).call,
          ),
        ],
        child: const FuckCorpoApp(),
      ),
    );
    await tester.pump();

    // Shell: brand, ticker, and the Timer screen as the landing route.
    expect(find.textContaining('FUCKCORPO'), findsOneWidget);
    expect(find.text(r'$EARN'), findsWidgets);
    expect(find.byType(TimerScreen), findsOneWidget);
    expect(find.text('START BREAK'), findsOneWidget);

    final BuildContext context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).scaffoldBackgroundColor, FcColors.navy);
    expect(Theme.of(context).colorScheme.primary, FcColors.green);
  });
}
