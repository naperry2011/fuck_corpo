export 'legacy_store_stub.dart'
    if (dart.library.js_interop) 'legacy_store_web.dart'
    show openLegacyStore;

/// Raw, unprefixed browser `localStorage`.
///
/// [KeyValueStore] on web goes through `shared_preferences`, which namespaces
/// every key under `flutter.`, so it cannot see the React key `fuckcorpo_data`.
/// This is the narrow escape hatch the v0 bridge needs. Reads and writes are
/// synchronous because `localStorage` is.
abstract interface class LegacyStore {
  String? read(String key);

  void write(String key, String value);
}
