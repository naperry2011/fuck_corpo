import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/migrations/v0_localstorage_to_v1.dart';
import '../data/storage/key_value_store.dart';
import 'providers.dart';

/// Whether Settings should warn that the one-time React import failed.
///
/// The bridge in `V0Migrator` sets a flag when it backs a payload up instead of
/// importing it. Reading that flag here, rather than threading the migration
/// result through boot, keeps this out of the render path: nothing about the
/// bridge has to change, and the notice survives a reload.
class MigrationNoticeController extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(keyValueStoreProvider).read(V0Migrator.failureNoticeKey) ==
      'true';

  /// Acknowledge the notice. One-time by design: it never comes back.
  Future<void> dismiss() async {
    if (!state) return;
    state = false;
    final KeyValueStore store = ref.read(keyValueStoreProvider);
    await store.remove(V0Migrator.failureNoticeKey);
  }
}

final NotifierProvider<MigrationNoticeController, bool>
migrationNoticeProvider =
    NotifierProvider<MigrationNoticeController, bool>(
      MigrationNoticeController.new,
    );
