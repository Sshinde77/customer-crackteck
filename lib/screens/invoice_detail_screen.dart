import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/invoice_model.dart';
import '../services/api_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key, required this.invoice, this.quoteId});

  final InvoiceModel invoice;
  final int? quoteId;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;
  late InvoiceModel _invoice;

  int get _resolvedQuoteId {
    if (widget.quoteId != null && widget.quoteId! > 0) {
      return widget.quoteId!;
    }
    if (widget.invoice.quoteId > 0) {
      return widget.invoice.quoteId;
    }
    return widget.invoice.id;
  }

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    _fetchInvoiceDetail();
  }

  Future<void> _fetchInvoiceDetail() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final int quoteId = _resolvedQuoteId;
      if (quoteId <= 0) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invoice reference is missing.';
        });
        return;
      }

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

      final response = await ApiService.instance.getInvoiceDetail(
        quoteId: quoteId,
        roleId: roleId,
        userId: userId,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _invoice = InvoiceModel.fromJson(response.data!);
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = response.message ?? 'Failed to fetch invoice detail';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred while loading details.';
      });
    }
  }

  Future<void> _submitInvoiceAction({required bool approve}) async {
    if (_isActionLoading) return;

    final int actionId = _invoice.id;
    if (actionId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice id is missing in detail response.'),
        ),
      );
      return;
    }

    setState(() => _isActionLoading = true);

    try {
      final int roleId =
          (await SecureStorageService.getRoleId()) ?? AppStrings.roleId;
      final int? userId = await SecureStorageService.getUserId();

      if (userId == null) {
        if (!mounted) return;
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User session missing. Please login again.'),
          ),
        );
        return;
      }

      final response = approve
          ? await ApiService.instance.approveInvoice(
              invoiceId: actionId,
              roleId: roleId,
              userId: userId,
            )
          : await ApiService.instance.rejectInvoice(
              invoiceId: actionId,
              roleId: roleId,
              userId: userId,
            );

      if (!mounted) return;

      setState(() => _isActionLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ??
                (approve
                    ? 'Invoice approved successfully'
                    : 'Invoice rejected successfully'),
          ),
          backgroundColor: response.success
              ? AppColors.primary
              : Colors.red.shade600,
        ),
      );

      if (response.success) {
        _fetchInvoiceDetail();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update invoice status')),
      );
    }
  }

  void _downloadPdf() {
    if (!_invoice.hasInvoicePdf) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${_invoice.invoiceNumber}.pdf')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text(
          'Invoice Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchInvoiceDetail,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading) ...[
              const LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: 12),
            ],
            if (_errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFC9C9)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFB42318)),
                ),
              ),
            ],
            _sectionCard(
              title: 'Invoice',
              icon: Icons.receipt_long_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _invoice.invoiceNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF101828),
                          ),
                        ),
                      ),
                      _StatusChip(status: _invoice.effectiveStatus),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoRow('Invoice Date', _formatDate(_invoice.invoiceDate)),
                  _infoRow('Due Date', _formatDate(_invoice.dueDate)),
                  _infoRow(
                    'Payment Status',
                    _invoice.paymentStatus.toUpperCase(),
                  ),
                  _infoRow('Lead Number', _invoice.leadNumber),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _invoice.hasInvoicePdf ? _downloadPdf : null,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Download PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: _invoice.hasInvoicePdf
                              ? AppColors.primary
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Billing',
              icon: Icons.location_on_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(
                    'Grand Total',
                    _formatAmount(_invoice.grandTotal, _invoice.currency),
                  ),
                  _infoRow(
                    'Paid Amount',
                    _formatAmount(_invoice.paidAmount, _invoice.currency),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Billing Address',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF667085),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _invoice.billingAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF344054),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Items',
              icon: Icons.inventory_2_outlined,
              child: Column(
                children: [
                  if (_invoice.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No items available'),
                    ),
                  for (int i = 0; i < _invoice.items.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == _invoice.items.length - 1 ? 0 : 10,
                      ),
                      child: _itemTile(_invoice.items[i]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isFinalDecisionStatus(_invoice.status)
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
                        onPressed: (_isActionLoading || _isLoading)
                            ? null
                            : () => _submitInvoiceAction(approve: false),
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
                        label: Text(
                          _isActionLoading ? 'Please wait' : 'Reject',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_isActionLoading || _isLoading)
                            ? null
                            : () => _submitInvoiceAction(approve: true),
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
                        label: Text(
                          _isActionLoading ? 'Please wait' : 'Approve',
                        ),
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
    return normalized == 'accepted' ||
        normalized == 'approved' ||
        normalized == 'rejected';
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
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF667085),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF101828),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemTile(InvoiceItemModel item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D2939),
            ),
          ),
          const SizedBox(height: 4),
          Text('Model: ${item.modelNo}', style: const TextStyle(fontSize: 12)),
          Text('Brand: ${item.brand}', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

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
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
    case 'accepted':
    case 'approved':
      return Colors.green;
    case 'unpaid':
    case 'rejected':
      return Colors.red;
    case 'sent':
    case 'pending':
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
