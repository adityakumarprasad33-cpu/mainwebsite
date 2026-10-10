import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores session values in OS-backed encrypted storage.
/// Legacy SharedPreferences values are migrated the first time they are read.
class SecureStorageAdapter {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }

  static Future<String?> read({required String key}) async {
    final secureValue = await _storage.read(key: key);
    if (secureValue != null) return secureValue;

    final preferences = await SharedPreferences.getInstance();
    final legacyValue = preferences.getString(key);
    if (legacyValue == null) return null;
    await _storage.write(key: key, value: legacyValue);
    await preferences.remove(key);
    return legacyValue;
  }

  static Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }

  static Future<void> clear() async {
    final savedApiUrls = await read(key: 'apiBaseUrls');
    await _storage.deleteAll();
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    if (savedApiUrls != null) {
      await _storage.write(key: 'apiBaseUrls', value: savedApiUrls);
    }
  }

  static Future<void> writeJson({
    required String key,
    required Map<String, dynamic> jsonValue,
  }) async {
    await write(key: key, value: jsonEncode(jsonValue));
  }

  static Future<Map<String, dynamic>?> readJson({required String key}) async {
    final raw = await read(key: key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }
}
