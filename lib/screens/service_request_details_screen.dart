import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';

class ServiceRequestDetailsScreen extends StatelessWidget {
  const ServiceRequestDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Service Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProductCard(
            context,
            title: 'Windows Update Issues',
            description: 'Visit charge of Rs 159 waived in final bill; spare part/repair cost extra.',
            price: '500',
            imageUrl: 'https://m.media-amazon.com/images/I/71rS87X1fEL._AC_SL1500_.jpg',
          ),
          _buildProductCard(
            context,
            title: 'Laptop Screen Repair',
            description: 'Genuine screen replacement with warranty. Labor charges included.',
            price: '2,500',
            imageUrl: 'https://m.media-amazon.com/images/I/61U7B8L4WFL._AC_SL1200_.jpg',
          ),
          _buildProductCard(
            context,
            title: 'Battery Replacement',
            description: 'Original high-capacity battery. 6 months replacement warranty.',
            price: '1,200',
            imageUrl: 'https://m.media-amazon.com/images/I/61V9Yv+Y8LL._AC_SL1500_.jpg',
          ),
          _buildProductCard(
            context,
            title: 'RAM Upgrade',
            description: 'High-speed DDR4/DDR5 RAM. Performance boost guaranteed.',
            price: '1,800',
            imageUrl: 'https://m.media-amazon.com/images/I/61S8n-iW7hL._AC_SL1200_.jpg',
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context, {
    required String title,
    required String description,
    required String price,
    required String imageUrl,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.workProgressTracker,
          arguments: {
            'productName': title,
            'price': price,
            'imageUrl': imageUrl,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container
            Container(
              width: 90,
              height: 90,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Starts at ',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '₹ $price',
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: ' (with GST)',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
