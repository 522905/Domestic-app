// Updated GlobalDrawer with proper SDMS navigation
import 'package:flutter/material.dart';
import '../../presentation/pages/profile/profile_screen.dart';
import '../../presentation/pages/purchase_invoice/purchase_invoice_screen.dart';
import '../../presentation/pages/reports/reports_screen.dart';
import '../../presentation/pages/sdms/sdms_transaction_list_page.dart';
import '../../core/services/api_service.dart';

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
      ListTile(
        leading: const Icon(Icons.report),
        title: const Text('Reports'),
        onTap: () {
          Navigator.push(
            navigatorContext!,
            MaterialPageRoute(builder: (context) => const ReportScreen()),
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