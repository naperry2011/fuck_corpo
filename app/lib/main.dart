import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/app_repository.dart';
import 'data/migrations/v0_localstorage_to_v1.dart';
import 'data/storage/legacy_store.dart';
import 'data/storage/shared_prefs_store.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPrefsStore store = await SharedPrefsStore.open();

  // Bridge an existing React profile before the first frame, so the app never
  // renders empty for a user who already has data. No-op off web and on any
  // profile that has run it before. See docs/migration/storage_schema_v1.md.
  await V0Migrator(
    store: store,
    repository: AppRepository(store),
    legacy: openLegacyStore(),
  ).run();

  runApp(
    ProviderScope(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
      child: const FuckCorpoApp(),
    ),
  );
}
