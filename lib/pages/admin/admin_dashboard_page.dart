import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/product_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/admin_layout.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final ProductService _productService = ProductService();
  final TransactionService _transactionService = TransactionService();
  bool _isLoading = false;
  
  // Dua variabel untuk Shared Preferences
  bool _showStats = true;
  bool _showRecentTransactions = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadData();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showStats = prefs.getBool('admin_show_stats') ?? true;
      _showRecentTransactions = prefs.getBool('admin_show_recent_transactions') ?? true;
    });
  }

  Future<void> _toggleStats(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_show_stats', value);
    setState(() {
      _showStats = value;
    });
  }

  Future<void> _toggleRecentTransactions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_show_recent_transactions', value);
    setState(() {
      _showRecentTransactions = value;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _productService.refreshProducts();
      await _transactionService.refreshTransactions();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat data: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _calculateStats(
    List<Map<String, dynamic>> products,
    List<Map<String, dynamic>> transactions,
  ) {
    final totalProduk = products.length;
    final totalTransaksi = transactions.length;
    final totalPenjualan = transactions.fold<double>(
      0.0,
      (sum, t) => sum + ((t['total'] ?? 0) as num).toDouble(),
    );
    final totalPembeli = transactions.map((t) => t['pembeli']).toSet().length;

    return {
      'totalProduk': totalProduk,
      'totalTransaksi': totalTransaksi,
      'totalPenjualan': totalPenjualan,
      'totalPembeli': totalPembeli,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Dashboard',
      selectedIndex: 0,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedBuilder(
              animation: Listenable.merge([
                _productService.productsNotifier,
                _transactionService.transactionsNotifier,
              ]),
              builder: (context, _) {
                final products = _productService.products;
                final transactions = _transactionService.transactions;
                final stats = _calculateStats(products, transactions);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pengaturan Shared Preferences Toggles
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.settings, color: Colors.grey),
                            const SizedBox(width: 10),
                            const Text(
                              'Pengaturan Tampilan Dashboard:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            const Text('Tampilkan Statistik'),
                            Switch(
                              value: _showStats,
                              onChanged: _toggleStats,
                              activeColor: Colors.pink,
                            ),
                            const SizedBox(width: 20),
                            const Text('Tampilkan Transaksi Terbaru'),
                            Switch(
                              value: _showRecentTransactions,
                              onChanged: _toggleRecentTransactions,
                              activeColor: Colors.pink,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Statistics Section
                      if (_showStats) ...[
                        GridView.count(
                          crossAxisCount: 4, // Desktop layout 4 columns
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        children: [
                          _buildStatCard(
                            'Produk',
                            '${stats['totalProduk']}',
                            Icons.shopping_bag,
                            Colors.blue,
                          ),
                          _buildStatCard(
                            'Transaksi',
                            '${stats['totalTransaksi']}',
                            Icons.receipt,
                            Colors.green,
                          ),
                          _buildStatCard(
                            'Penjualan',
                            'Rp ${(stats['totalPenjualan'] / 1000000).toStringAsFixed(1)}M',
                            Icons.trending_up,
                            Colors.orange,
                          ),
                          _buildStatCard(
                            'Pembeli',
                            '${stats['totalPembeli']}',
                            Icons.people,
                            Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],

                      // Recent Transactions
                      if (_showRecentTransactions) ...[
                        const Text(
                          'Transaksi Terbaru',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 15),
                      transactions.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('Tidak ada transaksi'),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = transactions[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              transaction['id'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Pembeli: ${transaction['pembeli']}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Rp ${transaction['total']}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.pink,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Tanggal: ${transaction['tanggal']}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                transaction['status'] ?? '',
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              (transaction['status'] ?? '')
                                                  .toString()
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(
                                                  transaction['status'] ?? '',
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          IconButton(
                                            icon: const Icon(Icons.info_outline,
                                                size: 24),
                                            onPressed: () {
                                              // Dialog untuk detail transaksi
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: Text(
                                                      transaction['id'] ?? ''),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          'Pembeli: ${transaction['pembeli']}'),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                          'Items: ${transaction['items']}'),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                          'Total: Rp ${transaction['total']}'),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                          'Status: ${transaction['status']}'),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                          'Tanggal: ${transaction['tanggal']}'),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child: const Text('Tutup'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            tooltip: 'Lihat detail',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'diproses':
        return Colors.orange;
      case 'menunggu':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
