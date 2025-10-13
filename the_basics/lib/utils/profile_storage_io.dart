import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ProfileStorage {
  static const _storage = FlutterSecureStorage();
  static const _kPendingKey = 'pending_profile';

  static Future<void> savePendingProfile(Map<String, String?> profile) async {
    await _storage.write(key: _kPendingKey, value: jsonEncode(profile));
  }

  static Future<Map<String, String>?> getPendingProfile() async {
    final s = await _storage.read(key: _kPendingKey);
    print("=> ProfileStorage.getPendingProfile() returned: $s");
    if (s == null) return null;
    
    final Map parsed = jsonDecode(s);
    return parsed.map((k, v) => MapEntry(k as String, v?.toString() ?? ''));
  }

  static Future<void> clearPendingProfile() async {
    await _storage.delete(key: _kPendingKey);
  }
}