import 'package:flutter/material.dart';

import '../models/order_model.dart';

const Map<String, String> orderStatusMapping = <String, String>{
  'pending': 'Confirm',
  'admin_approved': 'Confirm',
  'assigned_delivery_man': 'Confirm',
  'order_accepted': 'Shipping',
  'product_taken': 'On the Way',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
  'returned': 'Returned',
};

String normalizeOrderStatus(String? status) {
  return (status ?? '').trim().toLowerCase();
}

String getOrderDisplayStatus(String? status) {
  final normalized = normalizeOrderStatus(status);
  if (normalized.isEmpty) return '-';
  return orderStatusMapping[normalized] ?? _toTitleCase(normalized);
}

Color getOrderStatusColor(String? status) {
  switch (getOrderDisplayStatus(status).toLowerCase()) {
    case 'confirm':
      return Colors.blue;
    case 'shipping':
      return Colors.orange;
    case 'on the way':
      return Colors.purple;
    case 'delivered':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    case 'returned':
      return Colors.grey;
    default:
      return Colors.blueGrey;
  }
}

bool canCancelOrder(String? status) {
  const cancellableStatuses = <String>{
    'pending',
    'admin_approved',
    'assigned_delivery_man',
  };
  return cancellableStatuses.contains(normalizeOrderStatus(status));
}

bool canReplaceOrder(OrderModel? order, {DateTime? now}) {
  if (normalizeOrderStatus(order?.status ?? order?.orderStatus) != 'delivered') {
    return false;
  }

  final deliveredAt = parseOrderDate(order?.deliveredAt);
  if (deliveredAt == null) {
    return false;
  }

  final currentTime = now ?? DateTime.now();
  if (deliveredAt.isAfter(currentTime)) {
    return false;
  }

  return currentTime.difference(deliveredAt).inDays <= 7;
}

DateTime? parseOrderDate(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

String _toTitleCase(String value) {
  return value
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
