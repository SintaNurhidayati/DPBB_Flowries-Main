class RiwayatPembelian {
  final String id;
  final String productName;
  final String image;
  final int quantity;
  final int price;
  final int total;
  final DateTime tanggalPembelian;
  final String status;

  RiwayatPembelian({
    required this.id,
    required this.productName,
    required this.image,
    required this.quantity,
    required this.price,
    required this.total,
    required this.tanggalPembelian,
    this.status = 'Selesai',
  });
}