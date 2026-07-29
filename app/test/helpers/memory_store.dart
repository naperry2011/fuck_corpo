import 'package:fuckcorpo/data/storage/key_value_store.dart';

/// In-memory [KeyValueStore] so tests exercise the real repository without
/// touching platform preferences. Seeding the map simulates a prior session.
class MemoryStore implements KeyValueStore {
  MemoryStore([Map<String, String>? seed])
    : data = <String, String>{...?seed};

  final Map<String, String> data;

  @override
  String? read(String key) => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    data.remove(key);
  }
}
