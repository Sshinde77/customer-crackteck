import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../services/api_service.dart';
import 'feedback_detail_screen.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _feedbacks = [];

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
        setState(() {
          _feedbacks = List<Map<String, dynamic>>.from(response.data ?? []);
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
      return const Center(child: CircularProgressIndicator());
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

          final String name =
              feedback['customer_name']?.toString() ?? 'User';

          final String rawDate =
              feedback['created_at']?.toString() ?? '';
          final String date = rawDate.isNotEmpty
              ? rawDate.split(' ').first
              : '';

          final int rating =
              int.tryParse(feedback['rating']?.toString() ?? '0') ?? 0;

          final String comment =
              feedback['comments']?.toString() ?? '';

          return _feedbackCard(
            name: name,
            date: date,
            rating: rating,
            comment: comment,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FeedbackDetailScreen(
                    feedbackId: feedback['id'].toString(),
                  ),
                ),
              );
            },
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
                      color: i < rating
                          ? Colors.amber
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            /// Date
            Text(
              date,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
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
      ),
    );
  }
}
