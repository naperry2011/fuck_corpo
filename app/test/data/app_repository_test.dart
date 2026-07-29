import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/data/app_repository.dart';
import 'package:fuckcorpo/data/storage/key_value_store.dart';
import 'package:fuckcorpo/domain/models/app_state.dart';
import 'package:fuckcorpo/domain/models/break_category.dart';
import 'package:fuckcorpo/domain/models/break_record.dart';
import 'package:fuckcorpo/domain/models/salary.dart';

class InMemoryStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

AppState populatedState() => AppState.initial.copyWith(
  onboarded: true,
  salary: const Salary(
    amount: 85000,
    type: SalaryType.annual,
    currency: 'EUR',
  ),
  achievements: const <String>['first_flush'],
  breaks: <BreakRecord>[
    BreakRecord(
      id: 'a',
      category: BreakCategory.coffeeBreak,
      durationMs: 90000,
      timestamp: DateTime(2026, 3, 4, 9),
    ),
  ],
);

void main() {
  late InMemoryStore store;
  late AppRepository repo;

  setUp(() {
    store = InMemoryStore();
    repo = AppRepository(store);
  });

  group('load', () {
    test('returns defaults when nothing is stored', () {
      expect(repo.load(), AppState.initial);
    });

    test('returns defaults when the stored payload is corrupt', () {
      store.values[AppRepository.storageKey] = '{not json';
      expect(repo.load(), AppState.initial);
    });

    test('returns defaults when the stored payload is structurally invalid', () {
      store.values[AppRepository.storageKey] = '{"breaks": "x"}';
      expect(repo.load(), AppState.initial);
    });

    test('fills in defaults for a partial payload', () {
      store.values[AppRepository.storageKey] = '{"onboarded": true}';
      final AppState state = repo.load();
      expect(state.onboarded, isTrue);
      expect(state.settings.currency, 'USD');
      expect(state.salary, Salary.initial);
    });
  });

  test('save then load round trips', () async {
    final AppState state = populatedState();
    await repo.save(state);
    expect(repo.load(), state);
  });

  group('export', () {
    test('produces a dated filename', () {
      expect(
        AppRepository.exportFilename(DateTime(2026, 3, 4)),
        'fuckcorpo-export-2026-03-04.json',
      );
      expect(
        AppRepository.exportFilename(DateTime(2026, 12, 31)),
        'fuckcorpo-export-2026-12-31.json',
      );
    });

    test('produces indented JSON that re-imports to the same state', () {
      final AppState state = populatedState();
      final String payload = repo.exportJson(state);
      expect(payload, contains('\n  '));
      expect(jsonDecode(payload)['schemaVersion'], 1);
      expect(repo.importJson(payload), state);
    });
  });

  group('import', () {
    test('accepts a v0 payload with no schemaVersion', () {
      const String v0 = '''
{"salary":{"amount":60000,"type":"annual","currency":"USD"},
 "breaks":[{"id":"a","category":"Bathroom","duration":60000,
            "timestamp":"2026-03-04T09:00:00.000"}],
 "settings":{"theme":"light"},"achievements":["first_flush"],"onboarded":true}
''';
      final AppState state = repo.importJson(v0);
      expect(state.schemaVersion, 1);
      expect(state.breaks, hasLength(1));
      expect(state.settings.theme, 'light');
    });

    test('rejects malformed JSON', () {
      expect(() => repo.importJson('{not json'), throwsA(isA<FormatException>()));
    });

    test('rejects a payload whose breaks field is not a list', () {
      expect(
        () => repo.importJson('{"breaks":"x"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('leaves existing state untouched when the import is rejected', () async {
      final AppState state = populatedState();
      await repo.save(state);
      expect(() => repo.importJson('{"breaks":"x"}'), throwsFormatException);
      expect(repo.load(), state);
    });
  });

  test('clear removes the stored payload and returns to defaults', () async {
    await repo.save(populatedState());
    await repo.clear();
    expect(store.values.containsKey(AppRepository.storageKey), isFalse);
    expect(repo.load(), AppState.initial);
  });
}
