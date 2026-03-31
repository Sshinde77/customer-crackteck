class ServiceRequestListItem {
  final int? id;
  final String? serviceName;
  final String? serviceType;
  final String? customerName;
  final String? requestId;
  final String? requestDate;
  final String? serviceCode;
  final num? amount;
  final String? status;
  final String? createdAt;
  final Map<String, dynamic> raw;

  const ServiceRequestListItem({
    this.id,
    this.serviceName,
    this.serviceType,
    this.customerName,
    this.requestId,
    this.requestDate,
    this.serviceCode,
    this.amount,
    this.status,
    this.createdAt,
    this.raw = const {},
  });

  static int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static num? _tryParseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static String? _tryString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static Map<String, dynamic>? _tryMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _humanize(dynamic value) {
    final text = _tryString(value)?.trim() ?? '';
    if (text.isEmpty) return '-';

    final normalized = text
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return normalized
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          if (word == word.toUpperCase() && word.length <= 4) {
            return word;
          }
          final lower = word.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  factory ServiceRequestListItem.fromJson(Map<String, dynamic> json) {
    final customer = _tryMap(json['customer']) ??
        _tryMap(json['user']) ??
        _tryMap(json['customer_detail']);
    final service = _tryMap(json['service']) ?? _tryMap(json['service_detail']) ?? _tryMap(json['quick_service']);

    final serviceName = _tryString(json['service_name']) ??
        _tryString(json['title']) ??
        _tryString(json['name']) ??
        _tryString(service?['service_name']) ??
        _tryString(service?['serviceName']);

    final customerName = _tryString(json['customer_name']) ??
        _tryString(json['customer']) ??
        _tryString(customer?['name']) ??
        _tryString(customer?['full_name']) ??
        _tryString(customer?['fullName']);

    final serviceType = _tryString(json['service_type']) ??
        _tryString(json['type']) ??
        _tryString(service?['service_type']) ??
        _tryString(service?['type']);

    final requestId = _tryString(json['request_id']) ??
        _tryString(json['service_id']) ??
        _tryString(json['order_id']) ??
        _tryString(json['id']) ??
        _tryString(json['code']) ??
        _tryString(json['service_code']);

    final serviceCode = _tryString(json['service_id']) ??
        _tryString(json['request_id']) ??
        _tryString(json['order_id']) ??
        _tryString(json['id']) ??
        _tryString(json['code']) ??
        _tryString(json['service_code']);

    final amount = _tryParseNum(json['amount']) ??
        _tryParseNum(json['total_amount']) ??
        _tryParseNum(json['total']) ??
        _tryParseNum(json['grand_total']) ??
        _tryParseNum(json['price']) ??
        _tryParseNum(json['service_charge']);

    final status = _tryString(json['status']) ??
        _tryString(json['request_status']) ??
        _tryString(json['service_status']) ??
        _tryString(json['payment_status']);

    final createdAt = _tryString(json['created_at']) ??
        _tryString(json['createdAt']) ??
        _tryString(json['date']) ??
        _tryString(json['transaction_date']);

    final requestDate = _tryString(json['request_date']) ??
        _tryString(json['requestDate']) ??
        _tryString(json['service_date']) ??
        _tryString(json['serviceDate']) ??
        _tryString(json['transaction_date']) ??
        _tryString(json['date']) ??
        createdAt;

    return ServiceRequestListItem(
      id: _tryParseInt(json['id']),
      serviceName: serviceName,
      serviceType: serviceType,
      customerName: customerName,
      requestId: requestId,
      requestDate: requestDate,
      serviceCode: serviceCode,
      amount: amount,
      status: status,
      createdAt: createdAt,
      raw: json,
    );
  }

  bool get isDone {
    final s = (status ?? '').toLowerCase().trim();
    if (s.isEmpty) return false;
    return s.contains('done') ||
        s.contains('complete') ||
        s.contains('completed') ||
        s.contains('finish') ||
        s.contains('finished') ||
        s.contains('close') ||
        s.contains('closed') ||
        s.contains('resolved');
  }

  String get displayTitle => (serviceName ?? '').trim().isEmpty ? 'Service Request' : serviceName!.trim();

  String get displayCustomerName => (customerName ?? '').trim().isEmpty ? '-' : customerName!.trim();

  String get displayServiceType {
    final text = (serviceType ?? '').trim();
    if (text.isNotEmpty) return _humanize(text);
    final title = (serviceName ?? '').trim();
    if (title.isNotEmpty) return _humanize(title);
    return '-';
  }

  String get displayRequestId {
    final idText = (requestId ?? serviceCode ?? '').trim();
    if (idText.isNotEmpty) return idText.startsWith('#') ? idText : '#$idText';
    if (id != null) return '#$id';
    return '-';
  }

  String get displayRequestDate {
    final text = (requestDate ?? createdAt ?? '').trim();
    return text.isEmpty ? '-' : text;
  }

  String get displayServiceId {
    final idText = (serviceCode ?? '').trim();
    if (idText.isNotEmpty) return idText.startsWith('#') ? idText : '#$idText';
    if (id != null) return '#$id';
    return '-';
  }

  String get displayAmount {
    if (amount == null) return '-';
    final n = amount!;
    if (n % 1 == 0) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }

  String get displayStatus {
    final text = (status ?? '').trim();
    if (text.isEmpty) return '-';
    return _humanize(text);
  }
}
