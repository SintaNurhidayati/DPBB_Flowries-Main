import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/review_service.dart';
import '../../widgets/admin_layout.dart';

class LihatUlasan extends StatefulWidget {
  const LihatUlasan({super.key});

  @override
  State<LihatUlasan> createState() => _LihatUlasanState();
}

class _LihatUlasanState extends State<LihatUlasan> {
  final ReviewService _reviewService = ReviewService();
  String selectedSort = 'terbaru';
  String selectedRating = 'semua';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _reviewService.refreshReviews();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat ulasan: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> getFilteredReviews(
    List<Map<String, dynamic>> reviews,
  ) {
    var filtered = List<Map<String, dynamic>>.from(reviews);

    if (selectedRating != 'semua') {
      final rating = int.tryParse(selectedRating);
      if (rating != null) {
        filtered = filtered.where((r) => r['rating'] == rating).toList();
      }
    }

    if (selectedSort == 'tertinggi') {
      filtered.sort(
        (a, b) => (b['rating'] as num).compareTo(a['rating'] as num),
      );
    } else if (selectedSort == 'terendah') {
      filtered.sort(
        (a, b) => (a['rating'] as num).compareTo(b['rating'] as num),
      );
    } else {
      // terbaru
      filtered.sort(
        (a, b) {
          DateTime dateA;
          DateTime dateB;
          try {
            dateA = a['tanggalUlasan'] is DateTime
                ? a['tanggalUlasan']
                : DateTime.parse(a['tanggalUlasan'] ?? a['createdAt']);
            dateB = b['tanggalUlasan'] is DateTime
                ? b['tanggalUlasan']
                : DateTime.parse(b['tanggalUlasan'] ?? b['createdAt']);
          } catch (e) {
            dateA = DateTime.now();
            dateB = DateTime.now();
          }
          return dateB.compareTo(dateA);
        },
      );
    }

    return filtered;
  }

