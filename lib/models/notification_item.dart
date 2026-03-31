class NotificationItem {
  final int? id;
  final String title;
  final String message;
  final int? orderId;
  final double? amount;
  final String createdAt;

  NotificationItem({
    this.id,
    required this.title,
    required this.message,
    this.orderId,
    this.amount,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final title = _firstText(json, const [
      'title',
      'subject',
      'notification_title',
      'name',
    ]);
    final message = _firstText(json, const [
      'message',
      'body',
      'description',
      'notification_message',
      'content',
    ]);
    final createdAt = _firstText(json, const [
      'created_at',
      'createdAt',
      'date',
      'timestamp',
    ]);

    return NotificationItem(
      id: _asInt(_firstValue(json, const ['id'])),
      title: title.isEmpty ? 'Notification' : title,
      message: message.isEmpty ? 'No message available' : message,
      orderId: _asInt(_firstValue(json, const ['order_id', 'orderId'])),
      amount: _asDouble(_firstValue(json, const ['amount', 'price', 'total'])),
      createdAt: createdAt,
    );
  }

  static String _firstText(Map<String, dynamic> json, List<String> keys) {
    final value = _firstValue(json, keys);
    final text = value?.toString().trim() ?? '';
    return text;
  }

  static dynamic _firstValue(dynamic source, List<String> keys) {
    if (source is Map) {
      for (final key in keys) {
        if (source.containsKey(key)) {
          final value = source[key];
          final text = value?.toString().trim() ?? '';
          if (text.isNotEmpty) {
            return value;
          }
        }
      }

      for (final value in source.values) {
        final nested = _firstValue(value, keys);
        final text = nested?.toString().trim() ?? '';
        if (text.isNotEmpty) {
          return nested;
        }
      }
    } else if (source is List) {
      for (final value in source) {
        final nested = _firstValue(value, keys);
        final text = nested?.toString().trim() ?? '';
        if (text.isNotEmpty) {
          return nested;
        }
      }
    }
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString().trim());
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value == null) return null;
    final cleaned = value.toString().trim().replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
