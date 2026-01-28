// Updated GlobalDrawer with proper SDMS navigation
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/pages/profile/profile_screen.dart';
import '../../presentation/pages/reports/reports_screen.dart';
import '../../presentation/pages/sdms/sdms_transaction_list_page.dart';
// Hidden for release build - Digital Credit not ready
// import '../../presentation/pages/digital_credit/digital_credits_list_page.dart';
import '../../presentation/widgets/professional_snackbar.dart';
import '../../core/services/api_service.dart';
import '../../presentation/blocs/vehicle/vehicle_bloc.dart';
import '../../presentation/blocs/vehicle/vehicle_event.dart';
import '../../presentation/blocs/orders/orders_bloc.dart';
import '../../presentation/blocs/orders/orders_event.dart';
import '../../presentation/blocs/inventory/inventory_bloc.dart';
import '../../presentation/blocs/inventory/inventory_event.dart';
// Hidden for release build - Digital Credit not ready
// import '../../presentation/blocs/digital_credit/digital_credit_bloc.dart';
// import '../../presentation/blocs/digital_credit/digital_credit_event.dart';
import '../../presentation/blocs/quota_history/quota_history_bloc.dart';
import '../../presentation/pages/quota/quota_history_page.dart';
import '../services/service_provider.dart';

class GlobalDrawer {
  static ApiService? _apiService;
  static BuildContext? navigatorContext;

  static void initialize(ApiService apiService) {
    _apiService = apiService;
  }

  // Remove the static ValueNotifier - this was the core problem
  static Drawer getDrawer(BuildContext context, {Set<String>? userRoles}) {
    navigatorContext = context;

    // Build menu items dynamically based on userRoles
    List<Widget> menuItems = _buildMenuItems(userRoles);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'Services',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ...menuItems,
        ],
      ),
    );
  }

  static List<Widget> _buildMenuItems(Set<String>? userRoles) {
    List<Widget> items = [
      // ListTile(
      //   leading: const Icon(Icons.report),
      //   title: const Text('Reports'),
      //   onTap: () {
      //     Navigator.push(
      //       navigatorContext!,
      //       MaterialPageRoute(builder: (context) => const ReportScreen()),
      //     );
      //   },
      // ),
      // My Bonuses menu item
      ListTile(
        leading: const Icon(Icons.card_giftcard),
        title: const Text('My Bonuses'),
        onTap: () {
          Navigator.pushNamed(navigatorContext!, '/bonus-list');
        },
      ),

      ListTile(
        leading: const Icon(Icons.inventory_2),
        title: const Text('Stock Report'),
        onTap: () async {
          final apiService = await ServiceProvider.getApiService();
          if (navigatorContext != null && navigatorContext!.mounted) {
            // Fetch quota snapshot to get all available items for filter chips
            Map<String, String>? availableItems;
            try {
              final snapshot = await apiService.getQuotaSnapshot();
              if (snapshot.items.isNotEmpty) {
                availableItems = {};
                for (final item in snapshot.items) {
                  availableItems[item.itemCode] = item.itemName;
                }
              }
            } catch (e) {
              // If fetch fails, chips will load dynamically
              availableItems = null;
            }

            if (navigatorContext!.mounted) {
              Navigator.push(
                navigatorContext!,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => QuotaHistoryBloc(
                      apiService: apiService,
                      initialItemCode: 'M00087', // Default filter to 14.2 KG Cylinder
                    ),
                    child: QuotaHistoryPage(
                      pageTitle: 'Stock Report',
                      initialAvailableItems: availableItems,
                    ),
                  ),
                ),
              );
            }
          }
        },
      ),

      ListTile(
        leading: const Icon(Icons.add_box_sharp),
        title: const Text('SDMS Transactions'),

        onTap: () {
          Navigator.push(
            navigatorContext!,
            MaterialPageRoute(
                builder: (context) => const SDMSTransactionListPage(),
          ),
          );
        },
      ),

      ListTile(
        leading: const Icon(Icons.settings),
        title: const Text('Settings'),
        onTap: () {
          // Add navigation logic for Settings
        },
      ),

      // Hidden for release build - Digital Credit not ready
      // ListTile(
      //   leading: const Icon(Icons.payment),
      //   title: const Text('Digital Credits'),
      //   onTap: () {
      //     Navigator.push(
      //       navigatorContext!,
      //       MaterialPageRoute(
      //         builder: (context) => const DigitalCreditsListPage(),
      //       ),
      //     );
      //   },
      // ),
    ];

    // Add role-specific items
    // if (userRoles?.contains('Delivery Boy') != true) {
    //   items.add(
    //     ListTile(
    //       leading: const Icon(Icons.inventory_2_sharp),
    //       title: const Text('Procurement'),
    //       onTap: () {
    //         Navigator.push(
    //           navigatorContext!,
    //           MaterialPageRoute(
    //             builder: (context) => const PurchaseInvoiceScreen(),
    //           ),
    //         );
    //       },
    //     ),
    //   );
    // }

    // Add logout at the end
    items.add(
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Logout'),
        onTap: () {
          if (navigatorContext != null) {
            _confirmLogout(navigatorContext!);
          }
        },
      ),
    );

    return items;
  }

  static void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LogoutConfirmationDialog(
        onLogout: () => _logout(context),
      ),
    );
  }

  static Future<void> _logout(BuildContext context) async {
    try {
      // Clear all BLoC caches first
      context.read<VehicleBloc>().add(const ClearVehicleCache());
      context.read<OrdersBloc>().add(const ClearOrdersCache());
      context.read<InventoryBloc>().add(const ClearInventoryCache());
      // Hidden for release build - Digital Credit not ready
      // context.read<DigitalCreditBloc>().add(const ClearDigitalCreditCache());

      // Clear all cached data from secure storage
      if (_apiService != null) {
        await _apiService!.logout();
      }

      // Navigate to login and remove all previous routes
      Navigator.pushNamedAndRemoveUntil(
        context,
        'login',
            (route) => false,
      );
    } catch (e) {
      context.showInfoSnackBar('Error logging out: $e');
    }
  }
}