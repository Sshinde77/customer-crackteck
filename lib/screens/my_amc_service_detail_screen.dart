import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/customer_amc_model.dart';
import '../services/api_service.dart';

class MyAmcServiceDetailScreen extends StatefulWidget {
  const MyAmcServiceDetailScreen({
    super.key,
    required this.amcId,
  });

  final int amcId;

  @override
  State<MyAmcServiceDetailScreen> createState() => _MyAmcServiceDetailScreenState();
}

class _MyAmcServiceDetailScreenState extends State<MyAmcServiceDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  CustomerAmc? _amc;

  @override
  void initState() {
    super.initState();
    _fetchAmcDetail();
  }

  Future<void> _fetchAmcDetail() async {
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

      final response = await ApiService.instance.getCustomerAmcDetail(
        amcId: widget.amcId,
        roleId: roleId,
        userId: userId,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (response.success) {
          _amc = response.data;
        } else {
          _errorMessage = response.message ?? 'Failed to load AMC details';
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
    if (parsed == null) return text;

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
    if (lower.contains('rs') || text.contains('₹')) return text;
    return 'Rs $text';
  }

  Color _statusColor(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.contains('active')) return Colors.green;
    if (normalized.contains('expired')) return Colors.red;
    if (normalized.contains('pending')) return Colors.orange;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'AMC Details',
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
                onPressed: _fetchAmcDetail,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final amc = _amc;
    if (amc == null) {
      return const Center(child: Text('No AMC details available'));
    }

    return RefreshIndicator(
      onRefresh: _fetchAmcDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(amc),
            const SizedBox(height: 16),
            _buildOverviewSection(amc),
            const SizedBox(height: 16),
            _buildTimelineSection(amc),
            if ((amc.additionalNotes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNotesSection(amc),
            ],
            const SizedBox(height: 16),
            _buildCoveredServicesSection(amc),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(CustomerAmc amc) {
    final statusColor = _statusColor(amc.displayStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
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
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (amc.displayCode.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        amc.displayCode,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  amc.displayStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.96),
                  ),
                ),
              ),
            ],
          ),
          if (amc.displayDescription.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              amc.displayDescription,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewSection(CustomerAmc amc) {
    final priorityLevel = (amc.priorityLevel ?? '').trim();
    final payTerms = (amc.payTerms ?? '').trim();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AMC Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildInfoTile(
                  icon: Icons.payments_outlined,
                  label: 'Total Amount',
                  value: _formatMoney(amc.displayTotalAmount),
                  color: AppColors.primary,
                ),
                _buildInfoTile(
                  icon: Icons.timelapse_outlined,
                  label: 'Duration',
                  value: '${amc.displayDuration} months',
                  color: Colors.orange,
                ),
                _buildInfoTile(
                  icon: Icons.support_agent_outlined,
                  label: 'Total Visits',
                  value: amc.displayTotalVisits,
                  color: Colors.green,
                ),
                _buildInfoTile(
                  icon: Icons.build_circle_outlined,
                  label: 'Support Type',
                  value: amc.displaySupportType.toUpperCase(),
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.priority_high,
              label: 'Priority Level',
              value: priorityLevel.isEmpty ? '-' : priorityLevel,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Payment Terms',
              value: payTerms.isEmpty ? '-' : payTerms,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(CustomerAmc amc) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timeline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.play_circle_outline,
              label: 'Start Date',
              value: _formatDate(amc.startDate),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.stop_circle_outlined,
              label: 'End Date',
              value: _formatDate(amc.endDate),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Created On',
              value: _formatDate(amc.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(CustomerAmc amc) {
    final notes = (amc.additionalNotes ?? '').trim();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              notes.isEmpty ? '-' : notes,
              style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoveredServicesSection(CustomerAmc amc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Covered Services (${amc.coveredItems.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (!amc.hasCoveredItems)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No covered services available')),
            ),
          )
        else
          ...amc.coveredItems.map(
            (item) {
              final serviceName = (item.serviceName ?? '').trim();
              final itemCode = (item.itemCode ?? '').trim();
              final serviceType = (item.serviceType ?? '').trim();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName.isEmpty ? 'Unnamed Service' : serviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (itemCode.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          itemCode,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMiniChip(
                            Icons.category_outlined,
                            serviceType.isEmpty ? 'Service' : serviceType,
                          ),
                          _buildMiniChip(
                            Icons.payments_outlined,
                            _formatMoney(item.serviceCharge),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label.isEmpty ? '-' : label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
