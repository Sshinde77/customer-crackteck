import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Green Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    'Hello Sachin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        
            // Profile Options List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  _buildProfileOption(
                    Icons.info_outline,
                    'Personal info',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.personalInfo);
                    },
                  ),
                  _buildProfileOption(
                    Icons.inventory_2_outlined,
                    'My product orders',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.myProductOrders);
                    },
                  ),
                  // _buildProfileOption(
                  //   Icons.assignment_outlined,
                  //   'Work progress tracker',
                  //   onTap: () {
                  //     Navigator.pushNamed(context, AppRoutes.workProgressTracker);
                  //   },
                  // ),
                  // _buildProfileOption(Icons.handyman_outlined, 'Repair Material'),
                  _buildProfileOption(
                    Icons.assignment_outlined,
                    'My service request',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.myServiceRequest);
                    },
                  ),
                  _buildProfileOption(
                    Icons.description_outlined,
                    'Quotation',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.quotation);
                    },
                  ),
                  _buildProfileOption(
                    Icons.feedback_outlined,
                    'Feedback\'s',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.feedback);
                    },
                  ),
                  _buildProfileOption(Icons.headset_mic_outlined, 'Help & Support'),
                  _buildProfileOption(Icons.privacy_tip_outlined, 'Privacy policy'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.green.shade700, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward, color: Colors.green, size: 20),
        onTap: onTap ?? () {
          // Default empty handler
        },
      ),
    );
  }
}
