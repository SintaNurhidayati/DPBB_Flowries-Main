// lib/services/user_service.dart
import 'package:flutter/material.dart';
import 'package:flowries/services/database_helper.dart';

class UserService {
  static final UserService _instance = UserService._internal();

  factory UserService() {
    return _instance;
  }

  UserService._internal();

  Map<String, dynamic> _currentUser = {};
  final ValueNotifier<Map<String, dynamic>> userNotifier = ValueNotifier({});

  // ✅ TAMBAHKAN METHOD REGISTER USER INI
  Future<Map<String, dynamic>?> registerUser(Map<String, dynamic> userData) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Cek apakah email sudah terdaftar
      final existingUser = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [userData['email']],
      );
      
      if (existingUser.isNotEmpty) {
        debugPrint('❌ Email already registered: ${userData['email']}');
        return null;
      }
      
      // Buat ID baru
      final String newId = DateTime.now().millisecondsSinceEpoch.toString();
      final String createdAt = DateTime.now().toIso8601String();
      
      final Map<String, dynamic> newUser = {
        'id': newId,
        'email': userData['email'],
        'password': userData['password'],
        'nama': userData['nama'],
        'noTelepon': userData['noTelepon'] ?? '',
        'alamat': userData['alamat'] ?? '',
        'tipeUser': userData['tipeUser'] ?? 'pembeli',
        'createdAt': createdAt,
        'isActive': 1,
      };
      
      await db.insert('users', newUser);
      debugPrint('✅ User registered: ${userData['email']} with ID: $newId');
      
      return newUser;
      
    } catch (e) {
      debugPrint('❌ Error registering user: $e');
      return null;
    }
  }

  // Method addUser yang sudah ada (panggil registerUser)
  Future<void> addUser(Map<String, dynamic> userData) async {
    await registerUser(userData);
  }

  Future<List<Map<String, dynamic>>> getUsersByType(String tipe) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('users', where: 'tipeUser = ?', whereArgs: [tipe]);
  }
  
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('users');
  }

  Future<Map<String, dynamic>?> authenticateUser(String email, String password) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (results.isNotEmpty) {
      final user = results.first;
      if (user['isActive'] == 0) {
        throw Exception('Akun Anda telah dinonaktifkan. Silakan hubungi admin.');
      }
      return user;
    }
    // Check in-memory hardcoded admin as fallback for easy login testing
    if (email == 'admin@gmail.com' && password == 'admin123') {
       return {'id': 'admin', 'nama': 'Admin', 'email': 'admin@gmail.com', 'tipeUser': 'admin', 'password': '123'};
    }
    return null;
  }

  Map<String, dynamic> get currentUser => _currentUser;

  void setCurrentUser(Map<String, dynamic> userData) {
    _currentUser = userData;
    userNotifier.value = userData;
    debugPrint('✅ User logged in: ${userData['nama']} (${userData['email']})');
  }

  void clearCurrentUser() {
    _currentUser = {};
    userNotifier.value = {};
    debugPrint('✅ User logged out');
  }

  bool get isLoggedIn =>
      _currentUser.isNotEmpty && _currentUser.containsKey('email');

  String get userName => _currentUser['nama'] ?? 'User';
  String get userEmail => _currentUser['email'] ?? '';
  String get userType => _currentUser['tipeUser'] ?? 'pembeli';

  Future<void> deleteUser(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleUserStatus(String id, int currentStatus) async {
    final db = await DatabaseHelper.instance.database;
    final newStatus = currentStatus == 1 ? 0 : 1;
    await db.update('users', {'isActive': newStatus}, where: 'id = ?', whereArgs: [id]);
  }
}