import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../widgets/order_status_badge.dart';
import 'order_detail_screen.dart';

class MyProductOrdersScreen extends StatefulWidget {
  const MyProductOrdersScreen({super.key});

  @override
  State<MyProductOrdersScreen> createState() => _MyProductOrdersScreenState();
}

class _MyProductOrdersScreenState extends State<MyProductOrdersScreen> {
  static const String _imageBaseUrl = 'https://crackteck.co.in/';

  bool _isLoading = true;
  String? _errorMessage;
  List<_OrderDisplayItem> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  String _normalizeImageUrl(String? raw) {
    final trimmed = (raw ?? '').trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    if (trimmed.startsWith('/')) return '$_imageBaseUrl${trimmed.substring(1)}';
    return '$_imageBaseUrl$trimmed';
  }

  Future<void> _fetchOrders() async {
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

      final response = await ApiService.instance.getOrderList(
        roleId: roleId,
        customerId: customerId,
      );

      if (response.success) {
        final orders = response.data ?? <OrderModel>[];
        setState(() {
          _items = _flattenOrders(orders);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load orders';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  List<_OrderDisplayItem> _flattenOrders(List<OrderModel> orders) {
    final out = <_OrderDisplayItem>[];
    for (final order in orders) {
      final status = (order.status ?? order.orderStatus ?? '').trim();
      final orderNo = (order.orderNumber ?? '').trim();

      final items = order.items ?? const <OrderItemModel>[];
      if (items.isNotEmpty) {
        for (final item in items) {
          final productName = (item.product?.productName ?? '').trim();
          out.add(
            _OrderDisplayItem(
              title: productName.isNotEmpty ? productName : (orderNo.isNotEmpty ? 'Order $orderNo' : 'Order'),
              imageUrl: _normalizeImageUrl(item.product?.mainProductImage),
              status: status,
              qty: item.quantity ?? order.totalItems ?? 1,
              orderNumber: orderNo,
              orderId: order.id,
              orderItemId: item.id,
              productId: item.productId ?? item.product?.id,
              rewardAvailable: item.rewardAvailable ?? order.rewardAvailable ?? false,
              rewardClaimed: item.rewardClaimed ?? order.rewardClaimed ?? false,
            ),
          );
        }
        continue;
      }

      out.add(
        _OrderDisplayItem(
          title: orderNo.isNotEmpty ? 'Order $orderNo' : 'Order',
          imageUrl: '',
          status: status,
          qty: order.totalItems ?? 0,
          orderNumber: orderNo,
          orderId: order.id,
          orderItemId: null,
          productId: null,
          rewardAvailable: order.rewardAvailable ?? false,
          rewardClaimed: order.rewardClaimed ?? false,
        ),
      );
    }

    return out;
  }

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
          'My Product Orders',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
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
                          onPressed: _fetchOrders,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? const Center(child: Text('No orders found'))
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) => _buildOrderItem(_items[index]),
                      ),
                    ),
    );
  }

  Widget _buildOrderItem(_OrderDisplayItem item) {
    final showRewardSection = item.rewardAvailable && !item.rewardClaimed;
    final status = item.status.isNotEmpty ? item.status : '—';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: item.orderId == null
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(
                    orderId: item.orderId!,
                    orderItemId: item.orderItemId,
                    productId: item.productId,
                  ),
                ),
              );
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, color: Colors.grey),
                    )
                  : const Icon(Icons.image, color: Colors.grey, size: 40),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (item.orderNumber.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.orderNumber,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                  const SizedBox(height: 8),
                  OrderStatusBadge(status: item.status),
                  if (showRewardSection) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.14),
                        ),
                      ),
                      child: Row(
                        children: const <Widget>[
                          Icon(
                            Icons.card_giftcard_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Reward available for this product',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Qty',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  '${item.qty}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDisplayItem {
  final String title;
  final String imageUrl;
  final String status;
  final int qty;
  final String orderNumber;
  final int? orderId;
  final int? orderItemId;
  final int? productId;
  final bool rewardAvailable;
  final bool rewardClaimed;

  _OrderDisplayItem({
    required this.title,
    required this.imageUrl,
    required this.status,
    required this.qty,
    required this.orderNumber,
    required this.orderId,
    required this.orderItemId,
    required this.productId,
    required this.rewardAvailable,
    required this.rewardClaimed,
  });
}
