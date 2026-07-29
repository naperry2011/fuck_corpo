import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/data/app_repository.dart';
import 'package:fuckcorpo/data/migrations/v0_localstorage_to_v1.dart';
import 'package:fuckcorpo/domain/models/app_state.dart';
import 'package:fuckcorpo/domain/models/break_category.dart';
import 'package:fuckcorpo/domain/models/salary.dart';

import '../../helpers/memory_legacy_store.dart';
import '../../helpers/memory_store.dart';

/// A realistic React payload: no `schemaVersion`, `state` rather than `region`,
/// a `timezone` that Flutter ignores, and durations in milliseconds.
String v0Payload({int breakCount = 2}) => jsonEncode(<String, dynamic>{
  'salary': <String, dynamic>{
    'amount': 65000,
    'type': 'annual',
    'currency': 'EUR',
  },
  'breaks': <Map<String, dynamic>>[
    for (int i = 0; i < breakCount; i++)
      <String, dynamic>{
        'id': 'break-$i',
        'category': 'Bathroom',
        'duration': 600000 + i,
        'timestamp': '2026-03-0${i + 1}T09:00:00.000Z',
      },
  ],
  'settings': <String, dynamic>{
    'theme': 'light',
    'currency': 'EUR',
    'timezone': 'America/New_York',
    'industry': 'Technology',
    'state': 'NY',
    'soundEnabled': false,
  },
  'achievements': <String>['first_flush'],
  'onboarded': true,
});

