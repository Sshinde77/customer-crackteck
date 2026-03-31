import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/invoice_model.dart';
import '../services/api_service.dart';
import '../widgets/app_loading_screen.dart';
import 'invoice_detail_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'All';
  List<InvoiceModel> _invoices = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _fetchInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvoices() async {
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

      final response = await ApiService.instance.getInvoiceList(
        roleId: roleId,
        userId: userId,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _invoices = response.data!.map(InvoiceModel.fromJson).toList();
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = response.message ?? 'Failed to fetch invoices';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred';
      });
    }
  }

  List<InvoiceModel> get _visibleInvoices {
    final query = _searchController.text.trim().toLowerCase();

    return _invoices.where((invoice) {
      final status = invoice.effectiveStatus.toLowerCase();

      final filterMatch = switch (_selectedFilter) {
        'Paid' => status == 'paid',
        'Unpaid' => status == 'unpaid',
        'Sent' => status == 'sent',
        _ => true,
      };

      final searchMatch = query.isEmpty
          ? true
          : invoice.invoiceNumber.toLowerCase().contains(query);

      return filterMatch && searchMatch;
    }).toList();
  }

  void _openDetail(InvoiceModel invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(
          invoice: invoice,
          quoteId: invoice.quoteId > 0 ? invoice.quoteId : invoice.id,
        ),
      ),
    );
  }

  void _downloadPdf(InvoiceModel invoice) {
    if (!invoice.hasInvoicePdf) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${invoice.invoiceNumber}.pdf')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoices = _visibleInvoices;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Invoices',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _buildSearchBar(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _buildFilterChips(),
          ),
          Expanded(
            child: _isLoading
                ? const AppLoadingScreen(message: 'Loading your invoices.')
                : _errorMessage != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _fetchInvoices,
                    child: invoices.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: invoices.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _buildInvoiceCard(invoices[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by invoice number',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Paid', 'Unpaid', 'Sent'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (_) => setState(() => _selectedFilter = filter),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _selectedFilter == filter
                        ? AppColors.primary
                        : const Color(0xFF344054),
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: _selectedFilter == filter
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : const Color(0xFFD0D5DD),
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice) {
    final firstItem = invoice.firstItem;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openDetail(invoice),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
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
                      invoice.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                  ),
                  _StatusBadge(status: invoice.effectiveStatus),
                ],
              ),
              const SizedBox(height: 12),
              _detailLine(
                icon: Icons.calendar_today_outlined,
                label: 'Invoice Date',
                value: _formatDate(invoice.invoiceDate),
              ),
              const SizedBox(height: 6),
              _detailLine(
                icon: Icons.event_outlined,
                label: 'Due Date',
                value: _formatDate(invoice.dueDate),
              ),
              const SizedBox(height: 6),
              _detailLine(
                icon: Icons.confirmation_num_outlined,
                label: 'Lead Number',
                value: invoice.leadNumber,
              ),
              const SizedBox(height: 6),
              _detailLine(
                icon: Icons.inventory_2_outlined,
                label: 'Product Name',
                value: firstItem?.name ?? '-',
              ),
              const SizedBox(height: 6),
              _detailLine(
                icon: Icons.qr_code_2_outlined,
                label: 'Model Number',
                value: firstItem?.modelNo ?? '-',
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _metaBlock(
                      title: 'Grand Total',
                      value: _formatAmount(
                        invoice.grandTotal,
                        invoice.currency,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _metaBlock(
                      title: 'Payment Status',
                      value: invoice.paymentStatus.toUpperCase(),
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openDetail(invoice),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('View Invoice'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: invoice.hasInvoicePdf
                          ? () => _downloadPdf(invoice)
                          : null,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Download PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(height: 80),
        Icon(Icons.receipt_long_outlined, size: 96, color: Color(0xFF98A2B3)),
        SizedBox(height: 12),
        Center(
          child: Text(
            'No invoices found',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF475467),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage ?? 'Failed to load invoices',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchInvoices,
              child: const Text('Retry'),
            ),
          ],
        ),
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

  Widget _metaBlock({
    required String title,
    required String value,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

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
    case 'paid':
      return Colors.green;
    case 'unpaid':
      return Colors.red;
    case 'sent':
      return Colors.orange;
    default:
      return Colors.blueGrey;
  }
}

String _formatDate(String input) {
  final date = DateTime.tryParse(input);
  if (date == null) return input;

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

  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

String _formatAmount(double amount, String currency) {
  final symbol = _currencySymbol(currency);
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
