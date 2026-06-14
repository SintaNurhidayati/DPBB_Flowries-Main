import 'package:flutter/material.dart';
import '../../services/review_service.dart';

class DaftarUlasanPage extends StatefulWidget {
  const DaftarUlasanPage({super.key});

  @override
  State<DaftarUlasanPage> createState() => _DaftarUlasanPageState();
}

class _DaftarUlasanPageState extends State<DaftarUlasanPage> {
  final ReviewService _reviewService = ReviewService();

  @override
  void initState() {
    super.initState();
    _reviewService.refreshReviews();
  }

  void _showDeleteDialog(Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Ulasan?'),
        content: Text(
          'Yakin ingin menghapus ulasan untuk "${review['productName'] ?? 'Produk'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              try {
                _reviewService.deleteReview(review['id'].toString());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Ulasan berhasil dihapus'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> review) {
    final TextEditingController commentController =
        TextEditingController(text: review['isiUlasan']);
    int selectedRating = review['rating'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Ulasan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Produk: ${review['productName'] ?? 'Produk'}'),
                const SizedBox(height: 16),
                const Text('Rating:'),
                Row(
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedRating = index + 1;
                        });
                      },
                      child: Icon(
                        Icons.star,
                        size: 32,
                        color: index < selectedRating
                            ? Colors.amber
                            : Colors.grey[300],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Ulasan',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                try {
                  final updatedReview = {
                    ...review,
                    'rating': selectedRating,
                    'isiUlasan': commentController.text,
                    'tanggalUlasan': DateTime.now().toIso8601String(),
                  };
                  _reviewService.updateReview(review['id'].toString(), updatedReview);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Ulasan berhasil diupdate'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Ulasan Saya'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Reviews List - ListView dengan Local Data
          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _reviewService.reviewsNotifier,
              builder: (context, reviews, _) {
                if (reviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Belum ada ulasan',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/riwayat');
                          },
                          child: const Text('Buat Ulasan'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with user name
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.pink,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Center(
                                  child: Text(
                                    (review['userName'] ?? 'A')[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Produk: ${review['productName'] ?? review['productId']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      review['userName'] ?? 'Pembeli',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Rating
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                Icons.star,
                                size: 18,
                                color: i < (review['rating'] ?? 5)
                                    ? Colors.amber
                                    : Colors.grey[300],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Comment
                          Text(
                            review['isiUlasan'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Date
                          Text(
                            (review['tanggalUlasan'] ?? DateTime.now().toIso8601String())
                                .split('T')[0],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                  onPressed: () => _showEditDialog(review),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text('Hapus'),
                                  onPressed: () => _showDeleteDialog(review),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
