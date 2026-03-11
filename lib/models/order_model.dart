class OrderListModel {
  final List<OrderModel>? orders;

  OrderListModel({this.orders});

  factory OrderListModel.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'];
    return OrderListModel(
      orders: rawOrders is List
          ? rawOrders
              .whereType<Map>()
              .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : null,
    );
  }
}

class OrderModel {
  final int? id;
  final int? customerId;
  final String? orderNumber;
  final int? totalItems;
  final String? subtotal;
  final String? discountAmount;
  final String? couponCode;
  final String? taxAmount;
  final String? shippingCharges;
  final String? grandTotal;
  final String? paymentStatus;
  final String? status;
  final String? orderStatus;
  final String? createdAt;
  final String? deliveredAt;
  final String? expectedDeliveryDate;
  final int? invoiceId;
  final String? invoiceNumber;
  final String? invoicePdf;
  final bool? isReturnable;
  final List<OrderItemModel>? items;

  OrderModel({
    this.id,
    this.customerId,
    this.orderNumber,
    this.totalItems,
    this.subtotal,
    this.discountAmount,
    this.couponCode,
    this.taxAmount,
    this.shippingCharges,
    this.grandTotal,
    this.paymentStatus,
    this.status,
    this.orderStatus,
    this.createdAt,
    this.deliveredAt,
    this.expectedDeliveryDate,
    this.invoiceId,
    this.invoiceNumber,
    this.invoicePdf,
    this.isReturnable,
    this.items,
  });

  static int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return null;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['order_products'] ??
        json['order_items'] ??
        json['orderItems'] ??
        json['items'] ??
        json['products'];

    return OrderModel(
      id: _tryParseInt(json['id']),
      customerId: _tryParseInt(json['customer_id'] ?? json['customerId']),
      orderNumber: _readString(json['order_number'] ?? json['orderNumber']),
      totalItems: _tryParseInt(json['total_items'] ?? json['totalItems']),
      subtotal: _readString(json['subtotal']),
      discountAmount: _readString(json['discount_amount'] ?? json['discount']),
      couponCode: _readString(json['coupon_code'] ?? json['coupon']),
      taxAmount: _readString(json['tax_amount'] ?? json['tax']),
      shippingCharges: _readString(json['shipping_charges'] ?? json['shipping']),
      grandTotal: _readString(
        json['grand_total'] ??
            json['grandTotal'] ??
            json['total_amount'] ??
            json['final_amount'] ??
            json['net_amount'] ??
            json['total'],
      ),
      paymentStatus:
          _readString(json['payment_status'] ?? json['paymentStatus'] ?? json['payment']),
      status: _readString(json['status']),
      orderStatus: _readString(json['order_status'] ?? json['orderStatus'] ?? json['status']),
      createdAt: _readString(json['created_at'] ?? json['createdAt']),
      deliveredAt: _readString(
        json['delivered_at'] ??
            json['deliveredAt'] ??
            json['delivery_date'] ??
            json['deliveryDate'] ??
            json['order_delivered_at'],
      ),
      expectedDeliveryDate: _readString(
        json['expected_delivery_date'] ??
            json['expectedDeliveryDate'] ??
            json['delivery_expected_at'] ??
            json['deliveryExpectedAt'],
      ),
      invoiceId: _tryParseInt(
        json['invoice_id'] ??
            json['invoiceId'] ??
            json['order_invoice_id'],
      ),
      invoiceNumber: _readString(
        json['invoice_number'] ??
            json['invoiceNumber'] ??
            json['order_invoice_number'],
      ),
      invoicePdf: _readString(
        json['invoice_pdf'] ??
            json['invoicePdf'] ??
            json['pdf_url'] ??
            json['pdf'] ??
            json['order_invoice_pdf'],
      ),
      isReturnable: _tryParseBool(
        json['is_returnable'] ??
            json['isReturnable'],
      ),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => OrderItemModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : null,
    );
  }

  bool get hasInvoicePdf => (invoicePdf ?? '').trim().isNotEmpty;
}

class OrderItemModel {
  final int? id;
  final int? productId;
  final String? productName;
  final int? quantity;
  final String? price;
  final OrderProductModel? product;

  OrderItemModel({
    this.id,
    this.productId,
    this.productName,
    this.quantity,
    this.price,
    this.product,
  });

  static int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return null;
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final rawProduct = json['product'] ??
        json['warehouse_product'] ??
        json['warehouseProduct'] ??
        json['product_details'] ??
        json['productDetails'];
    final productMap = rawProduct is Map ? Map<String, dynamic>.from(rawProduct) : null;

    return OrderItemModel(
      id: _tryParseInt(json['id']),
      productId: _tryParseInt(json['product_id'] ?? json['productId']),
      productName: _readString(json['product_name'] ?? json['name'] ?? json['title']),
      quantity: _tryParseInt(json['qty'] ?? json['quantity'] ?? json['order_qty']),
      price: _readString(json['price'] ?? json['unit_price'] ?? json['final_price']),
      product: productMap != null ? OrderProductModel.fromJson(productMap) : null,
    );
  }
}

class OrderProductModel {
  final int? id;
  final String? productName;
  final String? mainProductImage;
  final String? finalPrice;

  OrderProductModel({
    this.id,
    this.productName,
    this.mainProductImage,
    this.finalPrice,
  });

  static int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return null;
  }

  factory OrderProductModel.fromJson(Map<String, dynamic> json) {
    return OrderProductModel(
      id: _tryParseInt(json['id']),
      productName: _readString(json['product_name'] ?? json['name'] ?? json['title']),
      mainProductImage: _readString(json['main_product_image'] ?? json['image'] ?? json['product_image']),
      finalPrice: _readString(json['final_price'] ?? json['selling_price'] ?? json['price']),
    );
  }
}

bool? _tryParseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;

  final normalized = value.toString().trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (normalized == '1' || normalized == 'true' || normalized == 'yes') {
    return true;
  }
  if (normalized == '0' || normalized == 'false' || normalized == 'no') {
    return false;
  }
  return null;
}
