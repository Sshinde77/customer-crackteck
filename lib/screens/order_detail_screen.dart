import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/api_response.dart';
import '../models/order_model.dart';
import '../models/reward_coupon_model.dart';
import '../services/api_service.dart';
import '../services/reward_local_service.dart';
import '../utils/order_status_utils.dart';
import '../widgets/claim_reward_button.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/scratch_reward_popup.dart';

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
  bool _isReturning = false;
  bool _isClaimingReward = false;
  String? _errorMessage;
  OrderModel? _order;
  OrderItemModel? _selectedItem;
  RewardCoupon? _reward;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  String get _rewardSourceId {
    final orderId = _order?.id?.toString() ?? widget.orderId.toString();
    final itemId = _selectedItem?.id?.toString();
    return itemId == null ? 'ORD$orderId' : 'ORD$orderId-ITEM$itemId';
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
      final selectedItem = _resolveSelectedItem(order);
      final rawOrderStatus = order.status ?? order.orderStatus;
      final isDelivered = normalizeOrderStatus(rawOrderStatus) == 'delivered';
      final canShowRewardSection =
          isDelivered &&
          order.rewardAvailable == true &&
          order.rewardClaimed == false;
      RewardCoupon? reward;
      if (canShowRewardSection) {
        reward = await RewardLocalService.instance.getRewardBySource(
          sourceType: 'order',
          sourceId: selectedItem?.id != null
              ? 'ORD${widget.orderId}-ITEM${selectedItem!.id}'
              : 'ORD${widget.orderId}',
        );
      }

      if (!mounted) return;
      setState(() {
        _order = order;
        _selectedItem = selectedItem;
        _reward = reward;
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

  String _formatDateTime(String? raw, {bool includeTime = true}) {
    final parsed = parseOrderDate(raw);
    if (parsed == null) {
      return _safeText(raw);
    }

    final day = parsed.day.toString().padLeft(2, '0');
    final month = _monthName(parsed.month);
    final year = parsed.year.toString();
    final date = '$day $month $year';
    if (!includeTime) {
      return date;
    }

    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = parsed.hour >= 12 ? 'PM' : 'AM';
    return '$date, ${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _monthName(int month) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (month < 1 || month > months.length) {
      return '';
    }
    return months[month - 1];
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

  Future<void> _returnOrder() async {
    final orderId = _order?.id;
    if (orderId == null || _isReturning) {
      return;
    }

    final notesController = TextEditingController();

    try {
      final customerNotes = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Return Order'),
            content: TextField(
              controller: notesController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'Enter return reason',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final notes = notesController.text.trim();
                  if (notes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter return notes.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, notes);
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );

      if (customerNotes == null || customerNotes.trim().isEmpty) {
        return;
      }

      setState(() {
        _isReturning = true;
      });

      final int roleId = (await SecureStorageService.getRoleId()) ?? AppStrings.roleId;
      final int? customerId = await SecureStorageService.getUserId();

      if (customerId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer id missing. Please login again.')),
        );
        return;
      }

      final response = await ApiService.instance.returnOrder(
        orderId: orderId,
        roleId: roleId,
        customerId: customerId,
        customerNotes: customerNotes,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ??
                (response.success ? 'Order returned successfully' : 'Failed to return order'),
          ),
          backgroundColor: response.success ? Colors.green : Colors.red,
        ),
      );

      if (response.success) {
        await _fetchOrderDetails();
      }
    } finally {
      notesController.dispose();
      if (mounted) {
        setState(() {
          _isReturning = false;
        });
      }
    }
  }

  Future<void> _downloadInvoice() async {
    final order = _order;
    if (order == null) return;

    if (!order.hasInvoicePdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice is not available yet.')),
      );
      return;
    }

    final fileName = _safeText(
      order.invoiceNumber,
      fallback: order.orderNumber ?? 'invoice',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading $fileName.pdf')),
    );
  }

  Future<void> _openRewardPopup() async {
    if (_isClaimingReward) return;

    RewardCoupon reward;
    if (_reward != null) {
      reward = _reward!;
    } else {
      final int roleId =
          (await SecureStorageService.getRoleId()) ?? AppStrings.roleId;
      final int? customerId = await SecureStorageService.getUserId();

      if (customerId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer id missing. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _isClaimingReward = true;
      });

      try {
        final ApiResponse<Map<String, dynamic>> response =
            await ApiService.instance.claimReward(
              orderId: widget.orderId,
              roleId: roleId,
              userId: customerId,
            );

        if (!mounted) return;

        if (!response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed to claim reward'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        reward = await RewardLocalService.instance.saveReward(
          _buildRewardFromClaimResponse(
            response.data ?? const <String, dynamic>{},
            message: response.message,
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Reward added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isClaimingReward = false;
          });
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _reward = reward;
    });

    final updatedReward = await ScratchRewardPopup.show(
      context,
      reward: reward,
      onRewardUpdated: (value) {
        if (!mounted) return;
        setState(() {
          _reward = value;
        });
      },
    );

    if (!mounted || updatedReward == null) return;
    setState(() {
      _reward = updatedReward;
    });
  }

  RewardCoupon _buildRewardFromClaimResponse(
    Map<String, dynamic> payload, {
    String? message,
  }) {
    final rewardDetails = payload['reward_details'] is Map<String, dynamic>
        ? payload['reward_details'] as Map<String, dynamic>
        : payload['reward_details'] is Map
        ? Map<String, dynamic>.from(payload['reward_details'] as Map)
        : const <String, dynamic>{};
    final couponDetails = payload['coupon_details'] is Map<String, dynamic>
        ? payload['coupon_details'] as Map<String, dynamic>
        : payload['coupon_details'] is Map
        ? Map<String, dynamic>.from(payload['coupon_details'] as Map)
        : const <String, dynamic>{};

    final couponCode = _pickFirstText([
      couponDetails['coupon_code'],
      couponDetails['code'],
      payload['coupon_code'],
    ], fallback: 'REWARD${widget.orderId}');
    final couponTitle = _pickFirstText([
      couponDetails['coupon_name'],
      couponDetails['title'],
      couponDetails['offer_title'],
      payload['title'],
    ], fallback: 'Order Reward');
    final couponDescription = _pickFirstText([
      couponDetails['description'],
      couponDetails['coupon_description'],
      message,
    ], fallback: 'Reward unlocked for this order');
    final validTill = _pickFirstText([
      rewardDetails['reward_end_date'],
      couponDetails['end_date'],
      couponDetails['valid_till'],
    ], fallback: 'Valid for limited time');
    final rewardId = (rewardDetails['reward_id'] ?? payload['reward_id'] ?? widget.orderId)
        .toString();
    final createdAt = _pickFirstText([
      rewardDetails['created_at'],
      payload['created_at'],
      DateTime.now().toIso8601String(),
    ], fallback: DateTime.now().toIso8601String());
    final alreadyScratched = _reward?.scratched == true;

    return RewardCoupon(
      id: 'reward_order_$rewardId',
      title: couponTitle,
      description: couponDescription,
      code: couponCode,
      sourceType: 'order',
      sourceId: _rewardSourceId,
      scratched: alreadyScratched,
      validTill: validTill,
      accentHex: '#1A73E8',
      iconName: 'redeem',
      createdAt: createdAt,
      applicableCategories: const <RewardRuleItem>[],
      applicableBrands: const <RewardRuleItem>[],
      excludedProducts: const <RewardRuleItem>[],
    );
  }

  String _pickFirstText(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return fallback;
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
    final productName = _safeText(
      item?.productName ?? item?.product?.productName,
      fallback: 'Product',
    );
    final imageUrl = _normalizeImageUrl(item?.product?.mainProductImage);
    final paymentStatus = _safeText(order?.paymentStatus);
    final rawOrderStatus = order?.status ?? order?.orderStatus;
    final orderStatus = getOrderDisplayStatus(rawOrderStatus);
    final isDelivered = normalizeOrderStatus(rawOrderStatus) == 'delivered';
    final showRewardSection =
        isDelivered &&
        order?.rewardAvailable == true &&
        order?.rewardClaimed == false;
    final canCancel = canCancelOrder(rawOrderStatus);
    final canReplace = order?.isReturnable == true;

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
      body: SafeArea(
        child: _isLoading
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
                              _buildInfoRow('Item Price', 'Rs ${_safeText(item?.price, fallback: '0')}'),
                              _buildInfoRow('Subtotal', 'Rs ${_safeText(order?.subtotal, fallback: '0')}'),
                              _buildInfoRow('Tax Amount', 'Rs ${_safeText(order?.taxAmount, fallback: '0')}'),
                              _buildInfoRow(
                                'Shipping Charges',
                                'Rs ${_safeText(order?.shippingCharges, fallback: '0')}',
                              ),
                              _buildInfoRow(
                                'Grand Total',
                                'Rs ${_safeText(order?.grandTotal ?? order?.subtotal, fallback: '0')}',
                                boldValue: true,
                              ),
                              _buildInfoRow(
                                'Ordered On',
                                _formatDateTime(order?.createdAt),
                              ),
                              _buildInfoRow(
                                'Expected Delivery Date',
                                _formatDateTime(
                                  order?.expectedDeliveryDate,
                                  includeTime: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showRewardSection) ...[
                          const SizedBox(height: 16),
                          ClaimRewardButton(
                            hasClaimed: _reward != null,
                            onPressed: _openRewardPopup,
                          ),
                        ],
                        if (isDelivered) ...[
                          const SizedBox(height: 16),
                          _buildActionButton(
                            label: 'Download Invoice',
                            backgroundColor: Colors.green,
                            onPressed: _downloadInvoice,
                          ),
                        ],
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
                              label: 'Return Order',
                              backgroundColor: AppColors.primary,
                              onPressed: _isReturning ? null : _returnOrder,
                              isLoading: _isReturning,
                            ),
                        ],
                        // if (_reward != null) ...[
                        //   const SizedBox(height: 16),
                        //   _buildActionButton(
                        //     label: 'View My Rewards',
                        //     backgroundColor: const Color(0xFF1A73E8),
                        //     onPressed: () {
                        //       Navigator.push(
                        //         context,
                        //         MaterialPageRoute(
                        //           builder: (_) => const RewardsScreen(),
                        //         ),
                        //       );
                        //     },
                        //   ),
                        // ],
                      ],
                    ),
                  ),
      ),
    );
  }
}
