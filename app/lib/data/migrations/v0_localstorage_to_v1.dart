import 'dart:convert';

import '../../domain/models/app_state.dart';
import '../app_repository.dart';
import '../storage/key_value_store.dart';
import '../storage/legacy_store.dart';

/// What the bridge did on this boot. Exposed so the caller can surface a notice
/// for [failedBackedUp] and log the rest.
enum V0MigrationStatus {
  /// A Flutter v1 payload already exists. The bridge never touches it.
  skippedExistingV1,

  /// The marker says this browser profile has already been through the bridge,
  /// so a later React edit must not silently replace the Flutter state.
  skippedAlreadyMigrated,

  /// No React data to bridge: a fresh profile, or a non-web platform.
  skippedNoLegacyData,

  /// A v0 payload was read and written to the v1 key.
  migrated,

  /// A v0 payload existed but could not be parsed. It was copied to the backup
  /// key and the app starts from defaults rather than bricking.
  failedBackedUp,
}

class V0MigrationResult {
  const V0MigrationResult(this.status, [this.state]);

  final V0MigrationStatus status;

  /// The migrated state, only for [V0MigrationStatus.migrated].
  final AppState? state;
}

/// The React-to-Flutter bridge described in the migration plan, Section 8.3.
///
/// Contract, in order:
/// 1. A v1 payload wins. Never overwritten.
/// 2. The marker wins next. Migration runs at most once per browser profile.
/// 3. The React key `fuckcorpo_data` is read but **never written or deleted**,
///    so React stays usable and rollback is lossless during the parallel period.
/// 4. A payload that will not parse is copied to `fuckcorpo_data_backup` and the
///    app boots to defaults.
///
/// Consequence, accepted deliberately: after the first Flutter load the two apps
/// diverge. They are not synchronized during the parallel window.
class V0Migrator {
  const V0Migrator({
    required this.store,
    required this.repository,
    required this.legacy,
  });

  /// The React payload key. Read-only from Flutter's side.
  static const String legacyKey = 'fuckcorpo_data';

  /// Where an unparseable React payload is preserved for manual recovery.
  static const String legacyBackupKey = 'fuckcorpo_data_backup';

  /// Guards against a second run re-importing stale React data.
  static const String markerKey = 'fuckcorpo_migrated_from_v0';

  /// Set when a payload was backed up rather than imported, so Settings can
  /// tell the user their old data exists instead of showing a silent empty app.
  /// Cleared when the user dismisses the notice.
  static const String failureNoticeKey = 'fuckcorpo_v0_migration_failed';

  final KeyValueStore store;
  final AppRepository repository;

  /// Null on every non-web platform, where there is no browser storage to read.
  final LegacyStore? legacy;

  Future<V0MigrationResult> run() async {
    final String? existing = store.read(AppRepository.storageKey);
    if (existing != null && existing.isNotEmpty) {
      return const V0MigrationResult(V0MigrationStatus.skippedExistingV1);
    }
    if (store.read(markerKey) == 'true') {
      return const V0MigrationResult(V0MigrationStatus.skippedAlreadyMigrated);
    }

    final LegacyStore? legacy = this.legacy;
    if (legacy == null) {
      return const V0MigrationResult(V0MigrationStatus.skippedNoLegacyData);
    }
    final String? raw = legacy.read(legacyKey);
    if (raw == null || raw.isEmpty) {
      return const V0MigrationResult(V0MigrationStatus.skippedNoLegacyData);
    }

    late final AppState migrated;
    try {
      migrated = AppState.fromJson(jsonDecode(raw));
    } on Object {
      // Any parse or shape failure. Preserve the raw payload, mark the profile
      // done so this does not retry every boot, and boot to defaults.
      legacy.write(legacyBackupKey, raw);
      await store.write(markerKey, 'true');
      // Persisted rather than passed in memory: the notice has to survive the
      // reloads a confused user is likely to try before they reach Settings.
      await store.write(failureNoticeKey, 'true');
      return const V0MigrationResult(V0MigrationStatus.failedBackedUp);
    }

    await repository.save(migrated);
    await store.write(markerKey, 'true');
    return V0MigrationResult(V0MigrationStatus.migrated, migrated);
  }
}
