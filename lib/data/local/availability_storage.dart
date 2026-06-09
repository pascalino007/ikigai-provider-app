import 'package:shared_preferences/shared_preferences.dart';

/// Persists partner "En ligne" (free) vs "Occupé" (occupé). `true` = available / En ligne.
abstract final class AvailabilityStorage {
  static String _key(int userId) => 'ikigai_provider_avail_$userId';

  static Future<bool> isAvailable(int userId) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key(userId)) ?? true;
  }

  static Future<void> setAvailable(int userId, bool available) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key(userId), available);
  }
}
