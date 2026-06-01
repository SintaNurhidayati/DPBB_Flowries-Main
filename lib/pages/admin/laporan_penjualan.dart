import 'package:flutter/material.dart';
import '../../services/transaction_service.dart';
import '../../widgets/admin_layout.dart';

class LaporanPenjualan extends StatefulWidget {
  const LaporanPenjualan({super.key});

  @override
  State<LaporanPenjualan> createState() => _LaporanPenjualanState();
}

class _LaporanPenjualanState extends State<LaporanPenjualan> {
  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _transactionService.refreshTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Laporan Penjualan',
      selectedIndex: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _transactionService.transactionsNotifier,
              builder: (context, allTransactions, _) {
                final completedTransactions = allTransactions
                    .where((t) => t['status']?.toString().toLowerCase() == 'selesai')
                    .toList();

                final totalRevenue = completedTransactions.fold<double>(
                  0.0,
                  (sum, t) => sum + ((t['total'] ?? 0) as num).toDouble(),
                );

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.pink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Pendapatan (Transaksi Selesai)',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rp ${totalRevenue.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Rincian Transaksi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: completedTransactions.isEmpty
                            ? const Center(child: Text('Belum ada transaksi selesai'))
                            : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(Colors.pink.shade50),
                                    columns: const [
                                      DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Pembeli', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: completedTransactions.map((t) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(t['id'].toString())),
                                          DataCell(Text(t['tanggal'].toString())),
                                          DataCell(Text(t['pembeli'].toString())),
                                          DataCell(Text('Rp ${t['total']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
