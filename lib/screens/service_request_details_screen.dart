import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';

class ServiceRequestDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> requestData;

  const ServiceRequestDetailsScreen({
    super.key,
    this.requestData = const {},
  });

  @override
  State<ServiceRequestDetailsScreen> createState() =>
      _ServiceRequestDetailsScreenState();
}

class _ServiceRequestDetailsScreenState extends State<ServiceRequestDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _detail = const {};
  List<_ServiceCardData> _cards = const [];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  int? _tryInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _toText(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  Map<String, dynamic>? _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String _pickFirstText(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      final text = _toText(value);
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  int? _resolveRequestId() {
    return _tryInt(widget.requestData['id']) ??
        _tryInt(widget.requestData['request_id']) ??
        _tryInt(widget.requestData['service_id']);
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final int? requestId = _resolveRequestId();
      if (requestId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Request id not found.';
        });
        return;
      }

      final roleId = await SecureStorageService.getRoleId();
      final customerId = await SecureStorageService.getUserId();

      if (roleId == null || customerId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session expired. Please login again.';
        });
        return;
      }

      final response = await ApiService.instance.getServiceRequestDetails(
        requestId: requestId,
        roleId: roleId,
        customerId: customerId,
      );

      if (!mounted) return;

      if (!response.success || response.data == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message ?? 'Failed to fetch service request details.';
        });
        return;
      }

      final detail = response.data!;
      final cards = _extractCards(detail);

      setState(() {
        _detail = detail;
        _cards = cards;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch service request details.';
      });
    }
  }

  List<_ServiceCardData> _extractCards(Map<String, dynamic> detail) {
    final nestedService = _toMap(detail['service']) ?? _toMap(detail['service_detail']) ?? const <String, dynamic>{};

    dynamic listNode = detail['products'] ??
        detail['service_products'] ??
        detail['items'] ??
        detail['product_details'];

    if (listNode == null && detail['data'] is Map<String, dynamic>) {
      final data = detail['data'] as Map<String, dynamic>;
      listNode = data['products'] ?? data['items'] ?? data['service_products'];
    }

    final List<_ServiceCardData> cards = [];
    if (listNode is List) {
      for (final item in listNode) {
        final map = _toMap(item);
        if (map == null) continue;
        cards.add(_buildCardFromMap(map, fallback: detail, nestedService: nestedService));
      }
    }

    if (cards.isNotEmpty) return cards;

    return [
      _buildCardFromMap(
        detail,
        fallback: widget.requestData,
        nestedService: nestedService,
      ),
    ];
  }

  _ServiceCardData _buildCardFromMap(
    Map<String, dynamic> source, {
    required Map<String, dynamic> fallback,
    required Map<String, dynamic> nestedService,
  }) {
    final requestId = _tryInt(source['request_id']) ??
        _tryInt(source['service_request_id']) ??
        _tryInt(fallback['request_id']) ??
        _tryInt(fallback['id']) ??
        _resolveRequestId();

    final serviceProductId = _tryInt(source['service_product_id']) ??
        _tryInt(source['request_product_id']) ??
        _tryInt(source['service_request_product_id']) ??
        _tryInt(source['id']);

    final productId = _tryInt(source['product_id']) ??
        _tryInt(source['warehouse_product_id']) ??
        _tryInt(source['id']);

    final title = _pickFirstText(
      [
        source['service_name'],
        source['name'],
        source['title'],
        source['product_name'],
        nestedService['service_name'],
        nestedService['name'],
        fallback['service_name'],
        fallback['service_type'],
      ],
      fallback: 'Service Request',
    );

    final description = _pickFirstText(
      [
        source['description'],
        source['remarks'],
        source['note'],
        source['service_type'],
        nestedService['service_type'],
        fallback['service_type'],
      ],
      fallback: 'No description available.',
    );

    final price = _pickFirstText(
      [
        source['service_charge'],
        source['amount'],
        source['price'],
        source['total'],
        fallback['amount'],
      ],
      fallback: '0',
    );

    final imageUrl = _pickFirstText(
      [
        source['image'],
        source['image_url'],
        source['photo'],
        source['thumbnail'],
        nestedService['image'],
      ],
      fallback: '',
    );

    return _ServiceCardData(
      requestId: requestId,
      serviceProductId: serviceProductId,
      productId: productId,
      title: title,
      description: description,
      price: price,
      imageUrl: imageUrl,
      raw: source,
    );
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
          'Service Details',
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetchDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDetails,
                  child: _cards.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: const [
                            Center(child: Text('No service details found')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cards.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(context, data: _cards[index]);
                          },
                        ),
                ),
    );
  }

  Widget _buildProductCard(
    BuildContext context, {
    required _ServiceCardData data,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.workProgressTracker,
          arguments: {
            'requestId': data.requestId ?? _resolveRequestId(),
            'serviceProductId': data.serviceProductId,
            'productId': data.productId,
            'productName': data.title,
            'price': data.price,
            'imageUrl': data.imageUrl,
            'serviceDetail': _detail,
            'serviceProductRaw': data.raw,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 90,
              height: 90,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: data.imageUrl.isNotEmpty
                  ? Image.network(
                      data.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.miscellaneous_services,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(
                      Icons.miscellaneous_services,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Starts at ',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: 'Rs ${data.price}',
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: ' (with GST)',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCardData {
  final int? requestId;
  final int? serviceProductId;
  final int? productId;
  final String title;
  final String description;
  final String price;
  final String imageUrl;
  final Map<String, dynamic> raw;

  const _ServiceCardData({
    this.requestId,
    this.serviceProductId,
    this.productId,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.raw = const {},
  });
}
