import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
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

  bool _hasDisplayableHtml(String? value) {
    if (value == null) return false;
    final normalized = value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .trim();
    return normalized.isNotEmpty;
  }

  bool _looksLikeHtml(String value) {
    return RegExp(r'<[a-z][\s\S]*>', caseSensitive: false).hasMatch(value);
  }

  String _extractTermsContent(Map<String, dynamic>? data) {
    final rawContent = data?['content'];
    if (rawContent is String) {
      return rawContent.trim();
    }

    if (rawContent is! List) {
      return '';
    }

    final buffer = StringBuffer();
    for (final item in rawContent) {
      if (item is! Map) continue;

      final map = item.map((key, value) => MapEntry(key.toString(), value));
      final type = map['type']?.toString().trim().toLowerCase() ?? '';
      final text = (map['text'] ?? map['content'] ?? map['value'] ?? '')
          .toString()
          .trim();
      if (text.isEmpty) continue;

      if (type == 'heading') {
        final rawLevel = int.tryParse('${map['level'] ?? ''}') ?? 1;
        final level = rawLevel.clamp(1, 4);
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.write('<h$level>$text</h$level>');
        continue;
      }

      if (type == 'paragraph') {
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.write('<p>$text</p>');
        continue;
      }

      if (buffer.isNotEmpty) {
        buffer.writeln();
        buffer.writeln();
      }
      buffer.write(text);
    }

    return buffer.toString().trim();
  }

  Future<void> _openTermsAndConditions() async {
    final response = await ApiService.instance.getStaticOrderTermsAndConditions();
    if (!mounted) return;

    final terms = _extractTermsContent(response.data);
    if (!response.success || terms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ?? 'Terms & Conditions are not available.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProductTermsAndConditionsScreen(
          title:
              response.data?['title']?.toString().trim().isNotEmpty == true
                  ? response.data!['title'].toString().trim()
                  : 'Terms & Conditions',
          productName:
              (widget.product.warehouseProduct?.productName ??
                      widget.product.metaTitle ??
                      'Product')
                  .trim(),
          termsAndConditions: terms,
        ),
      ),
    );
  }

  Widget _buildHtmlSection({
    required String title,
    required String? html,
  }) {
    if (!_hasDisplayableHtml(html)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Html(
          data: html ?? '',
          style: {
            'html': Style(
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
              fontSize: FontSize(15),
              lineHeight: const LineHeight(1.6),
              color: Colors.black87,
            ),
            'body': Style(
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
              fontSize: FontSize(15),
              lineHeight: const LineHeight(1.6),
              color: Colors.black87,
            ),
            'p': Style(
              margin: Margins.only(bottom: 12),
              fontSize: FontSize(15),
              lineHeight: const LineHeight(1.6),
            ),
            'br': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
            'ul': Style(
              margin: Margins.only(bottom: 12, left: 18),
              padding: HtmlPaddings.zero,
            ),
            'ol': Style(
              margin: Margins.only(bottom: 12, left: 18),
              padding: HtmlPaddings.zero,
            ),
            'li': Style(
              margin: Margins.only(bottom: 6),
              fontSize: FontSize(15),
              lineHeight: const LineHeight(1.5),
            ),
            'strong': Style(fontWeight: FontWeight.w600),
          },
        ),
        const SizedBox(height: 16),
      ],
    );
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: outOfStock
                            ? null
                            : () =>
                                _buyNow(context, title: title, unitPrice: unitPrice),
                        child: const Text(
                          'Buy Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
              _buildHtmlSection(
                title: 'About',
                html: wp?.shortDescription ?? _product.ecommerceShortDescription,
              ),
              _buildHtmlSection(
                title: 'Description',
                html: wp?.fullDescription ?? _product.ecommerceFullDescription,
              ),
              _buildHtmlSection(
                title: 'Technical Specs',
                html: wp?.technicalSpecification ?? _product.ecommerceTechnicalSpecification,
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.grey.shade700,
                  ),
                  children: [
                    const TextSpan(
                      text: 'By proceeding, you agree to our ',
                    ),
                    TextSpan(
                      text: 'Terms & Condition',
                      style: const TextStyle(
                        color: Color(0xFF1F8B00),
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _openTermsAndConditions,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductTermsAndConditionsScreen extends StatelessWidget {
  const _ProductTermsAndConditionsScreen({
    required this.title,
    required this.productName,
    required this.termsAndConditions,
  });

  final String title;
  final String productName;
  final String termsAndConditions;

  bool _hasDisplayableHtml(String value) {
    final normalized = value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .trim();
    return normalized.isNotEmpty;
  }

  bool _looksLikeHtml(String value) {
    return RegExp(r'<[a-z][\s\S]*>', caseSensitive: false).hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final hasHtml = _looksLikeHtml(termsAndConditions) &&
        _hasDisplayableHtml(termsAndConditions);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F8B00),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName.isEmpty ? 'Product' : productName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please review the order terms before continuing with your purchase.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: hasHtml
                  ? Html(
                      data: termsAndConditions,
                      style: {
                        'html': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(15),
                          lineHeight: const LineHeight(1.6),
                          color: Colors.black87,
                        ),
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(15),
                          lineHeight: const LineHeight(1.6),
                          color: Colors.black87,
                        ),
                        'h1': Style(
                          margin: Margins.only(bottom: 12),
                          fontSize: FontSize(18),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        'h2': Style(
                          margin: Margins.only(top: 12, bottom: 10),
                          fontSize: FontSize(17),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F8B00),
                        ),
                        'h3': Style(
                          margin: Margins.only(top: 10, bottom: 8),
                          fontSize: FontSize(16),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        'p': Style(
                          margin: Margins.only(bottom: 14),
                          fontSize: FontSize(15),
                          lineHeight: const LineHeight(1.7),
                          color: Colors.black87,
                        ),
                        'ul': Style(
                          margin: Margins.only(bottom: 14, left: 18),
                          padding: HtmlPaddings.zero,
                        ),
                        'ol': Style(
                          margin: Margins.only(bottom: 14, left: 18),
                          padding: HtmlPaddings.zero,
                        ),
                        'li': Style(
                          margin: Margins.only(bottom: 8),
                          fontSize: FontSize(15),
                          lineHeight: const LineHeight(1.6),
                        ),
                      },
                    )
                  : Text(
                      termsAndConditions.trim(),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: Colors.black87,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
