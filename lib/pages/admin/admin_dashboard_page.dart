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
      _showRecentTransactions =
          prefs.getBool('admin_show_recent_transactions') ?? true;
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

    return {'totalProduk': totalProduk}..addAll({
      'totalTransaksi': totalTransaksi,
      'totalPenjualan': totalPenjualan,
      'totalPembeli': totalPembeli,
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil lebar layar HP untuk menentukan jumlah kolom secara dinamis
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600
        ? 4
        : 2; // Kalau di HP jadi 2 kolom, kalau layar lebar (web/tablet) jadi 4 kolom

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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. PERBAIKAN: Pengaturan Toggles Menggunakan ExpansionTile (Biar Hemat Tempat & Ga Overflow)
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: ExpansionTile(
                          leading: const Icon(
                            Icons.settings,
                            color: Colors.grey,
                          ),
                          title: const Text(
                            'Pengaturan Tampilan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          children: [
                            SwitchListTile(
                              title: const Text(
                                'Tampilkan Statistik',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: _showStats,
                              onChanged: _toggleStats,
                              activeColor: Colors.pink,
                            ),
                            SwitchListTile(
                              title: const Text(
                                'Tampilkan Transaksi Terbaru',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: _showRecentTransactions,
                              onChanged: _toggleRecentTransactions,
                              activeColor: Colors.pink,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. PERBAIKAN: GridView Statistik yang Responsif (2 Kolom di HP)
                      if (_showStats) ...[
                        GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio:
                              1.1, // Mengatur rasio kotak biar pas
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
                              'Rp ${(stats['totalPenjualan'] / 1000).toStringAsFixed(0)}K', // Diubah ke Kilo (Ribu) atau sesuaikan kebutuhan display nilainya
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
                        const SizedBox(height: 24),
                      ],

                      // 3. Recent Transactions Section
                      if (_showRecentTransactions) ...[
                        const Text(
                          'Transaksi Terbaru',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
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
                                                    fontSize: 13,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Pembeli: ${transaction['pembeli']}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Rp ${transaction['total']}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.pink,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Tanggal: ${transaction['tanggal']}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
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
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getStatusColor(
                                                      transaction['status'] ??
                                                          '',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.info_outline,
                                                  size: 20,
                                                  color: Colors.grey,
                                                ),
                                                onPressed: () {
                                                  _showDetailDialog(
                                                    context,
                                                    transaction,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
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

  // Metode pembantu untuk memisahkan Dialog kode agar build utama lebih bersih
  void _showDetailDialog(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          transaction['id'] ?? '',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pembeli: ${transaction['pembeli']}'),
            const SizedBox(height: 8),
            Text('Items: ${transaction['items']}'),
            const SizedBox(height: 8),
            Text('Total: Rp ${transaction['total']}'),
            const SizedBox(height: 8),
            Text('Status: ${transaction['status']}'),
            const SizedBox(height: 8),
            Text('Tanggal: ${transaction['tanggal']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          FittedBox(
            // Supaya teks angka otomatis mengecil jika terlalu panjang
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
