// lib/pages/admin/akun_pembeli_page.dart
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../widgets/admin_layout.dart';
import 'tambah_user_page.dart';

class AkunPembeliPage extends StatefulWidget {
  const AkunPembeliPage({super.key});

  @override
  State<AkunPembeliPage> createState() => _AkunPembeliPageState();
}

class _AkunPembeliPageState extends State<AkunPembeliPage> {
  final UserService _userService = UserService();
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _userService.getAllUsers();
  }

  void _addUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TambahUserPage(useHttpApi: false),
      ),
    );
    if (result != null) {
      setState(() {
        _usersFuture = _userService.getAllUsers();
      });
    }
  }

  List<Map<String, dynamic>> _sortUsersByType(List<Map<String, dynamic>> users) {
    final sorted = List<Map<String, dynamic>>.from(users);
    sorted.sort((a, b) {
      final aType = a['tipeUser'] ?? 'pembeli';
      final bType = b['tipeUser'] ?? 'pembeli';
      
      if (aType == 'pembeli' && bType != 'pembeli') return -1;
      if (aType != 'pembeli' && bType == 'pembeli') return 1;
      
      final aName = (a['nama'] ?? '').toString().toLowerCase();
      final bName = (b['nama'] ?? '').toString().toLowerCase();
      return aName.compareTo(bName);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _userService.userType == 'admin';
    final screenWidth = MediaQuery.of(context).size.width;
    
    // 🔥 RESPONSIVE CROSS AXIS COUNT
    int crossAxisCount = 3;
    if (screenWidth < 900) crossAxisCount = 2;
    if (screenWidth < 600) crossAxisCount = 1;

    if (!isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('Akses ditolak. Hanya admin yang dapat melihat halaman ini.'),
        ),
      );
    }

    return AdminLayout(
      title: 'Akun Pembeli',
      selectedIndex: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              onPressed: _addUser,
              icon: const Icon(Icons.person_add),
              label: const Text('Tambah User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _usersFuture = _userService.getAllUsers();
                            });
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada user'));
                }

                final sortedUsers = _sortUsersByType(snapshot.data!);

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.8, // 🔥 UBAH AGAR LEBIH TINGGI
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: sortedUsers.length,
                  itemBuilder: (context, index) {
                    final user = sortedUsers[index];
                    final isPembeli = (user['tipeUser'] ?? 'pembeli') == 'pembeli';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: isPembeli ? Colors.pink.shade200 : Colors.blue.shade200,
                          width: 2,
                        ),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user['nama'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isPembeli ? Colors.pink.shade50 : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isPembeli ? Colors.pink.shade200 : Colors.blue.shade200,
                                  ),
                                ),
                                child: Text(
                                  isPembeli ? ((user['isActive'] ?? 1) == 1 ? 'PEMBELI' : 'NONAKTIF') : 'ADMIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isPembeli ? ((user['isActive'] ?? 1) == 1 ? Colors.pink.shade700 : Colors.red.shade700) : Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Email
                          Row(
                            children: [
                              const Icon(Icons.email, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  user['email'] ?? '-',
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          
                          // Phone
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  user['noTelepon'] ?? '-',
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          
                          // Alamat (jika ada)
                          if (user['alamat'] != null && user['alamat'] != '-' && user['alamat'].toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    user['alamat'] ?? '-',
                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          const Spacer(),
                          
                          // 🔥 BUTTON ROW YANG SUDAH DIPERBAIKI (TIDAK OVERFLOW)
                          Row(
                            children: [
                              // Tombol Nonaktifkan/Aktifkan
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 36,
                                  child: OutlinedButton(
                                    onPressed: isPembeli
                                        ? () async {
                                            await _userService.toggleUserStatus(
                                                user['id'].toString(),
                                                user['isActive'] ?? 1);
                                            setState(() {
                                              _usersFuture = _userService.getAllUsers();
                                            });
                                          }
                                        : null,
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      foregroundColor: (user['isActive'] ?? 1) == 1
                                          ? Colors.orange
                                          : Colors.green,
                                      side: BorderSide(
                                        color: (user['isActive'] ?? 1) == 1
                                            ? Colors.orange
                                            : Colors.green,
                                      ),
                                      textStyle: const TextStyle(fontSize: 11),
                                    ),
                                    child: Text((user['isActive'] ?? 1) == 1
                                        ? 'Nonaktif'
                                        : 'Aktifkan'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // Tombol Hapus
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 36,
                                  child: ElevatedButton(
                                    onPressed: isPembeli
                                        ? () async {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Hapus Akun'),
                                                content: const Text(
                                                    'Apakah Anda yakin ingin menghapus akun ini?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx),
                                                    child: const Text('Batal'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      Navigator.pop(ctx);
                                                      await _userService.deleteUser(
                                                          user['id'].toString());
                                                      setState(() {
                                                        _usersFuture =
                                                            _userService.getAllUsers();
                                                      });
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.red),
                                                    child: const Text('Hapus'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.zero,
                                      textStyle: const TextStyle(fontSize: 11),
                                    ),
                                    child: const Text('Hapus'),
                                  ),
                                ),
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