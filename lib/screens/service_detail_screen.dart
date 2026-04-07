import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/quick_service_model.dart';
import '../models/reward_coupon_model.dart';
import '../screens/rewards_screen.dart';
import '../services/api_service.dart';
import '../services/reward_local_service.dart';
import '../widgets/claim_reward_button.dart';
import '../widgets/scratch_reward_popup.dart';

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
  RewardCoupon? _reward;

  bool _hasDisplayableHtml(String value) {
    final normalized = value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .trim();
    return normalized.isNotEmpty;
  }

  bool _looksLikeHtml(String value) {
    return RegExp(r'<[a-z][\s\S]*>', caseSensitive: false).hasMatch(value);
  }

  String _extractTermsContent(Map<String, dynamic>? data) {
    final rawContent = data?['content'];
    if (rawContent is String) {
      return rawContent.trim();
    }

    if (rawContent is! List) {
      return '';
    }

    final buffer = StringBuffer();
    for (final item in rawContent) {
      if (item is! Map) continue;

      final map = item.map((key, value) => MapEntry(key.toString(), value));
      final type = map['type']?.toString().trim().toLowerCase() ?? '';
      final text = (map['text'] ?? map['content'] ?? map['value'] ?? '')
          .toString()
          .trim();
      if (text.isEmpty) continue;

      if (type == 'heading') {
        final rawLevel = int.tryParse('${map['level'] ?? ''}') ?? 1;
        final level = rawLevel.clamp(1, 4);
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.write('<h$level>$text</h$level>');
        continue;
      }

      if (type == 'paragraph') {
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.write('<p>$text</p>');
        continue;
      }

      if (buffer.isNotEmpty) {
        buffer.writeln();
        buffer.writeln();
      }
      buffer.write(text);
    }

    return buffer.toString().trim();
  }

  void _printApiLog(dynamic url, dynamic body, dynamic response) {
    print("API URL: $url");
    print("Request Body: $body");
    print("Response: $response");
  }

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

      final url = Uri.parse('${ApiConstants.service_detail}/$requestId').replace(
        queryParameters: {
          'role_id': roleId.toString(),
          'user_id': customerId.toString(),
        },
      ).toString();
      final body = {
        'service_id': requestId,
        'role_id': roleId,
        'user_id': customerId,
      };
      _printApiLog(url, body, 'Request started');

      final response = await ApiService.instance.getServiceDetails(
        serviceId: requestId,
        roleId: roleId,
        userId: customerId,
      );
      _printApiLog(url, body, response);

      if (!mounted) return;

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        final detail = response.data!;
        final nestedService =
            _toMap(detail['service']) ?? _toMap(detail['service_detail']) ?? <String, dynamic>{};
        final rawStatus = _pickFirstText(
          <dynamic>[
            detail['status'],
            detail['request_status'],
            detail['service_status'],
            nestedService['status'],
            widget.service?.status,
          ],
          fallback: 'unknown',
        );

        RewardCoupon? reward;
        if (_isCompletedStatus(rawStatus)) {
          reward = await RewardLocalService.instance.getRewardBySource(
            sourceType: 'service',
            sourceId: _rewardSourceId,
          );
        }

        if (!mounted) return;
        setState(() {
          _detailData = detail;
          _reward = reward;
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

  bool _isCompletedStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized.contains('completed') ||
        normalized.contains('complete') ||
        normalized.contains('closed') ||
        normalized.contains('delivered') ||
        normalized.contains('done');
  }

  String get _rewardSourceId {
    return widget.service?.id != null
        ? 'SRV${widget.service!.id}'
        : 'SRV${widget.service?.itemCode ?? widget.service?.serviceName ?? 'UNKNOWN'}';
  }

  Future<void> _openRewardPopup() async {
    final reward = await RewardLocalService.instance.createOrGetReward(
      sourceType: 'service',
      sourceId: _rewardSourceId,
    );
    if (!mounted) return;

    setState(() {
      _reward = reward;
    });

    final updatedReward = await ScratchRewardPopup.show(
      context,
      reward: reward,
      onRewardUpdated: (value) {
        if (!mounted) return;
        setState(() {
          _reward = value;
        });
      },
    );

    if (!mounted || updatedReward == null) return;
    setState(() {
      _reward = updatedReward;
    });
  }

  String _normalizeServiceType(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(' ', '_');
    if (normalized.contains('installation')) return 'installation';
    if (normalized.contains('repair')) return 'repair';
    return 'quick_service';
  }

  Future<void> _openTermsAndConditions(String serviceType) async {
    final response = await ApiService.instance.getStaticServiceTermsAndConditions(
      serviceType: _normalizeServiceType(serviceType),
    );
    if (!mounted) return;

    final terms = _extractTermsContent(response.data);
    if (!response.success || terms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ?? 'Terms & Conditions are not available.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ServiceTermsAndConditionsScreen(
          title:
              response.data?['title']?.toString().trim().isNotEmpty == true
                  ? response.data!['title'].toString().trim()
                  : 'Terms & Conditions',
          serviceName: _pickFirstText(
            [
              _detailData?['service_name'],
              _detailData?['name'],
              _detailData?['title'],
              widget.service?.serviceName,
            ],
            fallback: 'Service',
          ),
          termsAndConditions: terms,
        ),
      ),
    );
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
    final bool isCompleted = _isCompletedStatus(rawStatus);
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
            const SizedBox(height: 16),
            Wrap(
              children: [
                Text(
                  'By continuing, you confirm that you have read and agree to our ',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.grey.shade700,
                  ),
                ),
                GestureDetector(
                  onTap: () => _openTermsAndConditions(serviceType),
                  child: const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  '.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            if (isCompleted) ...[
              const SizedBox(height: 20),
              ClaimRewardButton(
                hasClaimed: _reward != null,
                onPressed: _openRewardPopup,
              ),
            ],
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
            if (_reward != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RewardsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('View My Rewards'),
                ),
              ),
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

