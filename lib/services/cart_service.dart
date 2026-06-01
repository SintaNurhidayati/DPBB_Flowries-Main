import 'package:flutter/material.dart';

class CartService {
  static final CartService _instance = CartService._internal();

  factory CartService() => _instance;

  late ValueNotifier<List<Map<String, dynamic>>> _cartNotifier;

  // Cart items data
  final List<Map<String, dynamic>> _cartItems = [];

  CartService._internal() {
    _cartNotifier = ValueNotifier<List<Map<String, dynamic>>>(_cartItems);
  }

  ValueNotifier<List<Map<String, dynamic>>> get cartNotifier => _cartNotifier;

  List<Map<String, dynamic>> get cartItems => _cartItems;

  void addToCart(Map<String, dynamic> product) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item['id'] == product['id'],
    );

    if (existingIndex >= 0) {
      _cartItems[existingIndex]['quantity'] =
          (_cartItems[existingIndex]['quantity'] ?? 1) + 1;
    } else {
      _cartItems.add({
        'id': product['id'],
        'nama': product['nama'] ?? 'Produk',
        'image': product['gambar'] ?? product['image'] ?? 'assets/images/flower1.png',
        'harga': product['harga'] ?? 0,
        'quantity': 1,
        'isSelected': true,
      });
    }
    _cartNotifier.value = [..._cartItems];
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item['id'] == productId);
    _cartNotifier.value = [..._cartItems];
  }

  void updateQuantity(String productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item['id'] == productId);
    if (index >= 0 && quantity > 0) {
      _cartItems[index]['quantity'] = quantity;
      _cartNotifier.value = [..._cartItems];
    }
  }

  void toggleSelection(String productId) {
    final index = _cartItems.indexWhere((item) => item['id'] == productId);
    if (index >= 0) {
      _cartItems[index]['isSelected'] =
          !(_cartItems[index]['isSelected'] ?? false);
      _cartNotifier.value = [..._cartItems];
    }
  }

  void clearCart() {
    _cartItems.clear();
    _cartNotifier.value = [..._cartItems];
  }

  double getTotalPrice() {
    double total = 0.0;
    for (var item in _cartItems) {
      if (item['isSelected'] == true) {
        total += ((item['harga'] ?? 0.0) as num).toDouble() *
            ((item['quantity'] ?? 1) as num).toDouble();
      }
    }
    return total;
  }

  int getCartCount() {
    return _cartItems.length;
  }
}