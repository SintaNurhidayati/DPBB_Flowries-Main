class Product {
  final String id;
  final String nama;
  final String deskripsi;
  final double harga;
  final String gambar;
  final int stok;
  final double rating;
  final int jumlahUlasan;
  final DateTime createdAt;
  final String createdBy;

  Product({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.harga,
    required this.gambar,
    required this.stok,
    this.rating = 0.0,
    this.jumlahUlasan = 0,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'deskripsi': deskripsi,
      'harga': harga,
      'gambar': gambar,
      'stok': stok,
      'rating': rating,
      'jumlahUlasan': jumlahUlasan,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      nama: json['nama'],
      deskripsi: json['deskripsi'],
      harga: json['harga'].toDouble(),
      gambar: json['gambar'],
      stok: json['stok'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      jumlahUlasan: json['jumlahUlasan'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
    );
  }
}
