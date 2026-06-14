import 'package:flutter/material.dart';
import '../../services/product_service.dart';

class EditProdukPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final int productIndex;

  const EditProdukPage({
    super.key,
    required this.product,
    required this.productIndex,
  });

  @override
  State<EditProdukPage> createState() => _EditProdukPageState();
}

class _EditProdukPageState extends State<EditProdukPage> {
  final ProductService _productService = ProductService();
  late TextEditingController _namaCtrl;
  late TextEditingController _deskripsiCtrl;
  late TextEditingController _hargaCtrl;
  late TextEditingController _stokCtrl;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.product['nama']);
    _deskripsiCtrl = TextEditingController(text: widget.product['deskripsi']);
    _hargaCtrl = TextEditingController(text: '${widget.product['harga']}');
    _stokCtrl = TextEditingController(text: '${widget.product['stok']}');
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _deskripsiCtrl.dispose();
    _hargaCtrl.dispose();
    _stokCtrl.dispose();
    super.dispose();
  }

  void _saveProduk() {
    if (_namaCtrl.text.isEmpty ||
        _hargaCtrl.text.isEmpty ||
        _stokCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua field harus diisi!')));
      return;
    }

    final updatedProduct = {
      ...widget.product,
      'nama': _namaCtrl.text,
      'deskripsi': _deskripsiCtrl.text,
      'harga': int.tryParse(_hargaCtrl.text) ?? 0,
      'stok': int.tryParse(_stokCtrl.text) ?? 0,
    };

    _productService.updateProduct(widget.product['id'].toString(), updatedProduct);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Produk berhasil diupdate!')));
    Navigator.pop(context, {
      'product': updatedProduct,
      'index': widget.productIndex,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Produk'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(32),
            children: [
              const Text(
                'Detail Produk',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _namaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _deskripsiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hargaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _stokCtrl,
                decoration: const InputDecoration(
                  labelText: 'Stok',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProduk,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update Produk', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
