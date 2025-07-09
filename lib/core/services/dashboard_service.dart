import 'package:flutter/material.dart';
import 'package:lpg_distribution_app/core/services/service_provider.dart';

import '../../presentation/widgets/dashboard/approval_card.dart';
import '../../presentation/widgets/dashboard/inventory_action_card.dart';
import 'api_service_interface.dart';
import 'mock_data.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  bool _isRefreshing = false;

  Future<void> refreshDashboardData() async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      final ApiServiceInterface apiService = await ServiceProvider.getApiService();

      // 1. Fetch base dashboard data
      final dashboardData = await apiService.getDashboardData();
      _updateDashboardData(dashboardData);

      // 2. Fetch inventory data - this updates stock items
      final inventoryData = await apiService.getInventory();
      _updateInventoryData(inventoryData);

      // 3. Fetch inventory requests - this updates approval items
      final inventoryRequests = await apiService.getInventoryRequests();
      _updateInventoryRequests(inventoryRequests);

      // 4. Fetch warehouses - updates warehouse name
      final warehouses = await apiService.getWarehouses();
      _updateWarehouseData(warehouses);

      // 5. Fetch vehicles - needed for vehicle assignments
      final vehicles = await apiService.getVehicles();
      _updateVehicleData(vehicles);

      debugPrint('All dashboard data refreshed successfully');
    } catch (e) {
      debugPrint('Error refreshing dashboard data: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  void _updateDashboardData(Map<String, dynamic> data) {
    if (data.containsKey('warehouseName')) {
      MockData.warehouseName = data['warehouseName'];
    }

    if (data.containsKey('pendingCounts')) {
      MockData.pendingCounts = Map<String, int>.from(data['pendingCounts']);
    }

    if (data.containsKey('welcomeMessage')) {
      MockData.welcomeMessage = data['welcomeMessage'];
    }
  }

  void _updateInventoryData(List<dynamic> inventoryData) {
    if (inventoryData.isEmpty) return;

    final stockItems = <StockItem>[];

    for (var item in inventoryData) {
      final String name = item['name'] ?? '';
      final int available = item['available'] ?? 0;
      final int reserved = item['reserved'] ?? 0;
      final int total = available + reserved;

      Color color = Colors.green;
      if (available / total < 0.3) {
        color = Colors.red;
      } else if (available / total < 0.7) {
        color = Colors.amber;
      }

      stockItems.add(StockItem(
        name: name,
        available: available,
        total: total,
        color: color,
      ));
    }

    // Update stock items for all roles
    MockData.stockItems['warehouse_manager'] = stockItems;
    MockData.stockItems['general_manager'] = stockItems;
  }

  void _updateInventoryRequests(List<dynamic> requests) {
    if (requests.isEmpty) return;

    final List<Map<String, dynamic>> warehouseManagerApprovals = [];
    final List<Map<String, dynamic>> generalManagerApprovals = [];

    for (var request in requests) {
      try {
        // Create details string
        String details = '';
        if (request['cylinders_14kg'] != null && request['cylinders_14kg'] > 0) {
          details += '14.2kg Cylinders × ${request['cylinders_14kg']} ';
        }
        if (request['cylinders_19kg'] != null && request['cylinders_19kg'] > 0) {
          details += '19kg Cylinders × ${request['cylinders_19kg']} ';
        }
        if (request['small_cylinders'] != null && request['small_cylinders'] > 0) {
          details += '5kg Cylinders × ${request['small_cylinders']}';
        }

        final Map<String, dynamic> approvalItem = {
          'type': ApprovalType.transfer, // Using transfer type to show in dashboard
          'id': request['id'] ?? '',
          'details': details,
          'time': request['timestamp'] ?? '',
          'status': request['status'] ?? 'PENDING',
          'warehouseFrom': request['warehouse_name'] ?? '',
          'warehouseTo': 'Central Warehouse',
          'itemDetails': details,
        };

        // Add to appropriate lists
        generalManagerApprovals.add(approvalItem);

        // For warehouse manager, only show their warehouse
        final int requestWarehouseId = request['warehouse_id'] ?? 0;
        final int userWarehouseId = MockData.userData['warehouse_id'] ?? 0;

        if (requestWarehouseId == userWarehouseId) {
          warehouseManagerApprovals.add(approvalItem);
        }
      } catch (e) {
        debugPrint('Error processing inventory request: $e');
      }
    }

    // Update approval items
    MockData.approvalItems['warehouse_manager'] = warehouseManagerApprovals;
    MockData.approvalItems['general_manager'] = generalManagerApprovals;

    // Update status summaries
    MockData.statusSummaries['general_manager'] = [
      {
        'title': 'Pending Orders',
        'count': generalManagerApprovals.length,
        'icon': Icons.hourglass_empty,
        'iconColor': Colors.amber,
        'backgroundColor': Colors.amber.withOpacity(0.1),
        'trend': 3,
        'trendUp': false,
        'critical': false,
      },
      {
        'title': 'Stock Alerts',
        'count': 4, // You can calculate this from inventory data
        'icon': Icons.warning,
        'iconColor': Colors.red,
        'backgroundColor': Colors.red.withOpacity(0.1),
        'trend': null,
        'trendUp': null,
        'critical': true,
      },
    ];
  }

  void _updateWarehouseData(List<dynamic> warehouses) {
    if (warehouses.isEmpty) return;

    // Find matching warehouse for current user
    final int userWarehouseId = MockData.userData['warehouse_id'] ?? 0;

    for (var warehouse in warehouses) {
      final int warehouseId = warehouse['id'] ?? 0;

      if (warehouseId == userWarehouseId) {
        MockData.warehouseName = warehouse['name'] ?? 'Unknown Warehouse';
        break;
      }
    }
  }

  void _updateVehicleData(List<dynamic> vehicles) {
    // Update any vehicle-related data in MockData if needed
    // For example, could be used for driver dashboard
  }
}