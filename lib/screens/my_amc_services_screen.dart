import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/customer_amc_model.dart';
import '../services/api_service.dart';
import '../widgets/app_loading_screen.dart';
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
    if (lower.contains('rs') || lower.contains('inr')) {
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

  String _toDisplayCase(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return '-';

    return text
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  void _openAmcDetail(CustomerAmc amc) {
    final amcId = amc.id;
    if (amcId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AMC details are not available for this item.'),
        ),
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
      return const AppLoadingScreen(message: 'Loading your AMC services.');
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverviewBanner(),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your AMC Plans',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${_amcs.length} items',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Track request details, visit counts, and plan pricing in one view.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 14),
          ..._amcs.map(_buildAmcCard),
        ],
      ),
    );
  }

  Widget _buildOverviewBanner() {
    final int activeCount = _amcs
        .where(
          (amc) => amc.displayStatus.trim().toLowerCase().contains('active'),
        )
        .length;
    final int plannedVisits = _amcs.fold<int>(
      0,
      (sum, amc) => sum + (amc.scheduleMeetingsCount ?? 0),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.86),
            const Color(0xFF1B365D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AMC Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'A cleaner view of your AMC requests, service visits, and plan value.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildBannerStat('Total AMC', _amcs.length.toString()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBannerStat('Active', activeCount.toString()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBannerStat('Visits', plannedVisits.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmcCard(CustomerAmc amc) {
    final statusColor = _statusColor(amc.displayStatus);
    final planCode = (amc.amcPlan?.planCode ?? '').trim();
    final List<_AmcSummaryItem> summaryItems = <_AmcSummaryItem>[
      _AmcSummaryItem(
        label: 'Request ID',
        value: amc.displayRequestId,
        icon: Icons.confirmation_number_outlined,
      ),
      _AmcSummaryItem(
        label: 'AMC Type',
        value: _toDisplayCase(amc.displayAmcType),
        icon: Icons.settings_remote_outlined,
      ),
      _AmcSummaryItem(
        label: 'Request Date',
        value: _formatDate(amc.displayRequestDate),
        icon: Icons.event_outlined,
      ),
      _AmcSummaryItem(
        label: 'Scheduled Meetings',
        value: amc.displayScheduledMeetingsCount,
        icon: Icons.event_repeat_outlined,
      ),
      _AmcSummaryItem(
        label: 'Total Visits',
        value: amc.displayTotalVisits,
        icon: Icons.support_agent_outlined,
      ),
      _AmcSummaryItem(
        label: 'Plan Cost',
        value: _formatMoney(amc.displayPlanCost),
        icon: Icons.currency_rupee_outlined,
      ),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openAmcDetail(amc),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.miscellaneous_services_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        if (planCode.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Plan Code: $planCode',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _toDisplayCase(amc.displayStatus),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  const double spacing = 12;
                  final int columns = constraints.maxWidth >= 720 ? 3 : 2;
                  final double itemWidth =
                      (constraints.maxWidth - (spacing * (columns - 1))) /
                      columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: summaryItems
                        .map(
                          (item) => SizedBox(
                            width: itemWidth,
                            child: _buildSummaryTile(item),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey[700],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(_AmcSummaryItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmcSummaryItem {
  const _AmcSummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}
