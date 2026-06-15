import 'package:flutter/material.dart';
import '../../widgets/custom_navbar.dart';
import '../../services/cart_service.dart';
import '../../widgets/product_image.dart';
import '../../services/session_preferences.dart';
import '../../widgets/swipe_to_delete_widget.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int _currentNavIndex = 2;
  final CartService _cartService = CartService();
  final SessionPreferences _session = SessionPreferences();
  
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _cartService.cartNotifier.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cartService.cartNotifier.removeListener(_onCartChanged);
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final userId = await _session.getUserId();
    setState(() {
      _userId = userId;
      _isLoading = false;
    });

    if (userId == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _onCartChanged() {
    setState(() {});
  }

  List<Map<String, dynamic>> get _keranjangItems => _cartService.cartItems;

  void _handleNavigation(int index) {
    if (_currentNavIndex == index) return;
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/customer-home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/katalog');
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/riwayat');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profil-pembeli');
        break;
    }
  }

  void _updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      _cartService.removeFromCart(productId);
      return;
    }
    _cartService.updateQuantity(productId, newQuantity);
  }

  void _toggleSelection(String productId) {
    _cartService.toggleSelection(productId);
  }

  void _deleteItem(String productId, String productName) {
    _cartService.removeFromCart(productId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$productName telah dihapus dari keranjang')),
      );
    }
  }

  Future<void> _checkout() async {
    final selectedItems = _keranjangItems.where((item) => item['isSelected'] == true).toList();
    
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk terlebih dahulu')),
      );
      return;
    }

    final double totalPrice = selectedItems.fold(0.0, (sum, item) {
      final price = (item['harga'] ?? 0).toDouble();
      final quantity = (item['quantity'] as int?) ?? 1;
      return sum + (price * quantity);
    });

    final List<String> selectedIds = selectedItems.map((item) => item['id'].toString()).toList();
    final List<Map<String, dynamic>> itemsToCheckout = List.from(selectedItems);

    // Navigasi ke halaman checkout dan tunggu hasilnya
    final result = await Navigator.pushNamed(
      context,
      '/checkout',
      arguments: {
        'items': itemsToCheckout,
        'total': totalPrice,
        'selectedIds': selectedIds,
      },
    );

    // HAPUS ITEM HANYA JIKA PESANAN BERHASIL DIBUAT
    if (result == 'success') {
      for (var item in selectedItems) {
        _cartService.removeFromCart(item['id']);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibuat!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    final selectedItems = _keranjangItems.where((item) => item['isSelected'] == true).toList();
    final double totalPrice = selectedItems.fold(0.0, (sum, item) {
      final price = (item['harga'] ?? 0).toDouble();
      final quantity = (item['quantity'] as int?) ?? 1;
      return sum + (price * quantity);
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Keranjang Belanja', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _keranjangItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Keranjang Anda kosong',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yuk, mulai belanja bunga favorit Anda!',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/katalog'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Mulai Belanja', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _keranjangItems.length,
                    itemBuilder: (context, index) {
                      final item = _keranjangItems[index];
                      final cartId = item['id'];
                      final isSelected = item['isSelected'] ?? false;
                      final productName = item['nama'] ?? 'Produk';
                      final productPrice = ((item['harga'] ?? 0) as num).toDouble();
                      final quantity = item['quantity'] as int? ?? 1;

                      return SwipeToDeleteWidget(
                        onDelete: () => _deleteItem(cartId, productName),
                        confirmationText: 'Apakah Anda yakin ingin menghapus "$productName" dari keranjang?',
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? primaryColor : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _toggleSelection(cartId),
                                  activeColor: primaryColor,
                                  checkColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: ProductImage(
                                      imageString: item['gambar'] ?? item['image'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rp ${productPrice.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove_circle_outline, color: primaryColor),
                                          onPressed: () => _updateQuantity(cartId, quantity - 1),
                                          iconSize: 24,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        Container(
                                          width: 35,
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$quantity',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.add_circle_outline, color: primaryColor),
                                          onPressed: () => _updateQuantity(cartId, quantity + 1),
                                          iconSize: 24,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${(productPrice * quantity).toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Belanja',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp ${totalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            '${selectedItems.length} item dipilih',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: selectedItems.isEmpty ? null : _checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Checkout',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentNavIndex,
        onIndexChanged: _handleNavigation,
        userRole: 'pembeli',
      ),
    );
  }
}