import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/transaction_service.dart';
import '../../widgets/admin_layout.dart';
import '../../services/database_helper.dart';

class KelolaPesanan extends StatefulWidget {
  const KelolaPesanan({super.key});

  @override
  State<KelolaPesanan> createState() => _KelolaPesananState();
}

class _KelolaPesananState extends State<KelolaPesanan> {
  final TransactionService _transactionService = TransactionService();
  String selectedStatus = 'semua';
  String selectedType = 'semua';

  @override
  void initState() {
    super.initState();
    _transactionService.refreshTransactions();
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'diproses':
      case 'menunggu_verifikasi_admin':
        return Colors.orange;
      case 'menunggu':
      case 'menunggu_pembayaran':
      case 'menunggu_harga_admin':
        return Colors.blue;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String? status) {
    if (status == null) return '';
    switch (status) {
      case 'menunggu_harga_admin': return 'Menunggu Harga';
      case 'menunggu_pembayaran': return 'Menunggu Pembayaran';
      case 'menunggu_verifikasi_admin': return 'Menunggu Verifikasi';
      default: return status.toUpperCase();
    }
  }

  void _setHargaCustom(Map<String, dynamic> transaction) {
    final TextEditingController _hargaController = TextEditingController(text: transaction['total'].toString());
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Harga Final Custom Bouquet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${transaction['id']}'),
            const SizedBox(height: 8),
            Text('Catatan:\n${transaction['catatanCustom'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _hargaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga Final (Rp)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final hargaStr = _hargaController.text;
              if (hargaStr.isEmpty) return;
              final double? newHarga = double.tryParse(hargaStr);
              if (newHarga == null) return;

              Navigator.pop(ctx);
              try {
                // Update harga and status to menunggu_pembayaran
                final db = await DatabaseHelper.instance.database;
                await db.update(
                  'transactions',
                  {
                    'totalSebelomDiskon': newHarga,
                    'totalSetelahDiskon': newHarga,
                    'status': 'menunggu_pembayaran',
                  },
                  where: 'id = ?',
                  whereArgs: [transaction['id']],
                );
                await _transactionService.refreshTransactions();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Harga final diset dan menunggu pembayaran'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String transactionId, String newStatus) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'transactions',
        {'status': newStatus},
        where: 'id = ?',
        whereArgs: [transactionId],
      );
      await _transactionService.refreshTransactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status pesanan berhasil diperbarui'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _hubungiWhatsApp(Map<String, dynamic> transaction) async {
    String phone = '';
    
    // Coba ambil dari catatan custom dulu
    final catatan = transaction['catatanCustom'] ?? '';
    final RegExp phoneRegex = RegExp(r'No HP:\s*([0-9\+]+)');
    final match = phoneRegex.firstMatch(catatan);
    
    if (match != null && match.groupCount >= 1) {
      phone = match.group(1)!;
    } else {
      // Jika tidak ada di catatan custom, ambil dari database users
      try {
        final db = await DatabaseHelper.instance.database;
        final userId = transaction['pembeli'];
        final userResult = await db.query('users', where: 'id = ?', whereArgs: [userId]);
        if (userResult.isNotEmpty) {
          phone = (userResult.first['noTelepon'] ?? '').toString();
        }
      } catch (e) {
        // Abaikan error DB
      }
    }
    
    if (phone.isNotEmpty) {
      if (phone.startsWith('0')) {
        phone = '62${phone.substring(1)}';
      }
      final Uri url = Uri.parse('https://wa.me/$phone?text=Halo,%20saya%20admin%20Flowries%20Bouquet%20terkait%20pesanan%20Anda%20dengan%20ID%20${transaction['id']}.');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka WhatsApp')));
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor HP tidak ditemukan')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Kelola Pesanan',
      selectedIndex: 3,
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
                  'menunggu_harga_admin',
                  'menunggu_pembayaran',
                  'menunggu_verifikasi_admin',
                  'diproses'
                ].map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(
                        _formatStatus(status),
                        style: TextStyle(
                          color: selectedStatus == status ? Colors.white : Colors.black87,
                          fontWeight: selectedStatus == status ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: selectedStatus == status,
                      selectedColor: Colors.pink,
                      checkmarkColor: Colors.white,
                      onSelected: (selected) => setState(() => selectedStatus = status),
                    ),
                  ),
                ).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['semua', 'katalog', 'custom'].map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(
                        type == 'semua' ? 'Semua Tipe' : type.toUpperCase(),
                        style: TextStyle(
                          color: selectedType == type ? Colors.white : Colors.black87,
                          fontWeight: selectedType == type ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: selectedType == type,
                      selectedColor: Colors.purple,
                      onSelected: (selected) => setState(() => selectedType = type),
                    ),
                  ),
                ).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _transactionService.transactionsNotifier,
              builder: (context, allTransactions, _) {
                var filteredTransactions = selectedStatus == 'semua'
                    ? allTransactions
                    : allTransactions.where((t) => t['status'] == selectedStatus).toList();

                if (selectedType != 'semua') {
                  filteredTransactions = filteredTransactions.where((t) => t['tipePesanan'] == selectedType).toList();
                }

                if (filteredTransactions.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada pesanan',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    final isCustom = transaction['tipePesanan'] == 'custom';
                    final status = transaction['status'];

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ID: ${transaction['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                child: Text(_formatStatus(status), style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(isCustom ? Icons.brush : Icons.local_florist, color: Colors.pink, size: 20),
                              const SizedBox(width: 8),
                              Text(isCustom ? 'Custom Bouquet' : 'Katalog Bouquet', style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (isCustom && transaction['catatanCustom'] != null)
                            Expanded(
                              child: Text(
                                transaction['catatanCustom'],
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 3,
                              ),
                            )
                          else
                            Expanded(
                              child: Text(
                                transaction['items'] ?? '',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 3,
                              ),
                            ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Rp ${transaction['total']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink, fontSize: 16)),
                                Row(
                                  children: [
                                      IconButton(
                                        icon: const Icon(Icons.chat, color: Colors.green),
                                        tooltip: 'Hubungi WhatsApp',
                                        onPressed: () => _hubungiWhatsApp(transaction),
                                      ),
                                    if (status == 'menunggu_harga_admin')
                                      ElevatedButton(
                                        onPressed: () => _setHargaCustom(transaction),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                        child: const Text('Set Harga'),
                                      )
                                    else if (status == 'menunggu_verifikasi_admin')
                                      ElevatedButton(
                                        onPressed: () => _updateStatus(transaction['id'].toString(), 'diproses'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                        child: const Text('Verifikasi'),
                                      )
                                    else if (status == 'diproses')
                                      ElevatedButton(
                                        onPressed: () => _updateStatus(transaction['id'].toString(), 'selesai'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                        child: const Text('Selesaikan'),
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
