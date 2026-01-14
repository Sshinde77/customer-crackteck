import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/user_model.dart';
import '../models/api_response.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (userId != null && roleId != null) {
        final ApiResponse<UserModel> response = await ApiService.instance.getProfile(
          userId: userId,
          roleId: roleId,
        );

        if (response.success && response.data != null) {
          setState(() {
            _user = response.data;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final userId = await SecureStorageService.getUserId();
        final roleId = await SecureStorageService.getRoleId();

        if (userId != null && roleId != null) {
          final response = await ApiService.instance.logout(
            userId: userId,
            roleId: roleId,
          );

          if (response.success) {
            // Clear local storage
            await SecureStorageService.clearTokens();
            await SecureStorageService.saveUserId(0); // Clear user ID
            
            if (context.mounted) {
              Navigator.pop(context); // Close loading indicator
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
            }
          } else {
            if (context.mounted) {
              Navigator.pop(context); // Close loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response.message ?? 'Logout failed')),
              );
            }
          }
        } else {
          // If no stored data, just clear and go to login
          await SecureStorageService.clearTokens();
          if (context.mounted) {
            Navigator.pop(context);
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An error occurred during logout')),
          );
        }
      }
    }
  }

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoading ? 'Loading...' : 'Hii ${_user?.firstName ?? 'User'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                      Navigator.pushNamed(context, AppRoutes.personalInfo).then((_) => _fetchProfileData());
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

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
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
