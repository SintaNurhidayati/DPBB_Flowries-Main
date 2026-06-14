import 'dart:convert';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String? imageString;
  final BoxFit fit;

  const ProductImage({
    super.key,
    this.imageString,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    String imageToUse = imageString ?? 'assets/images/produk_1.png';
    
    // Fix existing seeded data that used the wrong filename
    if (imageToUse == 'assets/images/flower1.png') imageToUse = 'assets/images/produk_1.png';
    if (imageToUse == 'assets/images/flower2.png') imageToUse = 'assets/images/produk_2.png';

    // If it's a very long string, it's likely base64
    if (imageToUse.length > 200 && !imageToUse.startsWith('assets/')) {
      try {
        return Image.memory(
          base64Decode(imageToUse),
          fit: fit,
        );
      } catch (e) {
        return Image.asset('assets/images/produk_1.png', fit: fit);
      }
    }

    return Image.asset(
      imageToUse,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
         return Icon(Icons.broken_image, size: 50, color: Colors.grey.shade400);
      },
    );
  }
}
