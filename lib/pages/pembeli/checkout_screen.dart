// lib/pages/pembeli/checkout_screen.dart
import 'package:flutter/material.dart';
import '../../services/transaction_service.dart';
import '../../services/session_preferences.dart';
import 'dart:math';

class CheckoutScreen extends StatefulWidget {
  final List<dynamic> items;
  final double total;
  final List<String> selectedIds;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.total,
    required this.selectedIds,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TransactionService _transactionService = TransactionService();
  final SessionPreferences _session = SessionPreferences();
  final TextEditingController _alamatController = TextEditingController();
  
  bool _isProcessing = false;

  Future<void> _buatPesanan() async {
    if (_alamatController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan alamat pengiriman')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    
    try {
      // ✅ AMBIL USER ID DARI SHAREDPREFERENCES
      final userId = await _session.getUserId();
      
      if (userId == null) {
        throw Exception('User tidak ditemukan, silakan login ulang');
      }

      final String transactionId = 'TRX${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(99)}';
      
      final Map<String, dynamic> transactionData = {
        'id': transactionId,
        'pembeli': userId,
        'itemsArray': widget.items,
        'total': widget.total,
        'status': 'menunggu_pembayaran',
        'alamat': _alamatController.text.trim(),
        'metode': 'transfer',
        'diskon': 0.0,
      };

      await _transactionService.addTransaction(transactionData);
      
      if (!mounted) return;
      
      await Navigator.pushReplacementNamed(
        context,
        '/pembayaran',
        arguments: {
          'transactionId': transactionId,
          'total': widget.total,
        },
      );
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Pesanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final price = ((item['harga'] ?? 0) as num).toDouble();
                final quantity = item['quantity'] as int? ?? 1;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_florist, color: Colors.pink),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['nama'] ?? 'Produk',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${quantity}x @ Rp ${price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rp ${(price * quantity).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.pink,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(thickness: 2),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Tagihan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rp ${widget.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Alamat Pengiriman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _alamatController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Masukkan alamat lengkap pengiriman...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _buatPesanan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Buat Pesanan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}