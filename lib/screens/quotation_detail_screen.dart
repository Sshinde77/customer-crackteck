import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/core/secure_storage_service.dart';
import '../services/api_service.dart';
import '../widgets/app_loading_screen.dart';

class QuotationDetailScreen extends StatefulWidget {
  const QuotationDetailScreen({
    super.key,
    required this.quotationId,
  });

  final int quotationId;

  @override
  State<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  QuotationDetailData? _quotation;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchQuotationDetail();
  }

  Future<void> _fetchQuotationDetail() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final int roleId =
          (await SecureStorageService.getRoleId()) ?? AppStrings.roleId;
      final int? userId = await SecureStorageService.getUserId();

      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'User session missing. Please login again.';
        });
        return;
      }

      final response = await ApiService.instance.getQuotationDetail(
        quotationId: widget.quotationId,
        roleId: roleId,
        userId: userId,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _quotation = QuotationDetailData.fromJson(response.data!);
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = response.message ?? 'Failed to fetch quotation detail';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred while loading details.';
      });
    }
  }

  Future<void> _submitQuotationAction({required bool approve}) async {
    if (_isActionLoading) return;

    final QuotationDetailData? quotation = _quotation;
    if (quotation == null) return;

    setState(() => _isActionLoading = true);

    try {
      final int roleId =
          (await SecureStorageService.getRoleId()) ?? AppStrings.roleId;
      final int? userId = await SecureStorageService.getUserId();

      if (userId == null) {
        if (!mounted) return;
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User session missing. Please login again.')),
        );
        return;
      }

      final response = approve
          ? await ApiService.instance.acceptQuotation(
              quotationId: widget.quotationId,
              roleId: roleId,
              userId: userId,
            )
          : await ApiService.instance.rejectQuotation(
              quotationId: widget.quotationId,
              roleId: roleId,
              userId: userId,
            );

      if (!mounted) return;

      setState(() {
        _isActionLoading = false;
        if (response.success) {
          _quotation = quotation.copyWith(
            status: approve ? 'accepted' : 'rejected',
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ??
                (approve
                    ? 'Quotation approved successfully'
                    : 'Quotation rejected successfully'),
          ),
          backgroundColor:
              response.success ? AppColors.primary : Colors.red.shade600,
        ),
      );

      if (response.success) {
        _fetchQuotationDetail();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update quotation status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final QuotationDetailData? quotation = _quotation;

    if (_isLoading && quotation == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.primary,
          title: const Text(
            'Quotation Details',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const AppLoadingScreen(message: 'Loading quotation details.'),
      );
    }

    if (quotation == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.primary,
          title: const Text(
            'Quotation Details',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage ?? 'Quotation details unavailable',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _fetchQuotationDetail,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text(
          'Quotation Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(
              title: 'Header',
              icon: Icons.receipt_long_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          quotation.quoteNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF101828),
                          ),
                        ),
                      ),
                      _StatusChip(status: quotation.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _twoColFields(
                    context,
                    fields: [
                      _InfoFieldData(
                        icon: Icons.calendar_today_outlined,
                        label: 'Quote Date',
                        value: _formatDate(quotation.quoteDate),
                      ),
                      _InfoFieldData(
                        icon: Icons.event_busy_outlined,
                        label: 'Expiry Date',
                        value: _formatDate(quotation.expiryDate),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // _sectionCard(
            //   title: 'Lead Information',
            //   icon: Icons.support_agent_outlined,
            //   child: _twoColFields(
            //     context,
            //     fields: [
            //       _InfoFieldData(
            //         icon: Icons.confirmation_num_outlined,
            //         label: 'Lead Number',
            //         value: quotation.leadDetails.leadNumber,
            //       ),
            //       _InfoFieldData(
            //         icon: Icons.tune_outlined,
            //         label: 'Requirement Type',
            //         value: quotation.leadDetails.requirementType,
            //       ),
            //       _InfoFieldData(
            //         icon: Icons.account_balance_wallet_outlined,
            //         label: 'Budget Range',
            //         value: quotation.leadDetails.budgetRange,
            //       ),
            //       _InfoFieldData(
            //         icon: Icons.priority_high_outlined,
            //         label: 'Urgency',
            //         value: quotation.leadDetails.urgency,
            //       ),
            //       _InfoFieldData(
            //         icon: Icons.assessment_outlined,
            //         label: 'Estimated Value',
            //         value: _formatMoney(
            //           quotation.leadDetails.estimatedValue,
            //           quotation.currency,
            //         ),
            //       ),
            //       _InfoFieldData(
            //         icon: Icons.flag_outlined,
            //         label: 'Lead Status',
            //         value: quotation.leadDetails.status,
            //       ),
            //     ],
            //   ),
            // ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'AMC Plan',
              icon: Icons.build_circle_outlined,
              child: _twoColFields(
                context,
                fields: [
                  _InfoFieldData(
                    icon: Icons.timelapse_outlined,
                    label: 'Plan Duration',
                    value: quotation.amcData.planDuration,
                  ),
                  _InfoFieldData(
                    icon: Icons.play_circle_outline,
                    label: 'Start Date',
                    value: _formatDate(quotation.amcData.planStartDate),
                  ),
                  _InfoFieldData(
                    icon: Icons.stop_circle_outlined,
                    label: 'End Date',
                    value: _formatDate(quotation.amcData.planEndDate),
                  ),
                  _InfoFieldData(
                    icon: Icons.priority_high,
                    label: 'Priority Level',
                    value: quotation.amcData.priorityLevel,
                  ),
                  _InfoFieldData(
                    icon: Icons.payments_outlined,
                    label: 'AMC Total Amount',
                    value: _formatMoney(
                      quotation.amcData.totalAmount,
                      quotation.currency,
                    ),
                  ),
                  _InfoFieldData(
                    icon: Icons.sticky_note_2_outlined,
                    label: 'Additional Notes',
                    value: quotation.amcData.additionalNotes.isEmpty
                        ? '-'
                        : quotation.amcData.additionalNotes,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Products',
              icon: Icons.inventory_2_outlined,
              child: Column(
                children: [
                  for (int index = 0; index < quotation.products.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == quotation.products.length - 1 ? 0 : 12,
                      ),
                      child: _ProductCard(
                        product: quotation.products[index],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isFinalDecisionStatus(quotation.status)
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isActionLoading
                            ? null
                            : () => _submitQuotationAction(approve: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isActionLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.close),
                        label: Text(_isActionLoading ? 'Please wait' : 'Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isActionLoading
                            ? null
                            : () => _submitQuotationAction(approve: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isActionLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isActionLoading ? 'Please wait' : 'Approve'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  bool _isFinalDecisionStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'accepted' || normalized == 'rejected';
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D2939),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _twoColFields(
    BuildContext context, {
    required List<_InfoFieldData> fields,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 560;
        final double itemWidth = isWide
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: fields
              .map(
                (field) => SizedBox(
                  width: itemWidth,
                  child: _InfoField(
                    icon: field.icon,
                    label: field.label,
                    value: field.value,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF667085)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1D2939),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
  });

  final QuotationProductLine product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECF0)),
        color: const Color(0xFFFCFCFD),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 560;
          final double itemWidth = isWide
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;

          final fields = [
            _InfoFieldData(
              icon: Icons.inventory_2_outlined,
              label: 'Product Name',
              value: product.name,
            ),
            _InfoFieldData(
              icon: Icons.qr_code_2_outlined,
              label: 'Model Number',
              value: product.modelNo,
            ),
            _InfoFieldData(
              icon: Icons.business_outlined,
              label: 'Brand',
              value: product.brand,
            ),
            _InfoFieldData(
              icon: Icons.format_list_numbered_outlined,
              label: 'Quantity',
              value: _formatNumber(product.quantity),
            ),
          ];

          return Wrap(
            spacing: 12,
            runSpacing: 10,
            children: fields
                .map(
                  (field) => SizedBox(
                    width: itemWidth,
                    child: _InfoField(
                      icon: field.icon,
                      label: field.label,
                      value: field.value,
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _InfoFieldData {
  const _InfoFieldData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class QuotationDetailData {
  const QuotationDetailData({
    required this.quoteNumber,
    required this.quoteDate,
    required this.expiryDate,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.currency,
    required this.leadDetails,
    required this.amcData,
    required this.products,
  });

  final String quoteNumber;
  final String quoteDate;
  final String expiryDate;
  final String status;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String currency;
  final LeadDetails leadDetails;
  final AmcPlanData amcData;
  final List<QuotationProductLine> products;

  QuotationDetailData copyWith({
    String? status,
  }) {
    return QuotationDetailData(
      quoteNumber: quoteNumber,
      quoteDate: quoteDate,
      expiryDate: expiryDate,
      status: status ?? this.status,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      currency: currency,
      leadDetails: leadDetails,
      amcData: amcData,
      products: products,
    );
  }

  factory QuotationDetailData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? leadSource =
        _toMap(json['lead_details']) ??
        _toMap(json['lead_detail']) ??
        _toMap(json['lead']) ??
        _toMap(json['lead_data']);

    final Map<String, dynamic>? amcSource =
        _toMap(json['amc_data']) ?? _toMap(json['amc']) ?? _toMap(json['amc_plan']);

    final dynamic productsNode =
        json['products'] ??
        json['quotation_products'] ??
        json['items'] ??
        json['product_lines'];

    return QuotationDetailData(
      quoteNumber:
          (json['quote_number'] ??
                  json['quotation_number'] ??
                  json['quote_id'] ??
                  json['id'] ??
                  '')
              .toString(),
      quoteDate: (json['quote_date'] ?? json['created_at'] ?? '').toString(),
      expiryDate:
          (json['expiry_date'] ?? json['expire_date'] ?? json['valid_till'] ?? '')
              .toString(),
      status: (json['status'] ?? json['quotation_status'] ?? 'pending').toString(),
      subtotal: _toDouble(json['subtotal']),
      discountAmount: _toDouble(json['discount_amount']),
      taxAmount: _toDouble(json['tax_amount']),
      totalAmount: _toDouble(json['total_amount']),
      currency: (json['currency'] ?? 'INR').toString(),
      leadDetails: LeadDetails.fromJson(
        leadSource ?? const <String, dynamic>{},
      ),
      amcData: AmcPlanData.fromJson(
        amcSource ?? const <String, dynamic>{},
      ),
      products: ((productsNode as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => QuotationProductLine.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }
}

class LeadDetails {
  const LeadDetails({
    required this.leadNumber,
    required this.requirementType,
    required this.budgetRange,
    required this.urgency,
    required this.estimatedValue,
    required this.status,
  });

  final String leadNumber;
  final String requirementType;
  final String budgetRange;
  final String urgency;
  final double estimatedValue;
  final String status;

  factory LeadDetails.fromJson(Map<String, dynamic> json) {
    return LeadDetails(
      leadNumber: (json['lead_number'] ?? json['lead_id'] ?? '').toString(),
      requirementType: (json['requirement_type'] ?? '').toString(),
      budgetRange: (json['budget_range'] ?? '').toString(),
      urgency: (json['urgency'] ?? '').toString(),
      estimatedValue: _toDouble(json['estimated_value']),
      status: (json['status'] ?? json['lead_status'] ?? '').toString(),
    );
  }
}

class AmcPlanData {
  const AmcPlanData({
    required this.planDuration,
    required this.planStartDate,
    required this.planEndDate,
    required this.priorityLevel,
    required this.totalAmount,
    required this.additionalNotes,
  });

  final String planDuration;
  final String planStartDate;
  final String planEndDate;
  final String priorityLevel;
  final double totalAmount;
  final String additionalNotes;

  factory AmcPlanData.fromJson(Map<String, dynamic> json) {
    return AmcPlanData(
      planDuration: (json['plan_duration'] ?? '').toString(),
      planStartDate: (json['plan_start_date'] ?? json['start_date'] ?? '').toString(),
      planEndDate: (json['plan_end_date'] ?? json['end_date'] ?? '').toString(),
      priorityLevel: (json['priority_level'] ?? '').toString(),
      totalAmount: _toDouble(json['total_amount']),
      additionalNotes: (json['additional_notes'] ?? json['notes'] ?? '').toString(),
    );
  }
}

class QuotationProductLine {
  const QuotationProductLine({
    required this.name,
    required this.modelNo,
    required this.brand,
    required this.type,
    required this.hsn,
    required this.quantity,
    required this.unitPrice,
    required this.discountPerUnit,
    required this.taxRate,
    required this.lineTotal,
  });

  final String name;
  final String modelNo;
  final String brand;
  final String type;
  final String hsn;
  final double quantity;
  final double unitPrice;
  final double discountPerUnit;
  final double taxRate;
  final double lineTotal;

  factory QuotationProductLine.fromJson(Map<String, dynamic> json) {
    return QuotationProductLine(
      name: (json['name'] ?? json['product_name'] ?? '').toString(),
      modelNo: (json['model_no'] ?? json['model'] ?? '').toString(),
      brand: (json['brand'] ?? json['brand_name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      hsn: (json['hsn'] ?? '').toString(),
      quantity: _toDouble(json['quantity']),
      unitPrice: _toDouble(json['unit_price']),
      discountPerUnit: _toDouble(json['discount_per_unit']),
      taxRate: _toDouble(json['tax_rate']),
      lineTotal: _toDouble(json['line_total']),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    case 'pending':
      return Colors.orange;
    default:
      return Colors.blueGrey;
  }
}

String _formatDate(String input) {
  final DateTime? date = DateTime.tryParse(input);
  if (date == null) return input;

  const List<String> months = [
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

  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

String _formatMoney(double amount, String currency) {
  final String symbol = _currencySymbol(currency);
  return '$symbol ${amount.toStringAsFixed(2)}';
}

String _currencySymbol(String currency) {
  switch (currency.toUpperCase()) {
    case 'INR':
      return 'Rs';
    case 'USD':
      return '\$';
    case 'EUR':
      return 'EUR';
    default:
      return currency.toUpperCase();
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

Map<String, dynamic>? _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
