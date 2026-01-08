import 'package:flutter/material.dart';
import 'service_request_screen.dart';

class QuickServicesScreen extends StatelessWidget {
  const QuickServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// AppBar
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F8B00),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Service Enquiry',
          style: TextStyle(color: Colors.white),
        ),
      ),

      /// Body
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _serviceCard(
                context: context,
                title: 'Installations Request',
                baseColor: Colors.green,
                icon: Icons.build_circle_outlined,
              ),
              const SizedBox(height: 14),
              _serviceCard(
                context: context,
                title: 'Repairing Service Request',
                baseColor: Colors.deepOrange,
                icon: Icons.handyman_outlined,
              ),
              const SizedBox(height: 14),
              _serviceCard(
                context: context,
                title: 'AMC Service Request',
                baseColor: Colors.indigo,
                icon: Icons.home_repair_service_outlined,
              ),
              const SizedBox(height: 14),
              _serviceCard(
                context: context,
                title: 'Quick Service Request',
                baseColor: Colors.teal,
                icon: Icons.support_agent_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Placeholder Service Card
  Widget _serviceCard({
    required BuildContext context,
    required String title,
    required Color baseColor,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceRequestScreen(title: title),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 110,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                baseColor.withOpacity(0.95),
                baseColor.withOpacity(0.75),
                baseColor.withOpacity(0.55),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Stack(
            children: [
              /// Decorative Icon Placeholder
              Positioned(
                right: -10,
                top: -10,
                child: Icon(
                  icon,
                  size: 110,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),

              /// Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
