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
import 'constants/core/secure_storage_service.dart';
import 'provider/document_provider.dart';
import 'provider/company_provider.dart';
import 'provider/banner_provider.dart';
import 'provider/quick_service_provider.dart';
import 'provider/amc_plan_provider.dart';

/// 🔔 Global Local Notifications Plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 🔔 Notification Channel (REQUIRED)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id (positional)
  'High Importance Notifications', // name (positional)
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
  playSound: true,
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
  await SecureStorageService.initialize();

  try {
    await Firebase.initializeApp();

    /// ✅ Request permission FIRST
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    /// ✅ Get token AFTER permission
    await _logFcmToken();

    /// 🔔 Local Notification Setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click here if needed
      },
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    /// 🔥 Foreground Message Listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id, // channelId (positional)
              channel.name, // channelName (positional)
              channelDescription: channel.description,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
          ),
        );
      }
    });

    /// 🔥 Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    /// 📊 Analytics
    await FirebaseAnalytics.instance.logAppOpen();

  } catch (e) {
    developer.log('Firebase Initialization Error: $e', error: e);
    print('❌ Firebase Initialization Error: $e');
  }

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

class CrackCustomerTechApp extends StatefulWidget {
  const CrackCustomerTechApp({super.key});

  @override
  State<CrackCustomerTechApp> createState() => _CrackCustomerTechAppState();
}

class _CrackCustomerTechAppState extends State<CrackCustomerTechApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncSessionOnResume();
    }
  }

  Future<void> _syncSessionOnResume() async {
    await SecureStorageService.refreshSessionFromStorage();
    final hasToken = await SecureStorageService.hasStoredToken();
    if (!hasToken) {
      await NavigationService.navigateToAuthRoot();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      scaffoldMessengerKey: NavigationService.scaffoldMessengerKey,
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
