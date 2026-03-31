import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../constants/api_constants.dart';
import '../constants/app_strings.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/address_model.dart';
import '../models/api_response.dart';
import '../models/product_model.dart';
import '../models/quick_service_model.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import 'address_screen.dart';

class PaymentScreen extends StatefulWidget {
  final ProductData? product;
  final int quantity;
  final double? unitPrice;
  final double? totalAmount;
  final String? serviceTitle;
  final String? serviceDescription;
  final double? serviceAmount;
  final int? serviceRequestId;
  final int? serviceQuantity;
  final Map<String, dynamic>? pendingServiceRequestData;

  const PaymentScreen({
    super.key,
    this.product,
    this.quantity = 1,
    this.unitPrice,
    this.totalAmount,
    this.serviceTitle,
    this.serviceDescription,
    this.serviceAmount,
    this.serviceRequestId,
    this.serviceQuantity,
    this.pendingServiceRequestData,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const int _addAddressDropdownValue = -1;
  static const int _cashOnDeliveryIndex = 2;
  static const String _razorpayKeyId = 'rzp_test_STpRW3sZohBEmz';
  int selectedIndex = -1;
  bool _isSubmitting = false;
  bool _isAddressLoading = false;
  bool _isServiceDetailLoading = false;
  bool _isServiceSummaryLoading = false;
  List<AddressModel> _addresses = [];
  int? _selectedAddressId;
  int? _pendingBackendOrderId;
  Map<String, dynamic>? _serviceDetailData;
  QuickService? _serviceSummary;
  late final Razorpay _razorpay;

  static const String _imageBaseUrl = 'https://crackteck.co.in/';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    if (widget.product != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchAddresses();
      });
    }
    if (_isServicePayment && widget.serviceRequestId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchServiceDetails();
      });
    }
    if (_isServicePayment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchServiceSummary();
      });
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  String _normalizeImageUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
     if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '$_imageBaseUrl${trimmed.substring(1)}';
    }
    return '$_imageBaseUrl$trimmed';
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  void _printApiLog(dynamic url, dynamic body, dynamic response) {
    print("API URL: $url");
    print("Request Body: $body");
    print("Response: $response");
  }

  void _printRazorpayLog(dynamic response, dynamic status) {
    print("RAZORPAY RESPONSE: $response");
    print("STATUS: $status");
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
    if (_isServicePayment) {
      final unit = _resolvedServiceUnitAmount;
      if (unit == null) return null;
      return unit * _resolvedServiceQuantity;
    }
    final unit = _resolvedUnitPrice;
    if (unit == null) return null;
    return unit * widget.quantity;
  }

  bool get _isCashOnDeliveryAvailable {
    final total = _resolvedTotal;
    if (_isServicePayment) {
      return false;
    }
    return total != null && total < 2000;
  }

  String get _resolvedTitle {
    if (_isServicePayment) {
      final summaryTitle = (_serviceSummary?.serviceName ?? '').trim();
      final title = summaryTitle.isNotEmpty
          ? summaryTitle
          : _extractStringByKeys(_serviceDetailData, const [
              'service_name',
              'name',
              'title',
            ]) ??
              (widget.serviceTitle ?? '').trim();
      return title.isEmpty ? 'Service Request' : title;
    }
    final wp = widget.product?.warehouseProduct;
    return (wp?.productName ?? widget.product?.metaTitle ?? 'Payment').trim();
  }

  String get _resolvedImageUrl {
    if (_isServicePayment) return '';
    final raw = widget.product?.warehouseProduct?.mainProductImage;
    if (raw == null || raw.trim().isEmpty) return '';
    return _normalizeImageUrl(raw);
  }

  bool get _isServicePayment =>
      widget.product == null &&
      (widget.pendingServiceRequestData != null ||
          widget.serviceRequestId != null ||
          (widget.serviceAmount != null && widget.serviceAmount! > 0));

  String get _resolvedDescription {
    if (_isServicePayment) {
      final diagnosis = _serviceSummary?.diagnosisList
          ?.where((item) => item.trim().isNotEmpty)
          .join(', ');
      final description = (diagnosis != null && diagnosis.trim().isNotEmpty)
          ? diagnosis.trim()
          : _extractStringByKeys(_serviceDetailData, const [
              'service_type',
              'type',
              'description',
              'remarks',
            ]) ??
              (widget.serviceDescription ?? '').trim();
      return description.isEmpty ? 'Service payment' : description;
    }
    return 'Product payment';
  }

  int get _resolvedServiceQuantity {
    final passedQuantity = widget.serviceQuantity;
    if (passedQuantity != null && passedQuantity > 0) {
      return passedQuantity;
    }

    final directQuantity = _extractIntByKeys(_serviceDetailData, const [
      'quantity',
      'qty',
      'product_count',
      'total_items',
      'items_count',
    ]);
    if (directQuantity != null && directQuantity > 0) {
      return directQuantity;
    }

    final detail = _serviceDetailData;
    if (detail != null) {
      for (final key in const [
        'products',
        'items',
        'service_products',
        'request_products',
      ]) {
        final value = detail[key];
        if (value is List && value.isNotEmpty) {
          return value.length;
        }
      }
    }
    return 1;
  }

  double? get _resolvedServiceAmount {
    final raw = _extractStringByKeys(_serviceDetailData, const [
      'service_charge',
      'amount',
      'price',
      'total',
      'total_amount',
      'grand_total',
    ]);
    return _tryParseAmount(raw);
  }

  double? get _resolvedServiceUnitAmount {
    final summaryAmount = _tryParseAmount(_serviceSummary?.serviceCharge);
    if (summaryAmount != null) return summaryAmount;
    return _resolvedServiceAmount ?? widget.serviceAmount;
  }

  String get _resolvedServiceType {
    final normalized = (widget.serviceDescription ?? '').trim().toLowerCase();
    if (normalized.isNotEmpty) {
      return normalized;
    }
    final fromDetail = _extractStringByKeys(_serviceDetailData, const [
      'service_type',
      'type',
    ]);
    if (fromDetail != null && fromDetail.trim().isNotEmpty) {
      return fromDetail.trim().toLowerCase();
    }
    return 'quick_service';
  }

  String _normalizeLookup(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _fetchServiceSummary() async {
    if (_isServiceSummaryLoading) return;

    final serviceType = _resolvedServiceType;
    final serviceTitle = (widget.serviceTitle ?? '').trim();
    if (serviceTitle.isEmpty) return;

    setState(() => _isServiceSummaryLoading = true);

    try {
      final roleId = await SecureStorageService.getRoleId();
      final url = Uri.parse(ApiConstants.servicesList).replace(
        queryParameters: {
          'service_type': serviceType,
          if (roleId != null && roleId > 0) 'role_id': roleId.toString(),
        },
      ).toString();
      final body = {
        'service_type': serviceType,
        'role_id': roleId,
        'service_title': serviceTitle,
      };
      _printApiLog(url, body, 'Request started');

      final response = await ApiService.instance.getServicesList(
        roleId: roleId,
        serviceType: serviceType,
      );
      _printApiLog(url, body, response);

      if (!mounted) return;
      if (!response.success || response.data == null) return;

      final normalizedTarget = _normalizeLookup(serviceTitle);
      QuickService? matched;
      for (final service in response.data!) {
        final name = _normalizeLookup(service.serviceName ?? '');
        final code = _normalizeLookup(service.itemCode ?? '');
        if (name == normalizedTarget || code == normalizedTarget) {
          matched = service;
          break;
        }
      }

      if (matched == null) {
        for (final service in response.data!) {
          if (_normalizeLookup(service.serviceType ?? '') == serviceType) {
            matched = service;
            break;
          }
        }
      }

      if (matched != null) {
        setState(() {
          _serviceSummary = matched;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isServiceSummaryLoading = false);
      }
    }
  }

  Future<void> _fetchServiceDetails() async {
    final serviceRequestId = widget.serviceRequestId;
    if (serviceRequestId == null || _isServiceDetailLoading) return;

    setState(() => _isServiceDetailLoading = true);

    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (userId == null || roleId == null) {
        return;
      }

      final response = await ApiService.instance.getServiceDetails(
        serviceId: serviceRequestId,
        roleId: roleId,
        userId: userId,
      );

      if (!mounted) return;
      if (response.success && response.data != null) {
        setState(() {
          _serviceDetailData = response.data;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isServiceDetailLoading = false);
      }
    }
  }

  int? _extractIntByKeys(dynamic source, List<String> keys) {
    if (source is Map) {
      for (final key in keys) {
        final value = source[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value.trim());
          if (parsed != null) return parsed;
        }
      }

      for (final value in source.values) {
        final nested = _extractIntByKeys(value, keys);
        if (nested != null) return nested;
      }
    } else if (source is List) {
      for (final value in source) {
        final nested = _extractIntByKeys(value, keys);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  String? _extractStringByKeys(dynamic source, List<String> keys) {
    if (source is Map) {
      for (final key in keys) {
        final value = source[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
        if (value is num || value is bool) {
          return value.toString();
        }
      }

      for (final value in source.values) {
        final nested = _extractStringByKeys(value, keys);
        if (nested != null) return nested;
      }
    } else if (source is List) {
      for (final value in source) {
        final nested = _extractStringByKeys(value, keys);
        if (nested != null) return nested;
      }
    }
    return null;
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

    if (_isServicePayment) {
      if (selectedIndex == _cashOnDeliveryIndex) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cash on delivery is not available for service payments.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      await _openRazorpay();
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

    final purchaseContext = await _resolvePurchaseContext();
    if (purchaseContext == null) return;

    if (selectedIndex == _cashOnDeliveryIndex) {
      await _callBuyProductApi();
      return;
    }

    await _startOnlinePayment(purchaseContext);
  }

  Future<void> _startOnlinePayment(
    ({
      int productId,
      int roleId,
      int quantity,
      int customerId,
      int shippingAddressId,
    }) purchaseContext,
  ) async {
    if (mounted && !_isSubmitting) {
      setState(() => _isSubmitting = true);
    }

    var checkoutOpened = false;
    try {
      final orderResponse = await ApiService.instance.buyProduct(
        productId: purchaseContext.productId,
        roleId: purchaseContext.roleId,
        quantity: purchaseContext.quantity,
        customerId: purchaseContext.customerId,
        shippingAddressId: purchaseContext.shippingAddressId,
      );
      _printRazorpayLog(orderResponse.data, orderResponse.success);

      if (!mounted) return;

      if (!orderResponse.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderResponse.message ?? 'Failed to create order'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final backendOrderId = _extractIntByKeys(orderResponse.data, const [
        'order_id',
        'orderId',
        'id',
      ]);
      if (backendOrderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created but no order id was returned.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      _pendingBackendOrderId = backendOrderId;

      final razorpayOrderResponse = await ApiService.instance.createRazorpayOrder(
        orderId: backendOrderId,
        userId: purchaseContext.customerId,
        roleId: purchaseContext.roleId,
      );
      _printRazorpayLog(
        razorpayOrderResponse.data,
        razorpayOrderResponse.success,
      );

      if (!mounted) return;

      if (!razorpayOrderResponse.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              razorpayOrderResponse.message ?? 'Failed to initialize Razorpay order',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final razorpayOrderId =
          _extractStringByKeys(razorpayOrderResponse.data, const [
            'razorpay_order_id',
            'order_id',
            'id',
          ]);

      if (razorpayOrderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Razorpay order was created but no order id was returned.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      checkoutOpened = true;
      await _openRazorpay(orderId: razorpayOrderId);
    } finally {
      if (!checkoutOpened && mounted && _isSubmitting) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openRazorpay({String? orderId}) async {
    final total = _resolvedTotal;
    if (total == null || total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start payment. Invalid order total.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userData = await SecureStorageService.getUserData();
    final prefillContact = _readUserValue(userData, const [
      'phone',
      'phone_number',
      'mobile',
      'contact',
    ]);
    final prefillEmail = _readUserValue(userData, const [
      'email',
      'email_id',
      'mail',
    ]);

    final options = <String, Object?>{
      'key': _razorpayKeyId,
      'amount': (total * 100).round(),
      'name': AppStrings.appName,
      'description': _resolvedDescription,
      'prefill': <String, String>{
        if (prefillContact != null) 'contact': prefillContact,
        if (prefillEmail != null) 'email': prefillEmail,
      },
      'notes': <String, String>{
        if (_isServicePayment)
          'service_name': _resolvedTitle.isEmpty ? 'Service Request' : _resolvedTitle
        else
          'product_name': _resolvedTitle.isEmpty ? 'Product' : _resolvedTitle,
        if (widget.serviceRequestId != null)
          'service_request_id': widget.serviceRequestId.toString(),
      },
      'external': <String, List<String>>{
        'wallets': <String>['paytm'],
      },
      if (orderId != null && orderId.trim().isNotEmpty) 'order_id': orderId.trim(),
    };

    setState(() => _isSubmitting = true);
    try {
      _razorpay.open(options);
    } catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open payment gateway: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

Future<
      ({
        int productId,
        int roleId,
        int quantity,
        int customerId,
        int shippingAddressId,
      })?> _resolvePurchaseContext() async {
    if (_isAddressLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
          content: Text('Please wait while addresses are loading.'),
        ),
      );
      return null;
    }

    if (_addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an address to continue.')),
      );
      await _goToAddressScreen();
      return null;
    }

    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address.')),
      );
      return null;
    }

    final productId = widget.product?.id;
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing product id'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    final customerId = await SecureStorageService.getUserId();
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    return (
      productId: productId,
      roleId: (await SecureStorageService.getRoleId()) ?? 4,
      quantity: widget.quantity < 1 ? 1 : widget.quantity,
      customerId: customerId,
      shippingAddressId: _selectedAddressId!,
    );
  }

  Future<void> _callBuyProductApi() async {
    final purchaseContext = await _resolvePurchaseContext();
    if (purchaseContext == null) {
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    if (mounted && !_isSubmitting) {
      setState(() => _isSubmitting = true);
    }

    try {
      final response = await ApiService.instance.buyProduct(
        productId: purchaseContext.productId,
        roleId: purchaseContext.roleId,
        quantity: purchaseContext.quantity,
        customerId: purchaseContext.customerId,
        shippingAddressId: purchaseContext.shippingAddressId,
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

  Future<void> _handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) async {
    _printRazorpayLog(
      {
        'orderId': response.orderId,
        'paymentId': response.paymentId,
        'signature': response.signature,
      },
      'payment_success',
    );

    final backendOrderId = _pendingBackendOrderId;

    if (_isServicePayment && widget.pendingServiceRequestData != null) {
      final submitResponse = await _submitPendingServiceRequestAfterPayment();
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      if (submitResponse.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              submitResponse.message ?? 'Payment successful and service request submitted',
            ),
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
            content: Text(
              submitResponse.message ??
                  'Payment succeeded but service request submission failed.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final customerId = await SecureStorageService.getUserId();
    final roleId = (await SecureStorageService.getRoleId()) ?? 4;

    if (_isServicePayment && backendOrderId == null) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful'),
          backgroundColor: Color(0xFF1F8B00),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.hometab,
        (route) => false,
      );
      return;
    }

    if (backendOrderId == null ||
        customerId == null ||
        response.orderId == null ||
        response.paymentId == null ||
        response.signature == null) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment succeeded but verification payload is incomplete.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final verifyResponse = await ApiService.instance.verifyRazorpayPayment(
      userId: customerId,
      roleId: roleId,
      orderId: backendOrderId,
      razorpayOrderId: response.orderId!,
      razorpayPaymentId: response.paymentId!,
      razorpaySignature: response.signature!,
    );
    _printRazorpayLog(verifyResponse.data, verifyResponse.success);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (!verifyResponse.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(verifyResponse.message ?? 'Payment verification failed.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _pendingBackendOrderId = null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(verifyResponse.message ?? 'Payment successful'),
        backgroundColor: const Color(0xFF1F8B00),
      ),
    );
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.hometab,
      (route) => false,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    final message = response.message?.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message == null || message.isEmpty
              ? 'Payment failed. Please try again.'
              : 'Payment failed: $message',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    final walletName = response.walletName?.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          walletName == null || walletName.isEmpty
              ? 'External wallet selected.'
              : 'External wallet selected: $walletName',
        ),
      ),
    );
  }

  String? _readUserValue(Map<String, dynamic>? userData, List<String> keys) {
    if (userData == null) return null;
    for (final key in keys) {
      final value = userData[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString().trim());
  }

  Future<dynamic> _submitPendingServiceRequestAfterPayment() async {
    final pending = widget.pendingServiceRequestData;
    if (pending == null) {
      return ApiResponse(success: false, message: 'Missing service request data.');
    }

    final customerId = await SecureStorageService.getUserId();
    final roleId = await SecureStorageService.getRoleId();
    if (customerId == null || roleId == null) {
      return ApiResponse(
        success: false,
        message: 'User session expired. Please login again.',
      );
    }

    final products = (pending['products'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final body = {
      'user_id': customerId,
      'role_id': roleId,
      ...pending,
    };
    _printApiLog(ApiConstants.submitQuickService, body, 'Request started');

    final submitResponse = await ApiService.instance.submitQuickServiceRequest(
      customerId: customerId,
      roleId: roleId,
      serviceType: (pending['service_type'] ?? 'quick_service').toString(),
      products: products,
      amcPlanId: _asInt(pending['amc_plan_id']),
      amcType: pending['amc_type']?.toString(),
      customerAddressId: _asInt(pending['customer_address_id']),
    );

    _printApiLog(ApiConstants.submitQuickService, body, submitResponse);
    return submitResponse;
  }

  Future<void> _fetchAddresses() async {
    if (_isAddressLoading) return;
    setState(() {
      _isAddressLoading = true;
    });

    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (userId == null || roleId == null) {
        if (!mounted) return;
        setState(() {
          _addresses = [];
          _selectedAddressId = null;
        });
        return;
      }

      final response = await ApiService.instance.getAddresses(
        userId: userId,
        roleId: roleId,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final fetched = response.data!.where((a) => a.id != null).toList();

        int? nextSelectedId = _selectedAddressId;
        final ids = fetched.map((e) => e.id).toSet();
        if (nextSelectedId == null || !ids.contains(nextSelectedId)) {
          final primary = fetched.where((a) => a.isDefault).toList();
          nextSelectedId = primary.isNotEmpty
              ? primary.first.id
              : (fetched.isNotEmpty ? fetched.first.id : null);
        }

        setState(() {
          _addresses = fetched;
          _selectedAddressId = nextSelectedId;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to load addresses')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load addresses: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddressLoading = false;
        });
      }
    }
  }

  Future<void> _goToAddressScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddressScreen()),
    );
    if (!mounted) return;
    await _fetchAddresses();
  }

  String _formatAddress(AddressModel address) {
    final branch = (address.branchName ?? '').trim();
    final title = branch.isEmpty ? 'Address' : branch;
    final parts = <String>[
      if (address.addressLine1.trim().isNotEmpty) address.addressLine1.trim(),
      if (address.addressLine2.trim().isNotEmpty) address.addressLine2.trim(),
      if (address.city.trim().isNotEmpty) address.city.trim(),
      if (address.state.trim().isNotEmpty) address.state.trim(),
    ];
    if (parts.isEmpty) return title;
    return '$title - ${parts.join(', ')}';
  }

  Widget _buildAddressSection() {
    if (_isAddressLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: const [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading addresses...'),
          ],
        ),
      );
    }

    if (_addresses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Expanded(child: Text('No address found. Please add one.')),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _goToAddressScreen,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add Address'),
            ),
          ],
        ),
      );
    }

    final dropdownItems = <DropdownMenuItem<int>>[
      ..._addresses.map((address) {
        return DropdownMenuItem<int>(
          value: address.id,
          child: Text(
            _formatAddress(address),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }),
      const DropdownMenuItem<int>(
        value: _addAddressDropdownValue,
        child: Text('Add Address'),
      ),
    ];

    return DropdownButtonFormField<int>(
      initialValue: _selectedAddressId,
      isExpanded: true,
      items: dropdownItems,
      onChanged: _isSubmitting
          ? null
          : (value) async {
              if (value == _addAddressDropdownValue) {
                setState(() => _selectedAddressId = null);
                await _goToAddressScreen();
                return;
              }
              setState(() => _selectedAddressId = value);
            },
      decoration: InputDecoration(
        hintText: 'Select Address',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              if (widget.product != null || _isServicePayment) ...[
                Text(
                  _isServicePayment ? 'Service Summary' : 'Order Summary',
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
                            ? Icon(
                                _isServicePayment
                                    ? Icons.miscellaneous_services_rounded
                                    : Icons.image,
                                color: Colors.grey,
                                size: _isServicePayment ? 34 : 24,
                              )
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
                              _resolvedTitle.isEmpty
                                  ? (_isServicePayment ? 'Service Request' : 'Product')
                                  : _resolvedTitle,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            if (_isServicePayment)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isServiceSummaryLoading) ...[
                                    const SizedBox(height: 4),
                                    const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF7EE),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Qty: $_resolvedServiceQuantity',
                                      style: const TextStyle(
                                        color: Color(0xFF1F8B00),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _resolvedDescription,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_resolvedServiceUnitAmount != null) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'Unit Price: \u20B9 ${_formatAmount(_resolvedServiceUnitAmount!)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF1F8B00),
                                      ),
                                    ),
                                  ],
                                  if (total != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Total: \u20B9 ${_formatAmount(total)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: Color(0xFF1F8B00),
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Text('Qty: ${widget.quantity}'),
                                  const SizedBox(width: 12),
                                  if (_resolvedUnitPrice != null)
                                    Text('Unit: \u20B9 ${_formatAmount(_resolvedUnitPrice!)}'),
                                ],
                              ),
                            if (!_isServicePayment && total != null) ...[
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
                if (!_isServicePayment) ...[
                  const Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildAddressSection(),
                  const SizedBox(height: 20),
                ],
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

                    /// Razorpay
                    _paymentTile(
                      index: 0,
                      leading: Container(
                        height: 36,
                        width: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C2D72),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'RZP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      title: 'Razorpay',
                      subtitle: 'Pay securely with Razorpay',
                      amount: '₹ 2,500',
                    ),

                    const Divider(height: 1),

                    if (false)
                      _paymentTile(
                      index: 1,
                      icon: Icons.payment,
                      title: 'PhonePe',
                      amount: '₹ 2,500',
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (!_isServicePayment) ...[
                const Text(
                  'Cash On Delivery',
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
                  child: _paymentTile(
                    index: _cashOnDeliveryIndex,
                    icon: Icons.local_shipping_outlined,
                    title: 'Cash on Delivery',
                    amount: '\u20B9 2,500',
                    enabled: _isCashOnDeliveryAvailable,
                    subtitle: _isCashOnDeliveryAvailable
                        ? 'Pay when your order is delivered'
                        : 'Available only for orders below \u20B9 2000',
                  ),
                ),
                const SizedBox(height: 24),
              ] else
                const SizedBox(height: 24),

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
    required String title,
    required String amount,
    IconData? icon,
    Widget? leading,
    bool enabled = true,
    String? subtitle,
  }) {
    final total = _resolvedTotal;
    final String resolvedAmount =
        total != null ? '\u20B9 ${_formatAmount(total)}' : amount;
    final Color? foregroundColor = enabled ? null : Colors.grey;

    return ListTile(
      enabled: enabled,
      leading: leading ??
          Icon(
            icon ?? Icons.payment,
            size: 28,
            color: foregroundColor,
          ),
      title: Text(title, style: TextStyle(color: foregroundColor)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: TextStyle(color: foregroundColor)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            resolvedAmount,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
          ),
          const SizedBox(width: 12),
          Checkbox(
            value: selectedIndex == index,
            onChanged: enabled
                ? (val) {
                    setState(() {
                      selectedIndex = index;
                    });
                  }
                : null,
          ),
        ],
      ),
      onTap: enabled
          ? () {
              setState(() {
                selectedIndex = index;
              });
            }
          : null,
    );
  }
}
