import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;
  final String userRole;

  const CustomNavBar({
    required this.currentIndex,
    required this.onIndexChanged,
    this.userRole = 'pembeli',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onIndexChanged,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFE91E63),
        unselectedItemColor: Colors.grey,
        elevation: 0,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: 'Cari',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.brush),
            label: 'Custom Buket',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
