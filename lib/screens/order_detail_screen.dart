import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../utils/order_status_utils.dart';
import '../widgets/order_status_badge.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final int? orderItemId;
  final int? productId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.orderItemId,
    this.productId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  static const String _imageBaseUrl = 'https://crackteck.co.in/';

  bool _isLoading = true;
  bool _isCancelling = false;
  String? _errorMessage;
  OrderModel? _order;
  OrderItemModel? _selectedItem;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  String _normalizeImageUrl(String? raw) {
    final trimmed = (raw ?? '').trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    if (trimmed.startsWith('/')) return '$_imageBaseUrl${trimmed.substring(1)}';
    return '$_imageBaseUrl$trimmed';
  }

  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final int roleId = (await SecureStorageService.getRoleId()) ?? AppStrings.roleId;
      final int? customerId = await SecureStorageService.getUserId();

      if (customerId == null) {
        setState(() {
          _errorMessage = 'Customer id missing. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.instance.getOrderDetail(
        roleId: roleId,
        customerId: customerId,
        orderId: widget.orderId,
      );

      if (!response.success || response.data == null) {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load order details';
          _isLoading = false;
        });
        return;
      }

      final order = response.data!;
      setState(() {
        _order = order;
        _selectedItem = _resolveSelectedItem(order);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  OrderItemModel? _resolveSelectedItem(OrderModel order) {
    final items = order.items ?? const <OrderItemModel>[];
    if (items.isEmpty) return null;

    if (widget.orderItemId != null) {
      for (final item in items) {
        if (item.id == widget.orderItemId) return item;
      }
    }

    if (widget.productId != null) {
      for (final item in items) {
        if (item.productId == widget.productId || item.product?.id == widget.productId) {
          return item;
        }
      }
    }

    return items.first;
  }

  String _safeText(String? value, {String fallback = '—'}) {
    final text = (value ?? '').trim();
    return text.isEmpty ? fallback : text;
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool boldValue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontSize: 14,
                fontWeight: boldValue ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder() async {
    final orderId = _order?.id;
    if (orderId == null || _isCancelling) {
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Order'),
          content: const Text('Are you sure you want to cancel this order?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) {
      return;
    }

    setState(() {
      _isCancelling = true;
    });

    try {
      final int roleId = (await SecureStorageService.getRoleId()) ?? AppStrings.roleId;
      final int? customerId = await SecureStorageService.getUserId();

      if (customerId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer id missing. Please login again.')),
        );
        return;
      }

      final response = await ApiService.instance.cancelOrder(
        orderId: orderId,
        roleId: roleId,
        userId: customerId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ??
                (response.success ? 'Order cancelled successfully' : 'Failed to cancel order'),
          ),
          backgroundColor: response.success ? Colors.green : Colors.red,
        ),
      );

      if (response.success) {
        await _fetchOrderDetails();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final item = _selectedItem;
    final productName = _safeText(item?.product?.productName, fallback: 'Product');
    final imageUrl = _normalizeImageUrl(item?.product?.mainProductImage);
    final paymentStatus = _safeText(order?.paymentStatus);
    final rawOrderStatus = order?.status ?? order?.orderStatus;
    final orderStatus = getOrderDisplayStatus(rawOrderStatus);
    final canCancel = canCancelOrder(rawOrderStatus);
    final canReplace = canReplaceOrder(order);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Detail',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetchOrderDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchOrderDetails,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.image_not_supported, color: Colors.grey),
                                    )
                                  : const Icon(Icons.image, color: Colors.grey, size: 42),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  OrderStatusBadge(status: rawOrderStatus),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Order Number', _safeText(order?.orderNumber)),
                            _buildInfoRow('Order Status', orderStatus),
                            _buildInfoRow('Payment Status', paymentStatus),
                            _buildInfoRow('Quantity', '${item?.quantity ?? order?.totalItems ?? 0}'),
                            _buildInfoRow('Item Price', '₹ ${_safeText(item?.price, fallback: '0')}'),
                            _buildInfoRow('Subtotal', '₹ ${_safeText(order?.subtotal, fallback: '0')}'),
                            _buildInfoRow('Tax Amount', '₹ ${_safeText(order?.taxAmount, fallback: '0')}'),
                            _buildInfoRow('Shipping Charges', '₹ ${_safeText(order?.shippingCharges, fallback: '0')}'),
                            _buildInfoRow(
                              'Grand Total',
                              '₹ ${_safeText(order?.grandTotal ?? order?.subtotal, fallback: '0')}',
                              boldValue: true,
                            ),
                            _buildInfoRow('Ordered On', _safeText(order?.createdAt)),
                          ],
                        ),
                      ),
                      if (canCancel || canReplace) ...[
                        const SizedBox(height: 16),
                        if (canCancel)
                          _buildActionButton(
                            label: 'Cancel Order',
                            backgroundColor: Colors.red,
                            onPressed: _isCancelling ? null : _cancelOrder,
                            isLoading: _isCancelling,
                          ),
                        if (canCancel && canReplace) const SizedBox(height: 12),
                        if (canReplace)
                          _buildActionButton(
                            label: 'Replace Product',
                            backgroundColor: AppColors.primary,
                            onPressed: () {},
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
