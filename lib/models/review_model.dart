class Review {
  final String id;
  final String productId;
  final String userId;
  final int rating;
  final String komentar;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    required this.komentar,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'rating': rating,
      'komentar': komentar,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      productId: json['productId'],
      userId: json['userId'],
      rating: json['rating'],
      komentar: json['komentar'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
