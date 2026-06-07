import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/transaction_service.dart';
import '../../services/database_helper.dart';
import '../../services/session_preferences.dart';
import '../../widgets/cart_badge_icon.dart';
import '../../widgets/custom_navbar.dart';

class CustomOrderPage extends StatefulWidget {
  const CustomOrderPage({super.key});

  @override
  State<CustomOrderPage> createState() => _CustomOrderPageState();
}

class _CustomOrderPageState extends State<CustomOrderPage> {
  int _currentNavIndex = 2;
  
  final SessionPreferences _sessionPrefs = SessionPreferences();
  String? _currentUserId;

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
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/riwayat');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profil-pembeli');
        break;
    }
  }

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _selectedFlowers = [];
  String _selectedWrapping = 'Kraft Paper';
  String _selectedSize = 'Medium';

  String? _referenceImageBase64;
  final ImagePicker _picker = ImagePicker();

  // Data default
  final List<Map<String, dynamic>> _defaultFlowers = [
    {'name': 'Roses', 'image': 'assets/images/flower_rose.png', 'price': 50000, 'isDefault': true},
    {'name': 'Sunflowers', 'image': 'assets/images/flower_sunflower.png', 'price': 45000, 'isDefault': true},
    {'name': 'Lilies', 'image': 'assets/images/flower_lily.png', 'price': 60000, 'isDefault': true},
    {'name': 'Tulips', 'image': 'assets/images/flower_tulip.png', 'price': 55000, 'isDefault': true},
    {'name': 'Peonies', 'image': 'assets/images/flower_peony.png', 'price': 75000, 'isDefault': true},
    {'name': 'Hydrangeas', 'image': 'assets/images/flower_hydrangea.png', 'price': 65000, 'isDefault': true},
  ];

  final List<Map<String, dynamic>> _defaultWrappings = [
    {'name': 'Kraft Paper', 'image': 'assets/images/wrapping_kraft.png', 'price': 15000, 'isDefault': true},
    {'name': 'Pine Sticks', 'image': 'assets/images/wrapping_pine.png', 'price': 20000, 'isDefault': true},
    {'name': 'Papers', 'image': 'assets/images/wrapping_papers.png', 'price': 25000, 'isDefault': true},
    {'name': 'Polkadot', 'image': 'assets/images/wrapping_polkadot.png', 'price': 18000, 'isDefault': true},
    {'name': 'Burlap', 'image': 'assets/images/wrapping_burlap.png', 'price': 12000, 'isDefault': true},
  ];

  final List<Map<String, dynamic>> _defaultSizes = [
    {'name': 'Small', 'price': 0, 'desc': '15-20 stems', 'isDefault': true},
    {'name': 'Medium', 'price': 50000, 'desc': '25-30 stems', 'isDefault': true},
    {'name': 'Large', 'price': 100000, 'desc': '35-40 stems', 'isDefault': true},
  ];

  List<Map<String, dynamic>> _dbFlowers = [];
  List<Map<String, dynamic>> _dbWrappings = [];
  List<Map<String, dynamic>> _dbSizes = [];

  List<Map<String, dynamic>> _allFlowers = [];
  List<Map<String, dynamic>> _allWrappings = [];
  List<Map<String, dynamic>> _allSizes = [];

  bool _isLoading = true;
  final double _imageSize = 50;

  double get _flowersTotalPrice {
    double total = 0;
    for (var flower in _selectedFlowers) {
      total += (flower['price'] as num).toDouble();
    }
    return total;
  }

  double get _wrappingPrice {
    final wrapping = _allWrappings.firstWhere(
      (w) => w['name'] == _selectedWrapping,
    );
    return (wrapping['price'] as num).toDouble();
  }

  double get _sizePrice {
    final size = _allSizes.firstWhere((s) => s['name'] == _selectedSize);
    return size['price'].toDouble();
  }

  double get _estimatedPrice {
    return _flowersTotalPrice + _wrappingPrice + _sizePrice;
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadDataFromDatabase();
  }

  Future<void> _loadCurrentUser() async {
    _currentUserId = await _sessionPrefs.getUserId();
    print('🔍 CustomOrder - Current User ID: $_currentUserId');
  }

  Future<void> _loadDataFromDatabase() async {
    setState(() => _isLoading = true);

    try {
      _dbFlowers = await DatabaseHelper.instance.getCustomFlowers();
      _dbWrappings = await DatabaseHelper.instance.getCustomWrappings();
      _dbSizes = await DatabaseHelper.instance.getCustomSizes();

      _allFlowers = [
        ..._defaultFlowers,
        ..._dbFlowers.map((f) => {
          'name': f['name'],
          'price': f['price'],
          'image': f['image_url'] != null && f['image_url'].toString().isNotEmpty
              ? f['image_url']
              : 'assets/images/flower_rose.png',
          'isDefault': false,
        }),
      ];

      _allWrappings = [
        ..._defaultWrappings,
        ..._dbWrappings.map((w) => {
          'name': w['name'],
          'price': w['price'],
          'image': w['image_url'] != null && w['image_url'].toString().isNotEmpty
              ? w['image_url']
              : 'assets/images/wrapping_kraft.png',
          'isDefault': false,
        }),
      ];

      _allSizes = [
        ..._defaultSizes,
        ..._dbSizes.map((s) => {
          'name': s['name'],
          'price': s['price'],
          'desc': s['description'] ?? '',
          'isDefault': false,
        }),
      ];
    } catch (e) {
      print('Error loading data: $e');
      _allFlowers = List.from(_defaultFlowers);
      _allWrappings = List.from(_defaultWrappings);
      _allSizes = List.from(_defaultSizes);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleFlowerSelection(Map<String, dynamic> flower) {
    setState(() {
      final isSelected = _selectedFlowers.any((f) => f['name'] == flower['name']);
      if (isSelected) {
        _selectedFlowers.removeWhere((f) => f['name'] == flower['name']);
      } else {
        if (_selectedFlowers.length < 3) {
          _selectedFlowers.add(flower);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maksimal memilih 3 jenis bunga')),
          );
        }
      }
    });
  }

  bool _isFlowerSelected(Map<String, dynamic> flower) {
    return _selectedFlowers.any((f) => f['name'] == flower['name']);
  }

  Widget _buildImageWidget(String imagePath, IconData defaultIcon, Color primaryColor) {
    if (imagePath.startsWith('/9j/') ||
        imagePath.startsWith('iVBOR') ||
        (imagePath.length > 100 && !imagePath.contains('assets/'))) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(imagePath),
            width: _imageSize,
            height: _imageSize,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(defaultIcon, size: _imageSize - 15, color: primaryColor),
          ),
        );
      } catch (e) {
        return Icon(defaultIcon, size: _imageSize - 15, color: primaryColor);
      }
    }

    return Image.asset(
      imagePath,
      width: _imageSize,
      height: _imageSize,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(defaultIcon, size: _imageSize - 15, color: primaryColor),
    );
  }

  Future<void> _pickReferenceImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Upload Referensi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (pickedFile != null) {
                  final bytes = await pickedFile.readAsBytes();
                  setState(() => _referenceImageBase64 = base64Encode(bytes));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (pickedFile != null) {
                  final bytes = await pickedFile.readAsBytes();
                  setState(() => _referenceImageBase64 = base64Encode(bytes));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (_selectedFlowers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 jenis bunga')),
      );
      return;
    }
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi nama lengkap')),
      );
      return;
    }
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi nomor telepon')),
      );
      return;
    }
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi alamat')),
      );
      return;
    }

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final flowersText = _selectedFlowers
          .map((f) => '- ${f['name']} (Rp ${f['price']})')
          .join('\n');
      final customDescription = '''
Bunga yang dipilih (${_selectedFlowers.length} jenis):
$flowersText

Kemasan: $_selectedWrapping
Ukuran: $_selectedSize
Nama Pemesan: ${_nameController.text}
No HP: ${_phoneController.text}
Catatan Tambahan: ${_notesController.text}
      ''';

      final transactionId = 'CUSTOM${DateTime.now().millisecondsSinceEpoch}';

      await TransactionService().addTransaction({
        'id': transactionId,
        'items': '1x Custom Bouquet ($_selectedSize)',
        'pembeli': _currentUserId,
        'itemsArray': [
          {
            'id': 'CUSTOM_${DateTime.now().millisecondsSinceEpoch}',
            'nama': 'Custom Bouquet ($_selectedSize)',
            'harga': _estimatedPrice,
            'quantity': 1,
          },
        ],
        'total': _estimatedPrice,
        'diskon': 0.0,
        'voucher': '',
        'status': 'menunggu_harga_admin',
        'metode': 'Belum Dipilih',
        'alamat': _addressController.text,
        'buktiPembayaran': _referenceImageBase64,
        'tipePesanan': 'custom',
        'catatanCustom': customDescription,
        'tanggalPemesanan': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      await TransactionService().refreshTransactions();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permintaan custom bouquet berhasil dikirim! Menunggu konfirmasi admin.'),
          backgroundColor: Colors.green,
        ),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/riwayat');
      }
    } catch (e) {
      print('❌ Error submitting custom order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('Custom Bouquet', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          centerTitle: true,
          actions: const [CartBadgeIcon()],
        ),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: CustomNavBar(
          currentIndex: _currentNavIndex,
          onIndexChanged: _handleNavigation,
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Custom Bouquet', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
        actions: const [CartBadgeIcon()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.brush, color: primaryColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✨ Custom Bouquet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Pilih maksimal 3 jenis bunga. Admin akan mengkonfirmasi harga final sebelum pembayaran.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Pilih Bunga - Wrap
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🌸 Pilih Bunga (Maks 3)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text('${_selectedFlowers.length}/3', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 🔥 FIX OVERFLOW: Gunakan Container dengan height dan width terbatas
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _allFlowers.length,
                      itemBuilder: (context, index) {
                        final flower = _allFlowers[index];
                        final isSelected = _isFlowerSelected(flower);
                        return GestureDetector(
                          onTap: () => _toggleFlowerSelection(flower),
                          child: Container(
                            width: 85,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor.withOpacity(0.1) : surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200, width: isSelected ? 2 : 1),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildImageWidget(flower['image'], Icons.local_florist, primaryColor),
                                const SizedBox(height: 4),
                                Text(
                                  flower['name'],
                                  style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Rp ${flower['price']}',
                                  style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
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

              if (_selectedFlowers.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bunga yang dipilih:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      ..._selectedFlowers.map((flower) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('• ${flower['name']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                            Text('Rp ${flower['price']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )),
                      const Divider(height: 12, thickness: 0.5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Bunga', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('Rp ${_flowersTotalPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Pilih Kemasan
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📦 Pilih Kemasan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _allWrappings.length,
                      itemBuilder: (context, index) {
                        final wrapping = _allWrappings[index];
                        final isSelected = _selectedWrapping == wrapping['name'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedWrapping = wrapping['name']),
                          child: Container(
                            width: 85,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor.withOpacity(0.1) : surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200, width: isSelected ? 2 : 1),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildImageWidget(wrapping['image'], Icons.shopping_bag, primaryColor),
                                const SizedBox(height: 4),
                                Text(
                                  wrapping['name'],
                                  style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Rp ${wrapping['price']}',
                                  style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
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
              const SizedBox(height: 20),

              // Pilih Ukuran - Wrap
              const Text('📏 Pilih Ukuran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allSizes.map((size) {
                  final isSelected = _selectedSize == size['name'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSize = size['name']),
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 48) / 3, // 🔥 RESPONSIVE WIDTH
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(size['name'], style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(size['desc'], style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey.shade500)),
                          Text('+Rp ${size['price']}', style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : primaryColor)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Estimasi Harga
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimasi Harga', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        Text('Rp ${_estimatedPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Harga final akan dikonfirmasi oleh admin setelah desain selesai',
                              style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form Informasi Pribadi
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📋 Informasi Pribadi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: backgroundColor,
                        prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: backgroundColor,
                        prefixIcon: Icon(Icons.phone_outlined, color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Alamat',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: backgroundColor,
                        prefixIcon: Icon(Icons.location_on_outlined, color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        hintText: 'Tambahkan catatan untuk pesanan custom Anda',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: backgroundColor,
                        prefixIcon: Icon(Icons.note_outlined, color: primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Upload Referensi
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🖼️ Upload Referensi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Upload gambar referensi untuk inspirasi (opsional)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickReferenceImage,
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _referenceImageBase64 != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(base64Decode(_referenceImageBase64!), fit: BoxFit.cover, width: double.infinity),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload, size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text('Tap to upload image', style: TextStyle(color: Colors.grey.shade500)),
                                  Text('JPEG, PNG up to 10MB', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Kirim Permintaan Custom', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentNavIndex,
        onIndexChanged: _handleNavigation,
      ),
    );
  }
}