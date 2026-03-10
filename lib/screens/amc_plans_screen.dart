import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/amc_plan_model.dart';
import '../provider/amc_plan_provider.dart';
import 'amc_plan_detail_screen.dart';

class AmcPlansScreen extends StatefulWidget {
  const AmcPlansScreen({
    super.key,
    this.supportTypeFilter,
    this.title = 'AMC Plans',
  });

  final String? supportTypeFilter;
  final String title;

  @override
  State<AmcPlansScreen> createState() => _AmcPlansScreenState();
}

class _AmcPlansScreenState extends State<AmcPlansScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AmcPlanProvider>().fetchAmcPlans(
        supportTypeFilter: widget.supportTypeFilter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: Consumer<AmcPlanProvider>(
        builder: (context, provider, child) {
          final filteredPlans = _filteredPlans(provider.amcPlans);

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${provider.errorMessage}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.fetchAmcPlans(
                        supportTypeFilter: widget.supportTypeFilter,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (filteredPlans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.supportTypeFilter == null
                        ? 'No AMC plans available'
                        : 'No ${widget.supportTypeFilter} AMC plans available',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchAmcPlans(
              supportTypeFilter: widget.supportTypeFilter,
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredPlans.length,
              itemBuilder: (context, index) =>
                  _buildPlanCard(filteredPlans[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(AmcPlanItem planItem) {
    final plan = planItem.plan;
    final coveredItems = planItem.coveredItems ?? [];
    final status = (plan?.status ?? 'inactive').trim().toLowerCase();
    final isActive = status == 'active';
    final planName = (plan?.planName ?? '').trim().isNotEmpty
        ? plan!.planName!
        : 'N/A';
    final planCode = (plan?.planCode ?? '').trim();
    final description = (plan?.description ?? '').trim();
    final totalCost = (plan?.totalCost ?? '').trim().isNotEmpty
        ? plan!.totalCost!
        : '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (plan?.id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AmcPlanDetailScreen(
                  planId: plan!.id!,
                  requestButtonLabel: 'Request for AMC',
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          planName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (planCode.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            planCode,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[50] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.green[700] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.calendar_today,
                    '${plan?.duration ?? 0} months',
                  ),
                  _buildInfoChip(
                    Icons.support_agent,
                    '${plan?.totalVisits ?? 0} visits',
                  ),
                  _buildInfoChip(
                    Icons.build,
                    '${coveredItems.length} services',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Cost',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹$totalCost',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (plan?.id != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AmcPlanDetailScreen(
                                planId: plan!.id!,
                                requestButtonLabel: 'Request for AMC',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(color: Colors.white),
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  List<AmcPlanItem> _filteredPlans(List<AmcPlanItem> plans) {
    final filter = widget.supportTypeFilter?.trim().toLowerCase();
    if (filter == null || filter.isEmpty) {
      return plans;
    }

    return plans.where((item) {
      final plan = item.plan;
      if (plan == null) {
        return false;
      }
      return plan.matchesSupportFilter(filter);
    }).toList();
  }
}
