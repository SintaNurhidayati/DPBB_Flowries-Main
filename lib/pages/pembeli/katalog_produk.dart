import 'package:flutter/material.dart';
import '../../widgets/custom_navbar.dart';
import '../../services/product_service.dart';
import '../../widgets/cart_badge_icon.dart';
import '../../widgets/product_image.dart';

class KatalogProduk extends StatefulWidget {
  const KatalogProduk({super.key});

  @override
  State<KatalogProduk> createState() => _KatalogProdukState();
}

class _KatalogProdukState extends State<KatalogProduk> {
  int _currentNavIndex = 1;
  final ProductService _productService = ProductService();

  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  String _selectedSort = 'terbaru';
  RangeValues _priceRange = const RangeValues(0, 1000000);
  double _maxPrice = 1000000;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _categories = ['Semua', 'Mawar', 'Matahari', 'Lily', 'Campuran'];
  final Map<String, String> _categoryNames = {
    'Semua': 'Semua',
    'Mawar': 'Mawar',
    'Matahari': 'Bunga Matahari',
    'Lily': 'Lily',
    'Campuran': 'Campuran',
  };
  
  final Map<String, String> _categoryDbMapping = {
    'Semua': 'Semua',
    'Mawar': 'Mawar',
    'Matahari': 'Matahari',
    'Lily': 'Lily',
    'Campuran': 'Campuran',
  };

  final String _heroImage = 'assets/images/custom.png';

  @override
  void initState() {
    super.initState();
    _productService.refreshProducts();
  }

  List<Map<String, dynamic>> _getFilteredProducts(List<Map<String, dynamic>> products) {
    if (products.isNotEmpty && _maxPrice == 1000000) {
      double maxPrice = 0;
      for (var p in products) {
        final price = (p['harga'] as num).toDouble();
        if (price > maxPrice) {
          maxPrice = price;
        }
      }
      if (maxPrice > _maxPrice) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {
            _maxPrice = maxPrice;
            _priceRange = RangeValues(0, maxPrice);
          });
        });
      }
    }

    var filtered = products.where((product) {
      if (_searchQuery.isNotEmpty) {
        final nameMatches = product['nama'].toLowerCase().contains(_searchQuery.toLowerCase());
        final descMatches = (product['deskripsi'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
        if (!nameMatches && !descMatches) return false;
      }
      
      if (_selectedCategory != 'Semua') {
        final productCategory = (product['kategori'] ?? '').toLowerCase();
        final selectedCat = _categoryDbMapping[_selectedCategory]?.toLowerCase() ?? _selectedCategory.toLowerCase();
        if (productCategory != selectedCat && 
            !product['nama'].toLowerCase().contains(selectedCat)) {
          return false;
        }
      }

      final price = (product['harga'] as num).toDouble();
      if (price < _priceRange.start || price > _priceRange.end) {
        return false;
      }

      return true;
    }).toList();

    switch (_selectedSort) {
      case 'termurah':
        filtered.sort((a, b) => (a['harga'] as num).compareTo(b['harga'] as num));
        break;
      case 'termahal':
        filtered.sort((a, b) => (b['harga'] as num).compareTo(a['harga'] as num));
        break;
      default:
        filtered.sort((a, b) {
          final dateA = a['createdAt'] ?? '';
          final dateB = b['createdAt'] ?? '';
          return dateB.compareTo(dateA);
        });
        break;
    }

    return filtered;
  }

  Widget _buildFilterDrawer() {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7, // Lebar 70% dari layar (lebih kecil)
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori
                    const Text(
                      'Kategori',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _categoryNames[category]!,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Urutkan
                    const Text(
                      'Urutkan',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildSortButton('Terbaru', 'terbaru', primaryColor),
                        const SizedBox(width: 8),
                        _buildSortButton('Termurah', 'termurah', primaryColor),
                        const SizedBox(width: 8),
                        _buildSortButton('Termahal', 'termahal', primaryColor),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Harga
                    const Text(
                      'Harga',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rp ${_priceRange.start.toInt()}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          'Rp ${_priceRange.end.toInt()}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: _maxPrice,
                      divisions: 100,
                      activeColor: primaryColor,
                      inactiveColor: primaryColor.withOpacity(0.2),
                      onChanged: (values) {
                        setState(() {
                          _priceRange = values;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Tombol Reset dan Terapkan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = 'Semua';
                          _selectedSort = 'terbaru';
                          _priceRange = RangeValues(0, _maxPrice);
                        });
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reset', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Terapkan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton(String label, String value, Color primaryColor) {
    final isSelected = _selectedSort == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSort = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    if (_currentNavIndex == index) return;
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0: Navigator.pushReplacementNamed(context, '/customer-home'); break;
      case 1: break;
      case 2: Navigator.pushReplacementNamed(context, '/custom-order'); break;
      case 3: Navigator.pushReplacementNamed(context, '/riwayat'); break;
      case 4: Navigator.pushReplacementNamed(context, '/profil-pembeli'); break;
    }
  }

  void _openFilterDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: ProductImage(
                imageString: product['gambar'],
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              product['nama'] ?? 'Tanpa Nama',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Rp ${(product['harga'] as num).toStringAsFixed(0)}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Text(
              product['deskripsi'] ?? 'Tidak ada deskripsi',
              style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/detail-produk',
                    arguments: product,
                  ).then((_) => _productService.refreshProducts());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Detail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(bool isDesktop) {
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
          border: Border.all(color: const Color(0xFFFFE4EB), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              SizedBox(
                width: isDesktop ? 120 : 80,
                height: isDesktop ? 100 : 80,
                child: Image.asset(
                  _heroImage,
                  width: isDesktop ? 120 : 80,
                  height: isDesktop ? 100 : 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: isDesktop ? 120 : 80,
                      height: isDesktop ? 100 : 80,
                      color: primaryColor.withOpacity(0.1),
                      child: Icon(Icons.image_outlined, size: 30, color: primaryColor),
                    );
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✨ Custom Bouquet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('Buat buket sesuai keinginanmu', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/custom-order');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 28),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Custom', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 600;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final crossAxisCount = isDesktop ? 4 : 2;
    
    final isFilterActive = _selectedCategory != 'Semua' || 
                           _selectedSort != 'terbaru' || 
                           _priceRange.start > 0 || 
                           _priceRange.end < _maxPrice;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Katalog Produk', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
        actions: const [CartBadgeIcon()],
      ),
      endDrawer: _buildFilterDrawer(),
      body: Column(
        children: [
          _buildHeroCard(isDesktop),
          const SizedBox(height: 8),
          
          // Search Bar dengan Icon Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Cari bunga...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: primaryColor, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: primaryColor, size: 20),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _openFilterDrawer,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.filter_list,
                            color: isFilterActive ? primaryColor : Colors.grey,
                            size: 22,
                          ),
                        ),
                        if (isFilterActive)
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _productService.productsNotifier,
              builder: (context, products, _) {
                if (products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredProducts = _getFilteredProducts(products);

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Tidak ada produk', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _selectedCategory = 'Semua';
                              _selectedSort = 'terbaru';
                              _priceRange = RangeValues(0, _maxPrice);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(filteredProducts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentNavIndex,
        onIndexChanged: _handleNavigation,
      ),
    );
  }
}