import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/data/app_repository.dart';
import 'package:fuckcorpo/data/migrations/v0_localstorage_to_v1.dart';
import 'package:fuckcorpo/domain/models/app_settings.dart';
import 'package:fuckcorpo/domain/models/app_state.dart';
import 'package:fuckcorpo/domain/models/break_category.dart';
import 'package:fuckcorpo/domain/models/break_record.dart';
import 'package:fuckcorpo/domain/models/salary.dart';
import 'package:fuckcorpo/features/settings/settings_screen.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/memory_store.dart';
import '../../helpers/pump_app.dart';

final DateTime _now = DateTime(2026, 7, 28, 10);

/// 124,800 annual is exactly 1.00 per working minute.
const Salary _onePerMinute = Salary(
  amount: 124800,
  type: SalaryType.annual,
  currency: 'USD',
);

AppState _state({
  Salary salary = _onePerMinute,
  AppSettings settings = AppSettings.initial,
  List<BreakRecord> breaks = const <BreakRecord>[],
  List<String> achievements = const <String>[],
}) => AppState(
  schemaVersion: AppState.currentSchemaVersion,
  salary: salary,
  breaks: breaks,
  settings: settings,
  achievements: achievements,
  onboarded: true,
);

MemoryStore _storeWith({
  Salary salary = _onePerMinute,
  AppSettings settings = AppSettings.initial,
}) => MemoryStore(<String, String>{
  AppRepository.storageKey: jsonEncode(
    _state(salary: salary, settings: settings).toJson(),
  ),
});

AppState _persisted(MemoryStore store) => AppState.fromJson(
  jsonDecode(store.data[AppRepository.storageKey]!),
);

/// Scrolls [finder] into view before tapping it. The settings page is far
/// taller than the test surface.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// The [Switch] inside an [FcSwitch] row, which is what a user actually taps.
Finder _switchIn(Key key) => find.descendant(
  of: find.byKey(key),
  matching: find.byType(Switch),
);

