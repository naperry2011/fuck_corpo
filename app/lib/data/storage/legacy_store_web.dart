import 'package:web/web.dart' as web;

import 'legacy_store.dart';

/// Reads the React app's unprefixed `localStorage` keys on web.
class WebLegacyStore implements LegacyStore {
  const WebLegacyStore();

  @override
  String? read(String key) => web.window.localStorage.getItem(key);

  @override
  void write(String key, String value) =>
      web.window.localStorage.setItem(key, value);
}

LegacyStore? openLegacyStore() => const WebLegacyStore();
