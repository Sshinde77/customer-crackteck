import 'package:customer_cracktreck/routes/app_routes.dart';
import 'package:customer_cracktreck/routes/route_generator.dart';
import 'package:customer_cracktreck/services/auth_service.dart';
import 'package:customer_cracktreck/services/google_auth_service.dart';
import 'package:customer_cracktreck/widgets/custom_button.dart';
import 'package:customer_cracktreck/widgets/error_dialog.dart';
import 'package:customer_cracktreck/widgets/google_sign_in_button.dart';
import 'package:customer_cracktreck/widgets/phone_input_field.dart';
import 'package:flutter/material.dart';

import 'constants/app_colors.dart';
import 'constants/app_spacing.dart';
import 'constants/app_strings.dart';

/// Unified Login Screen for all roles
class LoginScreen extends StatefulWidget {
  final int roleId;

  const LoginScreen({super.key, required this.roleId});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService.instance;
  final GoogleAuthService _googleAuthService = GoogleAuthService.instance;

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Validate phone number
  bool _validatePhoneNumber() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      setState(() {
        _errorText = AppStrings.invalidPhoneFormat;
      });
      return false;
    }
    setState(() {
      _errorText = null;
    });
    return true;
  }

  Future<void> _handleLogin() async {
    if (!_validatePhoneNumber()) return;

    setState(() {
      _isLoading = true;
    });

    final response = await _authService.sendOtp(
      roleId: widget.roleId,
      phoneNumber: _phoneController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.otpVerification,
        arguments: OtpArguments(
          roleId: widget.roleId,
          phoneNumber: _phoneController.text.trim(),
        ),
      );
    } else {
      if (!mounted) return;
      showErrorDialog(
        context: context,
        message: response.message ?? AppStrings.networkError,
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final Map<String, dynamic>? googleUserData =
          await _googleAuthService.signInWithGoogle();

      if (googleUserData == null) {
        return;
      }

      debugPrint('Selected Google email: ${googleUserData['email']}');

      await _googleAuthService.sendGoogleLoginDataToBackend(googleUserData);
    } catch (error) {
      if (!mounted) return;
      showErrorDialog(
        context: context,
        message: 'Google sign-in failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  /// Navigate to sign up screen
  void _navigateToSignUp() {
    Navigator.pushNamed(context, AppRoutes.signUp);
  }

  String getLoginSubtitle() {
    // Add logic to return appropriate subtitle based on roleId if needed
    return "Please enter your mobile number to login";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.loginTopPadding),

              // Title
              const Text(
                AppStrings.welcomeBack,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.titleSubtitleSpacing),

              // Subtitle (dynamic based on role)
              Text(
                getLoginSubtitle(),
                style: const TextStyle(
                  color: AppColors.lightGrey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.subtitleInputSpacing),

              // Phone Number Input
              PhoneInputField(
                controller: _phoneController,
                label: AppStrings.numberLabel,
                errorText: _errorText,
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() {
                      _errorText = null;
                    });
                  }
                },
              ),

              const SizedBox(height: AppSpacing.inputButtonSpacing),

              // Login Button
              CustomButton(
                text: AppStrings.loginButton,
                onPressed: _handleLogin,
                isLoading: _isLoading,
              ),

              const SizedBox(height: AppSpacing.buttonSpacing),

              GoogleSignInButton(
                onPressed: _handleGoogleLogin,
                isLoading: _isGoogleLoading,
              ),

              const SizedBox(height: AppSpacing.buttonSignUpSpacing),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    AppStrings.dontHaveAccount,
                    style: TextStyle(color: AppColors.lightGrey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: _navigateToSignUp,
                    child: const Text(
                      AppStrings.signUp,

                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.bottomPadding),
            ],
          ),
        ),
      ),
    );
  }
}
