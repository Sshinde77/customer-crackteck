import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/amc_plan_model.dart';
import '../provider/amc_plan_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_loading_screen.dart';
import 'service_request_screen.dart';

class AmcPlanDetailScreen extends StatefulWidget {
  final int planId;
  final String requestButtonLabel;
  final String? selectedAmcMode;

  const AmcPlanDetailScreen({
    super.key,
    required this.planId,
    this.requestButtonLabel = 'Subscribe to Plan',
    this.selectedAmcMode,
  });

  @override
  State<AmcPlanDetailScreen> createState() => _AmcPlanDetailScreenState();
}

class _AmcPlanDetailScreenState extends State<AmcPlanDetailScreen> {
  static const String _siteBaseUrl = 'https://crackteck.co.in/';

  bool _hidePriceForOffline(AmcPlan? plan) {
    final supportType = plan?.supportType?.trim().toLowerCase() ?? '';
    return supportType == 'offline' ||
        supportType == 'off line' ||
        supportType == 'onsite' ||
        supportType == 'on site';
  }

  String _buildBrochureUrl(String? brochurePath) {
    final trimmed = brochurePath?.trim() ?? '';
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final normalizedPath = trimmed.replaceAll('\\', '/').replaceFirst(
      RegExp(r'^/+'),
      '',
    );
    return '$_siteBaseUrl$normalizedPath';
  }

