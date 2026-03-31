import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../services/api_service.dart';
import '../widgets/app_loading_screen.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _feedbacks = [];

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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(_toText(value)) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
  }

  Future<void> _fetchFeedbacks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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

      final response = await ApiService.instance.getAllFeedback(
        roleId: roleId,
        customerId: customerId,
      );

      if (response.success) {
        final parsed = (response.data ?? const <dynamic>[])
            .map(_toMap)
            .whereType<Map<String, dynamic>>()
            .toList();
        setState(() {
          _feedbacks = parsed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load feedback';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
          "Feedback's",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoadingScreen(message: 'Loading your feedback.');
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchFeedbacks,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_feedbacks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchFeedbacks,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No feedback available')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFeedbacks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _feedbacks.length,
        itemBuilder: (context, index) {
          final feedback = _feedbacks[index];
          final customer =
              _toMap(feedback['customer']) ?? const <String, dynamic>{};

          final String name =
              _toText(
                feedback['customer_name'] ??
                    feedback['name'] ??
                    customer['name'] ??
                    customer['full_name'],
              ).isEmpty
              ? 'User'
              : _toText(
                  feedback['customer_name'] ??
                      feedback['name'] ??
                      customer['name'] ??
                      customer['full_name'],
                );

          final String rawDate = _toText(
            feedback['created_at'] ??
                feedback['updated_at'] ??
                feedback['date'],
          );
          final String date = rawDate.isNotEmpty
              ? rawDate.split(' ').first
              : '';

          final int rating = _toInt(feedback['rating']).clamp(0, 5);

          final String comment = _toText(
            feedback['comments'] ?? feedback['comment'],
          );
          return _feedbackCard(
            name: name,
            date: date,
            rating: rating,
            comment: comment,
          );
        },
      ),
    );
  }

  Widget _feedbackCard({
    required String name,
    required String date,
    required int rating,
    required String comment,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Name + Stars
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star,
                    size: 16,
                    color: i < rating ? Colors.amber : Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          /// Date
          Text(
            date,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),

          const SizedBox(height: 10),

          /// Comment
          Text(
            comment.isEmpty ? 'No comment provided' : comment,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
