  import 'package:customer_cracktreck/routes/app_routes.dart';
  import 'package:customer_cracktreck/routes/route_generator.dart';
  import 'package:customer_cracktreck/services/auth_service.dart';
  import 'package:customer_cracktreck/services/google_auth_service.dart';
  import 'package:customer_cracktreck/widgets/error_dialog.dart';
  import 'package:flutter/material.dart';
  
  import 'constants/app_colors.dart';
  import 'constants/app_strings.dart';
  
  /// Unified Login Screen for all roles
  class LoginScreen extends StatefulWidget {
    final int roleId;
  
    const LoginScreen({super.key, required this.roleId});
  
    @override
    State<LoginScreen> createState() => _LoginScreenState();
  }
  
  class _LoginScreenState extends State<LoginScreen>
      with SingleTickerProviderStateMixin {
    final TextEditingController _phoneController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final AuthService _authService = AuthService.instance;
    final GoogleAuthService _googleAuthService = GoogleAuthService.instance;
  
    bool _isLoading = false;
    bool _isEmailLoading = false;
    bool _isGoogleLoading = false;
    bool _isFacebookLoading = false;
    bool _obscurePassword = true;
    String? _errorText;
    late final TabController _tabController;
    int _selectedTabIndex = 0;
  
    @override
    void initState() {
      super.initState();
      _tabController = TabController(length: 2, vsync: this)
        ..addListener(_handleTabChange);
    }
  
    @override
    void dispose() {
      _tabController
        ..removeListener(_handleTabChange)
        ..dispose();
      _phoneController.dispose();
      _emailController.dispose();
      _passwordController.dispose();
      super.dispose();
    }
  
    void _handleTabChange() {
      if (_selectedTabIndex == _tabController.index) {
        return;
      }
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
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
  
        if (!mounted) return;
  
        if (googleUserData == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google sign-in was cancelled.')),
          );
          return;
        }
  
        final accessToken = (googleUserData['accessToken'] as String?)?.trim();
        if (accessToken == null || accessToken.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google access token not available.')),
          );
          return;
        }
  
        final response = await _authService.loginWithGoogle(
          accessToken,
          roleId: widget.roleId,
        );
  
        if (!mounted) return;
  
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Google login successful'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.hometab,
            (route) => false,
          );
          return;
        }
  
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Google login failed'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-in failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
          });
        }
      }
    }
  
    Future<void> _handleEmailLogin() async {
      FocusScope.of(context).unfocus();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

      if (!emailRegex.hasMatch(email)) {
        _showSnackBar('Enter a valid email address.', isError: true);
        return;
      }
      if (password.trim().isEmpty) {
        _showSnackBar('Enter your password.', isError: true);
        return;
      }

      setState(() {
        _isEmailLoading = true;
      });

      try {
        final response = await _authService.loginWithEmailPassword(
          email: email,
          password: password,
          roleId: widget.roleId,
        );

        if (!mounted) return;

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Login successful'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.hometab,
            (route) => false,
          );
          return;
        }

        _showSnackBar(
          response.message ?? 'Email login failed',
          isError: true,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isEmailLoading = false;
          });
        }
      }
    }
  
    Future<void> _handleFacebookLogin() async {
      setState(() {
        _isFacebookLoading = true;
      });
  
      await Future<void>.delayed(const Duration(milliseconds: 250));
  
      if (!mounted) return;
      setState(() {
        _isFacebookLoading = false;
      });
      _showSnackBar(
        'Facebook login UI is ready, but no existing Facebook auth handler was found in this project.',
        isError: true,
      );
    }
  
    void _showSnackBar(String message, {bool isError = false}) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : AppColors.primary,
        ),
      );
    }
  
    /// Navigate to sign up screen
    void _navigateToSignUp() {
      Navigator.pushNamed(context, AppRoutes.signUp);
    }
  
    String getLoginSubtitle() => 'Login to continue';
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Image.asset(
                  'assests/logo.png',
                  height: 88,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 88,
                      width: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  getLoginSubtitle(),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 52,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          tabAlignment: TabAlignment.fill,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          dividerColor: Colors.transparent,
                          labelColor: const Color(0xFF101828),
                          unselectedLabelColor: const Color(0xFF667085),
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 26),
                          tabs: const [
                            Tab(text: 'Phone'),
                            Tab(text: 'Email'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        alignment: Alignment.topCenter,
                        child: KeyedSubtree(
                          key: ValueKey(_selectedTabIndex),
                          child: _selectedTabIndex == 0
                              ? _PhoneLoginTab(
                                  controller: _phoneController,
                                  errorText: _errorText,
                                  isLoading: _isLoading,
                                  onChanged: (_) {
                                    if (_errorText != null) {
                                      setState(() {
                                        _errorText = null;
                                      });
                                    }
                                  },
                                  onSubmit: _handleLogin,
                                )
                              : _EmailLoginTab(
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  isLoading: _isEmailLoading,
                                  obscurePassword: _obscurePassword,
                                  onToggleObscure: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  onForgotPassword: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.forgotPassword,
                                    );
                                  },
                                  onSubmit: _handleEmailLogin,
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _OrDivider(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _SocialActionButton(
                              label: 'Google',
                              onPressed: _handleGoogleLogin,
                              isLoading: _isGoogleLoading,
                              icon: const _GoogleMark(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SocialActionButton(
                              label: 'Facebook',
                              onPressed: _handleFacebookLogin,
                              isLoading: _isFacebookLoading,
                              icon: const _FacebookMark(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToSignUp,
                      child: const Text(
                        AppStrings.signUp,
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
  
  class _PhoneLoginTab extends StatelessWidget {
    const _PhoneLoginTab({
      required this.controller,
      required this.errorText,
      required this.onChanged,
      required this.onSubmit,
      required this.isLoading,
    });
  
    final TextEditingController controller;
    final String? errorText;
    final ValueChanged<String> onChanged;
    final VoidCallback onSubmit;
    final bool isLoading;
  
    @override
    Widget build(BuildContext context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phone Number',
            style: TextStyle(
              color: Color(0xFF101828),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _PhoneField(
            controller: controller,
            errorText: errorText,
            onChanged: onChanged,
          ),
          const SizedBox(height: 18),
          _PrimaryActionButton(
            label: 'Login with OTP',
            onPressed: onSubmit,
            isLoading: isLoading,
          ),
        ],
      );
    }
  }
  
  class _EmailLoginTab extends StatelessWidget {
    const _EmailLoginTab({
      required this.emailController,
      required this.passwordController,
      required this.isLoading,
      required this.obscurePassword,
      required this.onToggleObscure,
      required this.onForgotPassword,
      required this.onSubmit,
    });
  
    final TextEditingController emailController;
    final TextEditingController passwordController;
    final bool isLoading;
    final bool obscurePassword;
    final VoidCallback onToggleObscure;
    final VoidCallback onForgotPassword;
    final VoidCallback onSubmit;
  
    @override
    Widget build(BuildContext context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Email Address',
            style: TextStyle(
              color: Color(0xFF101828),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _ModernInputField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            hintText: 'you@example.com',
            labelText: 'Email',
            prefixIcon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 14),
          _ModernInputField(
            controller: passwordController,
            hintText: 'Enter your password',
            labelText: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            suffix: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF667085),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.only(top: 4, bottom: 8),
              ),
              child: const Text('Forgot Password?'),
            ),
          ),
          _PrimaryActionButton(
            label: 'Login',
            onPressed: onSubmit,
            isLoading: isLoading,
          ),
        ],
      );
    }
  }
  
  class _PhoneField extends StatelessWidget {
    const _PhoneField({
      required this.controller,
      required this.errorText,
      required this.onChanged,
    });
  
    final TextEditingController controller;
    final String? errorText;
    final ValueChanged<String> onChanged;
  
    @override
    Widget build(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: errorText == null ? const Color(0xFFE4E7EC) : Colors.red,
              ),
            ),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.all(8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '+91',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: const Color(0xFFE4E7EC),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '9876543210',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Text(
              errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
    }
  }
  
  class _ModernInputField extends StatelessWidget {
    const _ModernInputField({
      required this.controller,
      required this.hintText,
      required this.labelText,
      required this.prefixIcon,
      this.keyboardType,
      this.obscureText = false,
      this.suffix,
    });
  
    final TextEditingController controller;
    final String hintText;
    final String labelText;
    final IconData prefixIcon;
    final TextInputType? keyboardType;
    final bool obscureText;
    final Widget? suffix;
  
    @override
    Widget build(BuildContext context) {
      return TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF667085)),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      );
    }
  }
  
  class _PrimaryActionButton extends StatelessWidget {
    const _PrimaryActionButton({
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
        height: 56,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      );
    }
  }
  
  class _SocialActionButton extends StatelessWidget {
    const _SocialActionButton({
      required this.label,
      required this.onPressed,
      required this.isLoading,
      required this.icon,
    });
  
    final String label;
    final VoidCallback onPressed;
    final bool isLoading;
    final Widget icon;
  
    @override
    Widget build(BuildContext context) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }
  }
  
  class _OrDivider extends StatelessWidget {
    const _OrDivider();
  
    @override
    Widget build(BuildContext context) {
      return Row(
        children: const [
          Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'OR',
              style: TextStyle(
                color: Color(0xFF98A2B3),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
        ],
      );
    }
  }
  
  class _GoogleMark extends StatelessWidget {
    const _GoogleMark();
  
    @override
    Widget build(BuildContext context) {
      return CustomPaint(
        size: const Size.square(18),
        painter: _GoogleMarkPainter(),
      );
    }
  }
  
  class _GoogleMarkPainter extends CustomPainter {
    @override
    void paint(Canvas canvas, Size size) {
      final strokeWidth = size.width * 0.22;
      final rect = Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      );
  
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
  
      paint.color = const Color(0xFF4285F4);
      canvas.drawArc(rect, -0.15, 1.05, false, paint);
  
      paint.color = const Color(0xFFEA4335);
      canvas.drawArc(rect, 0.90, 1.20, false, paint);
  
      paint.color = const Color(0xFFFBBC05);
      canvas.drawArc(rect, 2.10, 0.95, false, paint);
  
      paint.color = const Color(0xFF34A853);
      canvas.drawArc(rect, 3.05, 1.65, false, paint);
  
      final barPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.square
        ..color = const Color(0xFF4285F4);
  
      final centerY = size.height / 2;
      canvas.drawLine(
        Offset(size.width * 0.52, centerY),
        Offset(size.width * 0.92, centerY),
        barPaint,
      );
    }
  
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
  }
  
  class _FacebookMark extends StatelessWidget {
    const _FacebookMark();
  
    @override
    Widget build(BuildContext context) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Color(0xFF1877F2),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
  }