  Future<void> _downloadBrochure(String? brochurePath) async {
    final brochureUrl = _buildBrochureUrl(brochurePath);
    if (brochureUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brochure is not available.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(brochureUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid brochure link.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open brochure.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openTermsAndConditions(AmcPlan? plan) async {
    final response = await ApiService.instance.getStaticTermsAndConditions(
      useOnsiteTerms: _hidePriceForOffline(plan),
    );
    if (!mounted) return;

    final terms = _extractTermsContent(response.data);
    if (!response.success || terms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ?? 'Terms & Conditions are not available.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AmcTermsAndConditionsScreen(
          title:
              response.data?['title']?.toString().trim().isNotEmpty == true
                  ? response.data!['title'].toString().trim()
                  : 'Terms & Conditions',
          planName: plan?.planName,
          termsAndConditions: terms,
        ),
      ),
    );
  }

  String _extractTermsContent(Map<String, dynamic>? data) {
    final rawContent = data?['content'];
    if (rawContent is String) {
      return rawContent.trim();
    }

    if (rawContent is! List) {
      return '';
    }

    final buffer = StringBuffer();
    for (final item in rawContent) {
      if (item is! Map) continue;

      final map = item.map((key, value) => MapEntry(key.toString(), value));
      final type = map['type']?.toString().trim().toLowerCase() ?? '';
      final text = (map['text'] ?? map['content'] ?? map['value'] ?? '')
          .toString()
          .trim();
      if (text.isEmpty) continue;

      if (type == 'heading') {
        final rawLevel = int.tryParse('${map['level'] ?? ''}') ?? 1;
        final level = rawLevel.clamp(1, 4);
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.write('<h$level>$text</h$level>');
        continue;
      }

      if (type == 'paragraph') {
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.write('<p>$text</p>');
        continue;
      }

      if (buffer.isNotEmpty) {
        buffer.writeln();
        buffer.writeln();
      }
      buffer.write(text);
    }

    return buffer.toString().trim();
  }

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
            return const AppLoadingScreen(message: 'Loading AMC plan details.');
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
                  if (!_hidePriceForOffline(plan)) ...[
                    _buildPricingCard(plan),
                    const SizedBox(height: 16),
                  ],

                  // Plan Details Card
                  _buildPlanDetailsCard(plan),
                  const SizedBox(height: 16),

                  // Covered Services Section
                  _buildCoveredServicesSection(
                    coveredItems,
                    hidePrice: _hidePriceForOffline(plan),
                  ),
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

  Widget _buildCoveredServicesSection(
    List<CoveredItem> coveredItems, {
    required bool hidePrice,
  }) {
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
          ...coveredItems.map(
            (item) => _buildServiceCard(item, hidePrice: hidePrice),
          ),
      ],
    );
  }

  Widget _buildServiceCard(CoveredItem item, {required bool hidePrice}) {
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
                        'selectedAmcMode': widget.selectedAmcMode,
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
            child: Text(
              widget.requestButtonLabel,
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
            if ((plan?.brochure ?? '').trim().isNotEmpty)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _downloadBrochure(plan?.brochure),
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
            if ((plan?.brochure ?? '').trim().isNotEmpty)
              const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openTermsAndConditions(plan),
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

class _AmcTermsAndConditionsScreen extends StatelessWidget {
  const _AmcTermsAndConditionsScreen({
    required this.title,
    required this.planName,
    required this.termsAndConditions,
  });

  final String title;
  final String? planName;
  final String termsAndConditions;

  bool _hasDisplayableHtml(String value) {
    final normalized = value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .trim();
    return normalized.isNotEmpty;
  }

  bool _looksLikeHtml(String value) {
    return RegExp(r'<[a-z][\s\S]*>', caseSensitive: false).hasMatch(value);
  }

  List<_TermsSection> _buildPlainTextSections(String value) {
    final normalized = value
        .replaceAll('\r\n', '\n')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .trim();
    if (normalized.isEmpty) return const [];

    final blocks = normalized
        .split(RegExp(r'\n\s*\n'))
        .map((block) => block.trim())
        .where((block) => block.isNotEmpty)
        .toList();

    if (blocks.isEmpty) return const [];

    final sections = <_TermsSection>[];
    var untitledParagraphs = <String>[];

    for (final block in blocks) {
      final lines = block
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (lines.isEmpty) continue;

      final firstLine = lines.first;
      final remainingLines = lines.skip(1).toList();
      final hasBodyAfterFirstLine = remainingLines.isNotEmpty;
      final headingLike = _looksLikeHeading(firstLine);

      if (headingLike && hasBodyAfterFirstLine) {
        if (untitledParagraphs.isNotEmpty) {
          sections.add(
            _TermsSection(
              heading: null,
              paragraphs: List<String>.from(untitledParagraphs),
            ),
          );
          untitledParagraphs = <String>[];
        }
        sections.add(
          _TermsSection(
            heading: _cleanHeading(firstLine),
            paragraphs: <String>[remainingLines.join(' ')],
          ),
        );
        continue;
      }

      if (headingLike && !hasBodyAfterFirstLine) {
        if (untitledParagraphs.isNotEmpty) {
          sections.add(
            _TermsSection(
              heading: null,
              paragraphs: List<String>.from(untitledParagraphs),
            ),
          );
          untitledParagraphs = <String>[];
        }
        sections.add(
          _TermsSection(
            heading: _cleanHeading(firstLine),
            paragraphs: const [],
          ),
        );
        continue;
      }

      untitledParagraphs.add(lines.join(' '));
    }

    if (untitledParagraphs.isNotEmpty) {
      sections.add(
        _TermsSection(
          heading: null,
          paragraphs: untitledParagraphs,
        ),
      );
    }

    return sections;
  }

  bool _looksLikeHeading(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > 80) return false;
    if (trimmed.endsWith('.') || trimmed.endsWith('!') || trimmed.endsWith('?')) {
      return false;
    }
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length > 10) return false;
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return false;
    return true;
  }

  String _cleanHeading(String value) {
    return value.trim().replaceFirst(RegExp(r'[:\-]\s*$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final hasHtml = _looksLikeHtml(termsAndConditions) &&
        _hasDisplayableHtml(termsAndConditions);
    final sections = hasHtml ? const <_TermsSection>[] : _buildPlainTextSections(termsAndConditions);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  if ((planName ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7EE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        planName!.trim(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Please review the terms carefully before continuing.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: hasHtml
                  ? Html(
                      data: termsAndConditions,
                      style: {
                        'html': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(15),
                          lineHeight: const LineHeight(1.6),
                          color: Colors.black87,
                        ),
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(15),
                          lineHeight: const LineHeight(1.6),
                          color: Colors.black87,
                        ),
                        'h1': Style(
                          margin: Margins.only(bottom: 12),
                          fontSize: FontSize(18),
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                        'h2': Style(
                          margin: Margins.only(top: 12, bottom: 10),
                          fontSize: FontSize(20),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        'h3': Style(
                          margin: Margins.only(top: 10, bottom: 8),
                          fontSize: FontSize(18),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        'h4': Style(
                          margin: Margins.only(top: 10, bottom: 8),
                          fontSize: FontSize(16),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        'p': Style(
                          margin: Margins.only(bottom: 14),
                          fontSize: FontSize(15),
                          lineHeight: const LineHeight(1.7),
                          color: Colors.black87,
                        ),
                        'ul': Style(
                          margin: Margins.only(bottom: 14, left: 18),
                          padding: HtmlPaddings.zero,
                        ),
                        'ol': Style(
                          margin: Margins.only(bottom: 14, left: 18),
                          padding: HtmlPaddings.zero,
                        ),
                        'li': Style(
                          margin: Margins.only(bottom: 8),
                          fontSize: FontSize(15),
                          lineHeight: const LineHeight(1.6),
                        ),
                        'strong': Style(fontWeight: FontWeight.w700),
                        'br': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                        ),
                      },
                    )
                  : _TermsTextContent(sections: sections, fallbackText: termsAndConditions),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsTextContent extends StatelessWidget {
  const _TermsTextContent({
    required this.sections,
    required this.fallbackText,
  });

  final List<_TermsSection> sections;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return Text(
        fallbackText.trim(),
        style: const TextStyle(
          fontSize: 15,
          height: 1.7,
          color: Colors.black87,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((section.heading ?? '').trim().isNotEmpty) ...[
                Text(
                  section.heading!.trim(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              ...section.paragraphs.map(
                (paragraph) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    paragraph.trim(),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TermsSection {
  const _TermsSection({
    required this.heading,
    required this.paragraphs,
  });

  final String? heading;
  final List<String> paragraphs;
}
