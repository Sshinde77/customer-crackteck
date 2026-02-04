import 'package:flutter/material.dart';
import '../models/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductData product;

  const ProductDetailScreen({super.key, required this.product});

  static const String _imageBaseUrl = 'https://crackteck.co.in/';

  String _normalizeImageUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    if (trimmed.startsWith('/')) return '$_imageBaseUrl${trimmed.substring(1)}';
    return '$_imageBaseUrl$trimmed';
  }

  @override
  Widget build(BuildContext context) {
    final wp = product.warehouseProduct;

    final List<String> images = <String>[
      if ((wp?.mainProductImage ?? '').trim().isNotEmpty) _normalizeImageUrl(wp!.mainProductImage!),
      ...?wp?.additionalProductImages
          ?.where((s) => s.trim().isNotEmpty)
          .map(_normalizeImageUrl),
    ].toSet().toList();

    final String title = (wp?.productName ?? product.metaTitle ?? 'Product').trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F8B00),
        elevation: 0,
        title: Text(
          title.isEmpty ? 'Product' : title,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (images.isEmpty)
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 56, color: Colors.grey),
                  ),
                )
              else
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.network(
                          images[index],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                title.isEmpty ? 'Unnamed Product' : title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Rs ${wp?.finalPrice ?? '0'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  if ((wp?.stockStatus ?? '').trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        (wp?.stockStatus ?? '').trim(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if ((wp?.shortDescription ?? product.ecommerceShortDescription ?? '').trim().isNotEmpty) ...[
                const Text('About', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  (wp?.shortDescription ?? product.ecommerceShortDescription ?? '').trim(),
                  style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.black87),
                ),
                const SizedBox(height: 16),
              ],
              if ((wp?.fullDescription ?? product.ecommerceFullDescription ?? '').trim().isNotEmpty) ...[
                const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  (wp?.fullDescription ?? product.ecommerceFullDescription ?? '').trim(),
                  style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.black87),
                ),
                const SizedBox(height: 16),
              ],
              if ((wp?.technicalSpecification ?? product.ecommerceTechnicalSpecification ?? '').trim().isNotEmpty) ...[
                const Text('Technical Specs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  (wp?.technicalSpecification ?? product.ecommerceTechnicalSpecification ?? '').trim(),
                  style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.black87),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

