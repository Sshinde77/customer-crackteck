import 'package:flutter/material.dart';

class ProductScreen extends StatelessWidget {
  final String? initialCategory;

  const ProductScreen({super.key, this.initialCategory});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive grid columns
    int crossAxisCount = 3;
    if (screenWidth < 360) {
      crossAxisCount = 2;
    } else if (screenWidth > 600) {
      crossAxisCount = 5;
    }

    // Filter products if a category is provided
    final List<Product> filteredProducts = initialCategory != null && initialCategory != 'Other'
        ? _products.where((p) => p.category.toLowerCase() == initialCategory!.toLowerCase()).toList()
        : _products;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,

        /// APP BAR
        appBar: AppBar(
          backgroundColor: const Color(0xFF1F8B00),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            initialCategory ?? 'Product',
            style: const TextStyle(color: Colors.white),
          ),
        ),

        body: Column(
          children: [

            /// SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// PRODUCT GRID
            Expanded(
              child: filteredProducts.isEmpty
                  ? const Center(child: Text('No products found in this category'))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredProducts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75, 
                      ),
                      itemBuilder: (context, index) {
                        return _productCard(filteredProducts[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// PRODUCT CARD (UI SAME AS IMAGE)
  Widget _productCard(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// IMAGE PLACEHOLDER
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Image.asset(
                product.image,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        /// PRICE
        Text(
          product.price,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 2),

        /// NAME
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            height: 1.3,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

/// ----------------------------
/// PRODUCT MODEL
/// ----------------------------
class Product {
  final String name;
  final String price;
  final String category;
  final String image;

  Product({
    required this.name,
    required this.price,
    required this.category,
    required this.image,
  });
}

/// ----------------------------
/// STATIC PRODUCT LIST
/// ----------------------------
final List<Product> _products = [
  // Bio metric
  Product(
    name: 'ZKTeco K40 Fingerprint Terminal',
    price: '₹ 4,500',
    category: 'Bio Metric',
    image: 'assests/Bio_metric.png',
  ),
  Product(
    name: 'Realtime T52 Face & Fingerprint',
    price: '₹ 5,200',
    category: 'Bio Metric',
    image: 'assests/Bio_metric.png',
  ),
  // CCTV
  Product(
    name: 'Hikvision 2MP Night Vision Camera',
    price: '₹ 1,850',
    category: 'CCTV',
    image: 'assests/cctv.png',
  ),
  Product(
    name: 'CP Plus 4MP Full HD Dome Camera',
    price: '₹ 2,400',
    category: 'CCTV',
    image: 'assests/cctv.png',
  ),
  // Computer
  Product(
    name: 'HP Desktop PC i5 12th Gen',
    price: '₹ 35,000',
    category: 'Computer',
    image: 'assests/computer.png',
  ),
  Product(
    name: 'Dell OptiPlex Business Desktop',
    price: '₹ 42,000',
    category: 'Computer',
    image: 'assests/computer.png',
  ),
  // EPBX
  Product(
    name: 'Panasonic KX-TES824 Hybrid System',
    price: '₹ 12,500',
    category: 'EPBX',
    image: 'assests/epbx.png',
  ),
  Product(
    name: 'Matrix ETERNITY PE SOHO PBX',
    price: '₹ 15,800',
    category: 'EPBX',
    image: 'assests/epbx.png',
  ),
  // Laptop
  Product(
    name: 'Apple MacBook Air M2 chip',
    price: '₹ 89,900',
    category: 'Laptop',
    image: 'assests/laptop.png',
  ),
  Product(
    name: 'Dell Vostro 3420 Business Laptop',
    price: '₹ 45,600',
    category: 'Laptop',
    image: 'assests/laptop.png',
  ),
  // Printer
  Product(
    name: 'Epson EcoTank L3210 Ink Tank',
    price: '₹ 13,200',
    category: 'Printer',
    image: 'assests/printer.png',
  ),
  Product(
    name: 'HP LaserJet Pro M126nw Printer',
    price: '₹ 18,500',
    category: 'Printer',
    image: 'assests/printer.png',
  ),
  // Router
  Product(
    name: 'TP-Link Archer C6 AC1200 Router',
    price: '₹ 2,499',
    category: 'Router',
    image: 'assests/router.png',
  ),
  Product(
    name: 'D-Link DIR-825 Dual Band Router',
    price: '₹ 2,199',
    category: 'Router',
    image: 'assests/router.png',
  ),
  // Server
  Product(
    name: 'Dell PowerEdge R750 Rack Server',
    price: '₹ 4,50,000',
    category: 'Server',
    image: 'assests/server.png',
  ),
  Product(
    name: 'HP ProLiant DL380 Gen10 Server',
    price: '₹ 3,80,000',
    category: 'Server',
    image: 'assests/server.png',
  ),
];
