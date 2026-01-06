import 'package:customer_cracktreck/routes/app_routes.dart';
import 'package:customer_cracktreck/routes/route_generator.dart';
import 'package:flutter/material.dart';
import 'constants/app_strings.dart';
import 'constants/core/navigation_service.dart';


void main() {
  runApp(const CrackCustomerTechApp());
}

class CrackCustomerTechApp extends StatelessWidget {
  const CrackCustomerTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
        navigatorKey: NavigationService.navigatorKey,
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.login,
        onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
