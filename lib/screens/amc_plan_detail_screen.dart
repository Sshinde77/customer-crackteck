import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../provider/amc_plan_provider.dart';
import '../models/amc_plan_model.dart';
import 'service_request_screen.dart';

class AmcPlanDetailScreen extends StatefulWidget {
  final int planId;

  const AmcPlanDetailScreen({super.key, required this.planId});

  @override
  State<AmcPlanDetailScreen> createState() => _AmcPlanDetailScreenState();
}

class _AmcPlanDetailScreenState extends State<AmcPlanDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch plan details when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AmcPlanProvider>().fetchAmcPlanDetails(
        planId: widget.planId,
      );
    });
  }

  @override
  void dispose() {
    // Clear plan detail when leaving screen
    context.read<AmcPlanProvider>().clearPlanDetail();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AMC Plan Details',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: Consumer<AmcPlanProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingDetail) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.detailErrorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.detailErrorMessage}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        provider.fetchAmcPlanDetails(planId: widget.planId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final planDetail = provider.planDetail;
          if (planDetail == null) {
            return const Center(child: Text('No plan details available'));
          }

          final plan = planDetail.amcPlan;
          final coveredItems = planDetail.coveredItems ?? [];

          return RefreshIndicator(
            onRefresh: () =>
                provider.fetchAmcPlanDetails(planId: widget.planId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan Header Card
                  _buildPlanHeaderCard(plan),
                  const SizedBox(height: 16),

                  // Pricing Card
                  _buildPricingCard(plan),
                  const SizedBox(height: 16),

                  // Plan Details Card
                  _buildPlanDetailsCard(plan),
                  const SizedBox(height: 16),

                  // Covered Services Section
                  _buildCoveredServicesSection(coveredItems),
                  const SizedBox(height: 16),

                  // Action Buttons
                  _buildActionButtons(plan),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanHeaderCard(AmcPlan? plan) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan?.planName ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan?.planCode ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: plan?.status == 'active'
                        ? Colors.green
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    plan?.status?.toUpperCase() ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (plan?.description != null) ...[
              const SizedBox(height: 16),
              Text(
                plan!.description!,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard(AmcPlan? plan) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Plan Cost', '₹${plan?.planCost ?? '0'}'),
            const Divider(height: 24),
            _buildPriceRow('Tax', '₹${plan?.tax ?? '0'}'),
            const Divider(height: 24),
            _buildPriceRow(
              'Total Cost',
              '₹${plan?.totalCost ?? '0'}',
              isTotal: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.payment, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Payment Terms: ${plan?.payTerms?.replaceAll('_', ' ').toUpperCase() ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.primary : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanDetailsCard(AmcPlan? plan) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoBox(
                    Icons.calendar_today,
                    'Duration',
                    '${plan?.duration ?? 0} months',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoBox(
                    Icons.support_agent,
                    'Total Visits',
                    '${plan?.totalVisits ?? 0}',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.build_circle,
              'Support Type',
              plan?.supportType?.toUpperCase() ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCoveredServicesSection(List<CoveredItem> coveredItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Covered Services (${coveredItems.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (coveredItems.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No covered services',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...coveredItems.map((item) => _buildServiceCard(item)),
      ],
    );
  }

  Widget _buildServiceCard(CoveredItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.build_circle,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.serviceName ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.itemCode ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.serviceCharge ?? '0'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.status == 'active'
                            ? Colors.green[50]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.status?.toUpperCase() ?? 'N/A',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: item.status == 'active'
                              ? Colors.green[700]
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (item.diagnosisList != null &&
                item.diagnosisList!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Diagnosis Covered:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.diagnosisList!.map((diagnosis) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          diagnosis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AmcPlan? plan) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              // Navigate to AMC Service Request screen with plan data
              if (plan != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceRequestScreen(
                      title: 'AMC Service Request',
                      amcPlanData: {
                        'planId': plan.id,
                        'planName': plan.planName,
                        'planCode': plan.planCode,
                        'duration': plan.duration,
                        'totalVisits': plan.totalVisits,
                        'planCost': plan.planCost,
                        'tax': plan.tax,
                        'totalCost': plan.totalCost,
                        'supportType': plan.supportType,
                        'description': plan.description,
                      },
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Plan details not available'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Subscribe to Plan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (plan?.brochure != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Download brochure
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Brochure'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (plan?.brochure != null && plan?.tandc != null)
              const SizedBox(width: 12),
            if (plan?.tandc != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: View terms and conditions
                  },
                  icon: const Icon(Icons.description),
                  label: const Text('T&C'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
