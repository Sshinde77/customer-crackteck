import 'package:flutter/material.dart';

import '../constants/core/secure_storage_service.dart';
import '../models/notification_item.dart';
import '../services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<NotificationItem> _notifications = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (userId == null || roleId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'User session expired. Please login again.';
        });
        return;
      }

      final response = await ApiService.instance.getNotifications(
        roleId: roleId,
        customerId: userId,
      );

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _notifications = response.data ?? const [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load notifications';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load notifications: $e';
        _isLoading = false;
      });
    }
  }

  String _formatTime(String raw) {
    if (raw.trim().isEmpty) return '';

    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return raw;

    final now = DateTime.now();
    final difference = now.difference(parsed);

    if (difference.inMinutes < 1) return 'Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    if (difference.inDays < 7) return '${difference.inDays} day ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} week ago';

    return '${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.year}';
  }

  String _formatDateTime(String raw) {
    if (raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return raw;

    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final meridiem = parsed.hour >= 12 ? 'PM' : 'AM';
    return '${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.year} $hour:$minute $meridiem';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F8B00),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadNotifications,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _MessageCard(
                          message: _errorMessage!,
                          actionLabel: 'Retry',
                          onTap: _loadNotifications,
                        ),
                      ],
                    )
                  : _notifications.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            const _MessageCard(
                              message: 'No notifications found.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return _NotificationCard(
                              notification: notification,
                              time: _formatTime(notification.createdAt),
                              dateTime: _formatDateTime(notification.createdAt),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onTap;

  const _MessageCard({
    required this.message,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onTap,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final String time;
  final String dateTime;

  const _NotificationCard({
    required this.notification,
    required this.time,
    required this.dateTime,
  });

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        debugPrint('Notification tapped: ${notification.title}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4E7EC)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A101828),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFF1F8B00),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF101828),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (time.trim().isNotEmpty)
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF667085),
                          ),
                        ),
                    ],
                  ),
                ),
                if (notification.amount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F8B00),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Rs ${_formatAmount(notification.amount!)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notification.message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475467),
                height: 1.5,
              ),
            ),
            if (notification.orderId != null || dateTime.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (notification.orderId != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_rounded,
                            size: 16,
                            color: Color(0xFF667085),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Order ID',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF667085),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '#${notification.orderId}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF101828),
                            ),
                          ),
                        ],
                      ),
                    if (notification.orderId != null && dateTime.trim().isNotEmpty)
                      const SizedBox(height: 10),
                    if (dateTime.trim().isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: Color(0xFF667085),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Created At',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF667085),
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              dateTime,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF101828),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
