/// Minimal synchronous-read key/value contract the repository is built on.
///
/// Reads are synchronous so the app can render its first frame from already
/// loaded state; the concrete implementation warms its cache during boot.
abstract interface class KeyValueStore {
  String? read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);
}