/// Opens an [FcDropdown] by key and taps the option carrying [label].
Future<void> _selectOption(
  WidgetTester tester,
  Key dropdownKey,
  String label,
) async {
  await tester.ensureVisible(find.byKey(dropdownKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(dropdownKey));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  late MemoryStore store;
  late FakeClock clock;

  setUp(() {
    store = _storeWith();
    clock = FakeClock(_now);
  });

  Future<void> pump(WidgetTester tester) => pumpFcScreen(
    tester,
    const SettingsScreen(),
    store: store,
    clock: clock,
  );

  group('S6 / S7 static copy', () {
    testWidgets('header, about card and know-your-rights copy render', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('ACCOUNT SETTINGS'), findsOneWidget);
      expect(find.text('Manage your portfolio'), findsOneWidget);
      expect(find.text('Compensation Package'), findsOneWidget);
      expect(find.text('Employee Profile'), findsOneWidget);
      expect(find.text('Display Preferences'), findsOneWidget);
      expect(find.text('Data Management'), findsOneWidget);
      expect(find.text('Corporate Information'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(
        find.text('Your time is valuable, even in the bathroom.'),
        findsOneWidget,
      );
      expect(find.textContaining('Board of Directors:'), findsOneWidget);
      expect(find.textContaining('Chief Bathroom Officer:'), findsOneWidget);
      expect(find.textContaining('Shareholder Value:'), findsOneWidget);
      expect(find.text('Know Your Rights'), findsOneWidget);
      expect(
        find.textContaining('Under OSHA regulations'),
        findsOneWidget,
      );
      expect(
        find.text('This is not legal advice. Know your local labor laws.'),
        findsOneWidget,
      );
    });
  });

  group('N4 data-sync honesty', () {
    testWidgets('Data Management states that nothing syncs between surfaces', (
      tester,
    ) async {
      await pump(tester);

      final Finder notice = find.byKey(SettingsScreen.syncNoticeKey);
      expect(notice, findsOneWidget);

      final String copy = tester.widget<Text>(notice).data!;
      // The three facts a user has to walk away with (D-104).
      expect(copy, contains('this device only'));
      expect(copy, contains('Nothing syncs'));
      expect(copy, contains('Export Data'));
      expect(copy, contains('Import Data'));
    });
  });

  group('N3 failed-migration notice', () {
    testWidgets('is absent when the bridge did not fail', (tester) async {
      await pump(tester);

      expect(find.byKey(SettingsScreen.migrationNoticeKey), findsNothing);
    });

    testWidgets('names the backup key so the data is recoverable', (
      tester,
    ) async {
      store.data[V0Migrator.failureNoticeKey] = 'true';
      await pump(tester);

      expect(find.byKey(SettingsScreen.migrationNoticeKey), findsOneWidget);
      expect(
        find.textContaining(V0Migrator.legacyBackupKey),
        findsOneWidget,
      );
      // The user must not think their old data was destroyed.
      expect(find.textContaining('Nothing was deleted'), findsOneWidget);
    });

    testWidgets('dismissing clears the flag and does not come back', (
      tester,
    ) async {
      store.data[V0Migrator.failureNoticeKey] = 'true';
      await pump(tester);

      await _tap(tester, find.byKey(SettingsScreen.migrationDismissKey));
      await tester.pumpAndSettle();

      expect(find.byKey(SettingsScreen.migrationNoticeKey), findsNothing);
      expect(store.data.containsKey(V0Migrator.failureNoticeKey), isFalse);
    });
  });

  group('S1 compensation', () {
    testWidgets('per-minute preview reflects the amount and the type', (
      tester,
    ) async {
      await pump(tester);

      expect(
        tester.widget<Text>(find.byKey(SettingsScreen.ratePreviewKey)).data,
        contains(r'$1.00/min'),
      );

      // 124,800 hourly is 2,080 per working minute.
      await _selectOption(tester, SettingsScreen.salaryTypeKey, 'Hourly');
      expect(
        tester.widget<Text>(find.byKey(SettingsScreen.ratePreviewKey)).data,
        contains(r'$2,080.00/min'),
      );
    });

    testWidgets('Update Salary persists the amount and the type', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(
        find.byKey(SettingsScreen.salaryAmountKey),
        '62400',
      );
      await _selectOption(tester, SettingsScreen.salaryTypeKey, 'Weekly');
      await tester.tap(find.text('Update Salary'));
      await tester.pump();

      final AppState saved = _persisted(store);
      expect(saved.salary.amount, 62400);
      expect(saved.salary.type, SalaryType.weekly);
      expect(find.text('Salary updated'), findsOneWidget);
    });

    testWidgets('a non-positive salary is rejected and nothing is saved', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(find.byKey(SettingsScreen.salaryAmountKey), '0');
      await tester.tap(find.text('Update Salary'));
      await tester.pump();

      expect(find.text(SettingsScreen.invalidSalaryMessage), findsOneWidget);
      expect(_persisted(store).salary.amount, 124800);
      expect(find.byKey(SettingsScreen.ratePreviewKey), findsNothing);
    });
  });

  group('S2 employee profile', () {
    testWidgets('currency, industry and region are saved together', (
      tester,
    ) async {
      await pump(tester);

      await _selectOption(tester, SettingsScreen.currencyKey, 'EUR');
      await _selectOption(tester, SettingsScreen.industryKey, 'Healthcare');
      await tester.enterText(
        find.byKey(SettingsScreen.regionKey),
        'California',
      );
      await tester.tap(find.text('Save Profile'));
      await tester.pump();

      final AppSettings saved = _persisted(store).settings;
      expect(saved.currency, 'EUR');
      expect(saved.industry, 'Healthcare');
      expect(saved.region, 'California');
      expect(find.text('Profile saved'), findsOneWidget);
    });

    testWidgets('the currency selection drives the per-minute preview', (
      tester,
    ) async {
      store = _storeWith(
        settings: AppSettings.initial.copyWith(currency: 'JPY'),
      );
      await pump(tester);

      // JPY carries no decimals (BUG-009).
      expect(
        tester.widget<Text>(find.byKey(SettingsScreen.ratePreviewKey)).data,
        contains('/min'),
      );
      expect(
        tester.widget<Text>(find.byKey(SettingsScreen.ratePreviewKey)).data,
        isNot(contains('.00')),
      );
    });
  });

  group('S3 display preferences', () {
    testWidgets('the theme toggle persists the light preference', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Dark Mode'), findsOneWidget);
      await _tap(tester, _switchIn(SettingsScreen.themeToggleKey));

      expect(_persisted(store).settings.theme, 'light');
      expect(find.text('Light Mode'), findsOneWidget);
    });

    testWidgets('the sound toggle persists', (tester) async {
      await pump(tester);

      expect(find.text('On'), findsOneWidget);
      await _tap(tester, _switchIn(SettingsScreen.soundToggleKey));

      expect(_persisted(store).settings.soundEnabled, isFalse);
      expect(find.text('Off'), findsOneWidget);
    });
  });

  group('S4 export and import', () {
    testWidgets('Export Data puts the payload on the clipboard', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pump(tester);
      await tester.tap(find.text('Export Data').last);
      await tester.pump();

      expect(copied, isNotNull);
      expect(
        AppState.fromJson(jsonDecode(copied!)).salary.amount,
        124800,
      );
      expect(find.text('Data exported'), findsOneWidget);
    });

    testWidgets('a malformed payload surfaces an error and keeps state', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Import Data').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(SettingsScreen.importFieldKey),
        '{"breaks":"nope"}',
      );
      await tester.tap(find.text(SettingsScreen.importConfirmLabel));
      await tester.pumpAndSettle();

      expect(find.text(SettingsScreen.importErrorMessage), findsOneWidget);
      expect(_persisted(store).salary.amount, 124800);
    });

    testWidgets('a valid payload replaces the state', (tester) async {
      final String payload = jsonEncode(
        _state(
          salary: const Salary(
            amount: 50,
            type: SalaryType.hourly,
            currency: 'GBP',
          ),
          breaks: <BreakRecord>[
            BreakRecord(
              id: 'imported',
              category: BreakCategory.bathroom,
              durationMs: 60000,
              timestamp: _now,
            ),
          ],
        ).toJson(),
      );

      await pump(tester);
      await tester.tap(find.text('Import Data').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(SettingsScreen.importFieldKey), payload);
      await tester.tap(find.text(SettingsScreen.importConfirmLabel));
      await tester.pumpAndSettle();

      final AppState saved = _persisted(store);
      expect(saved.salary.amount, 50);
      expect(saved.salary.type, SalaryType.hourly);
      expect(saved.breaks.single.id, 'imported');
      expect(find.text('Data imported successfully'), findsOneWidget);
    });
  });

  group('S5 clear all data', () {
    testWidgets('the first tap only asks for confirmation', (tester) async {
      await pump(tester);

      await _tap(tester, find.text('Clear All Data').last);

      expect(find.text('Are you sure?'), findsOneWidget);
      expect(store.data.containsKey(AppRepository.storageKey), isTrue);

      await _tap(tester, find.text('Cancel'));
      expect(find.text('Are you sure?'), findsNothing);
    });

    testWidgets('confirming clears the stored payload without a reload', (
      tester,
    ) async {
      await pump(tester);

      await _tap(tester, find.text('Clear All Data').last);
      await _tap(tester, find.text('Confirm'));

      expect(store.data.containsKey(AppRepository.storageKey), isFalse);
      expect(find.text('All data cleared'), findsOneWidget);
    });
  });
}
