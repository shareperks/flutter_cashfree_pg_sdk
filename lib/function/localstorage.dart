import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static SharedPreferences? _prefs;

  /// Call this once at app startup (main.dart)
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Internal safety check
  static SharedPreferences get _instance {
    final prefs = _prefs;
    if (prefs == null) {
      throw Exception(
        'LocalStorage not initialized. Call LocalStorage.init() in main() first.',
      );
    }
    return prefs;
  }

  // ---------------- TOKEN ----------------

  static String? getToken() {
    return _instance.getString('token');
  }

  static Future<void> setToken(String token) async {
    await _instance.setString('token', token);
  }

  static Future<void> clearToken() async {
    await _instance.remove('token');
  }

  // ---------------- GENERIC HELPERS ----------------

  static Future<void> setString(String key, String value) async {
    await _instance.setString(key, value);
  }

  static String? getString(String key) {
    return _instance.getString(key);
  }

  static Future<void> remove(String key) async {
    await _instance.remove(key);
  }

  static Future<void> clearAll() async {
    await _instance.clear();
  }
}