class _ServiceTermsAndConditionsScreen extends StatelessWidget {
  const _ServiceTermsAndConditionsScreen({
    required this.title,
    required this.serviceName,
    required this.termsAndConditions,
  });

  final String title;
  final String serviceName;
  final String termsAndConditions;

  bool _hasDisplayableHtml(String value) {
    final normalized = value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .trim();
    return normalized.isNotEmpty;
  }

  bool _looksLikeHtml(String value) {
    return RegExp(r'<[a-z][\s\S]*>', caseSensitive: false).hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final hasHtml = _looksLikeHtml(termsAndConditions) &&
        _hasDisplayableHtml(termsAndConditions);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please review the service terms carefully before moving ahead.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: hasHtml
                  ? Html(
                      data: termsAndConditions,
                      style: {
                        'html': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(15),
                          lineHeight: const LineHeight(1.6),
                          color: Colors.black87,
                        ),
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(15),
                          lineHeight: const LineHeight(1.6),
                          color: Colors.black87,
                        ),
                        'h1': Style(
                          margin: Margins.only(bottom: 12),
                          fontSize: FontSize(18),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        'h2': Style(
                          margin: Margins.only(top: 12, bottom: 10),
                          fontSize: FontSize(17),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        'h3': Style(
                          margin: Margins.only(top: 10, bottom: 8),
                          fontSize: FontSize(16),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        'p': Style(
                          margin: Margins.only(bottom: 14),
                          fontSize: FontSize(15),
                          lineHeight: const LineHeight(1.7),
                          color: Colors.black87,
                        ),
                        'ul': Style(
                          margin: Margins.only(bottom: 14, left: 18),
                          padding: HtmlPaddings.zero,
                        ),
                        'ol': Style(
                          margin: Margins.only(bottom: 14, left: 18),
                          padding: HtmlPaddings.zero,
                        ),
                        'li': Style(
                          margin: Margins.only(bottom: 8),
                          fontSize: FontSize(15),
                          lineHeight: const LineHeight(1.6),
                        ),
                      },
                    )
                  : Text(
                      termsAndConditions.trim(),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: Colors.black87,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
