import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:lpg_distribution_app/core/services/token_manager.dart';
import '../models/inventory_request.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'api_service_interface.dart';
import 'mock_data.dart';

/// Mock API Service for development and testing
class MockApiService implements ApiServiceInterface {
  final ApiClient _apiClient;
  final bool _useMockData;
  late String baseUrl;

  // Singleton implementation
  static final MockApiService _instance = MockApiService._internal();
  factory MockApiService({bool useMockData = true}) => _instance._useMockData == useMockData
      ? _instance
      : MockApiService._internal(useMockData: useMockData);

  MockApiService._internal({bool useMockData = true})
      : _apiClient = ApiClient(),
        _useMockData = useMockData;

  @override
  Future<List<InventoryRequest>> getInventoryRequests() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      InventoryRequest(
        id: 'CL-1704098400000',
        warehouseId: '1',
        warehouseName: 'Mumbai Central Warehouse',
        requestedBy: 'Rajesh Kumar',
        role: 'CSE',
        cylinders14kg: 20,
        cylinders19kg: 10,
        smallCylinders: 5,
        status: 'PENDING',
        timestamp: '2025-01-01 10:30',
        isFavorite: false,
      ),
      InventoryRequest(
        id: 'DP-1704098500000',
        warehouseId: '2',
        warehouseName: 'Delhi North Warehouse',
        requestedBy: 'Sanjay Verma',
        role: 'Driver',
        cylinders14kg: 15,
        cylinders19kg: 25,
        smallCylinders: 0,
        status: 'APPROVED',
        timestamp: '2025-01-01 09:15',
        isFavorite: true,
      ),
    ];
  }

  @override
  Future<InventoryRequest> createInventoryRequest(InventoryRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return request;
  }

  @override
  Future<InventoryRequest> updateInventoryRequest(String id, InventoryRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return request;
  }

  @override
  Future<void> toggleFavoriteRequest(String requestId, bool isFavorite) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<List<Map<String, dynamic>>> getWarehouses() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return [
      {
        'id': 1,
        'name': 'Mumbai Central Warehouse',
        'address': '123 Industrial Area, Mumbai',
      },
      {
        'id': 2,
        'name': 'Delhi North Warehouse',
        'address': '456 Distribution Zone, Delhi',
      },
      {
        'id': 4,
        'name': 'Ludhiana Main Warehouse',
        'address': '45 Industrial Estate, Ludhiana, Punjab',
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getInventoryItems({
    int? warehouseId,
    String? itemType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    List<Map<String, dynamic>> allItems = [
      {
        'id': 1,
        'name': '14.2kg Cylinder',
        'item_type': 'Refill',
        'warehouse_id': 1,
        'available': 150,
      },
      {
        'id': 2,
        'name': '19kg Commercial Cylinder',
        'item_type': 'Refill',
        'warehouse_id': 1,
        'available': 80,
      },
      {
        'id': 3,
        'name': '5kg Cylinder',
        'item_type': 'Refill',
        'warehouse_id': 4,
        'available': 75,
      },
    ];

    if (warehouseId != null) {
      allItems = allItems.where((item) => item['warehouse_id'] == warehouseId).toList();
    }

    if (itemType != null) {
      allItems = allItems.where((item) => item['item_type'] == itemType).toList();
    }

    return allItems;
  }

  @override
  Future<void> initialize(String baseUrl) async {
    this.baseUrl = baseUrl;
    await _apiClient.init(baseUrl);
    // Perform any mock-specific initialization logic here
  }

  // Auth methods
  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Check credentials
      final user = _mockUsers.firstWhere(
            (user) => user['username'] == username && user['password'] == password,
        orElse: () => throw DioException(
          requestOptions: RequestOptions(path: 'login'),
          response: Response(
            requestOptions: RequestOptions(path: 'login'),
            statusCode: 401,
            data: {'detail': 'Invalid credentials'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Remove password from response
      final userResponse = Map<String, dynamic>.from(user);
      userResponse.remove('password');

      MockData.userData = userResponse;
      MockData.resetToDefaults();

      // Generate mock tokens
      final now = DateTime.now();
      final expiresIn = 3600;
      userResponse['access_token'] = _generateMockToken(user['username'], now.add(Duration(seconds: expiresIn)));
      userResponse['refresh_token'] = _generateMockToken(user['username'], now.add(const Duration(days: 7)));
      userResponse['expires_in'] = expiresIn;

      // Save tokens
      final tokenManager = TokenManager();
      await tokenManager.saveTokens(
        token: userResponse['access_token'],
        refreshToken: userResponse['refresh_token'],
        expiresIn: expiresIn,
      );

      return userResponse;
    } else {
      try {
        final response = await _apiClient.post(
          '/api/direct-test-token', // Use your test token endpoint
          data: {},
        );

        print("Token received: ${response.data['access_token']}");

        // Save token to TokenManager
        final tokenManager = TokenManager();
        await tokenManager.saveTokens(
          token: response.data['access_token'],
          refreshToken: response.data['refresh_token'],
          expiresIn: response.data['expires_in'] ?? 1800,
        );

        // Set token in API client
        await _apiClient.setToken(response.data['access_token']);

        return response.data;
      } catch (e) {
        print("Login error: $e");
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<void> logout() async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Clear tokens
      final tokenManager = TokenManager();
      await tokenManager.clearTokens();
      return;
    } else {
      try {
        await _apiClient.post(_apiClient.endpoints.logout);
        await _apiClient.logout(); // Clear tokens
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  // Get user profile
  @override
  Future<Map<String, dynamic>> getUserProfile() async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 700));

      // Get current token to determine user
      final tokenManager = TokenManager();
      final token = await tokenManager.getToken();

      if (token == null) {
        throw SessionExpiredException();
      }

      // Extract username from token (in real app would decode JWT)
      final username = token.split('.')[0];

      // Find user (in real app would get from token payload)
      final user = _mockUsers.firstWhere(
            (user) => user['username'] == username,
        orElse: () => _mockUsers[0],
      );

      // Remove password from response
      final userResponse = Map<String, dynamic>.from(user);
      userResponse.remove('password');

      return userResponse;
    } else {
      try {
        final response = await _apiClient.get(_apiClient.endpoints.userProfile);
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  // Orders methods
  @override
  Future<List<dynamic>> getOrdersList({
    Map<String, dynamic>? filters,
    int page = 1,
    int pageSize = 20,
    String? status,  // Add this parameter
  }) async {
    try {
      print("Calling getOrders with filters: $filters, status: $status");
      final String url = _apiClient.endpoints.orders;
      print("API URL: $url");

      // Add status to query parameters if provided
      Map<String, dynamic> queryParams = {
        'skip': (page - 1) * pageSize,
        'limit': pageSize,
        ...?filters,
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.get(url, queryParameters: queryParams);
      print("Raw API response: ${response.data}");
      return response.data;
    } catch (e) {
      print("Error in getOrders: $e");
      _handleError(e);
      return [];
    }
  }

  @override
  Future<void> requestOrderApproval(String orderId) async {
    // Mock implementation - just delay to simulate API call
    await Future.delayed(Duration(milliseconds: 500));
    print('Mock: Requesting approval for order $orderId');
  }

  @override
  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 600));

      // Find order by ID
      final order = _mockOrders.firstWhere(
            (order) => order['order_id'] == orderId,
        orElse: () => throw DioException(
          requestOptions: RequestOptions(path: 'orders/$orderId'),
          response: Response(
            requestOptions: RequestOptions(path: 'orders/$orderId'),
            statusCode: 404,
            data: {'detail': 'Order not found'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      return Map<String, dynamic>.from(order);
    } else {
      try {
        final response = await _apiClient.get(
          _apiClient.endpoints.orderDetail(orderId),
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));

      // Get current token to determine user
      final tokenManager = TokenManager();
      final token = await tokenManager.getToken();

      if (token == null) {
        throw SessionExpiredException();
      }

      // Extract username from token
      final username = token.split('.')[0];

      // Generate new order ID
      final orderId = 'ORD${Random().nextInt(90000) + 10000}';

      // Create new order
      final newOrder = {
        'order_id': orderId,
        'order_type': orderData['order_type'],
        'status': 'pending',
        'vehicle_id': orderData['vehicle_id'],
        'warehouse_id': orderData['warehouse_id'],
        'created_by': username,
        'created_at': DateTime.now().toIso8601String(),
        'items': orderData['items'],
        'total_amount': orderData['total_amount'],
        'virtual_code': orderData['virtual_code'] ?? 'VC${Random().nextInt(90000) + 10000}',
      };

      // Add to mock orders
      _mockOrders.add(newOrder);

      return newOrder;
    } else {
      try {
        final response = await _apiClient.post(
          _apiClient.endpoints.orders,
          data: orderData,
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<Map<String, dynamic>> approveOrder(String orderId, String comment) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Get current token to determine user
      final tokenManager = TokenManager();
      final token = await tokenManager.getToken();

      if (token == null) {
        throw SessionExpiredException();
      }

      // Extract username from token
      final username = token.split('.')[0];

      // Find order by ID
      final orderIndex = _mockOrders.indexWhere((order) => order['order_id'] == orderId);
      if (orderIndex == -1) {
        throw DioException(
          requestOptions: RequestOptions(path: 'orders/approve'),
          response: Response(
            requestOptions: RequestOptions(path: 'orders/approve'),
            statusCode: 404,
            data: {'detail': 'Order not found'},
          ),
          type: DioExceptionType.badResponse,
        );
      }

      // Check if order is already approved
      if (_mockOrders[orderIndex]['status'] == 'approved') {
        throw DioException(
          requestOptions: RequestOptions(path: 'orders/approve'),
          response: Response(
            requestOptions: RequestOptions(path: 'orders/approve'),
            statusCode: 400,
            data: {'detail': 'Order already approved'},
          ),
          type: DioExceptionType.badResponse,
        );
      }

      // Update order status
      _mockOrders[orderIndex]['status'] = 'approved';
      _mockOrders[orderIndex]['approved_by'] = username;
      _mockOrders[orderIndex]['approved_at'] = DateTime.now().toIso8601String();
      _mockOrders[orderIndex]['approval_comment'] = comment;

      return Map<String, dynamic>.from(_mockOrders[orderIndex]);
    } else {
      try {
        final response = await _apiClient.post(
          _apiClient.endpoints.orderApproval,
          data: {
            'order_id': orderId,
            'comment': comment,
          },
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<Map<String, dynamic>> rejectOrder(String orderId, String reason) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      print('Mock: Rejecting order $orderId with reason: $reason');
      // Get current token to determine user
      final tokenManager = TokenManager();
      final token = await tokenManager.getToken();

      if (token == null) {
        throw SessionExpiredException();
      }

      // Extract username from token
      final username = token.split('.')[0];

      // Find order by ID
      final orderIndex = _mockOrders.indexWhere((order) => order['order_id'] == orderId);
      if (orderIndex == -1) {
        throw DioException(
          requestOptions: RequestOptions(path: 'orders/reject'),
          response: Response(
            requestOptions: RequestOptions(path: 'orders/reject'),
            statusCode: 404,
            data: {'detail': 'Order not found'},
          ),
          type: DioExceptionType.badResponse,
        );
      }

      // Check if order is already rejected or approved
      if (_mockOrders[orderIndex]['status'] == 'rejected') {
        throw DioException(
          requestOptions: RequestOptions(path: 'orders/reject'),
          response: Response(
            requestOptions: RequestOptions(path: 'orders/reject'),
            statusCode: 400,
            data: {'detail': 'Order already rejected'},
          ),
          type: DioExceptionType.badResponse,
        );
      }

      // Update order status
      _mockOrders[orderIndex]['status'] = 'rejected';
      _mockOrders[orderIndex]['rejected_by'] = username;
      _mockOrders[orderIndex]['rejected_at'] = DateTime.now().toIso8601String();
      _mockOrders[orderIndex]['rejection_reason'] = reason;

      return Map<String, dynamic>.from(_mockOrders[orderIndex]);
    } else {
      try {
        final response = await _apiClient.post(
          _apiClient.endpoints.orderReject,
          data: {
            'order_id': orderId,
            'reason': reason,
          },
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  // Inventory methods
  @override
  Future<List<dynamic>> getInventory({
    String? warehouseId,
    String? itemType,
    Map<String, dynamic>? filters,
  }) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 700));

      // Filter inventory by warehouse and item type
      List<Map<String, dynamic>> filteredInventory = _mockInventory;

      if (warehouseId != null) {
        filteredInventory = filteredInventory
            .where((item) => item['warehouse_id'] == warehouseId)
            .toList();
      }

      if (itemType != null) {
        filteredInventory = filteredInventory
            .where((item) => item['item_type'] == itemType)
            .toList();
      }

      return filteredInventory;
    } else {
      try {
        String endpoint = warehouseId != null
            ? _apiClient.endpoints.inventoryByWarehouse(warehouseId)
            : _apiClient.endpoints.inventory;

        final response = await _apiClient.get(
          endpoint,
          queryParameters: {
            'item_type': itemType,
            ...?filters,
          },
        );
        return response.data['results'];
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<Map<String, dynamic>> transferInventory(
      String sourceWarehouseId,
      String destinationWarehouseId,
      List<Map<String, dynamic>> items,
      ) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1200));

      // Get current token to determine user
      final tokenManager = TokenManager();
      final token = await tokenManager.getToken();

      if (token == null) {
        throw SessionExpiredException();
      }

      // Extract username from token
      final username = token.split('.')[0];

      // Check if warehouses exist
      final sourceWarehouse = _mockWarehouses.firstWhere(
            (wh) => wh['warehouse_id'] == sourceWarehouseId,
        orElse: () => throw DioException(
          requestOptions: RequestOptions(path: 'inventory/transfer'),
          response: Response(
            requestOptions: RequestOptions(path: 'inventory/transfer'),
            statusCode: 404,
            data: {'detail': 'Source warehouse not found'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final destWarehouse = _mockWarehouses.firstWhere(
            (wh) => wh['warehouse_id'] == destinationWarehouseId,
        orElse: () => throw DioException(
          requestOptions: RequestOptions(path: 'inventory/transfer'),
          response: Response(
            requestOptions: RequestOptions(path: 'inventory/transfer'),
            statusCode: 404,
            data: {'detail': 'Destination warehouse not found'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Validate inventory availability
      for (var item in items) {
        final inventoryItem = _mockInventory.firstWhere(
              (inv) => inv['item_id'] == item['item_id'] && inv['warehouse_id'] == sourceWarehouseId,
          orElse: () => throw DioException(
            requestOptions: RequestOptions(path: 'inventory/transfer'),
            response: Response(
              requestOptions: RequestOptions(path: 'inventory/transfer'),
              statusCode: 400,
              data: {'detail': 'Item ${item['item_id']} not found in source warehouse'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        if (inventoryItem['available'] < item['quantity']) {
          throw DioException(
            requestOptions: RequestOptions(path: 'inventory/transfer'),
            response: Response(
              requestOptions: RequestOptions(path: 'inventory/transfer'),
              statusCode: 400,
              data: {'detail': 'Insufficient quantity for item ${item['item_id']}'},
            ),
            type: DioExceptionType.badResponse,
          );
        }
      }

      // Create transfer record
      final transferId = 'TRF${Random().nextInt(90000) + 10000}';
      final transferRecord = {
        'transfer_id': transferId,
        'source_warehouse_id': sourceWarehouseId,
        'destination_warehouse_id': destinationWarehouseId,
        'status': 'completed',
        'created_by': username,
        'created_at': DateTime.now().toIso8601String(),
        'items': items,
      };

      // Update inventory (reduce source, increase destination)
      for (var item in items) {
        // Decrease from source warehouse
        final sourceIndex = _mockInventory.indexWhere(
              (inv) => inv['item_id'] == item['item_id'] && inv['warehouse_id'] == sourceWarehouseId,
        );

        if (sourceIndex != -1) {
          _mockInventory[sourceIndex]['available'] -= item['quantity'];
          _mockInventory[sourceIndex]['in_transit'] += item['quantity'];
        }

        // Increase in destination warehouse
        final destIndex = _mockInventory.indexWhere(
              (inv) => inv['item_id'] == item['item_id'] && inv['warehouse_id'] == destinationWarehouseId,
        );

        if (destIndex != -1) {
          _mockInventory[destIndex]['in_transit'] += item['quantity'];
        } else {
          // Create new inventory record in destination
          final sourceItem = _mockInventory.firstWhere(
                (inv) => inv['item_id'] == item['item_id'] && inv['warehouse_id'] == sourceWarehouseId,
          );

          _mockInventory.add({
            'item_id': item['item_id'],
            'name': sourceItem['name'],
            'item_type': sourceItem['item_type'],
            'warehouse_id': destinationWarehouseId,
            'available': 0,
            'reserved': 0,
            'in_transit': item['quantity'],
          });
        }
      }

      return transferRecord;
    } else {
      try {
        final response = await _apiClient.post(
          _apiClient.endpoints.inventoryTransfer,
          data: {
            'source_warehouse_id': sourceWarehouseId,
            'destination_warehouse_id': destinationWarehouseId,
            'items': items,
          },
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  // Collection/Deposit methods
  @override
  Future<Map<String, dynamic>> collectItems(
      String vehicleId,
      String warehouseId,
      List<Map<String, dynamic>> items,
      List<String>? orderIds,
      ) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));

      // Get current token to determine user
      final tokenManager = TokenManager();
      final token = await tokenManager.getToken();

      if (token == null) {
        throw SessionExpiredException();
      }

      // Extract username from token
      final username = token.split('.')[0];

      // Check if vehicle and warehouse exist
      final vehicle = _mockVehicles.firstWhere(
            (v) => v['vehicle_id'] == vehicleId,
        orElse: () => throw DioException(
          requestOptions: RequestOptions(path: 'transactions/collect'),
          response: Response(
            requestOptions: RequestOptions(path: 'transactions/collect'),
            statusCode: 404,
            data: {'detail': 'Vehicle not found'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final warehouse = _mockWarehouses.firstWhere(
            (wh) => wh['warehouse_id'] == warehouseId,
        orElse: () => throw DioException(
          requestOptions: RequestOptions(path: 'transactions/collect'),
          response: Response(
            requestOptions: RequestOptions(path: 'transactions/collect'),
            statusCode: 404,
            data: {'detail': 'Warehouse not found'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Validate inventory availability
      for (var item in items) {
        final inventoryItem = _mockInventory.firstWhere(
              (inv) => inv['item_id'] == item['item_id'] && inv['warehouse_id'] == warehouseId,
          orElse: () => throw DioException(
            requestOptions: RequestOptions(path: 'transactions/collect'),
            response: Response(
              requestOptions: RequestOptions(path: 'transactions/collect'),
              statusCode: 400,
              data: {'detail': 'Item ${item['item_id']} not found in warehouse'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        if (inventoryItem['available'] < item['quantity']) {
          throw DioException(
            requestOptions: RequestOptions(path: 'transactions/collect'),
            response: Response(
              requestOptions: RequestOptions(path: 'transactions/collect'),
              statusCode: 400,
              data: {'detail': 'Insufficient quantity for item ${item['item_id']}'},
            ),
            type: DioExceptionType.badResponse,
          );
        }
      }

      // Create collection record
      final collectionId = 'COL${Random().nextInt(90000) + 10000}';
      final collectionRecord = {
        'collection_id': collectionId,
        'vehicle_id': vehicleId,
        'warehouse_id': warehouseId,
        'status': 'completed',
        'created_by': username,
        'created_at': DateTime.now().toIso8601String(),
        'items': items,
        'order_ids': orderIds,
      };

      // Update inventory
      for (var item in items) {
        final index = _mockInventory.indexWhere(
              (inv) => inv['item_id'] == item['item_id'] && inv['warehouse_id'] == warehouseId,
        );

        if (index != -1) {
          _mockInventory[index]['available'] -= item['quantity'];
        }
      }

      // Update orders if provided
      if (orderIds != null) {
        for (var orderId in orderIds) {
          final index = _mockOrders.indexWhere((order) => order['order_id'] == orderId);
          if (index != -1 && _mockOrders[index]['status'] == 'approved') {
            _mockOrders[index]['status'] = 'completed';
          }
        }
      }

      return collectionRecord;
    } else {
      try {
        final response = await _apiClient.post(
          _apiClient.endpoints.collect,
          data: {
            'vehicle_id': vehicleId,
            'warehouse_id': warehouseId,
            'items': items,
            'order_ids': orderIds,
          },
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<Map<String, dynamic>> depositItems(
      String vehicleId,
      String warehouseId,
      List<Map<String, dynamic>> items,
      List<String>? orderIds,
      List<String>? materialRequestIds,
      ) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));

      // Get current token to determine user
      final tokenManager = TokenManager();
      final token = await tokenManager.getToken();

      if (token == null) {
        throw SessionExpiredException();
      }

      // Extract username from token
      final username = token.split('.')[0];

      // Check if vehicle and warehouse exist
      final vehicle = _mockVehicles.firstWhere(
            (v) => v['vehicle_id'] == vehicleId,
        orElse: () => throw DioException(
          requestOptions: RequestOptions(path: 'transactions/deposit'),
          response: Response(
            requestOptions: RequestOptions(path: 'transactions/deposit'),
            statusCode: 404,
            data: {'detail': 'Vehicle not found'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final warehouse = _mockWarehouses.firstWhere(
            (wh) => wh['warehouse_id'] == warehouseId,
        orElse: () => throw DioException(
          requestOptions: RequestOptions(path: 'transactions/deposit'),
          response: Response(
            requestOptions: RequestOptions(path: 'transactions/deposit'),
            statusCode: 404,
            data: {'detail': 'Warehouse not found'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Create deposit record
      final depositId = 'DEP${Random().nextInt(90000) + 10000}';
      final depositRecord = {
        'deposit_id': depositId,
        'vehicle_id': vehicleId,
        'warehouse_id': warehouseId,
        'status': 'completed',
        'created_by': username,
        'created_at': DateTime.now().toIso8601String(),
        'items': items,
        'order_ids': orderIds,
        'material_request_ids': materialRequestIds,
      };

      // Update inventory
      for (var item in items) {
        final index = _mockInventory.indexWhere(
              (inv) => inv['item_id'] == item['item_id'] && inv['warehouse_id'] == warehouseId,
        );

        if (index != -1) {
          _mockInventory[index]['available'] += item['quantity'];
        } else {
          // Create new inventory record
          _mockInventory.add({
            'item_id': item['item_id'],
            'name': _getItemName(item['item_id']),
            'item_type': _getItemType(item['item_id']),
            'warehouse_id': warehouseId,
            'available': item['quantity'],
            'reserved': 0,
            'in_transit': 0,
          });
        }
      }

      return depositRecord;
    } else {
      try {
        final response = await _apiClient.post(
          _apiClient.endpoints.deposit,
          data: {
            'vehicle_id': vehicleId,
            'warehouse_id': warehouseId,
            'items': items,
            'order_ids': orderIds,
            'material_request_ids': materialRequestIds,
          },
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<List<dynamic>> getVehicles() async {
    try {
      final response = await _apiClient.get(ApiEndpoints(baseUrl).vehicles);
      print("Vehicles response: ${response.data}");
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> assignVehicle(
      String vehicleId,
      String warehouseId,
      DateTime validFrom,
      DateTime validUntil,
      ) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Get current token to determine user
      final tokenManager = TokenManager();
      final token = await tokenManager.getToken();

      if (token == null) {
        throw SessionExpiredException();
      }

      // Extract username from token
      final username = token.split('.')[0];

      // Check if vehicle and warehouse exist
      final vehicle = _mockVehicles.firstWhere(
            (v) => v['vehicle_id'] == vehicleId,
        orElse: () => throw DioException(
          requestOptions: RequestOptions(path: 'vehicles/assign'),
          response: Response(
            requestOptions: RequestOptions(path: 'vehicles/assign'),
            statusCode: 404,
            data: {'detail': 'Vehicle not found'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final warehouse = _mockWarehouses.firstWhere(
            (wh) => wh['warehouse_id'] == warehouseId,
        orElse: () => throw DioException(
          requestOptions: RequestOptions(path: 'vehicles/assign'),
          response: Response(
            requestOptions: RequestOptions(path: 'vehicles/assign'),
            statusCode: 404,
            data: {'detail': 'Warehouse not found'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Create assignment record
      final assignmentId = 'ASN${Random().nextInt(90000) + 10000}';
      final assignmentRecord = {
        'assignment_id': assignmentId,
        'vehicle_id': vehicleId,
        'warehouse_id': warehouseId,
        'valid_from': validFrom.toIso8601String(),
        'valid_until': validUntil.toIso8601String(),
        'assigned_by': username,
        'created_at': DateTime.now().toIso8601String(),
      };

      return assignmentRecord;
    } else {
      try {
        final response = await _apiClient.post(
          _apiClient.endpoints.vehicleAssignment,
          data: {
            'vehicle_id': vehicleId,
            'warehouse_id': warehouseId,
            'valid_from': validFrom.toIso8601String(),
            'valid_until': validUntil.toIso8601String(),
          },
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  // Gatepass methods
  @override
  Future<Map<String, dynamic>> generateGatepass(String transactionId) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 700));

      // Generate gatepass ID
      final gatepassId = 'GP${Random().nextInt(90000) + 10000}';

      // Create a mock gatepass
      final gatepass = {
        'gatepass_id': gatepassId,
        'transaction_id': transactionId,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'valid',
        'valid_until': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      };

      return gatepass;
    } else {
      try {
        final response = await _apiClient.post(
          _apiClient.endpoints.gatepass,
          data: {
            'transaction_id': transactionId,
          },
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<Map<String, dynamic>> printGatepass(String gatepassId) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 600));

      // Return print URL
      return {
        'print_url': 'https://example.com/api/gatepass/print?id=$gatepassId',
        'status': 'success',
      };
    } else {
      try {
        final response = await _apiClient.get(
          '${_apiClient.endpoints.gatepassPrint}?id=$gatepassId',
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  // Document methods
  @override
  Future<String> uploadDocument(
      dynamic file,
      String documentType,
      String? referenceId,
      ) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1500));

      // Generate document ID
      final documentId = 'DOC${Random().nextInt(90000) + 10000}';

      return documentId;
    } else {
      try {
        final fileName = file.path.split('/').last;
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: fileName),
          'document_type': documentType,
          'reference_id': referenceId,
        });

        final response = await _apiClient.post(
          _apiClient.endpoints.cashHandover,
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
          ),
        );

        return response.data['document_id'];
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  // Dashboard methods
  @override
  Future<Map<String, dynamic>> getDashboardData() async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 900));

      // Get current token to determine user
      final tokenManager = TokenManager();
      final token = await tokenManager.getToken();

      if (token == null) {
        throw SessionExpiredException();
      }

      // Extract username from token
      final username = token.split('.')[0];

      // Find user
      final user = _mockUsers.firstWhere(
            (user) => user['username'] == username,
        orElse: () => _mockUsers[0],
      );

      // Create dashboard data based on role
      Map<String, dynamic> dashboardData = {
        'orders_summary': {
          'pending': _mockOrders.where((o) => o['status'] == 'pending').length,
          'approved': _mockOrders.where((o) => o['status'] == 'approved').length,
          'rejected': _mockOrders.where((o) => o['status'] == 'rejected').length,
          'completed': _mockOrders.where((o) => o['status'] == 'completed').length,
        },
      };

      // Add role-specific data
      switch (user['role']) {
        case 'delivery_boy':
          dashboardData['my_orders'] = _mockOrders
              .where((o) => o['created_by'] == username)
              .take(5)
              .toList();
          break;
        case 'cse':
          dashboardData['my_orders'] = _mockOrders
              .where((o) => o['created_by'] == username)
              .take(5)
              .toList();
          dashboardData['sales_summary'] = {
            'today': 15000,
            'week': 85000,
            'month': 350000,
          };
          break;
        case 'cashier':
          dashboardData['pending_approvals'] = _mockOrders
              .where((o) =>
          o['status'] == 'pending' &&
              (o['order_type'] == 'SV' || o['order_type'] == 'TV'))
              .take(5)
              .toList();
          dashboardData['cash_summary'] = {
            'today_collected': 25000,
            'today_refunded': 2000,
            'balance': 23000,
          };
          break;
        case 'warehouse_manager':
          dashboardData['pending_approvals'] = _mockOrders
              .where((o) =>
          o['status'] == 'pending' &&
              (o['order_type'] == 'Refill' || o['order_type'] == 'NFR' || o['order_type'] == 'Transfer'))
              .take(5)
              .toList();
          dashboardData['inventory_summary'] = {
            'total_items': _mockInventory.length,
            'low_stock_items': _mockInventory
                .where((i) => i['available'] < 10)
                .length,
          };
          break;
        case 'general_manager':
          dashboardData['pending_approvals'] = _mockOrders
              .where((o) => o['status'] == 'pending')
              .take(5)
              .toList();
          dashboardData['sales_summary'] = {
            'today': 75000,
            'week': 425000,
            'month': 1750000,
          };
          dashboardData['inventory_summary'] = {
            'total_items': _mockInventory.length,
            'low_stock_items': _mockInventory
                .where((i) => i['available'] < 10)
                .length,
          };
          break;
      }

      return dashboardData;
    } else {
      try {
        final response = await _apiClient.get(_apiClient.endpoints.dashboard);
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  // Helper methods
  String _generateMockToken(String username, DateTime expiry) {
    final random = Random().nextInt(1000000).toString().padLeft(6, '0');
    final expiryStr = expiry.millisecondsSinceEpoch.toString();
    return '$username.$random.$expiryStr';
  }

  String _getItemName(String itemId) {
    switch (itemId) {
      case 'CYL14':
        return '14.2kg Cylinder';
      case 'CYL19':
        return '19kg Commercial Cylinder';
      case 'CYL5':
        return '5kg Cylinder';
      case 'REG001':
        return 'Regulator';
      case 'PIPE001':
        return 'Gas Pipe';
      case 'STOVE001':
        return 'Gas Stove';
      default:
        return 'Unknown Item';
    }
  }

  String _getItemType(String itemId) {
    if (itemId.startsWith('CYL')) {
      return 'Refill';
    } else {
      return 'NFR';
    }
  }

  // Unified error handling
  void _handleError(dynamic error) {
    if (error is DioException) {
      if (error.error is SessionExpiredException) {
        // Handle session expiry - emit event for global listener to redirect to login
        debugPrint('SESSION EXPIRED: ${error.message}');
        // Here you would likely trigger a global event that your app listens for
      } else if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        debugPrint('NETWORK ERROR: ${error.message}');
      } else if (error.response != null) {
        // Server returned an error response
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        debugPrint('SERVER ERROR [$statusCode]: $data');
      } else {
        debugPrint('UNKNOWN ERROR: ${error.message}');
      }
    } else {
      debugPrint('UNEXPECTED ERROR: $error');
    }
  }

  // Mock Data
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': 'DB1001',
      'username': 'delivery1',
      'password': 'password123',
      'name': 'Rajesh Kumar',
      'email': 'rajesh@example.com',
      'phone': '9876543210',
      'role': 'delivery_boy',
      'permissions': [
        'create_refill_order',
        'create_nfr_order',
        'collect_items',
        'deposit_items',
        'view_assigned_orders',
      ],
      'assigned_vehicles': ['V1001'],
      'assigned_warehouses': ['WH1001'],
    },
    {
      'id': 'CSE1001',
      'username': 'cse1',
      'password': 'password123',
      'name': 'Priya Singh',
      'email': 'priya@example.com',
      'phone': '9876543211',
      'role': 'cse',
      'permissions': [
        'create_refill_order',
        'create_nfr_order',
        'create_sv_order',
        'create_tv_order',
        'view_assigned_orders',
      ],
      'assigned_warehouses': ['WH1001', 'WH1002'],
    },
    {
      'id': 'CSH1001',
      'username': 'cashier1',
      'password': 'password123',
      'name': 'Amit Patel',
      'email': 'amit@example.com',
      'phone': '9876543212',
      'role': 'cashier',
      'permissions': [
        'view_sv_tv_orders',
        'approve_sv_orders',
        'approve_tv_orders',
        'manage_cash',
      ],
      'assigned_warehouses': ['WH1001'],
    },
    {
      'id': 'WM1001',
      'username': 'warehouse1',
      'password': 'password123',
      'name': 'Vikram Malhotra',
      'email': 'vikram@example.com',
      'phone': '9876543213',
      'role': 'warehouse_manager',
      'permissions': [
        'view_all_orders',
        'approve_refill_orders',
        'approve_nfr_orders',
        'approve_transfers',
        'manage_inventory',
        'manage_vehicles',
        'override_limits',
      ],
      'assigned_warehouses': ['WH1001', 'WH1002'],
    },
    {
      'id': 'GM1001',
      'username': 'gm1',
      'password': 'password123',
      'name': 'Sneha Sharma',
      'email': 'sneha@example.com',
      'phone': '9876543214',
      'role': 'general_manager',
      'permissions': [
        'view_all_orders',
        'view_all_transactions',
        'approve_all_orders',
        'approve_all_transactions',
        'manage_users',
        'manage_warehouses',
        'manage_vehicles',
        'override_all',
        'view_reports',
      ],
      'assigned_warehouses': ['WH1001', 'WH1002', 'WH1003'],
    },
  ];

  final List<Map<String, dynamic>> _mockOrders = [
    {
      'order_id': 'ORD10001',
      'order_type': 'Refill',
      'status': 'pending',
      'vehicle_id': 'V1001',
      'warehouse_id': 'WH1001',
      'created_by': 'delivery1',
      'created_at': '2025-04-20T10:30:00Z',
      'items': [
        {
          'item_id': 'CYL14',
          'name': '14.2kg Cylinder',
          'quantity': 10,
          'unit_price': 900.0,
        }
      ],
      'total_amount': 9000.0,
      'virtual_code': 'VC10001',
    },
    {
      'order_id': 'ORD10002',
      'order_type': 'NFR',
      'status': 'approved',
      'vehicle_id': 'V1001',
      'warehouse_id': 'WH1001',
      'created_by': 'delivery1',
      'created_at': '2025-04-20T11:15:00Z',
      'approved_by': 'warehouse1',
      'approved_at': '2025-04-20T11:45:00Z',
      'items': [
        {
          'item_id': 'REG001',
          'name': 'Regulator',
          'quantity': 5,
          'unit_price': 450.0,
        },
        {
          'item_id': 'PIPE001',
          'name': 'Gas Pipe',
          'quantity': 5,
          'unit_price': 250.0,
        }
      ],
      'total_amount': 3500.0,
      'virtual_code': 'VC10002',
    },
    {
      'order_id': 'ORD10003',
      'order_type': 'SV',
      'status': 'pending',
      'warehouse_id': 'WH1001',
      'created_by': 'cse1',
      'created_at': '2025-04-20T14:00:00Z',
      'items': [
        {
          'item_id': 'NEWCONN001',
          'name': 'New Connection Package',
          'quantity': 1,
          'unit_price': 5000.0,
        }
      ],
      'customer_details': {
        'name': 'Rahul Gupta',
        'address': '123 Main St, Mumbai',
        'phone': '9876543220',
      },
      'total_amount': 5000.0,
      'virtual_code': 'VC10003',
    },
    {
      'order_id': 'ORD10004',
      'order_type': 'TV',
      'status': 'approved',
      'warehouse_id': 'WH1002',
      'created_by': 'cse1',
      'created_at': '2025-04-19T09:30:00Z',
      'approved_by': 'cashier1',
      'approved_at': '2025-04-19T10:15:00Z',
      'items': [
        {
          'item_id': 'TERMINATION001',
          'name': 'Connection Termination',
          'quantity': 1,
          'unit_price': -2000.0, // Refund amount
        }
      ],
      'customer_details': {
        'name': 'Meena Verma',
        'address': '456 Park Ave, Delhi',
        'phone': '9876543221',
        'customer_id': 'CUST1005',
      },
      'total_amount': -2000.0,
      'virtual_code': 'VC10004',
    },
    {
      'order_id': 'ORD10005',
      'order_type': 'Transfer',
      'status': 'pending',
      'source_warehouse_id': 'WH1001',
      'warehouse_id': 'WH1002', // destination
      'created_by': 'warehouse1',
      'created_at': '2025-04-21T08:45:00Z',
      'items': [
        {
          'item_id': 'CYL14',
          'name': '14.2kg Cylinder',
          'quantity': 20,
        },
        {
          'item_id': 'CYL19',
          'name': '19kg Commercial Cylinder',
          'quantity': 10,
        }
      ],
      'notes': 'Urgent transfer needed for high demand',
    },
    {
      'order_id': 'ORD10006',
      'order_type': 'Refill',
      'status': 'rejected',
      'vehicle_id': 'V1002',
      'warehouse_id': 'WH1002',
      'created_by': 'delivery1',
      'created_at': '2025-04-18T16:30:00Z',
      'rejected_by': 'warehouse1',
      'rejected_at': '2025-04-18T17:00:00Z',
      'rejection_reason': 'Order exceeds daily limit by more than 20%',
      'items': [
        {
          'item_id': 'CYL14',
          'name': '14.2kg Cylinder',
          'quantity': 25,
          'unit_price': 900.0,
        }
      ],
      'total_amount': 22500.0,
      'virtual_code': 'VC10006',
    },
  ];

  final List<Map<String, dynamic>> _mockInventory = [
    {
      'item_id': 'CYL14',
      'name': '14.2kg Cylinder',
      'item_type': 'Refill',
      'warehouse_id': 'WH1001',
      'available': 150,
      'reserved': 10,
      'in_transit': 0,
    },
    {
      'item_id': 'CYL19',
      'name': '19kg Commercial Cylinder',
      'item_type': 'Refill',
      'warehouse_id': 'WH1001',
      'available': 80,
      'reserved': 5,
      'in_transit': 0,
    },
    {
      'item_id': 'CYL5',
      'name': '5kg Cylinder',
      'item_type': 'Refill',
      'warehouse_id': 'WH1001',
      'available': 45,
      'reserved': 0,
      'in_transit': 0,
    },
    {
      'item_id': 'REG001',
      'name': 'Regulator',
      'item_type': 'NFR',
      'warehouse_id': 'WH1001',
      'available': 100,
      'reserved': 5,
      'in_transit': 0,
    },
    {
      'item_id': 'PIPE001',
      'name': 'Gas Pipe',
      'item_type': 'NFR',
      'warehouse_id': 'WH1001',
      'available': 120,
      'reserved': 5,
      'in_transit': 0,
    },
    {
      'item_id': 'STOVE001',
      'name': 'Gas Stove',
      'item_type': 'NFR',
      'warehouse_id': 'WH1001',
      'available': 30,
      'reserved': 0,
      'in_transit': 0,
    },
    {
      'item_id': 'CYL14',
      'name': '14.2kg Cylinder',
      'item_type': 'Refill',
      'warehouse_id': 'WH1002',
      'available': 100,
      'reserved': 15,
      'in_transit': 0,
    },
    {
      'item_id': 'CYL19',
      'name': '19kg Commercial Cylinder',
      'item_type': 'Refill',
      'warehouse_id': 'WH1002',
      'available': 50,
      'reserved': 10,
      'in_transit': 0,
    },
    {
      'item_id': 'REG001',
      'name': 'Regulator',
      'item_type': 'NFR',
      'warehouse_id': 'WH1002',
      'available': 75,
      'reserved': 0,
      'in_transit': 0,
    },
  ];

  final List<Map<String, dynamic>> _mockWarehouses = [
    {
      'warehouse_id': 'WH1001',
      'name': 'Mumbai Central Warehouse',
      'address': '123 Industrial Area, Mumbai',
      'capacity': 500,
      'manager': 'Vikram Malhotra',
    },
    {
      'warehouse_id': 'WH1002',
      'name': 'Delhi North Warehouse',
      'address': '456 Distribution Zone, Delhi',
      'capacity': 350,
      'manager': 'Anjali Mehta',
    },
    {
      'warehouse_id': 'WH1003',
      'name': 'Bangalore East Warehouse',
      'address': '789 Supply Chain Road, Bangalore',
      'capacity': 400,
      'manager': 'Suresh Reddy',
    },
  ];

  final List<Map<String, dynamic>> _mockVehicles = [
    {
      'vehicle_id': 'V1001',
      'registration': 'MH01AB1234',
      'type': 'Delivery Truck',
      'capacity': 100,
      'driver': 'Rajesh Kumar',
      'status': 'active',
    },
    {
      'vehicle_id': 'V1002',
      'registration': 'DL02CD5678',
      'type': 'Delivery Van',
      'capacity': 50,
      'driver': 'Sanjay Verma',
      'status': 'active',
    },
    {
      'vehicle_id': 'V1003',
      'registration': 'KA03EF9012',
      'type': 'Delivery Truck',
      'capacity': 80,
      'driver': 'Mohan Das',
      'status': 'active',
    },
  ];

  List<Map<String, dynamic>> _mockInventoryRequests = [
    {
      'id': 'IR001',
      'warehouse_id': 'WH1001',
      'warehouse_name': 'Mumbai Central Warehouse',
      'requested_by': 'Rajesh Kumar',
      'role': 'CSE',
      'cylinders_14kg': 20,
      'cylinders_19kg': 10,
      'small_cylinders': 5,
      'status': 'PENDING',
      'timestamp': '2025-05-01 10:30 AM',
      'is_favorite': false,
    },
  ];

  int _inventoryRequestCounter = 4;

  @override
  Future<void> approveInventoryRequest({
    required String requestId,
    required String comment,
  }) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      final index = _mockInventoryRequests.indexWhere((r) => r['id'] == requestId);
      if (index != -1) {
        _mockInventoryRequests[index]['status'] = 'APPROVED';
        _mockInventoryRequests[index]['approval_comment'] = comment;
        _mockInventoryRequests[index]['approved_at'] = _formatTimestamp(DateTime.now());
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: 'inventory-requests/approve'),
          response: Response(
            requestOptions: RequestOptions(path: 'inventory-requests/approve'),
            statusCode: 404,
            data: {'detail': 'Request not found'},
          ),
          type: DioExceptionType.badResponse,
        );
      }
    } else {
      try {
        await _apiClient.post(
          '${_apiClient.endpoints.inventoryRequests}/approve',
          data: {
            'request_id': requestId,
            'comment': comment,
          },
        );
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<void> rejectInventoryRequest({
    required String requestId,
    required String reason,
  }) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      final index = _mockInventoryRequests.indexWhere((r) => r['id'] == requestId);
      if (index != -1) {
        _mockInventoryRequests[index]['status'] = 'REJECTED';
        _mockInventoryRequests[index]['rejection_reason'] = reason;
        _mockInventoryRequests[index]['rejected_at'] = _formatTimestamp(DateTime.now());
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: 'inventory-requests/reject'),
          response: Response(
            requestOptions: RequestOptions(path: 'inventory-requests/reject'),
            statusCode: 404,
            data: {'detail': 'Request not found'},
          ),
          type: DioExceptionType.badResponse,
        );
      }
    } else {
      try {
        await _apiClient.post(
          '${_apiClient.endpoints.inventoryRequests}/reject',
          data: {
            'request_id': requestId,
            'reason': reason,
          },
        );
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }


  @override
  Future<void> updateDashboardMockData(Map<String, dynamic> newData) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Get current token to determine user
      final tokenManager = TokenManager();
      final token = await tokenManager.getToken();

      if (token == null) {
        throw SessionExpiredException();
      }

      // Update specific mock data based on the provided data
      if (newData.containsKey('stockItems')) {
        _updateMockInventory(newData['stockItems']);
      }

      if (newData.containsKey('approvalItems')) {
        _updateMockOrders(newData['approvalItems']);
      }

      if (newData.containsKey('deliveries')) {
        _updateMockDeliveries(newData['deliveries']);
      }

      if (newData.containsKey('pendingCounts')) {
        _updatePendingCounts(newData['pendingCounts']);
      }

      if (newData.containsKey('warehouseName')) {
        _mockWarehouses[0]['name'] = newData['warehouseName'];
      }

      if (newData.containsKey('cashData')) {
        _updateCashData(newData['cashData']);
      }

      if (newData.containsKey('userData')) {
        _updateUserData(newData['userData']);
      }
    } else {
      try {
        await _apiClient.post(
          _apiClient.endpoints.dashboard,
          data: newData,
        );
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<Map<String, dynamic>> updateOrderStatus(String orderId, Map<String, dynamic> statusData) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Find the order by ID
      final index = _mockOrders.indexWhere((order) => order['order_id'] == orderId);
      if (index != -1) {
        // Update the order status
        _mockOrders[index]['status'] = statusData['status'].toLowerCase();
        return _mockOrders[index];
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: 'orders/update-status'),
          response: Response(
            requestOptions: RequestOptions(path: 'orders/update-status'),
            statusCode: 404,
            data: {'detail': 'Order not found'},
          ),
          type: DioExceptionType.badResponse,
        );
      }
    } else {
      try {
        final response = await _apiClient.post(
          '${_apiClient.endpoints.orders}/update-status',
          data: {
            'order_id': orderId,
            'status': statusData['status'],
          },
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<Map<String, dynamic>> getCashSummary() async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 700));

      return {
        "cash_in_hand": 76250,
        "last_updated": DateTime.now().toIso8601String(),
      };
    } else {
      try {
        final response = await _apiClient.get(_apiClient.endpoints.cashSummary);
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<List<dynamic>> getCashTransactions({
    String? type,
    String? status,
    int skip = 0,
    int limit = 20,
  }) async {
    if (_useMockData) {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 800));

        // Return mock transactions
        List<Map<String, dynamic>> transactions = [
          {
            "id": "TRX-1001",
            "type": "deposit",
            "amount": 15000,
            "status": "completed",
            "date": DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            "reference": "REF-1001",
            "account": "Refill Account",
            "notes": "Cash deposit for refill cylinders"
          },
          {
            "id": "TRX-1002",
            "type": "handover",
            "amount": 8500,
            "status": "pending",
            "date": DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
            "reference": "REF-1002",
            "account": "General Account",
            "notes": "Cash handover to warehouse manager"
          },
          {
            "id": "TRX-1003",
            "type": "bank",
            "amount": 25000,
            "status": "completed",
            "date": DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
            "reference": "REF-1003",
            "account": "Bank Account",
            "notes": "Transfer to bank account"
          }
        ];

        // Apply filters
        if (type != null) {
          transactions = transactions.where((t) => t["type"] == type).toList();
        }

        if (status != null) {
          transactions = transactions.where((t) => t["status"] == status).toList();
        }

        return transactions;
      } else {
      try {
        final queryParams = <String, dynamic>{
          'skip': skip,
          'limit': limit,
        };

        if (type != null) queryParams['transaction_type'] = type;
        if (status != null) queryParams['status'] = status;

        final response = await _apiClient.get(
          _apiClient.endpoints.cashTransactions,
          queryParameters: queryParams,
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        return [];
      }
    }
  }
  @override
  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> transaction) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));

      // Generate a new transaction ID
      final transactionId = "TRX-${1000 + Random().nextInt(9000)}";

      // Create the new transaction with default values where needed
      final newTransaction = {
        "id": transactionId,
        "type": transaction["type"] ?? "deposit",
        "amount": transaction["amount"] ?? 0,
        "status": transaction["status"] ?? "completed",
        "date": transaction["date"] ?? DateTime.now().toIso8601String(),
        "reference": transaction["reference"] ?? "REF-${Random().nextInt(9000) + 1000}",
        "account": transaction["account"] ?? "General Account",
        "notes": transaction["notes"] ?? ""
      };

      // Update mock cash in hand (in a real app this would be more sophisticated)
      if (MockData.cashierData.containsKey('collection')) {
        final currentCollection = int.tryParse(
            MockData.cashierData['collection']!.replaceAll('₹', '').replaceAll(',', '')
        ) ?? 0;

        if (newTransaction["type"] == "deposit") {
          MockData.cashierData['collection'] =
          '₹${currentCollection + (newTransaction["amount"] as int)}';
        }
      }

      return newTransaction;
    } else {
      try {
        final response = await _apiClient.post(
          _apiClient.endpoints.cashTransactions,
          data: transaction,
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<Map<String, dynamic>> refreshCashData() async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 600));

      return {
        "cash_in_hand": 76250,
        "last_updated": DateTime.now().toIso8601String(),
      };
    } else {
      try {
        final response = await _apiClient.put(_apiClient.endpoints.cashList);
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<Map<String, dynamic>> createCashTransaction(Map<String, dynamic> transaction) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 1000));

      final transactionId = "TRX-${1000 + Random().nextInt(9000)}";
      final newTransaction = {
        "id": transactionId,
        "type": transaction["type"] ?? "deposit",
        "amount": transaction["amount"] ?? 0,
        "status": transaction["status"] ?? "completed",
        "date": transaction["date"] ?? DateTime.now().toIso8601String(),
        "reference": transaction["reference"] ?? "REF-${Random().nextInt(9000) + 1000}",
        "account": transaction["account"] ?? "General Account",
        "notes": transaction["notes"] ?? ""
      };

      return newTransaction;
    } else {
      try {
        final response = await _apiClient.post(
          _apiClient.endpoints.cashTransactions,
          data: transaction,
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      _mockOrders.removeWhere((order) => order['order_id'] == orderId);
    } else {
      try {
        await _apiClient.delete('${_apiClient.endpoints.orders}/$orderId');
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

  @override
  Future<Map<String, dynamic>> updateOrder(String orderId, Map<String, dynamic> orderData) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));

      final index = _mockOrders.indexWhere((order) => order['order_id'] == orderId);
      if (index != -1) {
        _mockOrders[index] = {..._mockOrders[index], ...orderData};
        return _mockOrders[index];
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: 'orders/update'),
          response: Response(
            requestOptions: RequestOptions(path: 'orders/update'),
            statusCode: 404,
            data: {'detail': 'Order not found'},
          ),
          type: DioExceptionType.badResponse,
        );
      }
    } else {
      try {
        final response = await _apiClient.put(
          '${_apiClient.endpoints.orders}/$orderId',
          data: orderData,
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }
  }

// Helper methods for updating different types of mock data
  void _updateMockInventory(List<Map<String, dynamic>> stockItems) {
    for (var stockItem in stockItems) {
      final index = _mockInventory.indexWhere(
              (item) => item['item_id'] == stockItem['item_id'] &&
              item['warehouse_id'] == stockItem['warehouse_id']
      );

      if (index != -1) {
        // Update existing item
        _mockInventory[index]['available'] = stockItem['available'];
        _mockInventory[index]['reserved'] = stockItem['reserved'] ?? _mockInventory[index]['reserved'];
        _mockInventory[index]['in_transit'] = stockItem['in_transit'] ?? _mockInventory[index]['in_transit'];
      } else {
        // Add new item
        _mockInventory.add({
          'item_id': stockItem['item_id'],
          'name': stockItem['name'],
          'item_type': stockItem['item_type'],
          'warehouse_id': stockItem['warehouse_id'],
          'available': stockItem['available'],
          'reserved': stockItem['reserved'] ?? 0,
          'in_transit': stockItem['in_transit'] ?? 0,
        });
      }
    }
  }

  void _updateMockOrders(List<Map<String, dynamic>> approvalItems) {
    for (var approvalItem in approvalItems) {
      final index = _mockOrders.indexWhere(
              (order) => order['order_id'] == approvalItem['id']
      );

      if (index != -1) {
        // Update existing order
        _mockOrders[index]['status'] = approvalItem['status'].toLowerCase();

        if (approvalItem.containsKey('items')) {
          _mockOrders[index]['items'] = approvalItem['items'];
        }
      } else {
        // Add new order
        final orderType = _getOrderTypeFromApprovalType(approvalItem['type']);

        _mockOrders.add({
          'order_id': approvalItem['id'],
          'order_type': orderType,
          'status': approvalItem['status'].toLowerCase(),
          'warehouse_id': approvalItem['warehouse_id'] ?? 'WH1001',
          'created_by': approvalItem['created_by'] ?? 'system',
          'created_at': DateTime.now().toIso8601String(),
          'items': approvalItem['items'] ?? [],
          'total_amount': approvalItem['amount'] ?? 0.0,
        });
      }
    }
  }

  void _updateMockDeliveries(List<Map<String, dynamic>> deliveries) {
    // This would update mock delivery data
    // Assuming there might be a _mockDeliveries list in your real implementation
    // For this example, we'll just update orders with delivery status

    for (var delivery in deliveries) {
      final orderId = delivery['title'].toString().replaceAll(RegExp(r'[^0-9]'), '');

      final index = _mockOrders.indexWhere(
              (order) => order['order_id'].contains(orderId)
      );

      if (index != -1) {
        _mockOrders[index]['status'] = delivery['status'].toLowerCase();
        _mockOrders[index]['delivery_details'] = {
          'status': delivery['status'],
          'details': delivery['subtitle'],
        };
      }
    }
  }

  void _updatePendingCounts(Map<String, int> pendingCounts) {
    // This could update a separate tracking structure for pending counts
    // For this example, we'll just use it to update order counts

    if (pendingCounts.containsKey('collect')) {
      final collectOrders = _mockOrders.where((o) =>
      o['order_type'] == 'Refill' && o['status'] == 'approved').toList();

      // If we have fewer orders than the pending count, create more
      while (collectOrders.length < pendingCounts['collect']!) {
        _mockOrders.add({
          'order_id': 'ORD${10000 + _mockOrders.length + 1}',
          'order_type': 'Refill',
          'status': 'approved',
          'vehicle_id': 'V1001',
          'warehouse_id': 'WH1001',
          'created_by': 'delivery1',
          'created_at': DateTime.now().toIso8601String(),
          'items': [
            {
              'item_id': 'CYL14',
              'name': '14.2kg Cylinder',
              'quantity': 5 + Random().nextInt(10),
              'unit_price': 900.0,
            }
          ],
          'total_amount': 4500.0 + (Random().nextInt(10) * 900),
          'virtual_code': 'VC${10000 + _mockOrders.length + 1}',
        });
      }
    }

    if (pendingCounts.containsKey('deposit')) {
      // Similar logic for deposit orders
    }
  }

  void _updateCashData(Map<String, String> cashData) {
    // This would update whatever cash data storage you have
    // For this example, we'll just print that it was updated
    debugPrint('Updated cash data: $cashData');
  }

  void _updateUserData(Map<String, dynamic> userData) {
    final username = userData['username'] ?? '';
    final index = _mockUsers.indexWhere((user) => user['username'] == username);

    if (index != -1) {
      // Update existing user
      _mockUsers[index] = {..._mockUsers[index], ...userData};
    }
  }

  String _getOrderTypeFromApprovalType(dynamic approvalType) {
    // Convert approval type enum to order type string
    if (approvalType.toString().contains('refill')) {
      return 'Refill';
    } else if (approvalType.toString().contains('collect')) {
      return 'Refill';
    } else if (approvalType.toString().contains('deposit')) {
      return 'Deposit';
    } else if (approvalType.toString().contains('cashDeposit')) {
      return 'Cash';
    } else if (approvalType.toString().contains('nfr')) {
      return 'NFR';
    }
    return 'Other';
  }

// Helper method to format timestamp
  String _formatTimestamp(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Future<InventoryRequest> createInventoryRequestObject(InventoryRequest request) {
    // TODO: implement createInventoryRequestObject
    throw UnimplementedError();
  }

  @override
  Future getCollectionRequestById(String id) {
    // TODO: implement getCollectionRequestById
    throw UnimplementedError();
  }

  @override
  Future<List<InventoryRequest>> getInventoryRequestObjects() {
    // TODO: implement getInventoryRequestObjects
    throw UnimplementedError();
  }

  @override
  Future<InventoryRequest> updateInventoryRequestObject(String id, InventoryRequest request) {
    // TODO: implement updateInventoryRequestObject
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> submitHandover(Map<String, dynamic> data) async {
  // Simulate API delay
  await Future.delayed(Duration(milliseconds: 500));

  // Return mock response similar to your FastAPI endpoint
  return {
      'id': 'TRX-${DateTime.now().millisecondsSinceEpoch}',
      'type': 'handover',
      'amount': data['amount'],
      'status': 'pending',
      'date': DateTime.now().toIso8601String(),
      'reference': 'REF-${DateTime.now().millisecondsSinceEpoch % 10000}',
      'account': data['account_type'] ?? 'svTv',
      'notes': data['notes'] ?? '',
      'recipient': data['recipient'],
      'bank_details': data['bank_details'],
      'receipt_image_id': data['receipt_image_id'],
      };
    }

  @override
  Future<Map<String, dynamic>> approveTransaction(String transactionId) async {
    await Future.delayed(Duration(milliseconds: 500));
    return {
      'success': true,
      'message': 'Transaction approved successfully',
      'transaction': {
        'id': transactionId,
        'status': 'approved',
        'approved_at': DateTime.now().toIso8601String(),
      }
    };
  }

  @override
  Future<Map<String, dynamic>> rejectTransaction(String transactionId, Map<String, dynamic> rejectionData) async {
    await Future.delayed(Duration(milliseconds: 500));
    return {
      'success': true,
      'message': 'Transaction rejected successfully',
      'transaction': {
        'id': transactionId,
        'status': 'rejected',
        'rejected_at': DateTime.now().toIso8601String(),
        'rejection_reason': rejectionData['reason'],
      }
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getItemList() {
    // TODO: implement getItemList
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getAccountsList() {
    // TODO: implement getAccountsList
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> submitCashDeposit({required double amount, required String paidTo, String? remarks}) {
    // TODO: implement submitCashDeposit
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getBankList() {
    // TODO: implement getBankList
    throw UnimplementedError();
  }

}