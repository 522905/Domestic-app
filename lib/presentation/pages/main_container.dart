import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/cash_page.dart';
import 'package:lpg_distribution_app/presentation/pages/dashboard/dashboard_screen.dart';
import 'package:lpg_distribution_app/presentation/pages/profile/profile_screen.dart';
import 'package:lpg_distribution_app/presentation/widgets/orders/orders_page.dart';

import 'inventory/inventory_request_screen.dart';


class MainContainer extends StatefulWidget {
  const MainContainer({Key? key}) : super(key: key);

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardScreen(),
          OrdersPage(),
          CashPage(),
           // InventoryListPage(),
           InventoryRequestsPage(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0E5CA8), // Brand Blue
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12.sp),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Cash',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}