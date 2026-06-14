import 'package:shared_preferences/shared_preferences.dart';

class SessionPreferences {
  static final SessionPreferences _instance = SessionPreferences._internal();
  factory SessionPreferences() => _instance;
  SessionPreferences._internal();

  static const String KEY_USER_ID = 'user_id';
  static const String KEY_IS_LOGGED_IN = 'is_logged_in';
  static const String KEY_USER_NAME = 'user_name';
  static const String KEY_USER_EMAIL = 'user_email';

  static const String KEY_LAST_CHECKOUT_ADDRESS = 'last_checkout_address';
  static const String KEY_SELECTED_PAYMENT_METHOD = 'selected_payment_method';


  // Untuk checkout  9alamat terakhir)
  Future<void> saveLastCheckoutAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_LAST_CHECKOUT_ADDRESS, address);
  }

  Future<String> getLastCheckoutAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_LAST_CHECKOUT_ADDRESS) ?? '';
  }

  // Untuk payment (metode pembayaran yang dipilih)
  Future<void> saveSelectedPaymentMethod(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_SELECTED_PAYMENT_METHOD, method);
  }

  Future<String> getSelectedPaymentMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_SELECTED_PAYMENT_METHOD) ?? 'Transfer Bank BCA';
  }

  // Simpan session user
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
    print('Session saved: userId=$userId');
  }

  // Ambil userId
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_USER_ID);
  }

  // Cek login status
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KEY_IS_LOGGED_IN) ?? false;
  }

  // Ambil nama user
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_USER_NAME);
  }

  // Ambil email user
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_USER_EMAIL);
  }

  // Ambil semua data user
  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(KEY_USER_ID),
      'userName': prefs.getString(KEY_USER_NAME),
      'userEmail': prefs.getString(KEY_USER_EMAIL),
    };
  }

  // Logout (hapus session)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_USER_ID);
    await prefs.remove(KEY_IS_LOGGED_IN);
    await prefs.remove(KEY_USER_NAME);
    await prefs.remove(KEY_USER_EMAIL);
    print('Session cleared');
  }
}