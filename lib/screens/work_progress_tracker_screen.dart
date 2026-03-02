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
  static const String _imageBaseUrl = 'https://crackteck.co.in/';
  bool _didReadArgs = false;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _args = const {};
  List<_DiagnosisGroup> _groups = const [];
  final Set<String> _completedPartActionKeys = <String>{};
  final Set<String> _completedPickingActionKeys = <String>{};
  String? _activePartActionKey;
  String? _activePickingActionKey;

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

  String _pickFirstText(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      final text = _toText(value);
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  String _resolveImageUrl(dynamic value) {
    final raw = _toText(value);
    if (raw.isEmpty) return '';
    final normalized = raw.replaceAll('\\', '/');
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    if (normalized.startsWith('/')) {
      return '$_imageBaseUrl${normalized.substring(1)}';
    }
    return '$_imageBaseUrl$normalized';
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
        _tryInt(_args['service_product_id']) ??
        _tryInt(_args['service_request_product_id']) ??
        _tryInt(rawProduct['serviceProductId']) ??
        _tryInt(rawProduct['service_product_id']) ??
        _tryInt(rawProduct['service_request_product_id']) ??
        _tryInt(rawProduct['request_product_id']) ??
        _tryInt(rawProduct['id']);
  }

  Future<void> _fetchDiagnostics() async {
    if (!mounted) return;
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
          _errorMessage = 'Request id or service product id is missing.';
        });
        return;
      }

      final roleId = await SecureStorageService.getRoleId();
      final customerId = await SecureStorageService.getUserId();

      if (roleId == null || customerId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session expired. Please login again.';
        });
        return;
      }

      final response = await ApiService.instance
          .getServiceRequestProductDiagnostics(
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

  List<_DiagnosisGroup> _parseGroups(Map<String, dynamic> payload) {
    final defaultProductName = _toText(_args['productName']);
    final root = _toMap(payload['data']) ?? payload;
    final productMap = _toMap(root['product']) ?? const <String, dynamic>{};
    final productName = _toText(productMap['name']).isNotEmpty
        ? _toText(productMap['name'])
        : (defaultProductName.isNotEmpty ? defaultProductName : 'Product');
    final productId = _tryInt(productMap['id']) ?? _tryInt(_args['productId']);

    final diagnosesNode = root['diagnoses'];
    final diagnosisItems = <_DiagnosisItem>[];

    if (diagnosesNode is List) {
      for (final diagnosisEntry in diagnosesNode) {
        final diagnosisMap = _toMap(diagnosisEntry);
        if (diagnosisMap == null) continue;

        final diagnosisListNode = diagnosisMap['diagnosis_list'];
        if (diagnosisListNode is List) {
          for (final rawItem in diagnosisListNode) {
            final itemMap = _toMap(rawItem);
            final diagnosisName = _toText(
              itemMap?['name'] ??
                  itemMap?['diagnosis'] ??
                  itemMap?['title'] ??
                  rawItem,
            );
            if (diagnosisName.isNotEmpty) {
              final isWorking =
                  _toText(
                    itemMap?['status'] ??
                        diagnosisMap['status'] ??
                        itemMap?['diagnosis_status'] ??
                        diagnosisMap['diagnosis_status'],
                  ).toLowerCase() ==
                  'working';
              diagnosisItems.add(
                _DiagnosisItem(
                  title: diagnosisName,
                  isWorking: isWorking,
                  partSection: _resolvePartSection(
                    diagnosisMap: diagnosisMap,
                    itemMap: itemMap,
                    fallbackTitle: diagnosisName,
                  ),
                  pickingSection: _resolvePickingSection(
                    diagnosisMap: diagnosisMap,
                    itemMap: itemMap,
                    fallbackTitle: diagnosisName,
                  ),
                ),
              );
            }
          }
        } else {
          final directDiagnosisName = _toText(
            diagnosisMap['name'] ?? diagnosisMap['diagnosis'],
          );
          if (directDiagnosisName.isNotEmpty) {
            final isWorking =
                _toText(
                  diagnosisMap['status'] ?? diagnosisMap['diagnosis_status'],
                ).toLowerCase() ==
                'working';
            diagnosisItems.add(
              _DiagnosisItem(
                title: directDiagnosisName,
                isWorking: isWorking,
                partSection: _resolvePartSection(
                  diagnosisMap: diagnosisMap,
                  itemMap: null,
                  fallbackTitle: directDiagnosisName,
                ),
                pickingSection: _resolvePickingSection(
                  diagnosisMap: diagnosisMap,
                  itemMap: null,
                  fallbackTitle: directDiagnosisName,
                ),
              ),
            );
          }
        }
      }
    }

    if (diagnosisItems.isNotEmpty || productMap.isNotEmpty) {
      return [
        _DiagnosisGroup(
          productId: productId,
          productName: productName,
          diagnostics: diagnosisItems,
        ),
      ];
    }

    return [
      _DiagnosisGroup(
        productId: productId,
        productName: productName,
        diagnostics: const [],
      ),
    ];
  }

  _DiagnosisPartSection? _resolvePartSection({
    required Map<String, dynamic> diagnosisMap,
    required Map<String, dynamic>? itemMap,
    required String fallbackTitle,
  }) {
    final rawStatus = _toText(
      itemMap?['status'] ??
          diagnosisMap['status'] ??
          itemMap?['diagnosis_status'] ??
          diagnosisMap['diagnosis_status'],
    ).toLowerCase();
    final rawPartStatus = _toText(
      itemMap?['part_status'] ??
          itemMap?['partStatus'] ??
          diagnosisMap['part_status'] ??
          diagnosisMap['partStatus'],
    ).toLowerCase();

    final isPartFlow =
        rawStatus == 'stock_in_hand' || rawStatus == 'request_part';
    final shouldShow =
        isPartFlow &&
        (rawPartStatus == 'admin_approved' ||
            rawPartStatus == 'customer_approved' ||
            rawPartStatus == 'customer_rejected');

    if (!shouldShow) return null;

    final source = itemMap ?? diagnosisMap;
    final productData =
        _toMap(source['product_data']) ?? const <String, dynamic>{};
    final rawPrice = _pickFirstText([
      productData['final_price'],
      source['final_price'],
      source['part_price'],
      source['price'],
      source['amount'],
      source['selling_price'],
    ]);
    final formattedPrice = rawPrice.isEmpty
        ? ''
        : (rawPrice.toLowerCase().contains('rs') ||
              rawPrice.toLowerCase().contains('inr') ||
              rawPrice.contains('\u20B9'))
        ? rawPrice
        : 'Rs $rawPrice';

    return _DiagnosisPartSection(
      title: _pickFirstText([
        productData['product_name'],
        source['product_name'],
        source['part_name'],
        source['spare_part_name'],
        source['part_title'],
        source['name'],
        source['title'],
      ], fallback: fallbackTitle),
      priceText: formattedPrice,
      quantityText: _pickFirstText([
        source['quantity'],
        source['qty'],
        source['part_qty'],
        productData['quantity'],
        diagnosisMap['quantity'],
      ], fallback: '1'),
      imageUrl: _resolveImageUrl(
        _pickFirstText([
          productData['main_product_image'],
          source['main_product_image'],
          source['part_image'],
          source['part_image_url'],
          source['image'],
          source['image_url'],
          _args['imageUrl'],
        ]),
      ),
      requestId:
          _tryInt(source['request_id']) ??
          _tryInt(source['service_request_id']) ??
          _resolveRequestId(),
      serviceProductId:
          _tryInt(source['service_product_id']) ??
          _tryInt(source['service_request_product_id']) ??
          _tryInt(source['request_product_id']) ??
          _resolveServiceProductId(),
      diagnosisId:
          _tryInt(source['diagnosis_id']) ??
          _tryInt(source['service_diagnosis_id']) ??
          _tryInt(diagnosisMap['diagnosis_id']) ??
          _tryInt(diagnosisMap['service_diagnosis_id']) ??
          _tryInt(itemMap?['id']) ??
          _tryInt(diagnosisMap['id']),
      partId:
          _tryInt(source['part_id']) ??
          _tryInt(source['spare_part_id']) ??
          _tryInt(source['warehouse_product_id']),
      productId:
          _tryInt(source['product_id']) ??
          _tryInt(diagnosisMap['product_id']) ??
          _tryInt(_args['productId']) ??
          _resolveServiceProductId() ??
          _tryInt(productData['product_id']) ??
          _tryInt(productData['id']),
      canTakeAction: rawPartStatus == 'admin_approved',
    );
  }

  _DiagnosisPickingSection? _resolvePickingSection({
    required Map<String, dynamic> diagnosisMap,
    required Map<String, dynamic>? itemMap,
    required String fallbackTitle,
  }) {
    final rawStatus = _toText(
      itemMap?['status'] ??
          diagnosisMap['status'] ??
          itemMap?['diagnosis_status'] ??
          diagnosisMap['diagnosis_status'],
    ).toLowerCase();

    if (rawStatus != 'picking') return null;

    final source = itemMap ?? diagnosisMap;
    final productData =
        _toMap(source['product_data']) ?? const <String, dynamic>{};

    return _DiagnosisPickingSection(
      title: _pickFirstText([
        productData['product_name'],
        source['product_name'],
        source['name'],
        source['title'],
      ], fallback: fallbackTitle),
      requestId:
          _tryInt(source['request_id']) ??
          _tryInt(source['service_request_id']) ??
          _resolveRequestId(),
      serviceProductId:
          _tryInt(source['service_product_id']) ??
          _tryInt(source['service_request_product_id']) ??
          _tryInt(source['request_product_id']) ??
          _resolveServiceProductId(),
      productId:
          _tryInt(source['product_id']) ??
          _tryInt(diagnosisMap['product_id']) ??
          _tryInt(_args['productId']) ??
          _resolveServiceProductId() ??
          _tryInt(productData['product_id']) ??
          _tryInt(productData['id']),
    );
  }

  String _partActionKey(_DiagnosisPartSection section) {
    return [
      section.requestId?.toString() ??
          _resolveRequestId()?.toString() ??
          'no_request',
      section.serviceProductId?.toString() ??
          _resolveServiceProductId()?.toString() ??
          'no_service_product',
      section.diagnosisId?.toString() ?? 'no_diagnosis',
      section.partId?.toString() ?? 'no_part',
      section.title.toLowerCase(),
    ].join('|');
  }

  Future<void> _submitPartAction({
    required _DiagnosisPartSection section,
    required String partStatus,
  }) async {
    final key = _partActionKey(section);
    if (_activePartActionKey != null) return;

    final requestId = section.requestId ?? _resolveRequestId();
    final serviceProductId =
        section.serviceProductId ?? _resolveServiceProductId();
    final productId = section.productId ?? serviceProductId;
    final partId = section.partId;

    if (requestId == null || serviceProductId == null || productId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request id or product id is missing.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (partId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Part id is missing.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final roleId = await SecureStorageService.getRoleId();
    final customerId = await SecureStorageService.getUserId();

    if (roleId == null || customerId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _activePartActionKey = key;
    });

    try {
      final response = await ApiService.instance
          .submitServiceRequestPartApproval(
            requestId: requestId,
            roleId: roleId,
            customerId: customerId,
            action: partStatus,
            partId: partId,
            productId: productId,
          );

      if (!mounted) return;
      setState(() {
        _activePartActionKey = null;
        if (response.success) {
          _completedPartActionKeys.add(key);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ??
                (response.success
                    ? 'Part status updated successfully'
                    : 'Failed to update part status'),
          ),
          backgroundColor: response.success ? Colors.green : Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activePartActionKey = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update part status.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _pickingActionKey(_DiagnosisPickingSection section) {
    return [
      section.requestId?.toString() ??
          _resolveRequestId()?.toString() ??
          'no_request',
      section.serviceProductId?.toString() ??
          _resolveServiceProductId()?.toString() ??
          'no_service_product',
      section.productId?.toString() ?? 'no_product',
      section.title.toLowerCase(),
    ].join('|');
  }

  Future<void> _submitPickingAction({
    required _DiagnosisPickingSection section,
    required String action,
  }) async {
    final key = _pickingActionKey(section);
    if (_activePickingActionKey != null) return;

    final requestId = section.requestId ?? _resolveRequestId();
    final serviceProductId =
        section.serviceProductId ?? _resolveServiceProductId();
    final productId = section.productId ?? serviceProductId;

    if (requestId == null || serviceProductId == null || productId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request id or product id is missing.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final roleId = await SecureStorageService.getRoleId();
    final customerId = await SecureStorageService.getUserId();

    if (roleId == null || customerId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _activePickingActionKey = key;
    });

    try {
      final response = await ApiService.instance
          .submitServiceRequestPartApproval(
            requestId: requestId,
            roleId: roleId,
            customerId: customerId,
            action: action,
            productId: productId,
          );

      if (!mounted) return;
      setState(() {
        _activePickingActionKey = null;
        if (response.success) {
          _completedPickingActionKeys.add(key);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ??
                (response.success
                    ? 'Product picking status updated successfully'
                    : 'Failed to update product picking status'),
          ),
          backgroundColor: response.success ? Colors.green : Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activePickingActionKey = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update product picking status.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade200,
            child: ClipOval(
              child: Image.network(
                'https://img.freepik.com/free-photo/young-bearded-man-with-striped-shirt_273609-5677.jpg',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, color: Colors.grey),
              ),
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
              item: item,
              isLast: index == group.diagnostics.length - 1,
            );
          }),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTimelineItem({
    required _DiagnosisItem item,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                item.isWorking ? Icons.check_circle_outline : Icons.close,
                color: item.isWorking ? Colors.green : Colors.red,
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
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSmallImage(),
                  if (item.pickingSection != null) ...[
                    const SizedBox(height: 10),
                    _buildPickingApprovalSection(item.pickingSection!),
                  ],
                  if (item.partSection != null) ...[
                    const SizedBox(height: 10),
                    _buildPartApprovalSection(item.partSection!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickingApprovalSection(_DiagnosisPickingSection section) {
    final key = _pickingActionKey(section);
    final isSubmitting = _activePickingActionKey == key;
    final hasActionCompleted = _completedPickingActionKeys.contains(key);

    if (hasActionCompleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Picking decision submitted.',
          style: TextStyle(
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFFFE082)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Status: Picking',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting
                      ? null
                      : () => _submitPickingAction(
                          section: section,
                          action: 'customer_rejected',
                        ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Reject',
                          style: TextStyle(color: Colors.red),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () => _submitPickingAction(
                          section: section,
                          action: 'customer_approved',
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Approve',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartApprovalSection(_DiagnosisPartSection section) {
    final key = _partActionKey(section);
    final isSubmitting = _activePartActionKey == key;
    final hasActionCompleted = _completedPartActionKeys.contains(key);
    final showActionButtons = section.canTakeAction && !hasActionCompleted;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: section.imageUrl.isEmpty
                    ? const Icon(Icons.image_outlined, color: Colors.grey)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(
                          section.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (section.priceText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        section.priceText,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                    const Text(
                      'Incl. Shipping & all Taxes',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Qty: ${section.quantityText}',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showActionButtons) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting
                      ? null
                      : () => _submitPartAction(
                          section: section,
                          partStatus: 'customer_rejected',
                        ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Reject',
                          style: TextStyle(color: Colors.red, fontSize: 24),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting
                      ? null
                      : () => _submitPartAction(
                          section: section,
                          partStatus: 'customer_approved',
                        ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Approve',
                          style: TextStyle(
                            color: Color(0xFF1B5E20),
                            fontSize: 24,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSmallImage() {
    final imageUrl = _resolveImageUrl(_args['imageUrl']);
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
  final List<_DiagnosisItem> diagnostics;

  const _DiagnosisGroup({
    this.productId,
    required this.productName,
    required this.diagnostics,
  });
}

class _DiagnosisItem {
  final String title;
  final bool isWorking;
  final _DiagnosisPickingSection? pickingSection;
  final _DiagnosisPartSection? partSection;

  const _DiagnosisItem({
    required this.title,
    required this.isWorking,
    required this.pickingSection,
    required this.partSection,
  });
}

class _DiagnosisPickingSection {
  final String title;
  final int? requestId;
  final int? serviceProductId;
  final int? productId;

  const _DiagnosisPickingSection({
    required this.title,
    this.requestId,
    this.serviceProductId,
    this.productId,
  });
}

class _DiagnosisPartSection {
  final String title;
  final String priceText;
  final String quantityText;
  final String imageUrl;
  final int? requestId;
  final int? serviceProductId;
  final int? diagnosisId;
  final int? partId;
  final int? productId;
  final bool canTakeAction;

  const _DiagnosisPartSection({
    required this.title,
    required this.priceText,
    required this.quantityText,
    required this.imageUrl,
    this.requestId,
    this.serviceProductId,
    this.diagnosisId,
    this.partId,
    this.productId,
    required this.canTakeAction,
  });
}
