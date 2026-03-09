import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'payment_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductData product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const String _imageBaseUrl = 'https://crackteck.co.in/';

  bool _isLoading = false;
  String? _errorMessage;
  late ProductData _product = widget.product;

  String _normalizeImageUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    if (trimmed.startsWith('/')) return '$_imageBaseUrl${trimmed.substring(1)}';
    return '$_imageBaseUrl$trimmed';
  }

  int _quantity = 1;

  int? _readStockQuantity(WarehouseProduct? wp) {
    final qty = wp?.stockQuantity;
    if (qty == null) return null;
    if (qty < 0) return 0;
    return qty;
  }

  double? _tryParseAmount(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  ProductData _mergeProducts(ProductData base, ProductData fetched) {
    // Keep list payload values (like warehouse_product) when the single-product API doesn't return them.
    return ProductData(
      id: fetched.id ?? base.id,
      warehouseProductId: fetched.warehouseProductId ?? base.warehouseProductId,
      sku: fetched.sku ?? base.sku,
      metaTitle: fetched.metaTitle ?? base.metaTitle,
      metaDescription: fetched.metaDescription ?? base.metaDescription,
      metaKeywords: fetched.metaKeywords ?? base.metaKeywords,
      metaProductUrlSlug: fetched.metaProductUrlSlug ?? base.metaProductUrlSlug,
      ecommerceShortDescription: fetched.ecommerceShortDescription ?? base.ecommerceShortDescription,
      ecommerceFullDescription: fetched.ecommerceFullDescription ?? base.ecommerceFullDescription,
      ecommerceTechnicalSpecification: fetched.ecommerceTechnicalSpecification ?? base.ecommerceTechnicalSpecification,
      minOrderQty: fetched.minOrderQty ?? base.minOrderQty,
      maxOrderQty: fetched.maxOrderQty ?? base.maxOrderQty,
      ecommerceStatus: fetched.ecommerceStatus ?? base.ecommerceStatus,
      createdAt: fetched.createdAt ?? base.createdAt,
      updatedAt: fetched.updatedAt ?? base.updatedAt,
      categoryId: fetched.categoryId ?? base.categoryId,
      categoryName: fetched.categoryName ?? base.categoryName,
      categorySlug: fetched.categorySlug ?? base.categorySlug,
      warehouseProduct: fetched.warehouseProduct ?? base.warehouseProduct,
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchProductDetail();
  }

  Future<void> _fetchProductDetail() async {
    final productId = widget.product.id;
    if (productId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Keeping roleId=4 to match your existing product list call.
      final response = await ApiService.instance.getProductDetail(productId: productId, roleId: 4);

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _product = _mergeProducts(_product, response.data!);
          _isLoading = false;
        });

        // Clamp quantity to min/max if provided by the API.
        final minQty = _product.minOrderQty ?? 1;
        final maxQty = _product.maxOrderQty;
        setState(() {
          if (_quantity < minQty) _quantity = minQty;
          if (maxQty != null && _quantity > maxQty) _quantity = maxQty;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load product';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  Future<void> _buyNow(BuildContext context, {required String title, required double? unitPrice}) async {
    final total = unitPrice != null ? unitPrice * _quantity : null;

    final bool confirmed =
        (await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Confirm Purchase'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title.isEmpty ? 'Product' : title),
                      const SizedBox(height: 8),
                      Text('Quantity: $_quantity'),
                      if (total != null) ...[
                        const SizedBox(height: 6),
                        Text('Total: Rs ${_formatAmount(total)}'),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F8B00)),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Proceed', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              },
            )) ==
            true;

    if (!confirmed || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          product: _product,
          quantity: _quantity,
          unitPrice: unitPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wp = _product.warehouseProduct;

    final List<String> images = <String>{
      if ((wp?.mainProductImage ?? '').trim().isNotEmpty) _normalizeImageUrl(wp!.mainProductImage!),
      ...?wp?.additionalProductImages
          .where((s) => s.trim().isNotEmpty)
          .map(_normalizeImageUrl),
    }.toList();

    final String title = (wp?.productName ?? _product.metaTitle ?? 'Product').trim();
    final int? stockQty = _readStockQuantity(wp);
    final bool outOfStock = stockQty != null && stockQty <= 0;
    final int minQty = _product.minOrderQty ?? 1;
    final int? apiMaxQty = _product.maxOrderQty;
    final int resolvedMaxQty = (apiMaxQty != null && apiMaxQty < minQty) ? minQty : (apiMaxQty ?? stockQty ?? 99);
    final int maxQty = outOfStock ? minQty : resolvedMaxQty;
    final double? unitPrice = _tryParseAmount(wp?.finalPrice);

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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black12)),
          ),
          child: Row(
            children: [
              Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                  color: outOfStock ? Colors.grey.shade100 : Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Decrease quantity',
                      onPressed: (!outOfStock && _quantity > minQty)
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(
                      width: 38,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Increase quantity',
                      onPressed: (!outOfStock && _quantity < maxQty)
                          ? () => setState(() => _quantity++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F8B00),
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: outOfStock
                        ? null
                        : () => _buyNow(context, title: title, unitPrice: unitPrice),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading) ...[
                const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: 12),
              ],
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: _fetchProductDetail,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
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
              if ((wp?.shortDescription ?? _product.ecommerceShortDescription ?? '').trim().isNotEmpty) ...[
                const Text('About', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  (wp?.shortDescription ?? _product.ecommerceShortDescription ?? '').trim(),
                  style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.black87),
                ),
                const SizedBox(height: 16),
              ],
              if ((wp?.fullDescription ?? _product.ecommerceFullDescription ?? '').trim().isNotEmpty) ...[
                const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  (wp?.fullDescription ?? _product.ecommerceFullDescription ?? '').trim(),
                  style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.black87),
                ),
                const SizedBox(height: 16),
              ],
              if ((wp?.technicalSpecification ?? _product.ecommerceTechnicalSpecification ?? '').trim().isNotEmpty) ...[
                const Text('Technical Specs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  (wp?.technicalSpecification ?? _product.ecommerceTechnicalSpecification ?? '').trim(),
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
