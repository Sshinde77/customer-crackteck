
import 'package:customer_cracktreck/screens/notification.dart';
import 'package:customer_cracktreck/screens/quick_service_details.dart';
import 'package:customer_cracktreck/screens/service_enquiry.dart';
import 'package:customer_cracktreck/signup_screen.dart';
import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../login.dart';

import '../otp_screen.dart';
import '../screens/dashboard_screen.dart';
import 'app_routes.dart';


// Centralized route generator for the application
class RouteGenerator {
  RouteGenerator._(); // Private constructor to prevent instantiation

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // case AppRoutes.login:
      //   return MaterialPageRoute(
      //     builder: (_) => const DashboardScreen(),
      //     settings: settings,
      //   );
           case AppRoutes.login:
                  return MaterialPageRoute(
                    builder: (_) => const LoginScreen(roleId: AppStrings.roleId,),
                    settings: settings,
                  );

      case AppRoutes.otpVerification:
        final args = settings.arguments as OtpArguments?;
        if (args == null) {
          return _errorRoute('OTP arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(args: args,),
          settings: settings,
        );

      case AppRoutes.hometab:
        return MaterialPageRoute(
          builder: (_) => DashboardScreen(),
          settings: settings,
        );

      case AppRoutes.signUp:
        return MaterialPageRoute(
          builder: (_) => const SignUpScreen(),
          settings: settings,
        );
      case AppRoutes.notification:
        return MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
          settings: settings,
        );

      case AppRoutes.quickServiceDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => QuickServiceDetailsScreen(serviceData: args ?? {}),
          settings: settings,
        );

      case AppRoutes.serviceEnquiry:
        return MaterialPageRoute(
          builder: (_) => const QuickServicesScreen(),
          settings: settings,
        );


      default:
        return _errorRoute(settings.name);
    }
  }

  static Route<dynamic> _errorRoute(String? routeName) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('No route defined for $routeName')),
      ),
    );
  }
}

class LoginArguments {
  final int roleId;
  LoginArguments({ this.roleId =AppStrings.roleId});
}
class OtpArguments {
  final int roleId;
  final String phoneNumber;

  OtpArguments({
    required this.roleId,
    required this.phoneNumber,
  });
}
