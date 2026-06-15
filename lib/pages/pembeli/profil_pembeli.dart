import 'package:flutter/material.dart';
import 'dart:convert' as dart_convert;
import '../../widgets/custom_navbar.dart';
import '../../services/user_service.dart';
import '../../widgets/cart_badge_icon.dart';
import '../../widgets/custom_profile_avatar.dart';

class ProfilPembeli extends StatefulWidget {
  const ProfilPembeli({super.key});

  @override
  State<ProfilPembeli> createState() => _ProfilPembeliState();
}

class _ProfilPembeliState extends State<ProfilPembeli> {
  int _currentNavIndex = 4;
  final UserService _userService = UserService();

  // User data dari UserService
  late Map<String, dynamic> user;
  String? _userPhotoPath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _userService.userNotifier.addListener(_onUserChanged);
  }

  @override
  void dispose() {
    _userService.userNotifier.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    setState(() {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final currentUser = _userService.currentUser;
    user = {
      'nama': currentUser['nama'] ?? 'User',
      'email': currentUser['email'] ?? '-',
      'noTelepon': currentUser['noTelepon'] ?? '-',
      'alamat': currentUser['alamat'] ?? '-',
      'photo': currentUser['photo'],
      'noAnggota': 'FR${DateTime.now().year}0001',
      'tanggalGabung': DateTime.now().toString().split(' ')[0],
    };
  }

  void _handleNavigation(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/customer-home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/katalog');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/custom-order');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/riwayat');
        break;
      case 4:
        break;
    }
  }

  void _editProfile() {
    Navigator.pushNamed(context, '/edit-profile');
  }

  void _showChangePasswordDialog() {
    final TextEditingController passwordLamaCtrl = TextEditingController();
    final TextEditingController passwordBaruCtrl = TextEditingController();
    final TextEditingController konfirmasiPasswordCtrl =
        TextEditingController();
    bool obscurePasswordLama = true;
    bool obscurePasswordBaru = true;
    bool obscureKonfirmasi = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'Ubah Password',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Password Lama
                TextField(
                  controller: passwordLamaCtrl,
                  obscureText: obscurePasswordLama,
                  decoration: InputDecoration(
                    labelText: 'Password Lama',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePasswordLama
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePasswordLama = !obscurePasswordLama;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Password Baru
                TextField(
                  controller: passwordBaruCtrl,
                  obscureText: obscurePasswordBaru,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePasswordBaru
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePasswordBaru = !obscurePasswordBaru;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Konfirmasi Password
                TextField(
                  controller: konfirmasiPasswordCtrl,
                  obscureText: obscureKonfirmasi,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    prefixIcon: const Icon(Icons.verified_user),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureKonfirmasi
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureKonfirmasi = !obscureKonfirmasi;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                passwordLamaCtrl.dispose();
                passwordBaruCtrl.dispose();
                konfirmasiPasswordCtrl.dispose();
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                String passwordLama = passwordLamaCtrl.text.trim();
                String passwordBaru = passwordBaruCtrl.text.trim();
                String konfirmasi = konfirmasiPasswordCtrl.text.trim();

                // Validasi
                if (passwordLama.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Password lama tidak boleh kosong'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (passwordBaru.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Password baru tidak boleh kosong'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (passwordBaru.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Password minimal 6 karakter'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (passwordBaru != konfirmasi) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Password baru tidak cocok'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (passwordLama == passwordBaru) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '⚠️ Password baru harus berbeda dari yang lama',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Simulasi perubahan password (dalam produksi akan ke backend)
                setState(() {
                  user['password'] = passwordBaru;
                });

                passwordLamaCtrl.dispose();
                passwordBaruCtrl.dispose();
                konfirmasiPasswordCtrl.dispose();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Password berhasil diubah'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Ubah Password'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        centerTitle: true,
        elevation: 0,
        actions: [
          const CartBadgeIcon(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header with Photo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade300, Colors.pink.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  user['photo'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(45),
                          child: Image.memory(
                            dart_convert.base64Decode(user['photo']), // Need to import dart:convert as dart_convert or add it to imports
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        )
                      : CustomProfileAvatar(name: user['nama'], radius: 45),
                  const SizedBox(height: 16),
                  Text(
                    user['nama'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No. Anggota: ${user['noAnggota']}',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bergabung: ${user['tanggalGabung']}',
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _editProfile,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Profil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.pink,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showChangePasswordDialog,
                        icon: const Icon(Icons.lock, size: 16),
                        label: const Text('Ubah PW'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/riwayat'),
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text('Riwayat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.pink,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Informasi Pribadi Section
            const Text(
              '👤 Informasi Pribadi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildProfileField(Icons.email, 'Email', user['email']),
            _buildProfileField(Icons.phone, 'No. Telepon', user['noTelepon']),
            _buildProfileField(Icons.location_on, 'Alamat', user['alamat']),
            const SizedBox(height: 28),

            // Action Buttons Section
            const Text(
              '⚙️ Pengaturan Akun',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Konfirmasi Logout'),
                      content: const Text('Apakah Anda yakin ingin keluar?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentNavIndex,
        onIndexChanged: _handleNavigation,
      ),
    );
  }

  Widget _buildProfileField(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.pink, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
