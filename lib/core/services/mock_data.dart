import 'package:flutter/material.dart';
import '../../presentation/widgets/dashboard/approval_card.dart';
import '../../presentation/widgets/dashboard/inventory_action_card.dart';

/// Central location for all mock data used in the app
class MockData {
  // User data
  static Map<String, dynamic> userData = {
    'id': '12345',
    'name': 'Rahul Singh',
    'email': 'rahul.singh@example.com',
    'phone': '+91 98765 43210',
    'role': 'warehouse_manager', // Change this to test different roles
    'region': 'East',
  };

  // Dashboard data
  static Map<String, dynamic> dashboardData = {
    'pendingOrders': 17,
    'pendingApprovals': 12,
    'stockAlerts': 4,
    'todaysSales': 25000,
    'monthToDate': 450000,
  };

  // Role display names
  static Map<String, String> roleDisplayNames = {
    'delivery_boy': 'Delivery Executive',
    'cse': 'Customer Service Executive',
    'cashier': 'Cashier',
    'warehouse_manager': 'Warehouse Manager, East Region',
    'general_manager': 'General Manager, East Region',
  };

  // Default welcome message
  static String welcomeMessage = 'Welcome to your dashboard. Your recent activities will appear here.';

  // Warehouse name
  static String warehouseName = 'Whitefield';

  // Pending counts for inventory actions
  static Map<String, int> pendingCounts = {
    'collect': 3,
    'deposit': 5,
    'refill': 8,
    'cash': 4,
  };

  // Stock items by role
  static Map<String, List<StockItem>> stockItems = {
    'warehouse_manager': [
      StockItem(
        name: '14.2kg Cylinders',
        available: 120,
        total: 150,
        color: Colors.green,
      ),
      StockItem(
        name: '5kg Cylinders',
        available: 45,
        total: 75,
        color: Colors.amber,
      ),
      StockItem(
        name: '19kg Commercial',
        available: 12,
        total: 50,
        color: Colors.red,
      ),
    ],
    'general_manager': [
      StockItem(
        name: '14.2kg Cylinders',
        available: 250,
        total: 300,
        color: Colors.green,
      ),
      StockItem(
        name: '5kg Cylinders',
        available: 80,
        total: 120,
        color: Colors.amber,
      ),
      StockItem(
        name: '19kg Commercial',
        available: 30,
        total: 80,
        color: Colors.green,
      ),
    ],
  };

  // Approval items by role
  static Map<String, List<Map<String, dynamic>>> approvalItems = {
    'warehouse_manager': [
      {
        'type': ApprovalType.collect,
        'id': 'CLT-1234',
        'details': '14.2kg Cylinders × 20 | 5kg × 5',
        'time': '11:45 AM Today',
        'status': 'Pending',
      },
      {
        'type': ApprovalType.transfer,
        'id': 'TR-2025505',
        'details': 'Filled Cylinders × 10\nFrom: Warehouse 1 to Warehouse 2',
        'time': '14:30 PM Today',
        'status': 'Pending',
        'warehouseFrom': 'Warehouse 1 (Ludhiana Central)',
        'warehouseTo': 'Warehouse 2 (Ludhiana North)',
        'itemDetails': '10 Filled Cylinders',
      },
      {
        'type': ApprovalType.collect,
        'id': 'CLT-4321',
        'details': '14.2kg Cylinders × 15 | 5kg × 10',
        'time': '13:36 AM Today',
        'status': 'Review',
      },
      {
        'type': ApprovalType.cashDeposit,
        'id': 'C-1058',
        'details': 'Amount: ₹15,000\nAccount: Refill',
        'time': '11:15 AM Today',
        'status': 'Review',
      },
      {
        'type': ApprovalType.deposit,
        'id': 'DEP-3642',
        'details': 'Empty 14.2kg × 20',
        'time': '10:30 AM Today',
        'status': 'Pending',
      },
    ],
    'general_manager': [
      {
        'type': ApprovalType.refill,
        'id': 'R-2574',
        'details': '14.2kg Cylinders × 8\nVehicle: KA-01-AB-1234',
        'time': '12:30 PM Today',
        'status': 'Pending',
      },
      {
        'type': ApprovalType.cashDeposit,
        'id': 'C-1058',
        'details': 'Amount: ₹15,000\nAccount: Refill',
        'time': '11:15 AM Today',
        'status': 'Review',
      },
      {
        'type': ApprovalType.transfer,
        'id': 'TR-5051',
        'details': 'Filled Cylinders × 20\nFrom: Warehouse 3 to Warehouse 1',
        'time': '13:15 PM Today',
        'status': 'Pending',
        'warehouseFrom': 'Warehouse 3 (Jalandhar)',
        'warehouseTo': 'Warehouse 1 (Ludhiana Central)',
        'itemDetails': '20 Filled Cylinders',
      },
    ],
  };

