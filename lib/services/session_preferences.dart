// lib/services/session_preferences.dart
import 'package:shared_preferences/shared_preferences.dart';

class SessionPreferences {
  static final SessionPreferences _instance = SessionPreferences._internal();
  factory SessionPreferences() => _instance;
  SessionPreferences._internal();

  // 🔑 MINIMAL 2 KEY UNTUK TUGAS
  static const String KEY_USER_ID = 'user_id';
  static const String KEY_IS_LOGGED_IN = 'is_logged_in';
  
  // Key tambahan
  static const String KEY_USER_NAME = 'user_name';
  static const String KEY_USER_EMAIL = 'user_email';

  // ✅ Simpan session user
  Future<void> saveUserSession({
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_USER_ID, userId);
    await prefs.setBool(KEY_IS_LOGGED_IN, true);
    await prefs.setString(KEY_USER_NAME, userName);
    await prefs.setString(KEY_USER_EMAIL, userEmail);
    print('✅ Session saved: userId=$userId');
  }

  // ✅ Ambil userId
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_USER_ID);
  }

  // ✅ Cek login status
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KEY_IS_LOGGED_IN) ?? false;
  }

  // ✅ Ambil nama user
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_USER_NAME);
  }

  // ✅ Ambil email user
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_USER_EMAIL);
  }

  // ✅ Ambil semua data user
  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(KEY_USER_ID),
      'userName': prefs.getString(KEY_USER_NAME),
      'userEmail': prefs.getString(KEY_USER_EMAIL),
    };
  }

  // ✅ Logout (hapus session)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_USER_ID);
    await prefs.remove(KEY_IS_LOGGED_IN);
    await prefs.remove(KEY_USER_NAME);
    await prefs.remove(KEY_USER_EMAIL);
    print('✅ Session cleared');
  }
}