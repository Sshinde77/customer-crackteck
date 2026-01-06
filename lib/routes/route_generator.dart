
import 'package:customer_cracktreck/screens/hometab.dart';
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
      case AppRoutes.login:
        final args = settings.arguments as LoginArguments?;
        
        return MaterialPageRoute(
          builder: (_) =>  DashboardScreen(),
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
