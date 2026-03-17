import 'dart:developer' as developer;

import 'package:customer_cracktreck/routes/app_routes.dart';
import 'package:customer_cracktreck/routes/route_generator.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'constants/app_strings.dart';
import 'constants/core/navigation_service.dart';
import 'provider/document_provider.dart';
import 'provider/company_provider.dart';
import 'provider/banner_provider.dart';
import 'provider/quick_service_provider.dart';
import 'provider/amc_plan_provider.dart';

/// 🔔 Notification Channel (REQUIRED)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

/// 🔥 Background Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  developer.log('Background message: ${message.messageId}');
}

/// 🔥 Get & Print FCM Token
Future<void> _logFcmToken() async {
  try {
    final messaging = FirebaseMessaging.instance;

    String? token = await messaging.getToken();

    developer.log('FCM Token: $token', name: 'FCM');
    print('🔥 FCM TOKEN: $token');

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      developer.log('Refreshed Token: $newToken', name: 'FCM');
      print('🔄 NEW TOKEN: $newToken');
    });
  } catch (e) {
    developer.log('Error fetching FCM token: $e', name: 'FCM', error: e);
    print('❌ Error fetching FCM token: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();

    /// ✅ Request permission FIRST
    await FirebaseMessaging.instance.requestPermission();

    /// ✅ Get token AFTER permission (handled with try-catch inside)
    await _logFcmToken();

    /// 🔔 Local Notification Setup
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    /// 📊 Analytics
    await FirebaseAnalytics.instance.logAppOpen();

    /// 🔥 Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    developer.log('Firebase Initialization Error: $e', error: e);
    print('❌ Firebase Initialization Error: $e');
  }

  /// 🔇 Disable logs in release
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

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
    return MaterialApp(
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
