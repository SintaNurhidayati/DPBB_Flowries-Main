import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/database_helper.dart';

class AdminAddEditCustomComponent extends StatefulWidget {
  final String type;
  final Map<String, dynamic>? component;

  const AdminAddEditCustomComponent({
    super.key,
    required this.type,
    this.component,
  });

  @override
  State<AdminAddEditCustomComponent> createState() => _AdminAddEditCustomComponentState();
}

class _AdminAddEditCustomComponentState extends State<AdminAddEditCustomComponent> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.component != null) {
      _nameController.text = widget.component!['name'] ?? '';
      _priceController.text = (widget.component!['price'] ?? 0).toString();
      _imageBase64 = widget.component!['image_url'];
      if (widget.type == 'size') {
        _descController.text = widget.component!['description'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String get _title {
    final isEdit = widget.component != null;
    switch (widget.type) {
      case 'flower': return isEdit ? 'Edit Bunga' : 'Tambah Bunga';
      case 'wrapping': return isEdit ? 'Edit Kemasan' : 'Tambah Kemasan';
      case 'size': return isEdit ? 'Edit Ukuran' : 'Tambah Ukuran';
      default: return isEdit ? 'Edit Komponen' : 'Tambah Komponen';
    }
  }

  String get _typeName {
    switch (widget.type) {
      case 'flower': return 'Bunga';
      case 'wrapping': return 'Kemasan';
      case 'size': return 'Ukuran';
      default: return 'Komponen';
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Upload Gambar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (pickedFile != null) {
                  final bytes = await pickedFile.readAsBytes();
                  setState(() => _imageBase64 = base64Encode(bytes));
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
                  setState(() => _imageBase64 = base64Encode(bytes));
                }
              },
            ),
            if (_imageBase64 != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Gambar'),
                onTap: () {
                  setState(() => _imageBase64 = null);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final primaryColor = Theme.of(context).primaryColor;
    
    if (_imageBase64 != null && _imageBase64!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          base64Decode(_imageBase64!),
          width: double.infinity,
          height: 150,
          fit: BoxFit.cover,
        ),
      );
    }
    
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.type == 'flower' ? Icons.local_florist : Icons.shopping_bag, size: 50, color: primaryColor.withOpacity(0.5)),
            const SizedBox(height: 8),
            Text('Tap untuk upload gambar', style: TextStyle(color: primaryColor)),
            const SizedBox(height: 4),
            Text('JPG, PNG', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama harus diisi')));
      return;
    }

    final price = double.tryParse(_priceController.text) ?? 0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harga harus lebih dari 0')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> data = {
        'name': _nameController.text,
        'price': price,
      };
      
      if (widget.type != 'size') {
        if (_imageBase64 != null && _imageBase64!.isNotEmpty) {
          data['image_url'] = _imageBase64;
        }
      }
      
      if (widget.type == 'size') {
        data['description'] = _descController.text;
      }

      if (widget.type == 'flower') {
        if (widget.component != null) {
          await DatabaseHelper.instance.updateCustomFlower(widget.component!['id'], data);
        } else {
          await DatabaseHelper.instance.insertCustomFlower(data);
        }
      } else if (widget.type == 'wrapping') {
        if (widget.component != null) {
          await DatabaseHelper.instance.updateCustomWrapping(widget.component!['id'], data);
        } else {
          await DatabaseHelper.instance.insertCustomWrapping(data);
        }
      } else if (widget.type == 'size') {
        if (widget.component != null) {
          await DatabaseHelper.instance.updateCustomSize(widget.component!['id'], data);
        } else {
          await DatabaseHelper.instance.insertCustomSize(data);
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$_typeName berhasil disimpan')));
      }
    } catch (e) {
      print('Error saving: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final canUploadImage = widget.type != 'size';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: AppBar(
        title: Text(_title),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (canUploadImage) ...[
                      _buildImagePreview(),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama $_typeName',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(widget.type == 'flower' 
                            ? Icons.local_florist 
                            : widget.type == 'wrapping' 
                                ? Icons.shopping_bag 
                                : Icons.straighten),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: 'Rp ',
                      ),
                    ),
                    if (widget.type == 'size') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          prefixIcon: Icon(Icons.description),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.component != null ? 'Update' : 'Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}