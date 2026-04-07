import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';



/// Global navigation service to allow non-UI layers to trigger
/// navigation without tight coupling to widget contexts.
class NavigationService {
  NavigationService._();

  /// Global navigator key used by [MaterialApp].
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Navigate back to the authentication entry point while
  /// clearing the existing navigation stack.
  ///
  /// This uses the existing route configuration and does **not**
  /// introduce any new routes or change route names.
  static Future<void> navigateToAuthRoot() async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  static void showSnackBar(SnackBar snackBar) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}

