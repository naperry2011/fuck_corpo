import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

/// Default [KeyValueStore] on every platform. Backed by `localStorage` on web
/// and by the platform preference store on Android and iOS.
class SharedPrefsStore implements KeyValueStore {
  SharedPrefsStore(this._prefs);

  /// Loads the preference store. Call once during boot, before `runApp`.
  static Future<SharedPrefsStore> open() async =>
      SharedPrefsStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}
