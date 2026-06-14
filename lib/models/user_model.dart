class User {
  final String id;
  final String email;
  final String password;
  final String nama;
  final String noTelepon;
  final String alamat;
  final String tipeUser; // 'admin' atau 'pembeli'
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.nama,
    required this.noTelepon,
    required this.alamat,
    required this.tipeUser,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'nama': nama,
      'noTelepon': noTelepon,
      'alamat': alamat,
      'tipeUser': tipeUser,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      password: json['password'],
      nama: json['nama'],
      noTelepon: json['noTelepon'],
      alamat: json['alamat'],
      tipeUser: json['tipeUser'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
