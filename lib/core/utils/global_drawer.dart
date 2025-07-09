import 'package:flutter/material.dart';
import 'package:path/path.dart';
import '../../presentation/pages/api_test.dart';
import '../../presentation/pages/profile/profile_screen.dart';
import '../../presentation/pages/reports/reports_screen.dart';

class GlobalDrawer {
  // Use ValueNotifier to manage the menu items dynamically
  static final ValueNotifier<List<Widget>> menuItems = ValueNotifier([
    ListTile(
      leading: const Icon(Icons.report),
      title: const Text('Reports'),
      onTap: () {
        Navigator.push(
          GlobalDrawer.navigatorContext!,
          // MaterialPageRoute(builder: (context) => const ReportScreen()),
          MaterialPageRoute(builder: (context) =>  ApiTestScreen()),
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
      leading: const Icon(Icons.logout),
      title: const Text('Logout'),
      onTap: () {
        if (GlobalDrawer.navigatorContext != null) {
          GlobalDrawer._confirmLogout(GlobalDrawer.navigatorContext!);
        } else {
          debugPrint('Navigator context is null');
        }
      },
    ),
  ]);

  static BuildContext? navigatorContext;

  // Method to get the Drawer widget
  static Drawer getDrawer(BuildContext context) {
    navigatorContext = context; // Store the context for navigation
    return Drawer(
      child: ValueListenableBuilder<List<Widget>>(
        valueListenable: menuItems,
        builder: (context, items, _) {
          return ListView(
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
              ...items,
            ],
          );
        },
      ),
    );
  }

  // Method to update the menu items
  static void updateMenuItems(List<Widget> newItems) {
    menuItems.value = newItems;
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
    // Add your logout logic here
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error logging out: $e')),
    );
  }
}
}
