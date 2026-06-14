import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../services/transaction_service.dart';
import 'payment_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final int userId;

  const TransactionHistoryScreen({super.key, required this.userId});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final ts = TransactionService();
      await ts.refreshTransactions();
      final allTrx = ts.transactions;
      List<Map<String, dynamic>> transactions = [];

      for (var trx in allTrx) {
        // filter by user ID
        if (trx['pembeli'] == widget.userId || trx['pembeli'] == widget.userId.toString()) {
          String rawStatus = trx['status'] ?? 'menunggu';
          String status = 'pending';
          
          if (rawStatus == 'selesai' || rawStatus == 'dikirim' || rawStatus == 'diproses') {
            status = 'success';
          } else if (rawStatus == 'dibatalkan') {
            status = 'failed';
          }
          
          if (_filter != 'all' && status != _filter) continue;

          transactions.add({
            'order_id': trx['id'],
            'amount': trx['total'],
            'status': status,
            'payment_method': trx['metode'],
            'payment_date': trx['tanggal'],
            'address': trx['alamat'],
            'order_status': rawStatus,
            'payment_proof': null,
          });
        }
      }

      transactions.sort((a, b) {
        final dateA = a['payment_date'] ?? '';
        final dateB = b['payment_date'] ?? '';
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading transactions: $e');
      if (mounted) {
        setState(() {
          _transactions = [];
          _isLoading = false;
        });
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'success':
        return 'Berhasil';
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'failed':
        return 'Gagal';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Tanggal tidak tersedia';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString.substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTabButton(
                  'Semua',
                  _filter == 'all',
                  () => setState(() {
                    _filter = 'all';
                    _loadTransactions();
                  }),
                  primaryColor,
                ),
                _buildTabButton(
                  'Berhasil',
                  _filter == 'success',
                  () => setState(() {
                    _filter = 'success';
                    _loadTransactions();
                  }),
                  primaryColor,
                ),
                _buildTabButton(
                  'Menunggu',
                  _filter == 'pending',
                  () => setState(() {
                    _filter = 'pending';
                    _loadTransactions();
                  }),
                  primaryColor,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_outlined, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada riwayat transaksi',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yuk, selesaikan pembayaran pesanan Anda!',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      final status = transaction['status'] ?? 'pending';
                      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
                      final paymentMethod = transaction['payment_method'] ?? 'transfer';
                      final orderId = transaction['order_id'];
                      String methodText = paymentMethod == 'transfer'
                          ? 'Transfer Bank'
                          : (paymentMethod == 'ewallet' ? 'E-Wallet' : 'Transfer Bank');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          status == 'success'
                                              ? Icons.check_circle
                                              : (status == 'pending' ? Icons.access_time : Icons.error),
                                          color: _getStatusColor(status),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order #$orderId',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatDate(transaction['payment_date']),
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getStatusText(status),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Divider(color: Colors.grey.shade100),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Pembayaran',
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                  Text(
                                    'Rp ${amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Metode Pembayaran',
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                  Text(
                                    methodText,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (transaction['address'] != null)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Alamat Pengiriman',
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    Expanded(
                                      child: Text(
                                        transaction['address'],
                                        style: const TextStyle(fontSize: 12),
                                        textAlign: TextAlign.right,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                              // Bukti Pembayaran
                              if (transaction['payment_proof'] != null &&
                                  transaction['payment_proof'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Bukti Pembayaran:',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => Dialog(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Padding(
                                                    padding: EdgeInsets.all(16),
                                                    child: Text(
                                                      'Bukti Pembayaran',
                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  Container(
                                                    height: 400,
                                                    width: double.infinity,
                                                    child: Image.memory(
                                                      base64Decode(transaction['payment_proof']),
                                                      fit: BoxFit.contain,
                                                    ),
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
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.memory(
                                              base64Decode(transaction['payment_proof']),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    String title,
    bool isSelected,
    VoidCallback onTap,
    Color primaryColor,
  ) {
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
}