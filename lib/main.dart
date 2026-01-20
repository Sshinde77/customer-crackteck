import 'package:customer_cracktreck/routes/app_routes.dart';
import 'package:customer_cracktreck/routes/route_generator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_strings.dart';
import 'constants/core/navigation_service.dart';
import 'provider/document_provider.dart';
import 'provider/company_provider.dart';
import 'provider/banner_provider.dart';
import 'provider/quick_service_provider.dart';
import 'provider/amc_plan_provider.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => QuickServiceProvider()),
        ChangeNotifierProvider(create: (_) => AmcPlanProvider()),
      ],
      child: const CrackCustomerTechApp(),
    ),
  );
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