  // Status summaries for general manager
  static Map<String, List<Map<String, dynamic>>> statusSummaries = {
    'general_manager': [
      {
        'title': 'Pending Orders',
        'count': 17,
        'icon': Icons.hourglass_empty,
        'iconColor': Colors.amber,
        'backgroundColor': Colors.amber.withOpacity(0.1),
        'trend': 3,
        'trendUp': false,
        'critical': false,
      },
      {
        'title': 'Stock Alerts',
        'count': 4,
        'icon': Icons.warning,
        'iconColor': Colors.red,
        'backgroundColor': Colors.red.withOpacity(0.1),
        'trend': null,
        'trendUp': null,
        'critical': true,
      },
    ],
  };

  // Quick actions
  static List<Map<String, dynamic>> quickActions = [
    {
      'title': 'New Order',
      'icon': Icons.add,
      'iconColor': Colors.blue,
      'backgroundColor': Colors.blue.withOpacity(0.1),
    },
    {
      'title': 'Inventory',
      'icon': Icons.grid_view,
      'iconColor': Colors.green,
      'backgroundColor': Colors.green.withOpacity(0.1),
    },
  ];

  static List<Map<String, dynamic>> deliveries = [
    {
      'title': 'Order #ORD-10001',
      'subtitle': '14.2kg Cylinders × 5',
      'status': 'Pending',
      'statusColor': Colors.amber,
    },
    {
      'title': 'Order #ORD-10002',
      'subtitle': '14.2kg Cylinders × 10',
      'status': 'In Progress',
      'statusColor': Colors.blue,
    },
    {
      'title': 'Order #ORD-10003',
      'subtitle': '14.2kg Cylinders × 15',
      'status': 'Completed',
      'statusColor': Colors.green,
    },
  ];

  // Cashier data
  static Map<String, String> cashierData = {
    'collection': '₹25,000',
    'refunds': '₹2,000',
    'balance': '₹23,000',
  };

  // Customer orders for CSE
  static List<Map<String, dynamic>> customerOrders = [
    {
      'customer': 'Customer: Rahul Gupta',
      'type': 'New Connection',
      'status': 'Pending',
      'statusColor': Colors.amber,
    },
    {
      'customer': 'Customer: Priya Sharma',
      'type': 'Refill',
      'status': 'Approved',
      'statusColor': Colors.green,
    },
    {
      'customer': 'Customer: Amit Kumar',
      'type': 'Regulator',
      'status': 'Rejected',
      'statusColor': Colors.red,
    },
  ];

  // Custom tab content by role
  static Map<String, Map<String, Function>> tabContent = {};

  // Method to update dashboard data
  static void updateData(Map<String, dynamic> newData) {
    // Update user data
    if (newData.containsKey('userData')) {
      userData = {...userData, ...newData['userData']};
    }

    // Update stock items
    if (newData.containsKey('stockItems') && newData['stockItems'] is Map) {
      final Map stockItemsUpdate = newData['stockItems'];
      stockItemsUpdate.forEach((role, items) {
        stockItems[role] = items;
      });
    }

    // Update pending counts
    if (newData.containsKey('pendingCounts')) {
      pendingCounts = {...pendingCounts, ...newData['pendingCounts']};
    }

    // Update warehouse name
    if (newData.containsKey('warehouseName')) {
      warehouseName = newData['warehouseName'];
    }

    // Update approvals
    if (newData.containsKey('approvalItems') && newData['approvalItems'] is Map) {
      final Map approvalsUpdate = newData['approvalItems'];
      approvalsUpdate.forEach((role, items) {
        approvalItems[role] = items;
      });
    }

    // Update deliveries
    if (newData.containsKey('deliveries')) {
      deliveries = newData['deliveries'];
    }

    // Update cashier data
    if (newData.containsKey('cashierData')) {
      cashierData = {...cashierData, ...newData['cashierData']};
    }

    // Update welcome message
    if (newData.containsKey('welcomeMessage')) {
      welcomeMessage = newData['welcomeMessage'];
    }
  }

  static void resetToDefaults() {
    // Reset all fields to their default values based on user role
    final role = userData['role'];

    // Reset role-specific data
    if (role == 'warehouse_manager') {
      stockItems = {...defaultStockItems};
      // approvalItems = {...defaultApprovalItems};
      // Reset other fields
    } else if (role == 'general_manager') {
      // Reset GM specific data
    }
    // etc.
  }
  // Static default data in MockData class
  static final Map<String, List<StockItem>> defaultStockItems = {
    'warehouse_manager': [
      StockItem(name: '14.2kg Cylinders', available: 120, total: 150, color: Colors.green),
      // etc.
    ],
    'general_manager': [
      // Default GM stock items
    ],
  };


}