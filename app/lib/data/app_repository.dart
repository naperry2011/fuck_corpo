import 'dart:convert';

import '../domain/models/app_state.dart';
import 'storage/key_value_store.dart';

/// Owns reading and writing the persisted [AppState].
///
/// [load] is forgiving: a corrupt payload yields defaults rather than a crash.
/// [importJson] is strict: a bad file throws so the caller can surface an error
/// and keep the user's existing data (BUG-004).
class AppRepository {
  const AppRepository(this._store);

  /// v1 payload key. Distinct from the React key `fuckcorpo_data`, which stays
  /// untouched so React remains usable during the parallel period.
  static const String storageKey = 'fuckcorpo_state_v1';

  final KeyValueStore _store;

  AppState load() {
    final String? raw = _store.read(storageKey);
    if (raw == null || raw.isEmpty) return AppState.initial;
    try {
      return AppState.fromJson(jsonDecode(raw));
    } on FormatException {
      return AppState.initial;
    }
  }

  Future<void> save(AppState state) =>
      _store.write(storageKey, jsonEncode(state.toJson()));

  Future<void> clear() => _store.remove(storageKey);

  /// Pretty-printed payload for the Export Data action.
  String exportJson(AppState state) =>
      const JsonEncoder.withIndent('  ').convert(state.toJson());

  static String exportFilename(DateTime date) {
    final String iso = date.toIso8601String().substring(0, 10);
    return 'fuckcorpo-export-$iso.json';
  }

  /// Parses an exported file. Accepts both v0 (React) and v1 payloads.
  /// Throws [FormatException] for anything unusable.
  AppState importJson(String payload) => AppState.fromJson(jsonDecode(payload));
}
