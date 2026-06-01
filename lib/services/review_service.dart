import 'package:flutter/foundation.dart';
import 'package:flowries/services/database_helper.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();

  factory ReviewService() => _instance;

  late ValueNotifier<List<Map<String, dynamic>>> _reviewsNotifier;

  ReviewService._internal() {
    _reviewsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
    _loadInitialData();
  }

  ValueNotifier<List<Map<String, dynamic>>> get reviewsNotifier =>
      _reviewsNotifier;

  List<Map<String, dynamic>> get reviews => _reviewsNotifier.value;

  Future<void> _loadInitialData() async {
    await refreshReviews();
  }

  // HANYA SATU method refreshReviews (yang terbaru dengan reply)
  Future<void> refreshReviews() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        r.id, 
        r.productId, 
        p.nama as productName,
        r.userId, 
        u.nama as userName,
        r.rating, 
        r.komentar as isiUlasan, 
        r.createdAt as tanggalUlasan,
        r.image_url as imageUrl,
        r.reply,
        r.repliedAt,
        r.repliedBy
      FROM reviews r
      LEFT JOIN products p ON r.productId = p.id
      LEFT JOIN users u ON r.userId = u.id
      ORDER BY r.createdAt DESC
    ''');
    _reviewsNotifier.value = maps;
  }

  Future<List<Map<String, dynamic>>> getReviewsByProductId(
    String productId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery(
      '''
      SELECT 
        r.id, 
        r.productId, 
        p.nama as productName,
        r.userId, 
        u.nama as userName,
        r.rating, 
        r.komentar as isiUlasan, 
        r.createdAt as tanggalUlasan,
        r.image_url as imageUrl,
        r.reply,
        r.repliedAt,
        r.repliedBy
      FROM reviews r
      LEFT JOIN products p ON r.productId = p.id
      LEFT JOIN users u ON r.userId = u.id
      WHERE r.productId = ?
      ORDER BY r.createdAt DESC
    ''',
      [productId],
    );
  }

  Future<double> getAverageRating(String productId) async {
    final reviews = await getReviewsByProductId(productId);
    if (reviews.isEmpty) return 0.0;
    final sum = reviews.fold<double>(
      0,
      (sum, review) => sum + (review['rating'] as int).toDouble(),
    );
    return sum / reviews.length;
  }

  Future<void> addReview(Map<String, dynamic> reviewData) async {
    final db = await DatabaseHelper.instance.database;
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

    // Pastikan userId terisi, minimal dummy
    final String userId = reviewData['userId'] ?? 'user_dummy';

    final Map<String, dynamic> reviewMap = {
      'id': newId,
      'productId': reviewData['productId'],
      'userId': userId,
      'rating': reviewData['rating'] ?? 5,
      'komentar': reviewData['isiUlasan'] ?? reviewData['komentar'] ?? '',
      'createdAt': reviewData['tanggalUlasan'] ?? DateTime.now().toIso8601String(),
    };

    // Tambahkan image_url jika ada
    if (reviewData.containsKey('image_url') && reviewData['image_url'] != null) {
      reviewMap['image_url'] = reviewData['image_url'];
    }

    await db.insert('reviews', reviewMap);
    await refreshReviews();
  }

  Future<void> updateReview(String id, Map<String, dynamic> reviewData) async {
    final db = await DatabaseHelper.instance.database;

    final updateMap = <String, dynamic>{};
    if (reviewData.containsKey('rating')) updateMap['rating'] = reviewData['rating'];
    if (reviewData.containsKey('isiUlasan')) updateMap['komentar'] = reviewData['isiUlasan'];
    if (reviewData.containsKey('komentar')) updateMap['komentar'] = reviewData['komentar'];
    if (reviewData.containsKey('image_url')) updateMap['image_url'] = reviewData['image_url'];

    if (updateMap.isNotEmpty) {
      await db.update('reviews', updateMap, where: 'id = ?', whereArgs: [id]);
      await refreshReviews();
    }
  }

  Future<void> deleteReview(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('reviews', where: 'id = ?', whereArgs: [id]);
    await refreshReviews();
  }

  Future<bool> hasUserReviewedProduct(String userId, String productId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'reviews',
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, productId],
    );
    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getUserReviewForProduct(
    String userId,
    String productId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'reviews',
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, productId],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<void> addReplyToReview(
    String reviewId,
    String replyText,
    String adminId,
  ) async {
    final db = await DatabaseHelper.instance.database;

    await db.update(
      'reviews',
      {
        'reply': replyText,
        'repliedAt': DateTime.now().toIso8601String(),
        'repliedBy': adminId,
      },
      where: 'id = ?',
      whereArgs: [reviewId],
    );

    await refreshReviews();
  }

  Future<void> updateReply(String reviewId, String replyText) async {
    final db = await DatabaseHelper.instance.database;

    await db.update(
      'reviews',
      {'reply': replyText, 'repliedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [reviewId],
    );

    await refreshReviews();
  }

  Future<void> deleteReply(String reviewId) async {
    final db = await DatabaseHelper.instance.database;

    await db.update(
      'reviews',
      {'reply': null, 'repliedAt': null, 'repliedBy': null},
      where: 'id = ?',
      whereArgs: [reviewId],
    );

    await refreshReviews();
  }
}