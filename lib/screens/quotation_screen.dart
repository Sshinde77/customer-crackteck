import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/core/secure_storage_service.dart';
import '../services/api_service.dart';
import '../widgets/app_loading_screen.dart';
import 'quotation_detail_screen.dart';

class QuotationScreen extends StatefulWidget {
  const QuotationScreen({super.key});

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<QuotationItem> _quotations = [];

  @override
  void initState() {
    super.initState();
    _fetchQuotations();
  }

  Future<void> _fetchQuotations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final int roleId = (await SecureStorageService.getRoleId()) ?? AppStrings.roleId;
      final int? customerId = await SecureStorageService.getUserId();

      if (customerId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Customer session missing. Please login again.';
        });
        return;
      }

      final response = await ApiService.instance.getQuotationList(
        roleId: roleId,
        customerId: customerId,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _quotations = response.data!.map(QuotationItem.fromJson).toList();
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = response.message ?? 'Failed to fetch quotations';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred while loading quotations.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<QuotationItem> quotations = _quotations;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text(
          'Quotations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const AppLoadingScreen(message: 'Loading your quotations.')
          : _errorMessage != null
          ? _ErrorState(
              message: _errorMessage!,
              onRetry: _fetchQuotations,
            )
          : RefreshIndicator(
              onRefresh: _fetchQuotations,
              child: quotations.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
                      children: const [
                        Center(
                          child: Text(
                            'No quotations found',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF475467),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: quotations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _QuotationCard(quotation: quotations[index]);
                      },
                    ),
            ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotationCard extends StatelessWidget {
  const _QuotationCard({required this.quotation});

  final QuotationItem quotation;

  @override
  Widget build(BuildContext context) {
    final QuotationProduct? firstProduct =
        quotation.products.isNotEmpty ? quotation.products.first : null;

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
                const Icon(
                  Icons.receipt_long,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quotation.quoteNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                ),
                _StatusBadge(status: quotation.status),
              ],
            ),
            const SizedBox(height: 14),
            _sectionTitle('Customer Details'),
            const SizedBox(height: 8),
            _detailLine(
              icon: Icons.person_outline,
              label: 'Customer',
              value: quotation.customerName,
            ),
            const SizedBox(height: 6),
            _detailLine(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: quotation.phone,
            ),
            const SizedBox(height: 6),
            _detailLine(
              icon: Icons.confirmation_num_outlined,
              label: 'Lead Number',
              value: quotation.leadNumber,
            ),
            const SizedBox(height: 12),
            _sectionTitle('Product'),
            const SizedBox(height: 8),
            _detailLine(
              icon: Icons.inventory_2_outlined,
              label: 'Product Name',
              value: firstProduct?.name ?? '-',
            ),
            const SizedBox(height: 6),
            _detailLine(
              icon: Icons.qr_code_2_outlined,
              label: 'Model Number',
              value: firstProduct?.modelNo ?? '-',
            ),
            const SizedBox(height: 6),
            _detailLine(
              icon: Icons.business_outlined,
              label: 'Brand',
              value: firstProduct?.brand ?? '-',
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoChip(
                  icon: Icons.calendar_today_outlined,
                  label: 'Quote Date',
                  value: _formatDate(quotation.quoteDate),
                ),
                _infoChip(
                  icon: Icons.event_busy_outlined,
                  label: 'Expiry Date',
                  value: _formatDate(quotation.expiryDate),
                ),
                _infoChip(
                  icon: Icons.format_list_numbered_outlined,
                  label: 'Total Items',
                  value: quotation.totalItems.toString(),
                ),
                _infoChip(
                  icon: Icons.currency_rupee,
                  label: 'Total Amount',
                  value: _formatAmount(quotation.totalAmount),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (quotation.id <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Quotation ID is missing for this item'),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuotationDetailScreen(
                        quotationId: quotation.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('View Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF475467),
      ),
    );
  }

  Widget _detailLine({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF667085)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF344054)),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF667085)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF667085)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D2939),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

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
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
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

String _formatAmount(double amount) => 'Rs ${amount.toStringAsFixed(2)}';

class QuotationItem {
  QuotationItem({
    required this.id,
    required this.quoteNumber,
    required this.quoteDate,
    required this.expiryDate,
    required this.customerName,
    required this.phone,
    required this.leadNumber,
    required this.totalItems,
    required this.totalAmount,
    required this.status,
    required this.products,
  });

  final int id;
  final String quoteNumber;
  final String quoteDate;
  final String expiryDate;
  final String customerName;
  final String phone;
  final String leadNumber;
  final int totalItems;
  final double totalAmount;
  final String status;
  final List<QuotationProduct> products;

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? customer =
        _toMap(json['customer']) ??
        _toMap(json['customer_details']) ??
        _toMap(json['customer_detail']);
    final Map<String, dynamic>? lead =
        _toMap(json['lead']) ??
        _toMap(json['lead_details']) ??
        _toMap(json['lead_detail']);

    final dynamic productNode = json['products'] ?? json['items'] ?? json['product'];
    final List<dynamic> productList = productNode is List
        ? productNode
        : productNode is Map
        ? [productNode]
        : const [];

    return QuotationItem(
      id:
          _toInt(json['id']) ??
          _toInt(json['quotation_id']) ??
          _toInt(json['quote_id']) ??
          0,
      quoteNumber:
          _toText(json['quote_number']) ??
          _toText(json['quotation_number']) ??
          _toText(json['quote_no']) ??
          _toText(json['quoteNumber']) ??
          '-',
      quoteDate:
          _toText(json['quote_date']) ??
          _toText(json['created_at']) ??
          _toText(json['createdAt']) ??
          '-',
      expiryDate:
          _toText(json['expiry_date']) ??
          _toText(json['expire_date']) ??
          _toText(json['valid_till']) ??
          '-',
      customerName:
          _toText(json['customer_name']) ??
          _toText(customer?['name']) ??
          _toText(customer?['full_name']) ??
          '-',
      phone:
          _toText(json['phone']) ??
          _toText(json['phone_number']) ??
          _toText(customer?['phone']) ??
          _toText(customer?['phone_number']) ??
          '-',
      leadNumber:
          _toText(json['lead_number']) ??
          _toText(lead?['lead_number']) ??
          _toText(lead?['lead_no']) ??
          '-',
      totalItems:
          _toInt(json['total_items']) ??
          _toInt(json['item_count']) ??
          productList.length,
      totalAmount:
          _toDouble(json['total_amount']) ??
          _toDouble(json['total']) ??
          _toDouble(json['grand_total']) ??
          0,
      status: (json['status'] ?? 'pending').toString(),
      products: productList
          .whereType<Map>()
          .map((e) => QuotationProduct.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class QuotationProduct {
  QuotationProduct({
    required this.name,
    required this.modelNo,
    required this.brand,
  });

  final String name;
  final String modelNo;
  final String brand;

  factory QuotationProduct.fromJson(Map<String, dynamic> json) {
    return QuotationProduct(
      name:
          _toText(json['name']) ??
          _toText(json['product_name']) ??
          _toText(json['title']) ??
          '-',
      modelNo:
          _toText(json['model_no']) ??
          _toText(json['model']) ??
          _toText(json['model_number']) ??
          '-',
      brand: _toText(json['brand']) ?? _toText(json['brand_name']) ?? '-',
    );
  }
}

String? _toText(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final String text = value.trim();
    return text.isEmpty ? null : text;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

Map<String, dynamic>? _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
