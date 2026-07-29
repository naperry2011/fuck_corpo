import 'package:fuckcorpo/data/storage/legacy_store.dart';

/// In-memory stand-in for the browser `localStorage` the React app writes to,
/// so the v0 bridge can be tested off-web.
class MemoryLegacyStore implements LegacyStore {
  MemoryLegacyStore([Map<String, String>? seed])
    : data = <String, String>{...?seed};

  final Map<String, String> data;

  @override
  String? read(String key) => data[key];

  @override
  void write(String key, String value) {
    data[key] = value;
  }
}
