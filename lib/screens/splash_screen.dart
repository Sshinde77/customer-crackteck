import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/core/navigation_service.dart';
import '../constants/core/secure_storage_service.dart';
import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrapSession();
  }

  Future<void> _bootstrapSession() async {
    try {
      await SecureStorageService.initialize();
      final token = await SecureStorageService.getToken();
      final roleId = await SecureStorageService.getRoleId();

      if (!mounted) return;

      final nextRoute = token != null && token.isNotEmpty
          ? NavigationService.resolveHomeRoute(roleId: roleId)
          : AppRoutes.login;

      Navigator.of(context).pushNamedAndRemoveUntil(
        nextRoute,
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Checking session...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF344054),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
