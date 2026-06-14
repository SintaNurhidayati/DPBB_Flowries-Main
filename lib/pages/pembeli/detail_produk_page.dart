import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/review_service.dart';
import '../../services/cart_service.dart';
import '../../widgets/cart_badge_icon.dart';
import '../../widgets/product_image.dart';
import '../../widgets/custom_quantity_selector.dart';

class DetailProdukPage extends StatefulWidget {
  final Map<String, dynamic>? product;

  const DetailProdukPage({super.key, this.product});

  @override
  State<DetailProdukPage> createState() => _DetailProdukPageState();
}

class _DetailProdukPageState extends State<DetailProdukPage> {
  final ReviewService _reviewService = ReviewService();
  final CartService _cartService = CartService();
  Map<String, dynamic>? _product;
  String _productId = '';
  List<Map<String, dynamic>> _reviews = [];
  
  int _quantity = 1;
  String _selectedSize = 'Classic';
  
  final List<String> _sizes = ['Petite', 'Classic', 'Grand'];
  final Map<String, double> _sizePrices = {
    'Petite': 0.8,
    'Classic': 1.0,
    'Grand': 1.5,
  };

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _product = widget.product;
      _productId = _product?['id']?.toString() ?? '';
      _loadReviews();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
    // Listener untuk refresh otomatis ketika ada perubahan review
    _reviewService.reviewsNotifier.addListener(_onReviewsChanged);
  }

  @override
  void dispose() {
    _reviewService.reviewsNotifier.removeListener(_onReviewsChanged);
    super.dispose();
  }

  void _onReviewsChanged() {
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final reviews = await _reviewService.getReviewsByProductId(_productId);
    if (mounted) {
      setState(() {
        _reviews = reviews;
      });
    }
  }

  double get _finalPrice {
    final basePrice = (_product?['harga'] as num?)?.toDouble() ?? 0;
    return basePrice * _sizePrices[_selectedSize]! * _quantity;
  }
  
  double _getAverageRating() {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<double>(
      0,
      (sum, review) => sum + (review['rating'] as int).toDouble(),
    );
    return sum / _reviews.length;
  }

  void _addToCart() {
    if (_product != null) {
      final cartItem = Map<String, dynamic>.from(_product!);
      final basePrice = (_product?['harga'] as num?)?.toDouble() ?? 0;
      cartItem['harga'] = basePrice * _sizePrices[_selectedSize]!;
      cartItem['nama'] = '${_product?['nama']} ($_selectedSize)';

      for (int i = 0; i < _quantity; i++) {
        _cartService.addToCart(cartItem);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_quantity ${_product?['nama']} ($_selectedSize) ditambahkan ke keranjang!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // Widget untuk menampilkan review card dengan balasan admin
  Widget _buildReviewCard(Map<String, dynamic> review) {
    final primaryColor = Theme.of(context).primaryColor;
    
    final hasReply = review['reply'] != null && review['reply'].toString().isNotEmpty;
    final replyDate = hasReply && review['repliedAt'] != null
        ? (review['repliedAt'] as String).split('T')[0]
        : '';
    
    String reviewDate = '';
    try {
      reviewDate = review['tanggalUlasan'] != null
          ? (review['tanggalUlasan'] as String).split('T')[0]
          : '';
    } catch (e) {
      reviewDate = '';
    }

    final userName = review['userName'] ?? review['userId'] ?? 'Anonymous';
    final comment = review['isiUlasan'] ?? review['komentar'] ?? '';
    final rating = review['rating'] ?? 5;
    final imageUrl = review['imageUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (reviewDate.isNotEmpty)
                Text(
                  reviewDate,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Komentar
          Text(
            comment,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          // Foto jika ada
          if (imageUrl != null && imageUrl.toString().isNotEmpty)
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(imageUrl),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image, size: 50),
                              );
                            },
                          ),
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
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          // Balasan Admin
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
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review['reply'],
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Produk'), centerTitle: true, actions: const [CartBadgeIcon()]),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Detail Produk', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
        actions: const [CartBadgeIcon()],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar Produk
                Container(
                  margin: const EdgeInsets.all(16),
                  height: 350,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ProductImage(
                      imageString: _product?['gambar'] ?? _product?['image'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                // Info Produk
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product!['nama'] ?? 'Tanpa Nama',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < _getAverageRating().round() ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_getAverageRating().toStringAsFixed(1)} (${_reviews.length} ulasan)',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Rp ${((_product!['harga'] ?? 0) as num).toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Deskripsi Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              _product!['deskripsi'] ?? 'Tidak ada deskripsi',
                              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Pilih Ukuran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                  color: isSelected ? primaryColor : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSelected ? primaryColor : Colors.transparent),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      size,
                                      style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${((_sizePrices[size]! - 1) * 100).toInt()}%',
                                      style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text('Jumlah', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      CustomQuantitySelector(
                        initialQuantity: _quantity,
                        onQuantityChanged: (qty) => setState(() => _quantity = qty),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Harga', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
                            Text(
                              'Rp ${_finalPrice.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Ulasan dengan Balasan Admin
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ulasan Pelanggan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _reviews.isEmpty
                          ? Center(
                              child: Column(
                                children: [
                                  Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Text('Belum ada ulasan untuk produk ini', style: TextStyle(color: Colors.grey.shade500)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _reviews.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                return _buildReviewCard(_reviews[index]);
                              },
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addToCart,
                        icon: Icon(Icons.add_shopping_cart, color: primaryColor),
                        label: Text('Keranjang', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: primaryColor, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _addToCart();
                          Navigator.pushNamed(context, '/keranjang');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Beli Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}