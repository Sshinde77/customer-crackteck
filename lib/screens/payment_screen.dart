import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

import '../constants/core/secure_storage_service.dart';
import '../models/product_model.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final ProductData? product;
  final int quantity;
  final double? unitPrice;
  final double? totalAmount;

  const PaymentScreen({
    super.key,
    this.product,
    this.quantity = 1,
    this.unitPrice,
    this.totalAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int selectedIndex = -1;
  bool _isSubmitting = false;

  static const String _imageBaseUrl = 'https://crackteck.co.in/';

  String _normalizeImageUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    if (trimmed.startsWith('/')) return '$_imageBaseUrl${trimmed.substring(1)}';
    return '$_imageBaseUrl$trimmed';
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  double? _tryParseAmount(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  double? get _resolvedUnitPrice {
    if (widget.unitPrice != null) return widget.unitPrice;
    return _tryParseAmount(widget.product?.warehouseProduct?.finalPrice);
  }

  double? get _resolvedTotal {
    if (widget.totalAmount != null) return widget.totalAmount;
    final unit = _resolvedUnitPrice;
    if (unit == null) return null;
    return unit * widget.quantity;
  }

  String get _resolvedTitle {
    final wp = widget.product?.warehouseProduct;
    return (wp?.productName ?? widget.product?.metaTitle ?? 'Payment').trim();
  }

  String get _resolvedImageUrl {
    final raw = widget.product?.warehouseProduct?.mainProductImage;
    if (raw == null || raw.trim().isEmpty) return '';
    return _normalizeImageUrl(raw);
  }

  Future<void> _handleDone() async {
    if (_isSubmitting) return;

    if (selectedIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Only call buy-product API when this screen was opened from product purchase flow.
    if (widget.product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment Successful'),
          backgroundColor: Color(0xFF1F8B00),
        ),
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.hometab,
        (route) => false,
      );
      return;
    }

    final productId = widget.product?.id;
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing product id'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final int quantity = widget.quantity < 1 ? 1 : widget.quantity;
    final int roleId = (await SecureStorageService.getRoleId()) ?? 4;
    final int? customerId = await SecureStorageService.getUserId();

    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await ApiService.instance.buyProduct(
        productId: productId,
        roleId: roleId,
        quantity: quantity,
        customerId: customerId,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Product purchased successfully'),
            backgroundColor: const Color(0xFF1F8B00),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.hometab,
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to buy product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _resolvedTotal;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,

        /// AppBar
        appBar: AppBar(
          backgroundColor: const Color(0xFF1F8B00),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Payment',
            style: TextStyle(color: Colors.white),
          ),
        ),

        /// Body
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              if (widget.product != null) ...[
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _resolvedImageUrl.isEmpty
                            ? const Icon(Icons.image, color: Colors.grey)
                            : Image.network(
                                _resolvedImageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _resolvedTitle.isEmpty ? 'Product' : _resolvedTitle,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text('Qty: ${widget.quantity}'),
                                const SizedBox(width: 12),
                                if (_resolvedUnitPrice != null)
                                  Text('Unit: \u20B9 ${_formatAmount(_resolvedUnitPrice!)}'),
                              ],
                            ),
                            if (total != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Total: \u20B9 ${_formatAmount(total)}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              /// Offers
              const Text(
                'Offers',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter Offer Code',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Online
              const Text(
                'Online',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [

                    /// Google Pay
                    _paymentTile(
                      index: 0,
                      icon: Icons.account_balance_wallet,
                      title: 'Google Pay',
                      amount: '₹ 2,500',
                    ),

                    const Divider(height: 1),

                    /// PhonePe
                    _paymentTile(
                      index: 1,
                      icon: Icons.payment,
                      title: 'PhonePe',
                      amount: '₹ 2,500',
                    ),

                    const Divider(height: 1),

                    /// Add new UPI
                    ListTile(
                      leading: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.green,
                      ),
                      title: const Text('Add New UPI ID'),
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const Spacer(),

              /// Done Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F8B00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _handleDone,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Payment Tile Widget
  Widget _paymentTile({
    required int index,
    required IconData icon,
    required String title,
    required String amount,
  }) {
    final total = _resolvedTotal;
    final String resolvedAmount =
        total != null ? '\u20B9 ${_formatAmount(total)}' : amount;

    return ListTile(
      leading: Icon(icon, size: 28),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            resolvedAmount,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Checkbox(
            value: selectedIndex == index,
            onChanged: (val) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),
        ],
      ),
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }
}
