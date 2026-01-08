import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

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
          "Notification",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _NotificationCard(
              title: "Quotation Received",
              message:
              "Please verify your quotation and respond for further process",
              time: "Now",
            ),
            _NotificationCard(
              title: "Material ready",
              message:
              "Material is ready and under process",
              time: "Now",
            ),
            _NotificationCard(
              title: "Service Rating",
              message:
              "We value your feedback, kindly rate your recent order and share your experience",
              time: "1 day ago",
            ),
            _NotificationCard(
              title: "Hungry? Try Our New Pizza Specials!",
              message:
              "Check out the latest discounts on our menu and satisfy your cravings",
              time: "2 days ago",
            ),
            _NotificationCard(
              title: "Don’t Miss Out: Special Offer Just for You",
              message:
              "Grab this limited-time deal before it expires. Limited stock available!",
              time: "2 hours ago",
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔔 Notification Card Widget
class _NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String time;

  const _NotificationCard({
    required this.title,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        /// Handle click later
        debugPrint("Notification tapped: $title");
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            /// Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 8),

            /// Time
            Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
