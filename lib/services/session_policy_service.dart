import 'package:shared_preferences/shared_preferences.dart';

class SessionPolicyService {
  static final SessionPolicyService instance = SessionPolicyService._();
  SessionPolicyService._();

  static const _rememberKey = 'session_remember_me';
  static const _expiresAtKey = 'session_expires_at';
  static const Duration _ttl = Duration(days: 7);

  Future<void> saveLoginPolicy({required bool rememberMe}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!rememberMe) {
      await prefs.setBool(_rememberKey, false);
      await prefs.remove(_expiresAtKey);
      return;
    }

    final expiresAt = DateTime.now().add(_ttl).toIso8601String();
    await prefs.setBool(_rememberKey, true);
    await prefs.setString(_expiresAtKey, expiresAt);
  }

  Future<bool> isSessionAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_rememberKey) ?? false;
    if (!remember) return false;

    final rawExpiresAt = prefs.getString(_expiresAtKey);
    if (rawExpiresAt == null || rawExpiresAt.isEmpty) return false;

    final expiresAt = DateTime.tryParse(rawExpiresAt);
    if (expiresAt == null) return false;

    return DateTime.now().isBefore(expiresAt);
  }

  Future<void> clearPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberKey);
    await prefs.remove(_expiresAtKey);
  }
}

