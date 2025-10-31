import 'dart:convert';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:lpg_distribution_app/presentation/blocs/cash/cash_bloc.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_bloc.dart';
import 'package:lpg_distribution_app/presentation/blocs/orders/orders_bloc.dart';
import 'package:lpg_distribution_app/presentation/blocs/sdms/create/sdms_create_bloc.dart';
import 'package:lpg_distribution_app/presentation/blocs/sdms/transaction/sdms_transaction_bloc.dart';
import 'package:lpg_distribution_app/presentation/blocs/vehicle/vehicle_bloc.dart';
import 'package:lpg_distribution_app/presentation/pages/splash_screen.dart';
import 'package:lpg_distribution_app/presentation/routes/app_routes.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/service_provider.dart';
import 'core/services/api_service_interface.dart';
import 'core/services/version_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_novu/generated/app_localizations.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
final GlobalKey<NavigatorState> NavKey = GlobalKey<NavigatorState>();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  print("Background message: ${message.messageId}");
  print("Message data: ${message.data}"); // Debug log

  // Encode data as JSON string
  final payloadJson = message.data.isNotEmpty
      ? jsonEncode(message.data)
      : jsonEncode({});

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title,
    message.notification?.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
    payload: payloadJson, // Use JSON encoded string
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(kReleaseMode);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);

    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  await initializeNotifications();

  // Initialize Flutter Downloader for APK downloads
  await FlutterDownloader.initialize(debug: false);

  // Initialize Version Manager
  await VersionManager().initialize();

  final apiService = await ServiceProvider.getApiService();

  runApp(
    Provider<ApiServiceInterface>.value(
      value: apiService,
      child: MultiBlocProvider(
        providers: [
          RepositoryProvider<ApiServiceInterface>.value(value: apiService),
          BlocProvider<OrdersBloc>(
            create: (context) => OrdersBloc(apiService: context.read<ApiServiceInterface>()),
          ),
          BlocProvider<CashManagementBloc>(
            create: (context) => CashManagementBloc(
                apiService: context.read<ApiServiceInterface>()),
          ),
          BlocProvider<InventoryBloc>(
            create: (context) => InventoryBloc(
              apiService: apiService,
            ),
          ),
          BlocProvider<VehicleBloc>(
            create: (context) => VehicleBloc(apiService: context.read<ApiServiceInterface>()),
          ),
          BlocProvider<SDMSTransactionBloc>(
            create: (context) => SDMSTransactionBloc(apiService: context.read<ApiServiceInterface>()),
          ),
          BlocProvider<SDMSCreateBloc>(
            create: (context) => SDMSCreateBloc(apiService: context.read<ApiServiceInterface>()),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

Future<void> initializeNotifications() async {
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("App opened from background: ${message.data}");

    final payloadJson = message.data.isNotEmpty
        ? jsonEncode(message.data)
        : jsonEncode({});

    _handleNotificationTap(payloadJson);
  });

  // Create Android notification channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token on startup: $token");

  if (token != null) {
    _storeTokenForUpdate(token);
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        _handleNotificationTap(response.payload!);
      }
    },
  );

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _showNotification(message);
  });

  registerFCMTokenListener();

  // Handle notification tap when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationTap(message.data.toString());
  });

}

void _showNotification(RemoteMessage message) {
  print("Foreground message data: ${message.data}"); // Debug log

  final payloadJson = message.data.isNotEmpty
      ? jsonEncode(message.data)
      : jsonEncode({});

  flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title,
    message.notification?.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
    payload: payloadJson,
  );
}

void _handleNotificationTap(String payload) {
  final context = NavKey.currentContext;
  if (context == null) return;

  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final route = data['route'] as String?;

    if (route != null) {
      AppRoutes.navigateWithCompanyCheck(context, route);
    }

  } catch (e) {
    print('Error handling notification: $e');
  }
}

Future<String> _getDeviceId() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  return androidInfo.id;
}

Future<void> updateDeviceToken(BuildContext context) async {
  final apiService = context.read<ApiServiceInterface>();
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  try {
    String? token = await messaging.getToken();
    String deviceId = await _getDeviceId();

    await apiService.updateDeviceToken(token!, deviceId);
    if (kDebugMode) {
      print('Device token updated successfully');
    }
  } catch (error) {
    if (kDebugMode) {
      print("Error updating device token: $error");
    }
  }
}

void registerFCMTokenListener() {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print("New FCM Token: $newToken");
    _storeTokenForUpdate(newToken);

    // Try to send immediately if user is logged in
    final context = NavKey.currentContext;
    if (context != null) {
      try {
        await updateDeviceToken(context);
      } catch (e) {
        print("Failed to send token immediately: $e");
      }
    }
  });
}

void _storeTokenForUpdate(String token) async {
  // Store in SharedPreferences for later sending
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('pending_fcm_token', token);
}

// Call this after successful login when you have context
Future<void> sendPendingFCMToken(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final pendingToken = prefs.getString('pending_fcm_token');

  if (pendingToken != null) {
    await updateDeviceToken(context);
    await prefs.remove('pending_fcm_token');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _checkForInitialNotification();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.storage,
    ].request();

    debugPrint('Bluetooth: ${statuses[Permission.bluetooth]}');
    debugPrint('BluetoothScan: ${statuses[Permission.bluetoothScan]}');
    debugPrint('BluetoothConnect: ${statuses[Permission.bluetoothConnect]}');
    debugPrint('Location: ${statuses[Permission.location]}');
    debugPrint('Storage: ${statuses[Permission.storage]}');
  }

  Future<void> _checkForInitialNotification() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print("App opened from notification: ${initialMessage.data}");

      final payloadJson = initialMessage.data.isNotEmpty
          ? jsonEncode(initialMessage.data)
          : jsonEncode({});

      _handleNotificationTap(payloadJson);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: NavKey,
          title: 'LPG Distribution',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: const Color(0xFF0E5CA8),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0E5CA8),
              secondary: const Color(0xFFF7941D),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              labelStyle: TextStyle(fontSize: 14.sp),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedItemColor: const Color(0xFF0E5CA8),
              unselectedItemColor: Colors.grey[600],
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: TextStyle(fontSize: 12.sp),
              unselectedLabelStyle: TextStyle(fontSize: 12.sp),
            ),
            textTheme: TextTheme(
              headlineLarge: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              headlineMedium: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500),
              headlineSmall: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500),
              bodyLarge: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.normal),
              bodyMedium: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.normal),
              bodySmall: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.normal),
              labelLarge: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
          onGenerateRoute: AppRoutes.generateRoute,
          localizationsDelegates: SNovu.localizationsDelegates,
          supportedLocales: SNovu.supportedLocales,
        );
      },
    );
  }
}