  void _showDeleteDialog(Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Ulasan?'),
        content: Text(
          'Yakin ingin menghapus ulasan dari ${review['userName'] ?? review['userId']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _reviewService.deleteReview(review['id'].toString());
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

  void _showReplyDialog(Map<String, dynamic> review) {
    final TextEditingController replyController = TextEditingController();
    final bool hasReply = review['reply'] != null && review['reply'].toString().isNotEmpty;
    
    if (hasReply) {
      replyController.text = review['reply'];
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hasReply ? 'Edit Balasan' : 'Balas Ulasan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ulasan dari: ${review['userName'] ?? review['userId']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⭐ ${review['rating']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review['isiUlasan'] ?? review['komentar'] ?? '',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Balasan Admin:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: replyController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tulis balasan untuk ulasan ini...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          if (hasReply)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _reviewService.deleteReply(review['id'].toString());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Balasan berhasil dihapus'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    _loadReviews();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Hapus Balasan', style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () async {
              final replyText = replyController.text.trim();
              if (replyText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Balasan tidak boleh kosong'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              try {
                final adminId = 'admin'; // TODO: Ganti dengan ID admin yang login
                
                if (hasReply) {
                  await _reviewService.updateReply(review['id'].toString(), replyText);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Balasan berhasil diperbarui'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  await _reviewService.addReplyToReview(review['id'].toString(), replyText, adminId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Balasan berhasil ditambahkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                _loadReviews();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
            ),
            child: Text(hasReply ? 'Update Balasan' : 'Kirim Balasan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Lihat Ulasan',
      selectedIndex: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Urutkan:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedSort,
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(Icons.arrow_drop_down),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'terbaru', child: Text('Terbaru')),
                            DropdownMenuItem(value: 'tertinggi', child: Text('Rating Tertinggi')),
                            DropdownMenuItem(value: 'terendah', child: Text('Rating Terendah')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedSort = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter Rating:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['semua', '5', '4', '3', '2', '1'].map(
                            (rating) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  rating == 'semua' ? 'Semua' : '⭐ $rating',
                                  style: TextStyle(
                                    color: selectedRating == rating ? Colors.white : Colors.black87,
                                  ),
                                ),
                                selected: selectedRating == rating,
                                selectedColor: Colors.pink,
                                checkmarkColor: Colors.white,
                                onSelected: (selected) {
                                  setState(() {
                                    selectedRating = rating;
                                  });
                                },
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: _reviewService.reviewsNotifier,
                    builder: (context, reviews, _) {
                      if (reviews.isEmpty) {
                        return const Center(child: Text('Belum ada ulasan'));
                      }

                      final filteredReviews = getFilteredReviews(reviews);

                      if (filteredReviews.isEmpty) {
                        return const Center(
                          child: Text('Tidak ada ulasan dengan filter ini'),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: filteredReviews.length,
                        itemBuilder: (context, index) {
                          final review = filteredReviews[index];
                          
                          String dateStr = '';
                          try {
                            dateStr = review['tanggalUlasan'] != null 
                              ? (review['tanggalUlasan'] is DateTime ? review['tanggalUlasan'].toString() : review['tanggalUlasan'])
                              : review['createdAt'];
                            dateStr = dateStr.split('T')[0].split(' ')[0];
                          } catch(e) {
                            dateStr = 'N/A';
                          }

                          final hasReply = review['reply'] != null && review['reply'].toString().isNotEmpty;
                          final replyDate = hasReply && review['repliedAt'] != null
                              ? (review['repliedAt'] as String).split('T')[0]
                              : '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              review['userName'] ?? review['userId'] ?? 'Unknown User',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    size: 16,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${review['rating']}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Tooltip(
                                          message: hasReply ? 'Edit Balasan' : 'Balas Ulasan',
                                          child: IconButton(
                                            icon: Icon(
                                              hasReply ? Icons.edit : Icons.reply,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () => _showReplyDialog(review),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () => _showDeleteDialog(review),
                                          tooltip: 'Hapus ulasan',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Review Content
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review['isiUlasan'] ?? review['komentar'] ?? '',
                                        style: const TextStyle(fontSize: 14, height: 1.5),
                                      ),
                                      if (review['imageUrl'] != null && review['imageUrl'].toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => Dialog(
                                                  child: Image.memory(
                                                    base64Decode(review['imageUrl']),
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              height: 100,
                                              width: 100,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.grey.shade300),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.memory(
                                                  base64Decode(review['imageUrl']),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                
                                // Reply Section
                                if (hasReply) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    margin: const EdgeInsets.only(left: 20),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.pink[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.pink[100]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.admin_panel_settings, size: 16, color: Colors.pink[600]),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Balasan Admin',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Colors.pink[600],
                                              ),
                                            ),
                                            const Spacer(),
                                            if (replyDate.isNotEmpty)
                                              Text(
                                                replyDate,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          review['reply'],
                                          style: const TextStyle(fontSize: 13, height: 1.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(review['userName'] ?? review['userId'] ?? 'Unknown User'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: List.generate(
                                                    5,
                                                    (i) => Icon(
                                                      Icons.star,
                                                      size: 20,
                                                      color: i < (review['rating'] as num) ? Colors.amber : Colors.grey[300],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(review['isiUlasan'] ?? review['komentar'] ?? '', style: const TextStyle(height: 1.5)),
                                                if (hasReply) ...[
                                                  const SizedBox(height: 16),
                                                  const Divider(),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.admin_panel_settings, size: 16, color: Colors.pink[600]),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Balasan Admin:',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.pink[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(review['reply']),
                                                  if (replyDate.isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 8),
                                                      child: Text(
                                                        'Dibalas: $replyDate',
                                                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                                      ),
                                                    ),
                                                ],
                                                const SizedBox(height: 16),
                                                Text('Tanggal Ulasan: $dateStr', style: const TextStyle(color: Colors.grey)),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Tutup'),
                                              )
                                            ],
                                          )
                                        );
                                      },
                                      icon: const Icon(Icons.visibility, size: 18),
                                      label: const Text('Lihat Lengkap'),
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