import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../services/api_service.dart';

class FeedbackDetailScreen extends StatefulWidget {
  final String feedbackId;

  const FeedbackDetailScreen({super.key, required this.feedbackId});

  @override
  State<FeedbackDetailScreen> createState() => _FeedbackDetailScreenState();
}

class _FeedbackDetailScreenState extends State<FeedbackDetailScreen> {
  Map<String, dynamic>? _feedbackDetails;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFeedbackDetails();
  }

  Future<void> _fetchFeedbackDetails() async {
    try {
      final customerId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (customerId == null || roleId == null) {
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.instance.getFeedbackDetails(
        roleId: roleId,
        customerId: customerId,
        feedbackId: widget.feedbackId,
      );

      if (mounted) {
        if (response.success) {
          setState(() {
            _feedbackDetails = response.data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = response.message ?? 'Failed to load feedback details';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isLoading = false;
        });
      }
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
          'Feedback Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchFeedbackDetails();
                },
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    if (_feedbackDetails == null) {
      return const Center(child: Text('No details found'));
    }

    // Mapping API response to UI
    // Assuming API returns: { id, customer_name, rating, comments, created_at, service_type }
    final String user = _feedbackDetails!['customer_name'] ?? 'User';
    final String date = _feedbackDetails!['created_at'] ?? '';
    final int rating = int.tryParse(_feedbackDetails!['rating']?.toString() ?? '0') ?? 0;
    final String comment = _feedbackDetails!['comments'] ?? 'No comment provided';
    final String? serviceType = _feedbackDetails!['service_type'];
    final String? serviceId = _feedbackDetails!['service_id'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User and Date Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                radius: 24,
                child: Text(
                  user.isNotEmpty ? user[0].toUpperCase() : 'U',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    date,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Rating Section
          const Text(
            'Rating',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                Icons.star,
                color: i < rating ? Colors.amber : Colors.grey.shade300,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Comment Section
          const Text(
            'Comment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              comment,
              style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Service Info if available
          if (serviceType != null || serviceId != null) ...[
             const Text(
              'Service Info',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (serviceType != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  'Service Type: ${serviceType.toUpperCase().replaceAll('_', ' ')}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            if (serviceId != null)
              Text(
                'Service ID: $serviceId',
                style: TextStyle(color: Colors.grey.shade700),
              ),
          ]
        ],
      ),
    );
  }
}
