class InvoiceItemModel {
  const InvoiceItemModel({
    required this.name,
    required this.modelNo,
    required this.brand,
  });

  final String name;
  final String modelNo;
  final String brand;

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      name: _text(json['name']) ?? _text(json['product_name']) ?? '-',
      modelNo:
          _text(json['model_no']) ??
          _text(json['model']) ??
          _text(json['model_number']) ??
          '-',
      brand: _text(json['brand']) ?? _text(json['brand_name']) ?? '-',
    );
  }
}

class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.quoteId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.grandTotal,
    required this.currency,
    required this.status,
    required this.paymentStatus,
    required this.paidAmount,
    required this.billingAddress,
    required this.invoicePdf,
    required this.leadNumber,
    required this.items,
  });

  final int id;
  final int quoteId;
  final String invoiceNumber;
  final String invoiceDate;
  final String dueDate;
  final double grandTotal;
  final String currency;
  final String status;
  final String paymentStatus;
  final double paidAmount;
  final String billingAddress;
  final String invoicePdf;
  final String leadNumber;
  final List<InvoiceItemModel> items;

  bool get hasInvoicePdf => invoicePdf.trim().isNotEmpty;

  InvoiceItemModel? get firstItem => items.isNotEmpty ? items.first : null;

  String get effectiveStatus {
    final payment = paymentStatus.toLowerCase().trim();
    if (payment == 'paid') return 'paid';
    if (payment == 'unpaid') return 'unpaid';

    final state = status.toLowerCase().trim();
    if (state == 'paid') return 'paid';
    if (state == 'unpaid') return 'unpaid';
    if (state == 'sent') return 'sent';

    return state.isEmpty ? 'sent' : state;
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final quoteDetails =
        _map(json['quote_details']) ??
        _map(json['quotation']) ??
        _map(json['quote']);
    final leadDetails =
        _map(quoteDetails?['lead_details'] ?? quoteDetails?['lead_detail']) ??
        _map(json['lead_details']) ??
        _map(json['lead_detail']);

    final itemsNode =
        json['items'] ??
        json['invoice_items'] ??
        json['products'] ??
        json['quotation_products'];
    final items = itemsNode is List
        ? itemsNode
              .whereType<Map>()
              .map(
                (e) => InvoiceItemModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <InvoiceItemModel>[];

    final int resolvedQuoteId =
        _int(json['quote_id']) ??
        _int(json['quotation_id']) ??
        _int(json['quoteId']) ??
        _int(quoteDetails?['id']) ??
        _int(quoteDetails?['quote_id']) ??
        _int(quoteDetails?['quotation_id']) ??
        _int(json['id']) ??
        0;

    return InvoiceModel(
      id: _int(json['id']) ?? 0,
      quoteId: resolvedQuoteId,
      invoiceNumber:
          _text(json['invoice_number']) ??
          _text(json['invoice_no']) ??
          _text(json['quote_number']) ??
          _text(json['number']) ??
          '-',
      invoiceDate:
          _text(json['invoice_date']) ??
          _text(json['quote_date']) ??
          _text(json['date']) ??
          _text(json['created_at']) ??
          '-',
      dueDate:
          _text(json['due_date']) ??
          _text(json['dueDate']) ??
          _text(json['expiry_date']) ??
          '-',
      grandTotal:
          _double(json['grand_total']) ??
          _double(json['total_amount']) ??
          _double(json['total']) ??
          0,
      currency: _text(json['currency']) ?? 'INR',
      status: _text(json['status']) ?? _text(json['invoice_status']) ?? 'sent',
      paymentStatus:
          _text(json['payment_status']) ??
          _text(json['transaction_status']) ??
          'unpaid',
      paidAmount:
          _double(json['paid_amount']) ?? _double(json['amount_paid']) ?? 0,
      billingAddress:
          _text(json['billing_address']) ??
          _text(json['address']) ??
          _text(leadDetails?['address']) ??
          _text(json['billingAddress']) ??
          '-',
      invoicePdf:
          _text(json['invoice_pdf']) ??
          _text(json['pdf']) ??
          _text(json['pdf_url']) ??
          _text(json['quote_document_path']) ??
          '',
      leadNumber:
          _text(leadDetails?['lead_number']) ??
          _text(leadDetails?['lead_no']) ??
          _text(json['lead_number']) ??
          '-',
      items: items,
    );
  }
}

String? _text(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _int(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _double(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

Map<String, dynamic>? _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
