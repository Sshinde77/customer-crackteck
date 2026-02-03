import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';

class ProductScreen extends StatefulWidget {
  final String? initialCategory;

  const ProductScreen({super.key, this.initialCategory});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ProductData> _products = [];
  List<ProductData> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Role ID 4 as per your request
      final response = await ApiService.instance.getProducts(roleId: 4);
      
      if (response.success && response.data != null) {
        setState(() {
          _products = response.data!.products ?? [];
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load products';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((p) {
        final nameMatches = (p.warehouseProduct?.productName ?? '').toLowerCase().contains(query);
        final categoryFilter = widget.initialCategory?.trim();
        if (categoryFilter == null || categoryFilter.isEmpty) {
          return nameMatches;
        }
        final productCategory = (p.categoryName ?? '').toLowerCase();
        final categoryMatches = productCategory.contains(categoryFilter.toLowerCase());
        return nameMatches && categoryMatches;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,

        /// APP BAR
        appBar: AppBar(
          backgroundColor: const Color(0xFF1F8B00),
          elevation: 0,

          title: Text(
            widget.initialCategory ?? 'Product',
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
                        controller: _searchController,
                        onChanged: (value) => _applyFilters(),
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _fetchProducts,
                                child: const Text('Retry'),
                              )
                            ],
                          ),
                        )
                      : _filteredProducts.isEmpty
                          ? const Center(child: Text('No products found'))
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredProducts.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.68, // Slightly taller to fit 2 lines comfortably
                              ),
                              itemBuilder: (context, index) {
                                return _productCard(_filteredProducts[index]);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  /// PRODUCT CARD
  Widget _productCard(ProductData product) {
    final wp = product.warehouseProduct;
    final String imageUrl = wp?.mainProductImage != null 
        ? "https://crackteck.co.in/${wp!.mainProductImage}"
        : "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// IMAGE - Fixed square container
        AspectRatio(
          aspectRatio: 1, 
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
                    )
                  : const Icon(Icons.image, color: Colors.grey, size: 40),
            ),
          ),
        ),

        const SizedBox(height: 8),

        /// PRICE
        Text(
          "₹ ${wp?.finalPrice ?? '0'}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 2),

        /// NAME - Fixed height for 2 lines to keep layout uniform
        SizedBox(
          height: 32, // Height enough for 2 lines of text
          child: Text(
            wp?.productName ?? 'Unnamed Product',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.2,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
