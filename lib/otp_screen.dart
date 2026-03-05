// import 'dart:async';
// import 'package:customer_cracktreck/routes/route_generator.dart';
// import 'package:customer_cracktreck/widgets/custom_button.dart';
// import 'package:flutter/material.dart';
// import 'package:sms_autofill/sms_autofill.dart';
// import 'constants/app_colors.dart';
// import 'constants/app_spacing.dart';
//
// class OtpVerificationScreen extends StatefulWidget {
//   final OtpArguments args;
//
//   const OtpVerificationScreen({super.key, required this.args});
//
//   @override
//   State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
// }
//
// class _OtpVerificationScreenState extends State<OtpVerificationScreen>
//     with CodeAutoFill {
//   // final ApiService _apiService = ApiService.instance;
//
//   final TextEditingController _otpController = TextEditingController();
//   final FocusNode _otpFocusNode = FocusNode();
//
//   bool _isVerifying = false;
//   bool _canResend = false;
//
//   int _secondsLeft = 80;
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     startTimer();
//     listenForCode(); // 👈 SMS auto read
//   }
//
//   @override
//   void dispose() {
//     cancel();
//     _timer?.cancel();
//     _otpController.dispose();
//     _otpFocusNode.dispose();
//     super.dispose();
//   }
//
//   // ================= SMS AUTO READ =================
//   @override
//   void codeUpdated() {
//     setState(() {
//       _otpController.text = code ?? '';
//     });
//
//     if (_otpController.text.length == 4) {
//       // verifyOtp();
//     }
//   }
//
//   // ================= TIMER =================
//   void startTimer() {
//     _secondsLeft = 80;
//     _canResend = false;
//
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_secondsLeft == 0) {
//         setState(() => _canResend = true);
//         timer.cancel();
//       } else {
//         setState(() => _secondsLeft--);
//       }
//     });
//   }
//
//   // ================= VERIFY OTP =================
//   // Future<void> verifyOtp() async {
//   //   final otp = _otpController.text.trim();
//   //
//   //   if (otp.length != 4) {
//   //     _showSnack("Please enter valid OTP");
//   //     return;
//   //   }
//   //
//   //   setState(() => _isVerifying = true);
//   //
//   //   try {
//   //     final res = await _apiService.verifyOtp(
//   //       phoneNumber: widget.args.phoneNumber,
//   //       otp: otp,
//   //       roleId: widget.args.roleId,
//   //     );
//   //
//   //     if (!mounted) return;
//   //
//   //     if (res.success) {
//   //       _navigateByRole(widget.args.roleId);
//   //     } else {
//   //       _showSnack(res.message ?? "Invalid OTP");
//   //     }
//   //   } catch (_) {
//   //     _showSnack("Network error");
//   //   } finally {
//   //     if (mounted) setState(() => _isVerifying = false);
//   //   }
//   // }
//
//
//   // ================= RESEND OTP =================
//   // Future<void> resendOtp() async {
//   //   if (!_canResend) return;
//   //
//   //   final response = await _apiService.login(
//   //     roleId: widget.args.roleId,
//   //     phoneNumber: widget.args.phoneNumber,
//   //   );
//   //
//   //   if (response.success) {
//   //     _showSnack("OTP resent");
//   //     startTimer();
//   //   } else {
//   //     _showSnack("Resend failed");
//   //   }
//   // }
//
//   void _showSnack(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg)),
//     );
//   }
//
//   // ================= ANIMATED OTP BOX =================
//   Widget _otpBox(int index) {
//     final isActive = index == _otpController.text.length;
//
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 250),
//       height: 55,
//       width: 55,
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: isActive ? AppColors.primary : Colors.grey.shade300,
//           width: 2,
//         ),
//         boxShadow: [
//           if (isActive)
//             BoxShadow(
//               color: AppColors.primary.withOpacity(0.2),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             )
//         ],
//       ),
//       child: Text(
//         index < _otpController.text.length
//             ? _otpController.text[index]
//             : "",
//         style: const TextStyle(
//           fontSize: 22,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }
//
//   // ================= UI =================
//   @override
//   Widget build(BuildContext context) {
//     final args = widget.args;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         leading: BackButton(color: Colors.black),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(
//           horizontal: AppSpacing.horizontalPadding,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 10),
//
//             const Text(
//               "Verifying\nyour number",
//               style: TextStyle(
//                 fontSize: 30,
//                 fontWeight: FontWeight.bold,
//                 height: 1.2,
//               ),
//             ),
//
//             const SizedBox(height: 12),
//
//             Text(
//               "We sent a code to",
//               style: TextStyle(color: Colors.grey.shade600),
//             ),
//             Text(
//               args.phoneNumber,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//
//             const SizedBox(height: 35),
//
//             GestureDetector(
//               onTap: () {
//                 FocusScope.of(context).requestFocus(_otpFocusNode);
//               },
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: List.generate(4, _otpBox),
//               ),
//             ),
//
//             // Hidden TextField
//             Opacity(
//               opacity: 0,
//               child: TextField(
//                 controller: _otpController,
//                 focusNode: _otpFocusNode,
//                 keyboardType: TextInputType.number,
//                 maxLength: 4,
//                 onChanged: (val) {
//                   setState(() {});
//                   // if (val.length == 4) verifyOtp();
//                 },
//               ),
//             ),
//
//             const SizedBox(height: 25),
//
//             CustomButton(
//               text: "Verify",
//               isLoading: _isVerifying,
//               onPressed: () {},
//             ),
//
//             const SizedBox(height: 20),
//
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 GestureDetector(
//                   onTap: () {
//
//                   },
//                   child: Text(
//                     "Resend code",
//                     style: TextStyle(
//                       color: _canResend ? Colors.black : Colors.grey,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 Text(
//                   _canResend
//                       ? "Expired"
//                       : "${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')} left",
//                   style: const TextStyle(color: Colors.grey),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//

import 'dart:async';
import 'package:customer_cracktreck/routes/app_routes.dart';
import 'package:customer_cracktreck/routes/route_generator.dart';
import 'package:customer_cracktreck/services/auth_service.dart';
import 'package:customer_cracktreck/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

import 'constants/app_colors.dart';
import 'constants/app_spacing.dart';

class OtpVerificationScreen extends StatefulWidget {
  final OtpArguments args;

  const OtpVerificationScreen({super.key, required this.args});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with CodeAutoFill {
  final AuthService _authService = AuthService.instance;

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  bool _isVerifying = false;
  bool _canResend = false;

  int _secondsLeft = 80;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
    listenForCode(); // 👈 SMS auto read
  }

  @override
  void dispose() {
    cancel();
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  // ================= SMS AUTO READ =================
  @override
  void codeUpdated() {
    setState(() {
      _otpController.text = code ?? '';
    });

    if (_otpController.text.length == 4) {
      verifyOtp();
    }
  }

  // ================= TIMER =================
  void startTimer() {
    _secondsLeft = 80;
    _canResend = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        setState(() => _canResend = true);
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  // ================= VERIFY OTP =================
  Future<void> verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 4) {
      _showSnack("Please enter valid OTP");
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final res = await _authService.verifyOtp(
        phoneNumber: widget.args.phoneNumber,
        otp: otp,
        roleId: widget.args.roleId,
      );

      if (!mounted) return;

      if (res.success) {
        _navigateByRole(widget.args.roleId);
      } else {
        _showSnack(res.message ?? "Invalid OTP");
      }
    } catch (_) {
      _showSnack("Network error");
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // ================= NAVIGATION =================
  void _navigateByRole(int roleId) {
    switch (roleId) {
      case 1:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.adminDashboard,
          (_) => false,
        );
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.residentDashboard,
          (_) => false,
        );
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.salespersonDashboard,
          (_) => false,
        );
      case 4:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.hometab,
          (_) => false,
        );
        break;
      default:
        _showSnack("Unknown role");
    }
  }

  // ================= RESEND OTP =================
  Future<void> resendOtp() async {
    if (!_canResend) return;

    final response = await _authService.sendOtp(
      roleId: widget.args.roleId,
      phoneNumber: widget.args.phoneNumber,
    );

    if (response.success) {
      _showSnack("OTP resent");
      startTimer();
    } else {
      _showSnack("Resend failed");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= ANIMATED OTP BOX =================
  Widget _otpBox(int index) {
    final isActive = index == _otpController.text.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 55,
      width: 55,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppColors.primary : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Text(
        index < _otpController.text.length ? _otpController.text[index] : "",
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.horizontalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            const Text(
              "Verifying\nyour number",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "We sent a code to",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              args.phoneNumber,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 35),

            GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(_otpFocusNode);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, _otpBox),
              ),
            ),

            // Hidden TextField
            Opacity(
              opacity: 0,
              child: TextField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 4,
                onChanged: (val) {
                  setState(() {});
                  if (val.length == 4) verifyOtp();
                },
              ),
            ),

            const SizedBox(height: 25),

            CustomButton(
              text: "Verify",
              isLoading: _isVerifying,
              onPressed: verifyOtp,
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: resendOtp,
                  child: Text(
                    "Resend code",
                    style: TextStyle(
                      color: _canResend ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _canResend
                      ? "Expired"
                      : "${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')} left",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
