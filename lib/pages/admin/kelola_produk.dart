import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/product_service.dart';
import '../../services/database_helper.dart';
import '../../widgets/admin_layout.dart';
import 'tambah_produk_page.dart';
import 'admin_add_edit_custom_component.dart';
import '../../widgets/product_image.dart';

class KelolaProduk extends StatefulWidget {
  const KelolaProduk({super.key});

  @override
  State<KelolaProduk> createState() => _KelolaProdukState();
}

class _KelolaProdukState extends State<KelolaProduk> with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  late TabController _tabController;
  
  //Data default untuk komponen custom (TIDAK BISA DIHAPUS)
  final List<Map<String, dynamic>> _defaultFlowers = const [
    {'id': 1, 'name': 'Mawar Merah', 'price': 15000, 'image_url': 'assets/images/mawar_merah.png', 'isDefault': true},
    {'id': 2, 'name': 'Tulip Kuning', 'price': 12000, 'image_url': 'assets/images/tulip_kuning.png', 'isDefault': true},
    {'id': 3, 'name': 'Lily Putih', 'price': 18000, 'image_url': 'assets/images/lily_putih.png', 'isDefault': true},
    {'id': 4, 'name': 'Matahari', 'price': 10000, 'image_url': 'assets/images/matahari.png', 'isDefault': true},
    {'id': 5, 'name': 'Sakura Pink', 'price': 20000, 'image_url': 'assets/images/sakura_pink.png', 'isDefault': true},
  ];
  
  final List<Map<String, dynamic>> _defaultWrappings = const [
    {'id': 1, 'name': 'Kertas Kraft', 'price': 5000, 'image_url': 'assets/images/kraft.png', 'isDefault': true},
    {'id': 2, 'name': 'Kertas Mewah', 'price': 10000, 'image_url': 'assets/images/mewah.png', 'isDefault': true},
    {'id': 3, 'name': 'Kertas Bunga', 'price': 8000, 'image_url': 'assets/images/bunga.png', 'isDefault': true},
    {'id': 4, 'name': 'Kertas Polos', 'price': 3000, 'image_url': 'assets/images/polos.png', 'isDefault': true},
  ];
  
  final List<Map<String, dynamic>> _defaultSizes = const [
    {'id': 1, 'name': 'Small', 'price': 0, 'description': '10-15 batang', 'isDefault': true},
    {'id': 2, 'name': 'Medium', 'price': 25000, 'description': '20-25 batang', 'isDefault': true},
    {'id': 3, 'name': 'Large', 'price': 50000, 'description': '30-35 batang', 'isDefault': true},
  ];
  
  //Data dari database
  List<Map<String, dynamic>> _dbFlowers = [];
  List<Map<String, dynamic>> _dbWrappings = [];
  List<Map<String, dynamic>> _dbSizes = [];
  
  //Gabungan untuk ditampilkan
  List<Map<String, dynamic>> _displayFlowers = [];
  List<Map<String, dynamic>> _displayWrappings = [];
  List<Map<String, dynamic>> _displaySizes = [];
  
  List<Map<String, dynamic>> _catalogProducts = [];
  bool _isLoading = true;

  //SharedPreferences variables
  bool _canDisableProduct = false;
  bool _showLowStockWarning = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPreferences();
    _loadData();
    _tabController.addListener(() {
      setState(() {});
      if (!_tabController.indexIsChanging) _loadData();
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _canDisableProduct = prefs.getBool('allow_product_deactivation') ?? false;
      _showLowStockWarning = prefs.getBool('show_low_stock_warning') ?? true;
    });
  }

  Future<void> _toggleDisableProduct(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allow_product_deactivation', value);
    setState(() {
      _canDisableProduct = value;
    });
  }

  Future<void> _toggleLowStockWarning(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_low_stock_warning', value);
    setState(() {
      _showLowStockWarning = value;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (_tabController.index == 0) {
        _catalogProducts = await DatabaseHelper.instance.getAllProducts();
      } else {
        _dbFlowers = await DatabaseHelper.instance.getCustomFlowers();
        _dbWrappings = await DatabaseHelper.instance.getCustomWrappings();
        _dbSizes = await DatabaseHelper.instance.getCustomSizes();
        
        _displayFlowers = [..._defaultFlowers, ..._dbFlowers.map((f) => {...f, 'isDefault': false}).toList()];
        _displayWrappings = [..._defaultWrappings, ..._dbWrappings.map((w) => {...w, 'isDefault': false}).toList()];
        _displaySizes = [..._defaultSizes, ..._dbSizes.map((s) => {...s, 'isDefault': false}).toList()];
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleProductActive(Map<String, dynamic> product, bool currentStatus) async {
    final updatedProduct = Map<String, dynamic>.from(product);
    updatedProduct['isActive'] = currentStatus ? 0 : 1;
    await _productService.updateProduct(product['id'].toString(), updatedProduct);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Produk berhasil di${currentStatus ? "nonaktifkan" : "aktifkan"}'))
    );
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus "${product['nama']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Hapus')),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _productService.deleteProduct(product['id'].toString());
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk berhasil dihapus')));
    }
  }

  Future<void> _deleteCustomComponent(String type, int id, String name, bool isDefault) async {
    if (isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Komponen default tidak dapat dihapus!')));
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${_getTypeName(type)}'),
        content: Text('Apakah Anda yakin ingin menghapus "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Hapus')),
        ],
      ),
    );
    
    if (confirmed == true) {
      if (type == 'flower') await DatabaseHelper.instance.deleteCustomFlower(id);
      else if (type == 'wrapping') await DatabaseHelper.instance.deleteCustomWrapping(id);
      else if (type == 'size') await DatabaseHelper.instance.deleteCustomSize(id);
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_getTypeName(type)} berhasil dihapus')));
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'flower': return 'Bunga';
      case 'wrapping': return 'Kemasan';
      case 'size': return 'Ukuran';
      default: return 'Komponen';
    }
  }

  void _showAddComponentDialog() {
    final primaryColor = Theme.of(context).primaryColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Tipe Komponen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(backgroundColor: primaryColor.withOpacity(0.1), child: const Text('🌸')),
              title: const Text('Bunga Custom'),
              onTap: () { Navigator.pop(context); _showAddEditComponent(type: 'flower'); },
            ),
            ListTile(
              leading: CircleAvatar(backgroundColor: primaryColor.withOpacity(0.1), child: const Text('📦')),
              title: const Text('Kemasan Custom'),
              onTap: () { Navigator.pop(context); _showAddEditComponent(type: 'wrapping'); },
            ),
            ListTile(
              leading: CircleAvatar(backgroundColor: primaryColor.withOpacity(0.1), child: const Text('📏')),
              title: const Text('Ukuran Custom'),
              onTap: () { Navigator.pop(context); _showAddEditComponent(type: 'size'); },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditComponent({required String type, Map<String, dynamic>? component}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminAddEditCustomComponent(type: type, component: component)),
    );
    if (result == true) _loadData();
  }

  Widget _buildComponentCard(String title, IconData icon, List<Map<String, dynamic>> components, String type) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: primaryColor),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddEditComponent(type: type),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(),
          components.isEmpty
              ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Belum ada data')))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: components.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = components[index];
                    final isDefault = item['isDefault'] == true;

                    //Widget dasar tile item komponen
                    Widget tileContent = ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryColor.withOpacity(0.1), 
                        child: Icon(icon, color: primaryColor, size: 20),
                      ),
                      title: Text(
                        item['name'], 
                        style: TextStyle(fontWeight: isDefault ? FontWeight.bold : FontWeight.normal),
                      ),
                      subtitle: type == 'size' && item['description'] != null 
                          ? Text(item['description'], style: const TextStyle(fontSize: 12)) 
                          : null,
                      trailing: SizedBox(
                        width: 140,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Rp ${(item['price'] as num).toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            if (!isDefault) ...[
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                onPressed: () => _showAddEditComponent(type: type, component: item),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () => _deleteCustomComponent(type, item['id'], item['name'], isDefault),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );

                    //Jika item DEFAULT, langsung kembalikan tileContent tanpa Dismissible (biar gabisa diswipe)
                    if (isDefault) {
                      return tileContent;
                    }

                    //Bisa di-swipe hapus
                    return Dismissible(
                      //Menggunakan kombinasi tipe dan ID
                      key: Key('${type}_${item['id']}'),
                      
                      //gestur seret hanya ke kiri (End to Start)
                      direction: DismissDirection.endToStart,
                      
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        color: Colors.redAccent.shade200,
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      
                      //Konfirmasi sebelum benar-benar menghilangkan item dari layar
                      confirmDismiss: (direction) async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Hapus ${_getTypeName(type)}'),
                            content: Text('Apakah Anda yakin ingin menghapus "${item['name']}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true), 
                                style: TextButton.styleFrom(foregroundColor: Colors.red), 
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        return confirmed ?? false;
                      },
                      
                      //setelah konfirmasi, manggil fungsi penghapusan dari database
                      onDismissed: (direction) async {
                        if (type == 'flower') {
                          await DatabaseHelper.instance.deleteCustomFlower(item['id']);
                        } else if (type == 'wrapping') {
                          await DatabaseHelper.instance.deleteCustomWrapping(item['id']);
                        } else if (type == 'size') {
                          await DatabaseHelper.instance.deleteCustomSize(item['id']);
                        }
                        
                        await _loadData();
                        
                        // feedback snackbar sukses
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${_getTypeName(type)} "${item['name']}" berhasil dihapus')),
                          );
                        }
                      },
                      child: tileContent,
                    );
                  },
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return AdminLayout(
      selectedIndex: 1,
      title: 'Kelola Produk',
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              tabs: const [
                Tab(text: '📦 Katalog Produk'),
                Tab(text: '🎨 Komponen Custom'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_tabController.index == 0) ...[
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      leading: Icon(Icons.settings, color: primaryColor),
                      title: const Text('Pengaturan Katalog', style: TextStyle(fontWeight: FontWeight.bold)),
                      children: [
                        SwitchListTile(
                          title: const Text('Izinkan Menonaktifkan Produk'),
                          subtitle: const Text('Tampilkan opsi untuk menonaktifkan produk tanpa menghapusnya'),
                          value: _canDisableProduct,
                          onChanged: _toggleDisableProduct,
                          activeColor: primaryColor,
                        ),
                        SwitchListTile(
                          title: const Text('Peringatan Stok Menipis'),
                          subtitle: const Text('Sorot produk dengan stok kurang dari 5'),
                          value: _showLowStockWarning,
                          onChanged: _toggleLowStockWarning,
                          activeColor: primaryColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_tabController.index == 0) {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const TambahProdukPage()));
                        if (result == true) _loadData();
                      } else {
                        _showAddComponentDialog();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.all(12), 
                      shape: const CircleBorder(), 
                      elevation: 2,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      //Katalog Produk
                      _catalogProducts.isEmpty
                          ? const Center(child: Text('Belum ada produk'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _catalogProducts.length,
                              itemBuilder: (context, index) {
                                final product = _catalogProducts[index];
                                final price = (product['harga'] as num?)?.toDouble() ?? 0;
                                final stock = product['stok'] ?? 0;
                                final isActive = product['isActive'] == null || product['isActive'] == 1 || product['isActive'] == true;
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  color: isActive ? Colors.white : Colors.grey.shade200,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start, // Atur rata atas agar aman dari overflow vertikal
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: SizedBox(
                                            width: 70,
                                            height: 70,
                                            child: Opacity(
                                              opacity: isActive ? 1.0 : 0.5,
                                              child: ProductImage(
                                                imageString: product['gambar'] ?? product['image'],
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 3,
                                          child: Opacity(
                                            opacity: isActive ? 1.0 : 0.5,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                              Text(
                                                product['nama'] ?? 'Produk',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                product['deskripsi'] ?? '',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: (stock < 5 && _showLowStockWarning) ? Colors.red.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'Stok: $stock',
                                                  style: TextStyle(
                                                    fontSize: 10, 
                                                    color: (stock < 5 && _showLowStockWarning) ? Colors.red : primaryColor, 
                                                    fontWeight: FontWeight.bold
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Rp ${price.toStringAsFixed(0)}',
                                                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  if (_canDisableProduct) ...[
                                                    SizedBox(
                                                      height: 24,
                                                      child: Transform.scale(
                                                        scale: 0.7,
                                                        child: Switch(
                                                          value: isActive,
                                                          onChanged: (bool value) => _toggleProductActive(product, isActive),
                                                          activeColor: primaryColor,
                                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                  ],
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                                    onPressed: () async {
                                                      final result = await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(builder: (context) => TambahProdukPage(product: product)),
                                                      );
                                                      if (result == true) _loadData();
                                                    },
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                    onPressed: () => _deleteProduct(product),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                ],
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
                      
                      //Komponen Custom
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildComponentCard('🌸 Bunga Custom', Icons.local_florist, _displayFlowers, 'flower'),
                            const SizedBox(height: 20),
                            _buildComponentCard('📦 Kemasan Custom', Icons.shopping_bag, _displayWrappings, 'wrapping'),
                            const SizedBox(height: 20),
                            _buildComponentCard('📏 Ukuran Custom', Icons.straighten, _displaySizes, 'size'),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.sync, size: 20, color: Colors.blue.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Perubahan pada komponen custom akan langsung terlihat oleh pembeli di halaman Custom Bouquet.',
                                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}