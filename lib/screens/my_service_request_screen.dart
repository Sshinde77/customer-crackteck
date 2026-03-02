import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/service_request_list_model.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';

class MyServiceRequestScreen extends StatefulWidget {
  const MyServiceRequestScreen({super.key});

  @override
  State<MyServiceRequestScreen> createState() => _MyServiceRequestScreenState();
}

class _MyServiceRequestScreenState extends State<MyServiceRequestScreen> {
  int selectedTab = 0; // 0 for Done, 1 for Pending
  bool _isLoading = true;
  String? _errorMessage;
  List<ServiceRequestListItem> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customerId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (customerId == null || roleId == null) {
        setState(() {
          _errorMessage = 'User session expired. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.instance.getAllServiceRequests(
        roleId: roleId,
        customerId: customerId,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _requests = response.data!;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _errorMessage = response.message ?? 'Failed to load service requests';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsToShow = _requests
        .where((r) => selectedTab == 0 ? r.isDone : !r.isDone)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Service Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildToggleTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _fetchRequests,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchRequests,
                    child: requestsToShow.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Center(
                                child: Text(
                                  selectedTab == 0
                                      ? 'No done requests found'
                                      : 'No pending requests found',
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: requestsToShow.length,
                            itemBuilder: (context, index) {
                              return _buildRequestCard(requestsToShow[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.calendar_month, color: Colors.white),
        label: const Text('Calendar', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildToggleTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedTab == 0
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Done',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selectedTab == 0 ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedTab == 1
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Pending',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selectedTab == 1 ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(ServiceRequestListItem request) {
    final isDone = request.isDone;
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.serviceRequestDetails,
          arguments: request.raw,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.displayServiceType,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow('Service Type', request.displayServiceType),
            _buildInfoRow('Request ID', request.displayRequestId),
            _buildInfoRow(
              'Request Date',
              _formatRequestDate(request.displayRequestDate),
            ),
            _buildInfoRow('Status', request.displayStatus),
            if (isDone) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showFeedbackDialog(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Give Feedback',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showFeedbackDialog(ServiceRequestListItem request) async {
    final result = await showDialog<_FeedbackDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _FeedbackDialog(request: request),
    );

    if (!mounted || result == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? AppColors.primary
            : Colors.red.shade600,
      ),
    );

    if (result.success) {
      _fetchRequests();
    }
  }

  String _formatRequestDate(String value) {
    final raw = value.trim();
    if (raw.isEmpty || raw == '-') return '-';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[parsed.month - 1];
    final day = parsed.day.toString().padLeft(2, '0');
    final date = '$month $day, ${parsed.year}';

    int hour = parsed.hour % 12;
    if (hour == 0) hour = 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final meridiem = parsed.hour >= 12 ? 'PM' : 'AM';

    return '$date $hour:$minute $meridiem';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackDialogResult {
  final bool success;
  final String message;

  const _FeedbackDialogResult({required this.success, required this.message});
}

class _FeedbackDialog extends StatefulWidget {
  final ServiceRequestListItem request;

  const _FeedbackDialog({required this.request});

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final TextEditingController _commentsController = TextEditingController();
  final FocusNode _commentsFocusNode = FocusNode();

  int _rating = 4;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _commentsController.dispose();
    _commentsFocusNode.dispose();
    super.dispose();
  }

  String _normalizeServiceType(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty || raw == '-') return '';

    final snake = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceFirst(RegExp(r'^_+'), '')
        .replaceFirst(RegExp(r'_+$'), '');

    return snake;
  }

  String _resolveServiceType() {
    final raw = widget.request.raw;
    final candidates = <dynamic>[
      raw['service_type'],
      raw['type'],
      widget.request.serviceType,
      widget.request.displayServiceType,
    ];

    for (final candidate in candidates) {
      final normalized = _normalizeServiceType(candidate);
      if (normalized.isNotEmpty) return normalized;
    }

    return 'quick_service';
  }

  Map<String, dynamic>? _tryMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final cleaned = value.trim().replaceAll('#', '');
      if (cleaned.isEmpty) return null;
      if (!RegExp(r'^\d+$').hasMatch(cleaned)) return null;
      return int.tryParse(cleaned);
    }
    return null;
  }

  String? _normalizeServiceId(dynamic value) {
    if (value == null) return null;
    final id = _tryParseInt(value);
    if (id == null) return null;
    return id.toString();
  }

  String? _resolveServiceId() {
    final raw = widget.request.raw;
    final nestedService = _tryMap(raw['service']);
    final nestedServiceDetail = _tryMap(raw['service_detail']);
    final nestedQuickService = _tryMap(raw['quick_service']);

    final candidates = <dynamic>[
      nestedService?['id'],
      nestedService?['service_id'],
      nestedServiceDetail?['id'],
      nestedServiceDetail?['service_id'],
      nestedQuickService?['id'],
      nestedQuickService?['service_id'],
      raw['quick_service_id'],
      raw['service_master_id'],
      raw['service_type_id'],
      raw['id'],
      raw['request_id'],
      raw['service_id'],
      widget.request.requestId,
      widget.request.id,
      widget.request.serviceCode,
    ];

    for (final candidate in candidates) {
      final id = _normalizeServiceId(candidate);
      if (id != null) return id;
    }
    return null;
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Future<void> _submitFeedback() async {
    FocusScope.of(context).unfocus();
    final comments = _commentsController.text.trim();

    if (comments.isEmpty) {
      setState(
        () => _errorText = 'Please write a short comment before submitting.',
      );
      _commentsFocusNode.requestFocus();
      return;
    }

    final serviceId = _resolveServiceId();
    if (serviceId == null) {
      setState(() {
        _errorText = 'Valid numeric service ID not found for this request.';
      });
      return;
    }

    final roleId = await SecureStorageService.getRoleId();
    final customerId = await SecureStorageService.getUserId();

    if (roleId == null || customerId == null) {
      if (!mounted) return;
      Navigator.of(context).pop(
        const _FeedbackDialogResult(
          success: false,
          message: 'User session expired. Please login again.',
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final response = await ApiService.instance.giveFeedback(
      roleId: roleId,
      customerId: customerId,
      serviceType: _resolveServiceType(),
      serviceId: serviceId,
      rating: _rating,
      comments: comments,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (response.success) {
      Navigator.of(context).pop(
        _FeedbackDialogResult(
          success: true,
          message: response.message ?? 'Feedback submitted successfully.',
        ),
      );
      return;
    }

    setState(() {
      _errorText =
          response.message ?? 'Unable to submit feedback. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final serviceLabel = widget.request.displayServiceType == '-'
        ? 'Service Request'
        : widget.request.displayServiceType;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8F7EF), Color(0xFFDDF6E8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.rate_review_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share Your Feedback',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your review helps us improve service quality.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        serviceLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Rate this service',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final value = index + 1;
                        final selected = value <= _rating;
                        return GestureDetector(
                          onTap: _isSubmitting
                              ? null
                              : () => setState(() => _rating = value),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.14)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Icon(
                              selected
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: selected
                                  ? AppColors.primary
                                  : Colors.grey.shade500,
                              size: 26,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _ratingLabel(_rating),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _commentsController,
                      focusNode: _commentsFocusNode,
                      enabled: !_isSubmitting,
                      maxLines: 4,
                      minLines: 3,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Tell us about your experience...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.3,
                          ),
                        ),
                      ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorText!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitFeedback,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Submit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
