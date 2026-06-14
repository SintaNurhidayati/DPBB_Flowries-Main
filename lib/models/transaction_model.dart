import 'cart_model.dart';

class Transaction {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalSebelomDiskon;
  final double diskonNominal;
  final double totalSetelahDiskon;
  final String status; // 'menunggu', 'diproses', 'selesai', 'dibatalkan'
  final DateTime tanggalPemesanan;
  final DateTime? tanggalSelesai;
  final String metodePembayaran;
  final String alamatPengiriman;
  final String? buktiPembayaran;
  final String tipePesanan; // 'katalog' or 'custom'
  final String? catatanCustom;

  Transaction({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalSebelomDiskon,
    required this.diskonNominal,
    required this.totalSetelahDiskon,
    required this.status,
    required this.tanggalPemesanan,
    this.tanggalSelesai,
    required this.metodePembayaran,
    required this.alamatPengiriman,
    this.buktiPembayaran,
    this.tipePesanan = 'katalog',
    this.catatanCustom,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalSebelomDiskon': totalSebelomDiskon,
      'diskonNominal': diskonNominal,
      'totalSetelahDiskon': totalSetelahDiskon,
      'status': status,
      'tanggalPemesanan': tanggalPemesanan.toIso8601String(),
      'tanggalSelesai': tanggalSelesai?.toIso8601String(),
      'metodePembayaran': metodePembayaran,
      'alamatPengiriman': alamatPengiriman,
      'buktiPembayaran': buktiPembayaran,
      'tipePesanan': tipePesanan,
      'catatanCustom': catatanCustom,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['userId'],
      items: List<CartItem>.from(
          (json['items'] as List).map((item) => CartItem.fromJson(item))),
      totalSebelomDiskon: json['totalSebelomDiskon'].toDouble(),
      diskonNominal: json['diskonNominal'].toDouble(),
      totalSetelahDiskon: json['totalSetelahDiskon'].toDouble(),
      status: json['status'],
      tanggalPemesanan: DateTime.parse(json['tanggalPemesanan']),
      tanggalSelesai: json['tanggalSelesai'] != null
          ? DateTime.parse(json['tanggalSelesai'])
          : null,
      metodePembayaran: json['metodePembayaran'],
      alamatPengiriman: json['alamatPengiriman'],
      buktiPembayaran: json['buktiPembayaran'],
      tipePesanan: json['tipePesanan'] ?? 'katalog',
      catatanCustom: json['catatanCustom'],
    );
  }
}
