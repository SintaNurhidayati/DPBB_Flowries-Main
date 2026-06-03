import 'dart:convert';
import 'package:flutter/material.dart';
import '../../widgets/custom_navbar.dart';
import '../../services/transaction_service.dart';
import '../../services/review_service.dart';
import '../../widgets/cart_badge_icon.dart';
import '../../services/session_preferences.dart';
import 'tambah_ulasan_page.dart';

class RiwayatTransaksiPage extends StatefulWidget {
  const RiwayatTransaksiPage({super.key});

  @override
  State<RiwayatTransaksiPage> createState() => _RiwayatTransaksiPageState();
}

class _RiwayatTransaksiPageState extends State<RiwayatTransaksiPage> {
  int _currentNavIndex = 3;
  final TransactionService _transactionService = TransactionService();
  final ReviewService _reviewService = ReviewService();
  final SessionPreferences _session = SessionPreferences();
  String _filter = 'all';
  
  String? _currentUserId;
  bool _isLoading = true;

  Map<String, Map<String, dynamic>> _reviewStatusCache = {};

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _transactionService.initialize();
    _transactionService.transactionsNotifier.addListener(_onTransactionsChanged);
    _reviewService.reviewsNotifier.addListener(_onReviewsChanged);
  }

  @override
  void dispose() {
    _transactionService.transactionsNotifier.removeListener(_onTransactionsChanged);
    _reviewService.reviewsNotifier.removeListener(_onReviewsChanged);
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final userId = await _session.getUserId();
    setState(() {
      _currentUserId = userId;
      _isLoading = false;
    });
    
    if (userId != null) {
      _checkAllReviewStatuses();
    } else if (mounted) {
      // Jika tidak ada session, arahkan ke login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _onTransactionsChanged() {
    setState(() {});
    _checkAllReviewStatuses();
  }

  void _onReviewsChanged() {
    setState(() {});
    _checkAllReviewStatuses();
  }

  Future<void> _checkAllReviewStatuses() async {
    if (_currentUserId == null) return;
    
    final transactions = _transactionService.transactions;
    for (var transaction in transactions) {
      if (transaction['status'] == 'selesai' || transaction['status'] == 'Berhasil') {
        final itemsArray = transaction['itemsArray'] as List<dynamic>? ?? [];
        for (var item in itemsArray) {
          final dynamic rawProductId = item['id'] ?? item['productId'];
          if (rawProductId == null) continue;

          final String productId = rawProductId.toString();
          
          try {
            final hasReviewed = await _reviewService.hasUserReviewedProduct(
              _currentUserId!,
              productId,
            );
            final cacheKey = '${transaction['id']}_$productId';
            _reviewStatusCache[cacheKey] = {
              'isReviewed': hasReviewed,
              'productId': productId,
            };
          } catch (e) {
            print('Error checking review status: $e');
          }
        }
      }
    }
    if (mounted) setState(() {});
  }

  Future<bool> _checkProductReviewed(String transactionId, dynamic rawProductId) async {
    if (rawProductId == null) return false;
    if (_currentUserId == null) return false;

    final String productId = rawProductId.toString();
    final String cacheKey = '${transactionId}_$productId';

    if (_reviewStatusCache.containsKey(cacheKey)) {
      return _reviewStatusCache[cacheKey]!['isReviewed'] ?? false;
    }

    try {
      final isReviewed = await _reviewService.hasUserReviewedProduct(
        _currentUserId!,
        productId,
      );
      _reviewStatusCache[cacheKey] = {
        'isReviewed': isReviewed,
        'productId': productId,
      };
      return isReviewed;
    } catch (e) {
      print('Error checking product review: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_currentUserId == null) return [];
    
    final transactions = _transactionService.transactions
        .where((t) => t['pembeli'].toString() == _currentUserId)
        .toList();

    transactions.sort((a, b) {
      final dateA = a['tanggal'] ?? '';
      final dateB = b['tanggal'] ?? '';
      return dateB.compareTo(dateA);
    });

    if (_filter == 'all') return transactions;
    if (_filter == 'success') {
      return transactions
          .where((t) => t['status'] == 'selesai' || t['status'] == 'Berhasil')
          .toList();
    }
    if (_filter == 'pending') {
      return transactions
          .where(
            (t) =>
                t['status'] != 'selesai' &&
                t['status'] != 'Berhasil' &&
                t['status'] != 'dibatalkan',
          )
          .toList();
    }
    return transactions;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'selesai':
      case 'Berhasil':
        return Colors.green;
      case 'diproses':
      case 'menunggu_verifikasi_admin':
        return Colors.orange;
      case 'menunggu_pembayaran':
      case 'menunggu':
      case 'menunggu_harga_admin':
        return Colors.blue;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'selesai':
        return 'Berhasil';
      case 'Berhasil':
        return 'Berhasil';
      case 'diproses':
        return 'Diproses';
      case 'menunggu_harga_admin':
        return 'Menunggu Harga';
      case 'menunggu_pembayaran':
        return 'Menunggu Pembayaran';
      case 'menunggu_verifikasi_admin':
        return 'Menunggu Verifikasi';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'selesai':
      case 'Berhasil':
        return Icons.check_circle;
      case 'diproses':
      case 'menunggu_verifikasi_admin':
      case 'menunggu_pembayaran':
      case 'menunggu':
      case 'menunggu_harga_admin':
        return Icons.access_time;
      case 'dibatalkan':
        return Icons.cancel;
      default:
        return Icons.error_outline;
    }
  }

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
        Navigator.pushReplacementNamed(context, '/custom-order');
        break;
      case 3:
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profil-pembeli');
        break;
    }
  }

  Widget _buildTabButton(String title, bool isSelected, VoidCallback onTap, Color primaryColor) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewButton(Map<String, dynamic> transaction, dynamic item, Color primaryColor) {
    final dynamic rawProductId = item['id'] ?? item['productId'];
    final String productId = rawProductId?.toString() ?? '';
    final String transactionId = transaction['id'].toString();
    final String productName = item['nama'] ?? item['name'] ?? 'Produk';
    final int quantity = item['quantity'] ?? 1;
    final double price = (item['harga'] ?? item['price'] ?? 0).toDouble();

    if (productId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: _checkProductReviewed(transactionId, rawProductId),
      builder: (context, snapshot) {
        final isReviewed = snapshot.data ?? false;

        return SizedBox(
          width: 110,
          height: 36,
          child: ElevatedButton(
            onPressed: () {
              final productData = {
                'id': productId,
                'nama': productName,
                'harga': price,
                'quantity': quantity,
                'image': item['image'] ?? 'assets/images/flower1.png',
              };

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TambahUlasanPage(
                    transactionId: transactionId,
                    product: productData,
                    isEdit: isReviewed,
                  ),
                ),
              ).then((_) {
                _checkAllReviewStatuses();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isReviewed ? Colors.orange : primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              minimumSize: const Size(0, 36),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isReviewed ? Icons.edit : Icons.rate_review, size: 16),
                const SizedBox(width: 6),
                Text(
                  isReviewed ? 'Edit Ulasan' : 'Beri Ulasan',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, Color primaryColor, Color surfaceColor) {
    final status = transaction['status'] ?? 'pending';
    final isMenungguPembayaran = status == 'menunggu_pembayaran' || status == 'menunggu';
    final isMenungguHarga = status == 'menunggu_harga_admin';
    final itemsArray = transaction['itemsArray'] as List<dynamic>? ?? [];
    final isSelesai = status == 'selesai' || status == 'Berhasil';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #${transaction['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(transaction['tanggal'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(status), size: 14, color: _getStatusColor(status)),
                      const SizedBox(width: 6),
                      Text(_formatStatus(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _getStatusColor(status))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Detail Produk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (itemsArray.isNotEmpty)
                  ...itemsArray.map((item) {
                    final qty = item['quantity'] ?? 1;
                    final nama = item['nama'] ?? item['name'] ?? 'Produk';
                    final harga = (item['harga'] ?? item['price'] ?? 0).toDouble();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.local_florist, size: 24, color: primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${qty}x', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    Text('Rp ${(harga * qty).toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (isSelesai) _buildReviewButton(transaction, item, primaryColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                else
                  Text(transaction['items'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade100, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('Rp ${(transaction['total'] as num).toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                      ],
                    ),
                    if (isMenungguPembayaran)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/pembayaran', arguments: {
                            'transactionId': transaction['id'],
                            'isPaymentOnly': true,
                            'total': transaction['total'],
                            'items': itemsArray,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 0,
                        ),
                        child: const Text('Bayar Sekarang', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      )
                    else if (isMenungguHarga)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(25)),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.orange),
                            const SizedBox(width: 6),
                            const Text('Menunggu Admin...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.orange)),
                          ],
                        ),
                      )
                    else if (isSelesai)
                      OutlinedButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/katalog'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text('Belanja Lagi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                if (transaction['buktiPembayaran'] != null && transaction['buktiPembayaran'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bukti Pembayaran:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Padding(padding: EdgeInsets.all(16), child: Text('Bukti Pembayaran', style: TextStyle(fontWeight: FontWeight.bold))),
                                    SizedBox(
                                      height: 400,
                                      width: double.infinity,
                                      child: Image.memory(base64Decode(transaction['buktiPembayaran']), fit: BoxFit.contain),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(base64Decode(transaction['buktiPembayaran']), fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
    final surfaceColor = Theme.of(context).colorScheme.surface;

    final transactions = _filteredTransactions;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: const [CartBadgeIcon()],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                _buildTabButton('Semua', _filter == 'all', () => setState(() => _filter = 'all'), primaryColor),
                _buildTabButton('Berhasil', _filter == 'success', () => setState(() => _filter = 'success'), primaryColor),
                _buildTabButton('Menunggu', _filter == 'pending', () => setState(() => _filter = 'pending'), primaryColor),
              ],
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Tidak ada riwayat transaksi', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Yuk, mulai belanja sekarang!', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionCard(transactions[index], primaryColor, surfaceColor);
                    },
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