import 'package:flutter/material.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Berhasil'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent going back
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'Pembayaran Berhasil!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pesanan Anda sedang kami proses. Terima kasih telah berbelanja di Flowries Bouquet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/customer-home', 
                    (route) => false
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Belanja Lagi'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/riwayat', 
                    (route) => route.settings.name == '/customer-home'
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.pink,
                  side: const BorderSide(color: Colors.pink),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Lihat Pesanan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}