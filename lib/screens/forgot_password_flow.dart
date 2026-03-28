import 'package:customer_cracktreck/constants/app_colors.dart';
import 'package:customer_cracktreck/constants/app_strings.dart';
import 'package:customer_cracktreck/routes/app_routes.dart';
import 'package:customer_cracktreck/services/auth_service.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService.instance;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      _showSnack('Enter a valid email address.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _authService.sendForgotPasswordCode(
        email: email,
        roleId: AppStrings.roleId,
      );

      if (!mounted) return;

      if (response.success) {
        _showSnack(
          response.message ?? 'Verification code sent successfully',
        );
        Navigator.pushNamed(
          context,
          AppRoutes.forgotPasswordOtp,
          arguments: ForgotPasswordOtpArguments(
            email: email,
            maskedEmail: _maskEmail(email),
            roleId: AppStrings.roleId,
          ),
        );
        return;
      }

      _showSnack(response.message ?? 'Failed to send verification code');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final local = parts.first;
    final domain = parts.last;
    if (local.length <= 2) {
      return '${local[0]}***@$domain';
    }

    return '${local.substring(0, 2)}***@$domain';
  }

  @override
  Widget build(BuildContext context) {
    return _FlowScaffold(
      title: 'Forgot Password',
      subtitle: 'Enter your email to receive a one-time password.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Email Address',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 12),
          _FlowInputField(
            controller: _emailController,
            hintText: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 20),
          _FlowPrimaryButton(
            label: 'Send OTP',
            isLoading: _isSubmitting,
            onPressed: _sendOtp,
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordOtpScreen extends StatefulWidget {
  const ForgotPasswordOtpScreen({super.key, required this.args});

  final ForgotPasswordOtpArguments args;

  @override
  State<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService.instance;
  bool _isVerifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 4) {
      _showSnack('Enter the 4-digit OTP.');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final response = await _authService.verifyForgotPasswordCode(
        email: widget.args.email,
        roleId: widget.args.roleId,
        code: otp,
      );

      if (!mounted) return;

      if (response.success) {
        _showSnack(response.message ?? 'Verification code verified successfully');
        Navigator.pushNamed(
          context,
          AppRoutes.resetPassword,
          arguments: ResetPasswordArguments(
            email: widget.args.email,
            roleId: widget.args.roleId,
          ),
        );
        return;
      }

      _showSnack(response.message ?? 'Failed to verify code');
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return _FlowScaffold(
      title: 'Verify OTP',
      subtitle: 'We sent a verification code to ${widget.args.maskedEmail}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter OTP',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 12),
          _FlowInputField(
            controller: _otpController,
            hintText: '1234',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.password_rounded,
          ),
          const SizedBox(height: 20),
          _FlowPrimaryButton(
            label: 'Verify OTP',
            isLoading: _isVerifying,
            onPressed: _verifyOtp,
          ),
        ],
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.args});

  final ResetPasswordArguments args;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService.instance;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.length < 8) {
      _showSnack('Password must be at least 8 characters.');
      return;
    }

    if (password != confirmPassword) {
      _showSnack('Passwords do not match.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await _authService.resetForgotPassword(
        email: widget.args.email,
        roleId: widget.args.roleId,
        password: password,
        passwordConfirmation: confirmPassword,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Password reset successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
        return;
      }

      _showSnack(response.message ?? 'Failed to reset password');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return _FlowScaffold(
      title: 'Set New Password',
      subtitle: 'Create a new password for ${widget.args.email}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Password',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 12),
          _FlowInputField(
            controller: _passwordController,
            hintText: 'Enter new password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffix: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF667085),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _FlowInputField(
            controller: _confirmPasswordController,
            hintText: 'Confirm new password',
            prefixIcon: Icons.lock_reset_rounded,
            obscureText: _obscureConfirmPassword,
            suffix: IconButton(
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF667085),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _FlowPrimaryButton(
            label: 'Update Password',
            isLoading: _isSaving,
            onPressed: _resetPassword,
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordOtpArguments {
  const ForgotPasswordOtpArguments({
    required this.email,
    required this.maskedEmail,
    required this.roleId,
  });

  final String email;
  final String maskedEmail;
  final int roleId;
}

class ResetPasswordArguments {
  const ResetPasswordArguments({
    required this.email,
    required this.roleId,
  });

  final String email;
  final int roleId;
}

class _FlowScaffold extends StatelessWidget {
  const _FlowScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FB),
        foregroundColor: const Color(0xFF101828),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowInputField extends StatelessWidget {
  const _FlowInputField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF98A2B3)),
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF667085)),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _FlowPrimaryButton extends StatelessWidget {
  const _FlowPrimaryButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
