import 'package:flutter/foundation.dart';
import 'package:flowries/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();

  factory ProductService() => _instance;

  late ValueNotifier<List<Map<String, dynamic>>> _productsNotifier;

  ProductService._internal() {
    _productsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
    _loadInitialData();
  }

  ValueNotifier<List<Map<String, dynamic>>> get productsNotifier =>
      _productsNotifier;

  List<Map<String, dynamic>> get products => _productsNotifier.value;

  Future<void> _loadInitialData() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    
    if (maps.isEmpty) {
      final initialProducts = [
        {
          'id': '1', 'nama': 'Bunga Mawar Merah', 'deskripsi': 'Bunga mawar merah segar berkualitas premium',
          'harga': 150000.0, 'stok': 25, 'rating': 4.8, 'jumlahUlasan': 234, 'gambar': 'assets/images/flower1.png',
          'createdAt': DateTime.now().toIso8601String(), 'createdBy': 'admin'
        },
        {
          'id': '2', 'nama': 'Bunga Tulip Kuning', 'deskripsi': 'Tulip kuning asli Belanda',
          'harga': 120000.0, 'stok': 30, 'rating': 4.6, 'jumlahUlasan': 156, 'gambar': 'assets/images/flower2.png',
          'createdAt': DateTime.now().toIso8601String(), 'createdBy': 'admin'
        },
      ];
      for (var product in initialProducts) {
        await db.insert('products', product, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      _productsNotifier.value = initialProducts;
    } else {
      _productsNotifier.value = maps;
    }
  }

  Future<void> refreshProducts() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('products');
    _productsNotifier.value = maps;
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    final db = await DatabaseHelper.instance.database;
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newProduct = {
      ...product, 
      'id': newId, 
      'createdAt': DateTime.now().toIso8601String(),
      'createdBy': product['createdBy'] ?? 'admin',
    };
    
    await db.insert('products', newProduct);
    await refreshProducts();
  }

  Future<void> updateProduct(String id, Map<String, dynamic> product) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshProducts();
  }

  Future<void> deleteProduct(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshProducts();
  }

  int getProductCount() {
    return _productsNotifier.value.length;
  }
}
