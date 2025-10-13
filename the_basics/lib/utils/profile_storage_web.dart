import 'dart:html' as html;
import 'dart:convert';

class ProfileStorage {
  static const _kPendingKey = 'pending_profile';

  static Future<void> savePendingProfile(Map<String, String?> profile) async {
    html.window.localStorage[_kPendingKey] = jsonEncode(profile);
  }

  static Future<Map<String, String>?> getPendingProfile() async {
    final s = html.window.localStorage[_kPendingKey];
    print("=> ProfileStorage.getPendingProfile() returned: $s");
    if (s == null) return null;
    
    final Map parsed = jsonDecode(s);
    return parsed.map((k, v) => MapEntry(k as String, v?.toString() ?? ''));
  }

  static Future<void> clearPendingProfile() async {
    html.window.localStorage.remove(_kPendingKey);
  }
}