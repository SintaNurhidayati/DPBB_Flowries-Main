class RiwayatService {
  static final RiwayatService _instance = RiwayatService._internal();
  factory RiwayatService() => _instance;
  RiwayatService._internal();

  final List<Map<String, dynamic>> _riwayatPembelian = [];

  List<Map<String, dynamic>> get riwayatPembelian => _riwayatPembelian;

  void tambahRiwayat({
    required List<Map<String, dynamic>> items,
    required int total,
    required String namaPembeli,
    required String alamat,
    required String metodePembayaran,
  }) {
    final riwayat = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "tanggal": DateTime.now(),
      "items": items,
      "total": total,
      "namaPembeli": namaPembeli,
      "alamat": alamat,
      "metodePembayaran": metodePembayaran,
      "status": "Selesai",
    };

    _riwayatPembelian.insert(0, riwayat);
  }
}
