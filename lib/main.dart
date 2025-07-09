import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/presentation/blocs/cash/cash_bloc.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_bloc.dart';
import 'package:lpg_distribution_app/presentation/blocs/order_form/order_form_bloc.dart';
import 'package:lpg_distribution_app/presentation/blocs/orders/orders_bloc.dart';
import 'package:lpg_distribution_app/presentation/pages/login_screen.dart';
import 'package:lpg_distribution_app/presentation/pages/main_container.dart';
import 'package:lpg_distribution_app/presentation/pages/orders/create_order_page.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/forms/cash_deposit_page.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/cash_page.dart';
import 'package:lpg_distribution_app/presentation/pages/orders/orders_page.dart';
import 'package:lpg_distribution_app/presentation/pages/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/services/api_service.dart';
import 'core/services/service_provider.dart';
import 'core/services/api_service_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
           // Add the OrderFormBloc provider
            BlocProvider<OrderFormBloc>(
              create: (context) => OrderFormBloc(
                  apiService: context.read<ApiServiceInterface>()),
            ),
            BlocProvider<CashManagementBloc>(
              create: (context) => CashManagementBloc(
                  apiService: context.read<ApiServiceInterface>()),
               ),
           // Somewhere in your widget hierarchy (main.dart or app.dart)
            BlocProvider<InventoryBloc>(
              create: (context) => InventoryBloc(
                apiService: apiService,
              ),
            ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void initState() {
    super.initState();
    _requestBluetoothPermissions();
  }

  Future<void> _requestBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    debugPrint('Bluetooth: ${statuses[Permission.bluetooth]}');
    debugPrint('BluetoothScan: ${statuses[Permission.bluetoothScan]}');
    debugPrint('BluetoothConnect: ${statuses[Permission.bluetoothConnect]}');
    debugPrint('Location: ${statuses[Permission.location]}');
  }

  @override
  Widget build(BuildContext context) {
    // Wrap MaterialApp with ScreenUtilInit for responsive design
    return ScreenUtilInit(
      // Design size based on style guide - these dimensions should match your design mockups
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'LPG Distribution',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: const Color(0xFF0E5CA8), // Brand Blue
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0E5CA8),
              secondary: const Color(0xFFF7941D), // Brand Orange
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
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              margin: EdgeInsets.symmetric(vertical: 8.h),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedItemColor: const Color(0xFF0E5CA8),
              unselectedItemColor: Colors.grey[600],
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: TextStyle(fontSize: 12.sp),
              unselectedLabelStyle: TextStyle(fontSize: 12.sp),
            ),
            textTheme: TextTheme(
              // Based on style guide
              headlineLarge: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold), // Headline 1
              headlineMedium: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500), // Headline 2
              headlineSmall: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500), // Headline 3
              bodyLarge: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.normal), // Body 1
              bodyMedium: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.normal), // Body 2
              bodySmall: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.normal), // Caption
              labelLarge: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500), // Button
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/dashboard': (context) => const MainContainer(),
            '/orders/create': (context) => BlocProvider.value(
              value: BlocProvider.of<OrdersBloc>(context),
              child: const CreateOrderPage(),
            ),
            '/cash': (context) => const CashPage(),
            '/cash/deposit': (context) =>  CashDepositPage(),
            '/inventory/create': (context) => BlocProvider.value(
              value: BlocProvider.of<InventoryBloc>(context),
              child:  const CreateOrderPage(),
            ),
          },
        );
      },
    );
  }

}