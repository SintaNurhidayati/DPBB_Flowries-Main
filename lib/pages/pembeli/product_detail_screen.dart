// lib/pages/pembeli/product_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../services/review_service.dart';
import '../../widgets/custom_quantity_selector.dart';
import '../../services/cart_service.dart';
import '../../services/session_preferences.dart';  // ✅ TAMBAHKAN
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;  // ✅ HANYA productId, TIDAK PERLU userId

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? _product;
  bool _isLoading = true;
  int _quantity = 1;
  String _selectedSize = 'Classic';
  final List<String> _sizes = ['Petite', 'Classic', 'Grand'];
  final Map<String, double> _sizePrices = {
    'Petite': 0.8,
    'Classic': 1.0,
    'Grand': 1.5,
  };
  List<Map<String, dynamic>> _reviews = [];
  int _cartCount = 0;
  final ReviewService _reviewService = ReviewService();
  final SessionPreferences _session = SessionPreferences();  // ✅ TAMBAHKAN
  String? _userId;  // ✅ TAMBAHKAN

  final String _defaultImage = 'assets/images/placeholder.png';

  @override
  void initState() {
    super.initState();
    _loadUserId();  // ✅ PANGGIL INI
    _loadProduct();
    _loadReviews();
    _loadCartCount();
    _reviewService.reviewsNotifier.addListener(_onReviewsChanged);
  }

  @override
  void dispose() {
    _reviewService.reviewsNotifier.removeListener(_onReviewsChanged);
    super.dispose();
  }

  // ✅ TAMBAHKAN METHOD INI
  Future<void> _loadUserId() async {
    final userId = await _session.getUserId();
    setState(() {
      _userId = userId;
    });
  }

  void _onReviewsChanged() {
    _loadReviews();
  }

  Future<void> _loadCartCount() async {
    if (mounted) setState(() => _cartCount = CartService().getCartCount());
  }

  Future<void> _loadProduct() async {
    final product = await DatabaseHelper.instance.getProductById(
      widget.productId,
    );
    setState(() {
      _product = product;
      _isLoading = false;
    });
  }

  Future<void> _loadReviews() async {
    final reviews = await _reviewService.getReviewsByProductId(
      widget.productId.toString(),
    );
    setState(() => _reviews = reviews);
  }

  String _getProductImageUrl() {
    if (_product == null) return '';
    return _product!['image_url'] ?? '';
  }

  Widget _buildProductImage() {
    final primaryColor = Theme.of(context).primaryColor;
    final imageUrl = _getProductImageUrl();

    if (imageUrl.isEmpty) {
      return _buildPlaceholderImage(primaryColor);
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        height: 300,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderImage(primaryColor),
      );
    }

    try {
      if (imageUrl.startsWith('/9j/') || imageUrl.startsWith('iVBOR')) {
        return Image.memory(
          base64Decode(imageUrl),
          height: 300,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholderImage(primaryColor),
        );
      }
    } catch (e) {}

    return Image.asset(
      'assets/images/$imageUrl',
      height: 300,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceholderImage(primaryColor),
    );
  }

  Widget _buildPlaceholderImage(Color primaryColor) {
    return Container(
      height: 300,
      color: primaryColor.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 60, color: primaryColor),
          const SizedBox(height: 8),
          Text(
            'Gambar tidak tersedia',
            style: TextStyle(color: primaryColor, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'ID Produk: ${_product!['id']}',
            style: TextStyle(color: primaryColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  double get _finalPrice {
    final basePrice = (_product?['price'] as num?)?.toDouble() ?? (_product?['harga'] as num?)?.toDouble() ?? 0;
    return basePrice * _sizePrices[_selectedSize]! * _quantity;
  }

  // ✅ PERBAIKI _addToCart (tidak perlu userId)
  Future<void> _addToCart() async {
    try {
      final productMap = {
        'id': widget.productId.toString(),
        'nama': _product?['nama'] ?? _product?['name'] ?? 'Produk',
        'gambar': _product?['gambar'] ?? _product?['image_url'],
        'harga': _finalPrice / _quantity,
      };
      
      for (int i = 0; i < _quantity; i++) {
        CartService().addToCart(productMap);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk ditambahkan ke keranjang')),
        );
        // ✅ PERBAIKI: CartScreen TANPA parameter userId
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CartScreen(),  // ✅ Tanpa parameter
          ),
        );
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan: $e')),
        );
      }
    }
  }

  // ✅ PERBAIKI _buyNow (tidak perlu userId)
  Future<void> _buyNow() async {
    try {
      final productMap = {
        'id': widget.productId.toString(),
        'nama': _product?['nama'] ?? _product?['name'] ?? 'Produk',
        'gambar': _product?['gambar'] ?? _product?['image_url'],
        'harga': _finalPrice / _quantity,
      };
      
      for (int i = 0; i < _quantity; i++) {
        CartService().addToCart(productMap);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CartScreen(),  // ✅ Tanpa parameter
          ),
        );
      }
    } catch (e) {
      print('Error in buy now: $e');
    }
  }

  Widget _buildReviewCard(Map<String, dynamic> review, Color primaryColor, Color backgroundColor) {
    final hasReply = review['reply'] != null && review['reply'].toString().isNotEmpty;
    final replyDate = hasReply && review['repliedAt'] != null
        ? (review['repliedAt'] as String).split('T')[0]
        : '';
    
    final reviewDate = review['tanggalUlasan'] != null
        ? (review['tanggalUlasan'] as String).split('T')[0]
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text(
                      (review['userName'] ?? review['userId'] ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['userName'] ?? review['userId'] ?? 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < (review['rating'] ?? 5)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                reviewDate,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review['isiUlasan'] ?? review['komentar'] ?? '',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          if (review['imageUrl'] != null && review['imageUrl'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: Container(
                        height: 400,
                        width: 400,
                        child: Image.memory(
                          base64Decode(review['imageUrl']),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(review['imageUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          if (hasReply) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 14, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Balasan Admin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: primaryColor,
                        ),
                      ),
                      const Spacer(),
                      if (replyDate.isNotEmpty)
                        Text(
                          replyDate,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review['reply'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAllReviewsDialog() {
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Semua Ulasan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      return _buildReviewCard(review, primaryColor, backgroundColor);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ✅ PERBAIKI bagian actions di AppBar
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_product == null) {
      return const Scaffold(
        body: Center(child: Text('Produk tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Produk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  // ✅ PERBAIKI: CartScreen TANPA parameter
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),  // ✅ Tanpa parameter
                    ),
                  ).then((_) => _loadCartCount());
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildProductImage(),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product!['name'] ?? _product!['nama'] ?? 'Produk',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < (_product!['rating']?.toInt() ?? 4)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_product!['rating'] ?? 4.5} (${_reviews.length} ulasan)',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rp ${(_product!['price'] as num).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deskripsi Produk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _product!['description'] ?? _product!['deskripsi'] ?? 'Tidak ada deskripsi',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pilih Ukuran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _sizes.map((size) {
                      final isSelected = _selectedSize == size;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSize = size),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  size,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${((_sizePrices[size]! - 1) * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected
                                        ? Colors.white70
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Jumlah',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  CustomQuantitySelector(
                    initialQuantity: _quantity,
                    onQuantityChanged: (qty) => setState(() => _quantity = qty),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Harga',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Rp ${_finalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _addToCart,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Tambah ke Keranjang'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _buyNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Beli Sekarang'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ulasan Pelanggan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_reviews.isNotEmpty)
                        TextButton(
                          onPressed: _showAllReviewsDialog,
                          style: TextButton.styleFrom(
                            foregroundColor: primaryColor,
                          ),
                          child: const Text('Lihat Semua >'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_reviews.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.reviews,
                              size: 50,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada ulasan',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Jadilah yang pertama memberi ulasan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length > 2 ? 2 : _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        return _buildReviewCard(review, primaryColor, backgroundColor);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}