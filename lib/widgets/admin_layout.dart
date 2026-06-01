import 'package:flutter/material.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final int selectedIndex;

  const AdminLayout({
    super.key,
    required this.child,
    required this.title,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.pink.shade50,
            child: Column(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.pink,
                  ),
                  child: const Center(
                    child: Text(
                      'Flowries Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                _buildMenuItem(context, 0, 'Dashboard', Icons.dashboard, '/admin-dashboard'),
                _buildMenuItem(context, 1, 'Kelola Produk', Icons.shopping_bag, '/kelola-produk'),

                _buildMenuItem(context, 3, 'Kelola Pesanan', Icons.shopping_cart, '/kelola-pesanan'),
                _buildMenuItem(context, 4, 'Kelola Transaksi', Icons.receipt_long, '/kelola-transaksi'),
                _buildMenuItem(context, 5, 'Lihat Ulasan', Icons.star, '/lihat-ulasan'),
                _buildMenuItem(context, 6, 'Akun Pembeli', Icons.people, '/akun-pembeli'),
                _buildMenuItem(context, 7, 'Laporan Penjualan', Icons.bar_chart, '/laporan-penjualan'),
                const Spacer(),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // AppBar
                Container(
                  height: 60,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Body
                Expanded(
                  child: Container(
                    color: Colors.grey.shade100,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, int index, String title, IconData icon, String route) {
    final isSelected = index == selectedIndex;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.pink : Colors.grey.shade700),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.pink : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.pink.withOpacity(0.1),
      onTap: () {
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
