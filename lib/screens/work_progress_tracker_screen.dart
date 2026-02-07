import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../services/api_service.dart';

class WorkProgressTrackerScreen extends StatefulWidget {
  const WorkProgressTrackerScreen({super.key});

  @override
  State<WorkProgressTrackerScreen> createState() =>
      _WorkProgressTrackerScreenState();
}

class _WorkProgressTrackerScreenState extends State<WorkProgressTrackerScreen> {
  bool _didReadArgs = false;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _args = const {};
  List<_DiagnosisGroup> _groups = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) return;
    _didReadArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _args = args;
    } else if (args is Map) {
      _args = Map<String, dynamic>.from(args);
    }
    _fetchDiagnostics();
  }

  int? _tryInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
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

  int? _resolveRequestId() {
    final detail = _toMap(_args['serviceDetail']) ?? const <String, dynamic>{};
    return _tryInt(_args['requestId']) ??
        _tryInt(_args['request_id']) ??
        _tryInt(detail['request_id']) ??
        _tryInt(detail['service_request_id']) ??
        _tryInt(detail['id']);
  }

  int? _resolveServiceProductId() {
    final rawProduct =
        _toMap(_args['serviceProductRaw']) ?? const <String, dynamic>{};
    return _tryInt(_args['serviceProductId']) ??
        _tryInt(_args['productId']) ??
        _tryInt(_args['product_id']) ??
        _tryInt(rawProduct['service_product_id']) ??
        _tryInt(rawProduct['service_request_product_id']) ??
        _tryInt(rawProduct['request_product_id']) ??
        _tryInt(rawProduct['product_id']) ??
        _tryInt(rawProduct['id']);
  }

  Future<void> _fetchDiagnostics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requestId = _resolveRequestId();
      final serviceProductId = _resolveServiceProductId();

      if (requestId == null || serviceProductId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Request id or product id is missing.';
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

      final response =
          await ApiService.instance.getServiceRequestProductDiagnostics(
        requestId: requestId,
        serviceProductId: serviceProductId,
        roleId: roleId,
        customerId: customerId,
      );

      if (!mounted) return;

      if (!response.success || response.data == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message ?? 'Failed to fetch diagnostics.';
        });
        return;
      }

      final parsed = _parseGroups(response.data!);
      setState(() {
        _groups = parsed;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch diagnostics.';
      });
    }
  }

  List<_DiagnosisGroup> _parseGroups(List<Map<String, dynamic>> items) {
    final defaultProductName = _toText(_args['productName']);
    final groups = <_DiagnosisGroup>[];

    for (final item in items) {
      final productName = _toText(item['product_name']).isNotEmpty
          ? _toText(item['product_name'])
          : (defaultProductName.isNotEmpty ? defaultProductName : 'Product');

      final diagnosticsNode = item['diagnostics'];
      final diagnostics = <String>[];

      if (diagnosticsNode is List) {
        for (final entry in diagnosticsNode) {
          final text = _toText(entry is Map ? entry['diagnosis'] ?? entry['name'] : entry);
          if (text.isNotEmpty) diagnostics.add(text);
        }
      } else {
        final single = _toText(diagnosticsNode);
        if (single.isNotEmpty) diagnostics.add(single);
      }

      groups.add(
        _DiagnosisGroup(
          productId: _tryInt(item['product_id']),
          productName: productName,
          diagnostics: diagnostics,
        ),
      );
    }

    if (groups.isNotEmpty) return groups;

    return [
      _DiagnosisGroup(
        productId: _tryInt(_args['productId']),
        productName: defaultProductName.isEmpty ? 'Product' : defaultProductName,
        diagnostics: const [],
      ),
    ];
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
          'Work Progress Tracker',
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
                          onPressed: _fetchDiagnostics,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDiagnostics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildExecutiveCard(),
                      const SizedBox(height: 24),
                      ..._groups.map(_buildDiagnosisGroup),
                    ],
                  ),
                ),
    );
  }

  Widget _buildExecutiveCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(
              'https://img.freepik.com/free-photo/young-bearded-man-with-striped-shirt_273609-5677.jpg',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Field Executive',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Assigned for service diagnostics',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Colors.green),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisGroup(_DiagnosisGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.productName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        if (group.diagnostics.isEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text('No diagnostics found'),
          )
        else
          ...group.diagnostics.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildTimelineItem(
              title: item,
              isLast: index == group.diagnostics.length - 1,
            );
          }),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 20,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSmallImage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallImage() {
    final imageUrl = _toText(_args['imageUrl']);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: imageUrl.isEmpty
          ? const Icon(Icons.image_outlined, color: Colors.grey)
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined, color: Colors.grey),
            ),
    );
  }
}

class _DiagnosisGroup {
  final int? productId;
  final String productName;
  final List<String> diagnostics;

  const _DiagnosisGroup({
    this.productId,
    required this.productName,
    required this.diagnostics,
  });
}
