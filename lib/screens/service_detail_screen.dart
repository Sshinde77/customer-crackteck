import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/quick_service_model.dart';
import '../services/api_service.dart';

class ServiceDetailScreen extends StatefulWidget {
  final QuickService? service;
  final String imagePath;

  const ServiceDetailScreen({
    super.key,
    required this.service,
    required this.imagePath,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _detailData;

  @override
  void initState() {
    super.initState();
    _fetchServiceDetails();
  }

  Future<void> _fetchServiceDetails() async {
    final int? requestId = widget.service?.id;
    if (requestId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customerId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (customerId == null || roleId == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Unable to fetch latest details. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.instance.getServiceRequestDetails(
        requestId: requestId,
        roleId: roleId,
        customerId: customerId,
      );

      if (!mounted) return;

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _detailData = response.data;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _errorMessage = response.message ?? 'Failed to load service details';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load service details';
        _isLoading = false;
      });
    }
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

  String _pickFirstText(List<dynamic> values, {String fallback = 'N/A'}) {
    for (final value in values) {
      final text = _toText(value);
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  List<String> _resolveDiagnosis(Map<String, dynamic> detail, Map<String, dynamic> nestedService) {
    final dynamic diagnosisNode = detail['diagnosis_list'] ??
        detail['diagnosisList'] ??
        detail['diagnosis'] ??
        nestedService['diagnosis_list'] ??
        nestedService['diagnosisList'];

    if (diagnosisNode is List) {
      return diagnosisNode
          .map((item) {
            if (item is String) return item.trim();
            if (item is Map) {
              return _pickFirstText(
                [
                  item['diagnosis'],
                  item['name'],
                  item['title'],
                  item['description'],
                ],
                fallback: '',
              );
            }
            return _toText(item);
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (diagnosisNode is String && diagnosisNode.trim().isNotEmpty) {
      return diagnosisNode
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return widget.service?.diagnosisList ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> detail = _detailData ?? <String, dynamic>{};
    final Map<String, dynamic> nestedService =
        _toMap(detail['service']) ?? _toMap(detail['service_detail']) ?? <String, dynamic>{};

    final String serviceName = _pickFirstText(
      [
        detail['service_name'],
        detail['name'],
        detail['title'],
        nestedService['service_name'],
        nestedService['name'],
        widget.service?.serviceName,
      ],
    );

    final String serviceType = _pickFirstText(
      [
        detail['service_type'],
        detail['type'],
        nestedService['service_type'],
        nestedService['type'],
        widget.service?.serviceType,
      ],
    );

    final String serviceCharge = _pickFirstText(
      [
        detail['service_charge'],
        detail['amount'],
        detail['price'],
        nestedService['service_charge'],
        nestedService['amount'],
        nestedService['price'],
        widget.service?.serviceCharge,
      ],
      fallback: '0.00',
    );

    final String rawStatus = _pickFirstText(
      [
        detail['status'],
        detail['request_status'],
        detail['service_status'],
        nestedService['status'],
        widget.service?.status,
      ],
      fallback: 'unknown',
    );

    final String status = rawStatus.toUpperCase();
    final bool isActive = rawStatus.toLowerCase() == 'active';
    final List<String> diagnosis = _resolveDiagnosis(detail, nestedService);

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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      widget.imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          serviceType,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.shade50 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Service Type', serviceType),
            const SizedBox(height: 12),
            _buildInfoRow('Service Name', serviceName),
            const SizedBox(height: 12),
            _buildInfoRow('Service Charge', ' $serviceCharge'),
            const SizedBox(height: 12),
            _buildInfoRow('Status', status),
            const SizedBox(height: 20),
            const Text(
              'Diagnosis List',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (diagnosis.isEmpty)
              Text(
                'No diagnosis available',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: diagnosis.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          item,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
