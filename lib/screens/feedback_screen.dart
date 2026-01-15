import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../services/api_service.dart';
import 'give_feedback_screen.dart';
import 'feedback_detail_screen.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _givenFeedbacks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchGivenFeedbacks();
  }

  Future<void> _fetchGivenFeedbacks() async {
    if (!mounted) return;
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

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _givenFeedbacks = List<Map<String, dynamic>>.from(response.data ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load feedback';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'Feedback\'s',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Given'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingFeedbackList(),
          _buildGivenFeedbackList(),
        ],
      ),
    );
  }

  // ------------------ PENDING ------------------

  Widget _buildPendingFeedbackList() {
    // Note: This is currently static. In a real app, you would fetch this from an API.
    final List<Map<String, String>> pendingServices = [
      {'id': 'QS-001', 'type': 'Quick Service', 'date': '15 Jan 2024'},
      {'id': 'AMC-042', 'type': 'AMC Service', 'date': '12 Jan 2024'},
      {'id': 'INST-99', 'type': 'Installation', 'date': '08 Jan 2024'},
      {'id': 'REP-213', 'type': 'Repairing', 'date': '05 Jan 2024'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingServices.length,
      itemBuilder: (context, index) {
        final service = pendingServices[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.miscellaneous_services,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['type'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'ID: ${service['id']} | ${service['date']}',
                      style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GiveFeedbackScreen(service: service),
                    ),
                  );
                  if (result == true) {
                    _fetchGivenFeedbacks();
                    _tabController.animateTo(1); // Switch to "Given" tab on success
                  }
                },
                child: const Text('Feedback'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------ GIVEN ------------------

  Widget _buildGivenFeedbackList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchGivenFeedbacks, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_givenFeedbacks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchGivenFeedbacks,
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(child: Text('No feedback given yet')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchGivenFeedbacks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _givenFeedbacks.length,
        itemBuilder: (context, index) {
          final Map<String, dynamic> feedback = _givenFeedbacks[index];

          final String user = feedback['customer_name']?.toString() ?? 'User';
          final String date = feedback['created_at']?.toString() ?? '';
          final int rating = int.tryParse(feedback['rating']?.toString() ?? '0') ?? 0;
          final String comment = feedback['comments']?.toString() ?? '';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FeedbackDetailScreen(
                    feedbackId: '${feedback['id']}',
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(user,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      Row(
                        children: List.generate(
                          5,
                              (i) => Icon(Icons.star,
                              size: 16,
                              color: i < rating
                                  ? Colors.amber
                                  : Colors.grey.shade300),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (date.isNotEmpty)
                    Text(
                      date,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    comment.isEmpty ? 'No comment provided' : comment,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
