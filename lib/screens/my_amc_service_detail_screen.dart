import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/customer_amc_model.dart';
import '../services/api_service.dart';
import '../widgets/app_loading_screen.dart';

class MyAmcServiceDetailScreen extends StatefulWidget {
  const MyAmcServiceDetailScreen({
    super.key,
    required this.amcId,
  });

  final int amcId;

  @override
  State<MyAmcServiceDetailScreen> createState() =>
      _MyAmcServiceDetailScreenState();
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
    if (parsed == null) return text.split(' ').first;

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

  String _formatDateTime(String? raw) {
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

    final int hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final String minute = parsed.minute.toString().padLeft(2, '0');
    final String suffix = parsed.hour >= 12 ? 'PM' : 'AM';

    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}, ${hour.toString().padLeft(2, '0')}:$minute $suffix';
  }

  String _formatMoney(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return 'Rs 0';
    final lower = text.toLowerCase();
    if (lower.contains('rs') || lower.contains('inr')) return text;
    return 'Rs $text';
  }

  Color _statusColor(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.contains('completed')) return Colors.green;
    if (normalized.contains('active')) return Colors.green;
    if (normalized.contains('scheduled')) return Colors.blue;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
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
      return const AppLoadingScreen(message: 'Loading AMC service details.');
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

    final completedMeetings = amc.completedScheduleMeetings;

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
            _buildSnapshotSection(amc, completedMeetings.length),
            if (completedMeetings.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildCompletedMeetingsSection(completedMeetings),
            ],
            if ((amc.additionalNotes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildNotesSection(amc),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(CustomerAmc amc) {
    final statusColor = _statusColor(amc.displayStatus);
    final secondaryCode = amc.displayCode.trim();
    final showSecondaryCode =
        secondaryCode.isNotEmpty &&
        secondaryCode != '-' &&
        secondaryCode != amc.displayRequestId.trim();
    final List<_HeaderMetaItem> headerItems = <_HeaderMetaItem>[
      _HeaderMetaItem(
        label: 'Type',
        value: _toDisplayCase(amc.displayAmcType),
        icon: Icons.settings_remote_outlined,
      ),
      _HeaderMetaItem(
        label: 'Date',
        value: _formatDate(amc.displayRequestDate),
        icon: Icons.event_outlined,
      ),
      if (showSecondaryCode)
        _HeaderMetaItem(
          label: 'Code',
          value: secondaryCode,
          icon: Icons.sell_outlined,
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Request ID: ${amc.displayRequestId}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
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
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  _toDisplayCase(amc.displayStatus),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildHeaderMetaRow(headerItems),
          if (amc.displayDescription.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              amc.displayDescription,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderMetaRow(List<_HeaderMetaItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 360;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 14,
            vertical: isCompact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int index = 0; index < items.length; index++) ...[
                Expanded(
                  child: _buildHeaderMetaSegment(
                    item: items[index],
                    isCompact: isCompact,
                  ),
                ),
                if (index != items.length - 1)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 12,
                    ),
                    child: Container(
                      width: 1,
                      height: isCompact ? 48 : 54,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderMetaSegment({
    required _HeaderMetaItem item,
    required bool isCompact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: isCompact ? 28 : 32,
          width: isCompact ? 28 : 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            item.icon,
            size: isCompact ? 15 : 17,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isCompact ? 8 : 10),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isCompact ? 10 : 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: isCompact ? 11 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSnapshotSection(CustomerAmc amc, int completedCount) {
    final List<_DetailStatItem> stats = <_DetailStatItem>[
      _DetailStatItem(
        label: 'Plan Cost',
        value: _formatMoney(amc.displayPlanCost),
        icon: Icons.currency_rupee_outlined,
        color: AppColors.primary,
      ),
      _DetailStatItem(
        label: 'Total Visits',
        value: amc.displayTotalVisits,
        icon: Icons.support_agent_outlined,
        color: Colors.teal,
      ),
      _DetailStatItem(
        label: 'Completed Visits',
        value: completedCount.toString(),
        icon: Icons.task_alt_outlined,
        color: Colors.green,
      ),
      _DetailStatItem(
        label: 'Scheduled Visits',
        value: amc.displayScheduledMeetingsCount,
        icon: Icons.event_repeat_outlined,
        color: Colors.orange,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plan Snapshot',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Core AMC details without timeline or covered service clutter.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const double spacing = 12;
            final int columns = constraints.maxWidth >= 720 ? 4 : 2;
            final double itemWidth =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: stats
                  .map(
                    (item) => SizedBox(
                      width: itemWidth,
                      child: _buildStatTile(item),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatTile(_DetailStatItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(height: 14),
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
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedMeetingsSection(List<AmcScheduleMeeting> meetings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Completed AMC Meetings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${meetings.length} done',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Only meetings with status completed are shown here.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 14),
        ...meetings.map(_buildMeetingCard),
      ],
    );
  }

  Widget _buildMeetingCard(AmcScheduleMeeting meeting) {
    final statusColor = _statusColor(meeting.status ?? '');
    final remarks = (meeting.remarks ?? '').trim();
    final report = (meeting.report ?? '').trim();
    final visitNumber =
        meeting.visitsCount == null ? 'Visit' : 'Visit ${meeting.visitsCount}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.task_alt_outlined,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visitNumber,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completed on ${_formatDateTime(meeting.completedAt)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _toDisplayCase(meeting.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
                final List<Widget> items = <Widget>[
                  _buildMeetingMeta(
                    icon: Icons.schedule_outlined,
                    label: 'Scheduled At',
                    value: _formatDateTime(meeting.scheduledAt),
                  ),
                  _buildMeetingMeta(
                    icon: Icons.check_circle_outline,
                    label: 'Completed At',
                    value: _formatDateTime(meeting.completedAt),
                  ),
                  if ((meeting.rescheduledAt ?? '').trim().isNotEmpty)
                    _buildMeetingMeta(
                      icon: Icons.update_outlined,
                      label: 'Rescheduled At',
                      value: _formatDateTime(meeting.rescheduledAt),
                    ),
                ];

                final int columns = constraints.maxWidth >= 720 ? 3 : 1;
                final double itemWidth =
                    (constraints.maxWidth - (spacing * (columns - 1))) /
                    columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: items
                      .map((item) => SizedBox(width: itemWidth, child: item))
                      .toList(),
                );
              },
            ),
            if (remarks.isNotEmpty || report.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (remarks.isNotEmpty) ...[
                      const Text(
                        'Remarks',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remarks,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (remarks.isNotEmpty && report.isNotEmpty)
                      const SizedBox(height: 12),
                    if (report.isNotEmpty) ...[
                      const Text(
                        'Report',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingMeta({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(CustomerAmc amc) {
    final notes = (amc.additionalNotes ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Notes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            notes.isEmpty ? '-' : notes,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStatItem {
  const _DetailStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _HeaderMetaItem {
  const _HeaderMetaItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}
