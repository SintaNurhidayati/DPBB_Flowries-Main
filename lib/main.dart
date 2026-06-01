import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:io' as io;
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/pembeli/home_pembeli.dart';
import 'pages/pembeli/katalog_produk.dart';
import 'pages/pembeli/detail_produk_page.dart';
import 'pages/pembeli/cart_screen.dart';
import 'pages/pembeli/payment_screen.dart';
import 'pages/pembeli/riwayat_transaksi.dart';
import 'pages/pembeli/custom_order_page.dart';
import 'pages/pembeli/tambah_ulasan_page.dart';
import 'pages/pembeli/profil_pembeli.dart';
import 'pages/pembeli/daftar_ulasan.dart';
import 'pages/pembeli/checkout_screen.dart';
import 'pages/pembeli/payment_success_page.dart';
import 'pages/pembeli/edit_profile_page.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'pages/admin/akun_pembeli_page.dart';
import 'pages/admin/kelola_produk.dart';
import 'pages/admin/kelola_transaksi.dart';
import 'pages/admin/kelola_pesanan.dart';
import 'pages/admin/lihat_ulasan.dart';
import 'pages/admin/tambah_produk_page.dart';
import 'pages/admin/laporan_penjualan.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    if (io.Platform.isWindows || io.Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }
  runApp(const FlowriesApp());
}

class FlowriesApp extends StatelessWidget {
  const FlowriesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flowries Bouquet",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFCDE6),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
      onGenerateRoute: (settings) {
        // Routes untuk Pembeli
        if (settings.name == '/customer-home') {
          return MaterialPageRoute(builder: (context) => const HomePembeli());
        }
        if (settings.name == '/katalog') {
          return MaterialPageRoute(builder: (context) => const KatalogProduk());
        }
        if (settings.name == '/custom-order') {
          return MaterialPageRoute(
            builder: (context) => const CustomOrderPage(),
          );
        }
        if (settings.name == '/detail-produk') {
          final product = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => DetailProdukPage(product: product),
            settings: settings,
          );
        }
        if (settings.name == '/keranjang') {
          final args = settings.arguments as Map<String, dynamic>?;
          final userId = args?['userId'] ?? 1;
          return MaterialPageRoute(
            builder: (context) => CartScreen(userId: userId),
            settings: settings,
          );
        }
        if (settings.name == '/pembayaran') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => PaymentScreen(
              transactionId: args?['transactionId'] ?? '',
              isPaymentOnly: args?['isPaymentOnly'] ?? false,
              total: args?['total'] ?? 0.0,
              items: args?['items'] ?? [],
            ),
            settings: settings,
          );
        }
        if (settings.name == '/riwayat') {
          return MaterialPageRoute(
            builder: (context) => const RiwayatTransaksiPage(),
          );
        }

        // PERBAIKAN: Route /tambah-ulasan dengan constructor
        if (settings.name == '/tambah-ulasan') {
          final args = settings.arguments as Map<String, dynamic>?;

          // Ambil produk dari arguments
          Map<String, dynamic>? product;
          if (args != null && args.containsKey('products')) {
            final productsList = args['products'];
            if (productsList is List && productsList.isNotEmpty) {
              product = Map<String, dynamic>.from(productsList[0]);
            }
          }

          // Jika tidak ada di products, coba dari productId
          if (product == null &&
              args != null &&
              args.containsKey('productId')) {
            product = {
              'id': args['productId'].toString(),
              'nama': args['productName']?.toString() ?? 'Produk',
              'harga': (args['productPrice'] ?? 0).toDouble(),
              'quantity': args['productQuantity'] ?? 1,
              'image': args['productImage'] ?? 'assets/images/flower1.png',
            };
          }

          return MaterialPageRoute(
            builder: (context) => TambahUlasanPage(
              transactionId: args?['transactionId']?.toString(),
              product: product,
              isEdit: args?['isEdit'] ?? false,
            ),
            settings: settings,
          );
        }

        if (settings.name == '/profil-pembeli') {
          return MaterialPageRoute(builder: (context) => const ProfilPembeli());
        }
        if (settings.name == '/daftar-ulasan') {
          return MaterialPageRoute(
            builder: (context) => const DaftarUlasanPage(),
          );
        }
        if (settings.name == '/checkout') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => CheckoutScreen(
              items: args?['items'] ?? [],
              total: (args?['total'] as num?)?.toDouble() ?? 0.0,
              selectedIds: args?['selectedIds']?.cast<String>() ?? [],
            ),
            settings: settings,
          );
        }
        if (settings.name == '/payment-success') {
          return MaterialPageRoute(
            builder: (context) => const PaymentSuccessPage(),
          );
        }
        if (settings.name == '/edit-profile') {
          return MaterialPageRoute(
            builder: (context) => const EditProfilePage(),
          );
        }

        // Routes untuk Admin
        if (settings.name == '/admin-dashboard') {
          return MaterialPageRoute(
            builder: (context) => const AdminDashboardPage(),
          );
        }
        if (settings.name == '/kelola-produk') {
          return MaterialPageRoute(builder: (context) => const KelolaProduk());
        }
        if (settings.name == '/kelola-transaksi') {
          return MaterialPageRoute(
            builder: (context) => const KelolaTransaksi(),
          );
        }
        if (settings.name == '/kelola-pesanan') {
          return MaterialPageRoute(builder: (context) => const KelolaPesanan());
        }
        if (settings.name == '/laporan-penjualan') {
          return MaterialPageRoute(
            builder: (context) => const LaporanPenjualan(),
          );
        }
        if (settings.name == '/lihat-ulasan') {
          return MaterialPageRoute(builder: (context) => const LihatUlasan());
        }
        if (settings.name == '/tambah-produk') {
          return MaterialPageRoute(
            builder: (context) => const TambahProdukPage(),
          );
        }
        if (settings.name == '/akun-pembeli') {
          return MaterialPageRoute(
            builder: (context) => const AkunPembeliPage(),
          );
        }

        return null;
      },
    );
  }
}