void main() {
  V0Migrator migratorFor(MemoryStore store, MemoryLegacyStore legacy) =>
      V0Migrator(
        store: store,
        repository: AppRepository(store),
        legacy: legacy,
      );

  group('v0 localStorage bridge', () {
    test('migrates a full v0 payload into the v1 key', () async {
      final store = MemoryStore();
      final legacy = MemoryLegacyStore(<String, String>{
        V0Migrator.legacyKey: v0Payload(),
      });

      final result = await migratorFor(store, legacy).run();

      expect(result.status, V0MigrationStatus.migrated);
      expect(result.state, isNotNull);
      expect(result.state!.breaks, hasLength(2));
      expect(result.state!.breaks.first.category, BreakCategory.bathroom);
      expect(result.state!.salary.amount, 65000);
      expect(result.state!.salary.type, SalaryType.annual);
      expect(result.state!.settings.currency, 'EUR');
      expect(result.state!.settings.soundEnabled, isFalse);
      expect(result.state!.achievements, <String>['first_flush']);
      expect(result.state!.onboarded, isTrue);

      // Written under the v1 key, at the current schema version.
      final persisted = AppRepository(store).load();
      expect(persisted, result.state);
      expect(persisted.schemaVersion, AppState.currentSchemaVersion);
    });

    test('never destroys the React payload', () async {
      final store = MemoryStore();
      final raw = v0Payload();
      final legacy = MemoryLegacyStore(<String, String>{
        V0Migrator.legacyKey: raw,
      });

      await migratorFor(store, legacy).run();

      expect(legacy.data[V0Migrator.legacyKey], raw);
    });

    test('writes the migrated marker', () async {
      final store = MemoryStore();
      final legacy = MemoryLegacyStore(<String, String>{
        V0Migrator.legacyKey: v0Payload(),
      });

      await migratorFor(store, legacy).run();

      expect(store.data[V0Migrator.markerKey], 'true');
    });

    test('is idempotent: a second run does not re-import', () async {
      final store = MemoryStore();
      final legacy = MemoryLegacyStore(<String, String>{
        V0Migrator.legacyKey: v0Payload(),
      });

      await migratorFor(store, legacy).run();
      final second = await migratorFor(store, legacy).run();

      expect(second.status, V0MigrationStatus.skippedExistingV1);
      expect(AppRepository(store).load().breaks, hasLength(2));
    });

    test('does not overwrite Flutter data that already exists', () async {
      final store = MemoryStore();
      await AppRepository(store).save(
        AppState.initial.copyWith(onboarded: true),
      );
      final legacy = MemoryLegacyStore(<String, String>{
        V0Migrator.legacyKey: v0Payload(breakCount: 5),
      });

      final result = await migratorFor(store, legacy).run();

      expect(result.status, V0MigrationStatus.skippedExistingV1);
      expect(AppRepository(store).load().breaks, isEmpty);
    });

    test(
      're-migration is blocked by the marker even if the v1 key is cleared',
      () async {
        final store = MemoryStore();
        final legacy = MemoryLegacyStore(<String, String>{
          V0Migrator.legacyKey: v0Payload(),
        });

        await migratorFor(store, legacy).run();
        await AppRepository(store).clear();
        final result = await migratorFor(store, legacy).run();

        expect(result.status, V0MigrationStatus.skippedAlreadyMigrated);
        expect(AppRepository(store).load(), AppState.initial);
      },
    );

    test('no legacy key means a clean first-run', () async {
      final store = MemoryStore();
      final result = await migratorFor(store, MemoryLegacyStore()).run();

      expect(result.status, V0MigrationStatus.skippedNoLegacyData);
      expect(result.state, isNull);
      expect(store.data, isEmpty);
    });

    test('an empty legacy value is treated as no data', () async {
      final store = MemoryStore();
      final legacy = MemoryLegacyStore(<String, String>{
        V0Migrator.legacyKey: '',
      });

      final result = await migratorFor(store, legacy).run();

      expect(result.status, V0MigrationStatus.skippedNoLegacyData);
    });

    test('a null legacy store (non-web) skips cleanly', () async {
      final store = MemoryStore();
      final result = await V0Migrator(
        store: store,
        repository: AppRepository(store),
        legacy: null,
      ).run();

      expect(result.status, V0MigrationStatus.skippedNoLegacyData);
      expect(store.data, isEmpty);
    });

    test('a partial v0 payload falls back to defaults per field', () async {
      final store = MemoryStore();
      final legacy = MemoryLegacyStore(<String, String>{
        V0Migrator.legacyKey: jsonEncode(<String, dynamic>{
          'settings': <String, dynamic>{'currency': 'GBP'},
        }),
      });

      final result = await migratorFor(store, legacy).run();

      expect(result.status, V0MigrationStatus.migrated);
      expect(result.state!.settings.currency, 'GBP');
      expect(result.state!.settings.theme, AppState.initial.settings.theme);
      expect(
        result.state!.settings.soundEnabled,
        AppState.initial.settings.soundEnabled,
      );
      expect(result.state!.breaks, isEmpty);
      expect(result.state!.onboarded, isFalse);
    });

    test('corrupt JSON backs up, does not brick, and starts fresh', () async {
      final store = MemoryStore();
      final legacy = MemoryLegacyStore(<String, String>{
        V0Migrator.legacyKey: '{not json',
      });

      final result = await migratorFor(store, legacy).run();

      expect(result.status, V0MigrationStatus.failedBackedUp);
      expect(result.state, isNull);
      expect(legacy.data[V0Migrator.legacyBackupKey], '{not json');
      expect(legacy.data[V0Migrator.legacyKey], '{not json');
      expect(store.data[V0Migrator.markerKey], 'true');
      expect(AppRepository(store).load(), AppState.initial);
    });

    test('a structurally invalid payload backs up rather than importing',
        () async {
      final store = MemoryStore();
      final legacy = MemoryLegacyStore(<String, String>{
        V0Migrator.legacyKey: '{"breaks":"nope"}',
      });

      final result = await migratorFor(store, legacy).run();

      expect(result.status, V0MigrationStatus.failedBackedUp);
      expect(legacy.data[V0Migrator.legacyBackupKey], '{"breaks":"nope"}');
    });

    test('a failed migration raises the notice flag Settings reads', () async {
      final store = MemoryStore();
      final legacy = MemoryLegacyStore(<String, String>{
        V0Migrator.legacyKey: '{not json',
      });

      await migratorFor(store, legacy).run();

      expect(store.data[V0Migrator.failureNoticeKey], 'true');
    });

    test('a successful migration raises no notice', () async {
      final store = MemoryStore();
      final legacy = MemoryLegacyStore(<String, String>{
        V0Migrator.legacyKey: v0Payload(),
      });

      await migratorFor(store, legacy).run();

      expect(store.data.containsKey(V0Migrator.failureNoticeKey), isFalse);
    });

    test('a failed migration does not retry on the next boot', () async {
      final store = MemoryStore();
      final legacy = MemoryLegacyStore(<String, String>{
        V0Migrator.legacyKey: '{not json',
      });

      await migratorFor(store, legacy).run();
      final second = await migratorFor(store, legacy).run();

      expect(second.status, V0MigrationStatus.skippedAlreadyMigrated);
    });
  });
}
