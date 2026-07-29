import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/core/theme/colors.dart';
import 'package:fuckcorpo/domain/models/app_settings.dart';
import 'package:fuckcorpo/domain/models/app_state.dart';
import 'package:fuckcorpo/domain/models/break_category.dart';
import 'package:fuckcorpo/domain/models/break_record.dart';
import 'package:fuckcorpo/domain/models/running_timer.dart';
import 'package:fuckcorpo/domain/models/salary.dart';

void main() {
  group('SalaryType', () {
    test('wire values match the React strings', () {
      expect(
        SalaryType.values.map((t) => t.wire).toList(),
        <String>['annual', 'hourly', 'monthly', 'weekly'],
      );
    });

    test('parses known values and falls back to annual', () {
      expect(SalaryType.fromWire('hourly'), SalaryType.hourly);
      expect(SalaryType.fromWire('nonsense'), SalaryType.annual);
      expect(SalaryType.fromWire(null), SalaryType.annual);
    });
  });

  group('Salary', () {
    test('defaults match the React defaultData', () {
      const Salary salary = Salary.initial;
      expect(salary.amount, 0);
      expect(salary.type, SalaryType.annual);
      expect(salary.currency, 'USD');
    });

    test('round trips through JSON', () {
      const Salary salary = Salary(
        amount: 85000,
        type: SalaryType.annual,
        currency: 'EUR',
      );
      expect(Salary.fromJson(salary.toJson()), salary);
    });

    test('rejects a non-map payload by falling back to defaults', () {
      expect(Salary.fromJson(null), Salary.initial);
      expect(Salary.fromJson('nope'), Salary.initial);
    });
  });

  group('BreakCategory', () {
    test('has the five React categories in order', () {
      expect(
        BreakCategory.values.map((c) => c.wire).toList(),
        <String>[
          'Bathroom',
          'Smoke Break',
          'Mental Health Moment',
          'Coffee Break',
          'Other',
        ],
      );
    });

    test('every category owns a label, an emoji and a distinct color', () {
      for (final BreakCategory c in BreakCategory.values) {
        expect(c.label, isNotEmpty);
        expect(c.emoji, isNotEmpty);
      }
      // Fixes BUG-005: all five wedges are visually distinct.
      expect(
        BreakCategory.values.map((c) => c.color).toSet().length,
        BreakCategory.values.length,
      );
      expect(BreakCategory.bathroom.color, FcColors.green);
      expect(BreakCategory.smokeBreak.color, FcColors.red);
      expect(BreakCategory.mentalHealth.color, FcColors.gold);
      expect(BreakCategory.coffeeBreak.color, FcColors.mutedGold);
      expect(BreakCategory.other.color, FcColors.gray);
    });

    test('unknown wire values resolve to Other', () {
      expect(BreakCategory.fromWire('Smoke Break'), BreakCategory.smokeBreak);
      expect(BreakCategory.fromWire('Nap'), BreakCategory.other);
      expect(BreakCategory.fromWire(null), BreakCategory.other);
    });
  });

  group('BreakRecord', () {
    final DateTime ts = DateTime(2026, 3, 4, 10, 30);

    test('round trips through JSON with an ISO timestamp', () {
      final BreakRecord record = BreakRecord(
        id: 'abc',
        category: BreakCategory.coffeeBreak,
        durationMs: 90000,
        timestamp: ts,
      );
      final Map<String, dynamic> json = record.toJson();
      expect(json['duration'], 90000);
      expect(json['category'], 'Coffee Break');
      expect(json['timestamp'], ts.toIso8601String());
      expect(BreakRecord.fromJson(json), record);
    });

    test('rejects payloads missing required fields', () {
      expect(BreakRecord.tryFromJson(<String, dynamic>{}), isNull);
      expect(
        BreakRecord.tryFromJson(<String, dynamic>{
          'id': 'a',
          'duration': 'not a number',
          'timestamp': ts.toIso8601String(),
        }),
        isNull,
      );
      expect(BreakRecord.tryFromJson('nope'), isNull);
    });

    test('accepts a v0 record with a missing category', () {
      final BreakRecord? record = BreakRecord.tryFromJson(<String, dynamic>{
        'id': 'a',
        'duration': 1000,
        'timestamp': ts.toIso8601String(),
      });
      expect(record, isNotNull);
      expect(record!.category, BreakCategory.other);
    });
  });

  group('AppSettings', () {
    test('defaults match the React defaultData', () {
      const AppSettings settings = AppSettings.initial;
      expect(settings.theme, 'dark');
      expect(settings.currency, 'USD');
      expect(settings.industry, '');
      expect(settings.region, '');
      expect(settings.soundEnabled, isTrue);
    });

    test('merges per field against defaults (fixes BUG-007)', () {
      final AppSettings settings = AppSettings.fromJson(<String, dynamic>{
        'currency': 'EUR',
      });
      expect(settings.currency, 'EUR');
      expect(settings.theme, 'dark');
      expect(settings.soundEnabled, isTrue);
    });

    test('keeps the deprecated timezone field for import compatibility', () {
      final AppSettings settings = AppSettings.fromJson(<String, dynamic>{
        'timezone': 'America/New_York',
      });
      expect(settings.timezone, 'America/New_York');
      expect(settings.toJson()['timezone'], 'America/New_York');
    });

    test('persists the region under the legacy "state" key', () {
      const AppSettings settings = AppSettings.initial;
      expect(settings.copyWith(region: 'NY').toJson()['state'], 'NY');
      expect(
        AppSettings.fromJson(<String, dynamic>{'state': 'NY'}).region,
        'NY',
      );
    });
  });

  group('RunningTimer', () {
    test('round trips and reports elapsed from the wall clock', () {
      final DateTime started = DateTime(2026, 3, 4, 10, 0);
      final RunningTimer timer = RunningTimer(
        startedAt: started,
        category: BreakCategory.bathroom,
      );
      expect(RunningTimer.fromJson(timer.toJson()), timer);
      expect(
        timer.elapsed(now: started.add(const Duration(seconds: 42))).inSeconds,
        42,
      );
    });

    test('parses a null payload as no running timer', () {
      expect(RunningTimer.fromJson(null), isNull);
    });
  });

  group('AppState', () {
    test('initial state matches the React defaults plus schemaVersion 1', () {
      const AppState state = AppState.initial;
      expect(state.schemaVersion, 1);
      expect(state.salary, Salary.initial);
      expect(state.breaks, isEmpty);
      expect(state.achievements, isEmpty);
      expect(state.onboarded, isFalse);
      expect(state.runningTimer, isNull);
    });

    test('round trips through JSON', () {
      final AppState state = AppState.initial.copyWith(
        onboarded: true,
        achievements: const <String>['first_flush'],
        breaks: <BreakRecord>[
          BreakRecord(
            id: 'a',
            category: BreakCategory.bathroom,
            durationMs: 60000,
            timestamp: DateTime(2026, 3, 4, 9),
          ),
        ],
      );
      expect(AppState.fromJson(state.toJson()), state);
    });

    test('reads a v0 payload with no schemaVersion', () {
      final AppState state = AppState.fromJson(<String, dynamic>{
        'salary': <String, dynamic>{
          'amount': 60000,
          'type': 'annual',
          'currency': 'USD',
        },
        'breaks': <dynamic>[
          <String, dynamic>{
            'id': 'a',
            'category': 'Bathroom',
            'duration': 60000,
            'timestamp': '2026-03-04T09:00:00.000',
          },
        ],
        'settings': <String, dynamic>{'currency': 'USD'},
        'achievements': <dynamic>['first_flush'],
        'onboarded': true,
      });
      expect(state.schemaVersion, 1);
      expect(state.salary.amount, 60000);
      expect(state.breaks, hasLength(1));
      expect(state.onboarded, isTrue);
    });

    test('drops malformed break entries instead of bricking', () {
      final AppState state = AppState.fromJson(<String, dynamic>{
        'breaks': <dynamic>[
          <String, dynamic>{'id': 'a', 'duration': 1000, 'timestamp': 'x'},
          <String, dynamic>{
            'id': 'b',
            'duration': 1000,
            'timestamp': '2026-03-04T09:00:00.000',
          },
        ],
      });
      expect(state.breaks, hasLength(1));
      expect(state.breaks.single.id, 'b');
    });

    test('rejects a payload whose breaks field is not a list', () {
      expect(
        () => AppState.fromJson(<String, dynamic>{'breaks': 'x'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a non-map payload', () {
      expect(() => AppState.fromJson('nope'), throwsA(isA<FormatException>()));
    });
  });
}
