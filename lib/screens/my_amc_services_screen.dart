import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/customer_amc_model.dart';
import '../services/api_service.dart';
import 'my_amc_service_detail_screen.dart';

class MyAmcServicesScreen extends StatefulWidget {
  const MyAmcServicesScreen({super.key});

  @override
  State<MyAmcServicesScreen> createState() => _MyAmcServicesScreenState();
}

class _MyAmcServicesScreenState extends State<MyAmcServicesScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<CustomerAmc> _amcs = const <CustomerAmc>[];

  @override
  void initState() {
    super.initState();
    _fetchAmcs();
  }

  Future<void> _fetchAmcs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final int? userId = await SecureStorageService.getUserId();
      final int? roleId = await SecureStorageService.getRoleId();

      if (userId == null || roleId == null) {
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.instance.getCustomerAmcs(
        roleId: roleId,
        userId: userId,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (response.success) {
          _amcs = response.data ?? const <CustomerAmc>[];
        } else {
          _errorMessage = response.message ?? 'Failed to load AMC services';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unexpected error: $e';
      });
    }
  }

  String _formatDate(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return '-';

    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      return text.split(' ').first;
    }

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

    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  }

  String _formatMoney(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return 'Rs 0';
    final lower = text.toLowerCase();
    if (lower.contains('rs') || text.contains('₹')) {
      return text;
    }
    return 'Rs $text';
  }

  Color _statusColor(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.contains('active')) return Colors.green;
    if (normalized.contains('expired')) return Colors.red;
    if (normalized.contains('pending')) return Colors.orange;
    return Colors.blueGrey;
  }

  void _openAmcDetail(CustomerAmc amc) {
    final amcId = amc.id;
    if (amcId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AMC details are not available for this item.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyAmcServiceDetailScreen(amcId: amcId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'My AMC Service',
          style: TextStyle(color: Colors.white),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 56),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchAmcs,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_amcs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchAmcs,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No AMC services found')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAmcs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _amcs.length,
        itemBuilder: (context, index) => _buildAmcCard(_amcs[index]),
      ),
    );
  }

  Widget _buildAmcCard(CustomerAmc amc) {
    final statusColor = _statusColor(amc.displayStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openAmcDetail(amc),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          amc.displayTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (amc.displayCode.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            amc.displayCode,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      amc.displayStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (amc.displayDescription.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  amc.displayDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.timelapse_outlined, '${amc.displayDuration} months'),
                  _buildInfoChip(Icons.support_agent_outlined, '${amc.displayTotalVisits} visits'),
                  _buildInfoChip(Icons.build_circle_outlined, amc.displaySupportType),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AMC Amount',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatMoney(amc.displayTotalAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Valid Till',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(amc.endDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
