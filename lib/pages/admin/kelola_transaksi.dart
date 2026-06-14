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
      case 'menunggu_verifikasi_admin':
        return Colors.orange;
      case 'menunggu':
      case 'menunggu_pembayaran':
        return Colors.blue;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu_verifikasi_admin':
        return 'MENUNGGU VERIFIKASI';
      case 'menunggu_pembayaran':
        return 'MENUNGGU PEMBAYARAN';
      default:
        return status.toUpperCase();
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
          // Filter Chips Status
          Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'semua',
                  'menunggu',
                  'menunggu_verifikasi_admin',
                  'diproses',
                  'selesai',
                  'dibatalkan'
                ].map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(
                        _formatStatusText(status),
                        style: TextStyle(
                          color: selectedStatus == status
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: selectedStatus == status
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
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
          
          // Daftar Grid Transaksi
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
                    crossAxisCount: 2,
                    childAspectRatio: 0.95, // Rasio diperkecil agar card memanjang ke bawah dan memberikan ruang tombol
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    final currentStatus = (transaction['status'] ?? '').toString();

                    return Container(
                      padding: const EdgeInsets.all(16),
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
                          // Bagian Atas: ID & Label Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'ID: ${transaction['id']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(currentStatus).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _formatStatusText(currentStatus),
                                  style: TextStyle(
                                    color: _getStatusColor(currentStatus),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Detail Item & Alamat
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction['items'] ?? '',
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Alamat: ${transaction['alamat'] ?? '-'}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Bukti Pembayaran jika ada
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
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.image, size: 14, color: Colors.blue.shade700),
                                    const SizedBox(width: 4),
                                    Text('Lihat Bukti', style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          
                          const Divider(height: 20),
                          
                          // Bagian Bawah: Harga, Tanggal, dan Tombol Aksi
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
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      transaction['tanggal'] ?? 'N/A',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // Susunan Tombol secara Vertikal agar hemat ruang kesamping
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (currentStatus == 'menunggu_verifikasi_admin' || currentStatus == 'menunggu')
                                    SizedBox(
                                      height: 28,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _updateStatus(transaction, 'diproses'),
                                        icon: Icon(currentStatus == 'menunggu_verifikasi_admin' ? Icons.verified : Icons.sync, size: 12),
                                        label: Text(currentStatus == 'menunggu_verifikasi_admin' ? 'Konfirmasi' : 'Proses', style: const TextStyle(fontSize: 10)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                      ),
                                    ),
                                  if (currentStatus == 'diproses')
                                    SizedBox(
                                      height: 28,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _updateStatus(transaction, 'selesai'),
                                        icon: const Icon(Icons.check, size: 12),
                                        label: const Text('Selesai', style: TextStyle(fontSize: 10)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                      ),
                                    ),
                                  if (currentStatus != 'selesai' && currentStatus != 'dibatalkan') ...[
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 24,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _cancelTransaction(transaction),
                                        icon: const Icon(Icons.close, size: 10),
                                        label: const Text('Batal', style: TextStyle(fontSize: 9)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                      ),
                                    ),
                                  ],
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