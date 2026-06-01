import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/transaction_service.dart';
import '../../widgets/admin_layout.dart';

class KelolaTransaksi extends StatefulWidget {
  const KelolaTransaksi({super.key});

  @override
  State<KelolaTransaksi> createState() => _KelolaTransaksiState();
}

class _KelolaTransaksiState extends State<KelolaTransaksi> {
  final TransactionService _transactionService = TransactionService();
  String selectedStatus = 'semua';

  @override
  void initState() {
    super.initState();
    _transactionService.refreshTransactions();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'diproses':
        return Colors.orange;
      case 'menunggu':
        return Colors.blue;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _updateStatus(Map<String, dynamic> transaction, String newStatus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Status Transaksi'),
        content: Text(
          'Ubah status dari "${transaction['status']}" menjadi "$newStatus"?\n\nID: ${transaction['id']}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _transactionService.updateTransactionStatus(
                  transaction['id'],
                  newStatus,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Status diubah menjadi $newStatus'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Ubah Status'),
          ),
        ],
      ),
    );
  }

  void _cancelTransaction(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Batalkan Transaksi'),
        content: Text(
          'Yakin batalkan transaksi ini?\n\nID: ${transaction['id']}\nTotal: Rp ${transaction['total']}\n\nAksi ini tidak bisa dibatalkan!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _transactionService.updateTransactionStatus(
                  transaction['id'],
                  'dibatalkan',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Transaksi dibatalkan'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Kelola Transaksi',
      selectedIndex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'semua',
                  'menunggu',
                  'diproses',
                  'selesai',
                  'dibatalkan'
                ].map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: selectedStatus == status
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: selectedStatus == status
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: selectedStatus == status,
                      selectedColor: Colors.pink,
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setState(() {
                          selectedStatus = status;
                        });
                      },
                    ),
                  ),
                ).toList(),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _transactionService.transactionsNotifier,
              builder: (context, allTransactions, _) {
                final filteredTransactions = selectedStatus == 'semua'
                    ? allTransactions
                    : allTransactions
                        .where((t) => t['status'] == selectedStatus)
                        .toList();

                if (filteredTransactions.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada transaksi',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Desktop 2 columns for transactions
                    childAspectRatio: 1.7, // Lower ratio for more vertical space
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ID: ${transaction['id']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    transaction['status'] ?? '',
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (transaction['status'] ?? '').toString().toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(transaction['status'] ?? ''),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction['items'] ?? '',
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: Text(
                                    'Alamat: ${transaction['alamat'] ?? '-'}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (transaction['buktiPembayaran'] != null && transaction['buktiPembayaran'] != '')
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Bukti Pembayaran'),
                                    content: Image.memory(
                                      base64Decode(transaction['buktiPembayaran']),
                                      fit: BoxFit.contain,
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.shade200)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.image, size: 16, color: Colors.blue.shade700),
                                    const SizedBox(width: 4),
                                    Text('Lihat Bukti', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rp ${transaction['total']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.pink,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      transaction['tanggal'] ?? 'N/A',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                                Row(
                                  children: [
                                    if (transaction['status'] == 'menunggu_verifikasi_admin')
                                      ElevatedButton.icon(
                                        onPressed: () => _updateStatus(transaction, 'diproses'),
                                        icon: const Icon(Icons.verified, size: 16),
                                        label: const Text('Konfirmasi'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                      ),
                                    if (transaction['status'] == 'menunggu')
                                      ElevatedButton.icon(
                                        onPressed: () => _updateStatus(transaction, 'diproses'),
                                        icon: const Icon(Icons.sync, size: 16),
                                        label: const Text('Proses'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                      ),
                                  if (transaction['status'] == 'diproses')
                                    ElevatedButton.icon(
                                      onPressed: () => _updateStatus(transaction, 'selesai'),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Selesai'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                    ),
                                  if (transaction['status'] != 'selesai' && transaction['status'] != 'dibatalkan')
                                    const SizedBox(width: 8),
                                  if (transaction['status'] != 'selesai' && transaction['status'] != 'dibatalkan')
                                    ElevatedButton.icon(
                                      onPressed: () => _cancelTransaction(transaction),
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text('Batal'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
