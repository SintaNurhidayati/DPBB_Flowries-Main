import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/transaction_service.dart';
import '../../services/session_preferences.dart';
import 'payment_success_page.dart';

class PaymentScreen extends StatefulWidget {
  final String? transactionId;
  final bool isPaymentOnly;
  final double total;
  final List<dynamic> items;

  const PaymentScreen({
    super.key,
    this.transactionId,
    this.isPaymentOnly = false,
    this.total = 0.0,
    this.items = const [],
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TransactionService _transactionService = TransactionService();
  final SessionPreferences _session = SessionPreferences();
  String? _transactionId;
  double _total = 0.0;
  bool _initialized = false;

  String? _buktiPembayaranBase64;
  final ImagePicker _picker = ImagePicker();

  String _selectedMethod = 'Transfer Bank BCA';

  final Map<String, Map<String, dynamic>> _paymentMethods = {
    'Transfer Bank BCA': {
      'name': 'BCA Virtual Account',
      'icon': Icons.account_balance,
      'instructions': '1. Buka aplikasi m-BCA\n2. Pilih m-Transfer > BCA Virtual Account\n3. Masukkan nomor VA: 8077708123456789\n4. Masukkan nominal transfer\n5. Simpan resi sebagai bukti',
    },
    'Transfer Bank Mandiri': {
      'name': 'Mandiri Virtual Account',
      'icon': Icons.account_balance_wallet,
      'instructions': '1. Buka aplikasi Livin\' by Mandiri\n2. Pilih Bayar > E-Commerce\n3. Masukkan nomor VA: 896508123456789\n4. Masukkan nominal transfer\n5. Simpan resi sebagai bukti',
    },
    'E-Wallet GoPay': {
      'name': 'GoPay',
      'icon': Icons.phone_android,
      'instructions': '1. Buka aplikasi Gojek\n2. Pilih Bayar\n3. Scan QR Code yang akan muncul setelah ini atau masukkan nomor: 081234567890\n4. Simpan screenshot sebagai bukti',
    },
    'E-Wallet OVO': {
      'name': 'OVO',
      'icon': Icons.payment,
      'instructions': '1. Buka aplikasi OVO\n2. Pilih Transfer > Ke Sesama OVO\n3. Masukkan nomor: 081234567890\n4. Masukkan nominal transfer\n5. Simpan screenshot sebagai bukti',
    },
  };

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.transactionId != null) {
      _transactionId = widget.transactionId;
      _total = widget.total;
      _initialized = true;
    }
    _loadSavedPaymentMethod();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _transactionId = args['transactionId']?.toString();
        _total = (args['total'] as num?)?.toDouble() ?? 0.0;
      }
      _initialized = true;
    }
  }

  Future<void> _loadSavedPaymentMethod() async {
    final savedMethod = await _session.getSelectedPaymentMethod();
    if (_paymentMethods.containsKey(savedMethod)) {
      setState(() {
        _selectedMethod = savedMethod;
      });
    }
  }

  Future<void> _savePaymentMethod() async {
    await _session.saveSelectedPaymentMethod(_selectedMethod);
  }

  Future<bool> _onWillPop() async {
    // Tampilkan dialog konfirmasi
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pembayaran?'),
        content: const Text(
          'Apakah ingin membatalkan pembayaran? \n\n'
          'Anda dapat melanjutkan pembayaran nanti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Lanjutkan Bayar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      Navigator.pushReplacementNamed(context, '/riwayat');
      return false;
    }
    return false; 
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // menampilkan dialog konfirmasi
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Batalkan Pembayaran?'),
                  content: const Text(
                     'Apakah ingin membatalkan pembayaran? \n\n'
                      'Anda dapat melanjutkan pembayaran nanti.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Lanjutkan Bayar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Ya, Batalkan'),
                    ),
                  ],
                ),
              );
              
              if (result == true && mounted) {
                Navigator.pushReplacementNamed(context, '/riwayat');
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Pembayaran
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('💵 Total Tagihan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Rp ${_total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.pink)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Metode Pembayaran
              const Text('Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._paymentMethods.entries.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                ),
                child: RadioListTile<String>(
                  value: entry.key,
                  groupValue: _selectedMethod,
                  onChanged: (value) {
                    setState(() => _selectedMethod = value!);
                    _savePaymentMethod();
                  },
                  title: Text(entry.value['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.pink.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(entry.value['icon'], color: Colors.pink, size: 24),
                  ),
                  activeColor: Colors.pink,
                ),
              )),
              const SizedBox(height: 24),

              // Instruksi Pembayaran
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.pink.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.pink),
                      const SizedBox(width: 8),
                      Text('Instruksi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.pink))
                    ]),
                    const SizedBox(height: 12),
                    Text(_paymentMethods[_selectedMethod]!['instructions'], style: const TextStyle(height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Upload Bukti Pembayaran
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📸 Upload Bukti Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Upload foto bukti transfer Anda', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                        if (pickedFile != null) {
                          final bytes = await pickedFile.readAsBytes();
                          setState(() => _buktiPembayaranBase64 = base64Encode(bytes));
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _buktiPembayaranBase64 != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(base64Decode(_buktiPembayaranBase64!), fit: BoxFit.cover, width: double.infinity),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload, size: 50, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text('Tap to upload', style: TextStyle(color: Colors.grey.shade500)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Tombol Kirim
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () async {
                    if (_buktiPembayaranBase64 == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan upload bukti pembayaran')));
                      return;
                    }
                    
                    if (_transactionId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID Transaksi tidak valid')));
                      return;
                    }

                    setState(() => _isProcessing = true);
                    try {
                      await _savePaymentMethod();
                      await _transactionService.updateTransactionPaymentProof(_transactionId!, _buktiPembayaranBase64!);
                      
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentSuccessPage(),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        // 🔥 GAGAL UPLOAD: TETAP KE RIWAYAT (status masih menunggu)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal upload: $e. Silakan coba lagi nanti.')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isProcessing = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Selesaikan Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 🔥 TOMBOL BATAL (Opsional)
              TextButton(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Batalkan Pembayaran?'),
                      content: const Text(
                        'Apakah ingin membatalkan pembayaran? \n\n'
                        'Anda dapat melanjutkan pembayaran nanti.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Lanjutkan Bayar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Ya, Batalkan'),
                        ),
                      ],
                    ),
                  );
                  
                  if (result == true && mounted) {
                    Navigator.pushReplacementNamed(context, '/riwayat');
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Batalkan Pembayaran'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}