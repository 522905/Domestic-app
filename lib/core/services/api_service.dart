import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:lpg_distribution_app/core/services/token_manager.dart';

import '../../domain/entities/warehouse.dart';
import '../models/inventory_request.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'api_service_interface.dart';

class ApiService implements ApiServiceInterface {
  late String baseUrl;

  final ApiClient apiClient;

  ApiService(this.apiClient);

  @override
  Future<void> initialize(String baseUrl) async {
    this.baseUrl = baseUrl;
    await apiClient.init(baseUrl);
  }

  @override
  Future<void> updateDashboardMockData(Map<String, dynamic> newData) async {
    try {
      await apiClient.post(
        apiClient.endpoints.dashboard,
        data: newData,
      );
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    await apiClient.logout();
    final resp = await apiClient.post(
      apiClient.endpoints.login,
      data: {
        "username": username,
        "password": password,
      },
      options: Options(
        contentType: 'application/json',
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    final access = resp.data['token']['access'];
    final refresh = resp.data['token']['refresh'];

final user = Map<String, dynamic>.from(resp.data['user']);
final roles = List<String>.from(user['roles'] ?? []); // Extract roles as a list of strings

        await TokenManager().saveSession(
          access: access,
          refresh: refresh,
          user: user,
          roles: roles, // Pass the roles list instead of a single role
        );
    await apiClient.setToken(access);
    return resp.data;
  }

  @override
  Future<void> logout() async {
    try {
      // No logout endpoint in FastAPI implementation, just clear token
      await apiClient.logout();
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> orderData) async {
    try {
      final accessToken = await TokenManager().getToken();

      final userName = await TokenManager().getUserName();

      orderData['customer_name'] = userName ?? 'Unknown User';

      final response = await apiClient.post(
        apiClient.endpoints.orders,
        data: orderData,
        options: Options(
          contentType: 'application/json',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken'
          },
        ),
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> getWarehouses() async {
    try {
      final response = await apiClient.get(
          apiClient.endpoints.warehouses
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('warehouses')) {
          return (data['warehouses'] as List<dynamic>)
              .map((warehouse) => Warehouse.fromJson(warehouse))
              .toList();
        }
      }
      throw Exception('Failed to load warehouses');
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getItemList() async {
    final accessToken = await TokenManager().getToken();
    try {
      final response = await apiClient.get(
        apiClient.endpoints.itemList,
        options: Options(
          contentType: 'application/json',
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['items']);
      } else {
        throw Exception('Failed to fetch items');
      }
    } catch (e) {
      print('Error fetching items: $e');
      rethrow;
    }
  }

  // Order methods
  @override
  Future<List<dynamic>> getOrdersList() async {
    try {
      Map<String, dynamic> queryParams = {};
      final userRole = await TokenManager().getUserRole();
      if (userRole.contains('delivery-boy')) {
        final userName = await TokenManager().getUserName();
        queryParams['customer'] = userName ?? 'Unknown User';
      }

      final response = await apiClient.get(
        apiClient.endpoints.ordersList,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> &&
            response.data['sales_orders'] is List<dynamic>) {
          return response.data['sales_orders'] as List<dynamic>;
        } else {
          throw Exception('Unexpected response format: ${response.data}');
        }
      } else {
        throw Exception(
            'Failed to fetch orders: ${response.statusCode}'
        );
      }
    } catch (e) {
      _handleError(e);
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    try {
      final response = await apiClient.get(
        apiClient.endpoints.orderDetail(orderId),
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getCashSummary() async {
    Map<String, dynamic> queryParams = {};
    final userRole = await TokenManager().getUserRole();
    if (userRole.contains('delivery-boy')) {
      // final userName = await TokenManager().getUserName();
      // queryParams['customer'] = userName ?? 'Unknown User';
      queryParams['customer'] = 'Brijesh Pandey';
    }

    final response = await apiClient.get(
      queryParameters: queryParams,
      apiClient.endpoints.cashSummary,
    );

    if (response.data['success'] == true) {
      return {
        'success': true,
        'customerOverview': response.data['customer_overview'] ?? [],
      };
    } else {
      throw Exception('Failed to fetch cash summary');
    }
  }

  @override
    Future<Map<String, dynamic>> getAccountsList() async {
      final response = await apiClient.get(
        queryParameters: {
          'role': 'cashier',
        },
        apiClient.endpoints.accountsList,
      );

      if (response.statusCode == 200) {
        final accounts = response.data;
        return {
          'success': true,
          'accounts': accounts.map((account) => {'username': account['username'] ?? 'Unknown Username'}).toList(),
        };
      } else {
        return {
          'success': false,
          'accounts': [],
        };
      }
    }

  @override
  Future<Map<String, dynamic>> createTransaction(
      Map<String, dynamic> transactionData) async {
    final userRole = await TokenManager().getUserRole();
    final userName = await TokenManager().getUserName();
      if(userRole.contains('delivery-boy')){
          transactionData['customer_name'] = userName ?? 'Unknown User';
          transactionData['payment_type'] = "Receive";
          transactionData['mode_of_payment'] = "Cash ";
        } else {
          transactionData['customer_name'] = userName ?? 'Unknown User';
          transactionData['payment_type'] = "Internal Transfer";
        }
        final response = await apiClient.post(
          apiClient.endpoints.cashTransactions,
          data: transactionData,
        );
        return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> refreshCashData() async {
    try {
      // Change this from PUT to GET
      final response = await apiClient.get(
          apiClient.endpoints.cashList);
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> getCashTransactions() async {
    final response = await apiClient.get(

      apiClient.endpoints.cashList);

    return response.data as List<dynamic>;

  }

  @override
  Future<Map<String, dynamic>> approveTransaction(
    String transactionId) async {
        final response = await apiClient.post(
          apiClient.endpoints.transactionApproval(transactionId),
        );
        return response.data;
  }

  @override
  Future<Map<String, dynamic>> rejectTransaction(
      String transactionId, Map<String, dynamic> rejectionData) async {
    final response = await apiClient.post(
      apiClient.endpoints.transactionReject(transactionId),
      data: rejectionData,
    );
    return response.data;
  }

    Future<Map<String, dynamic>> getBankList() async {
      final response = await apiClient.get(
        apiClient.endpoints.bankList,
      );

      if (response.statusCode == 200) {
        return {
          'banks': response.data['banks'] ?? [],
        };
      } else {
        throw Exception('Failed to fetch bank list');
      }
    }

  // Inventory methods
  @override
  Future<List<dynamic>> getInventory({
    String? warehouseId,
    String? itemType,
    Map<String, dynamic>? filters,
  }) async {
    try {
      String endpoint = warehouseId != null
          ? '${apiClient.endpoints.inventory}/$warehouseId'  // Use inventory-items/{warehouse_id}
          : apiClient.endpoints.inventory;

      print(" Getting inventory from $endpoint");

      final response = await apiClient.get(
        endpoint,
        queryParameters: {
          if (itemType != null) 'item_type': itemType,
          if (filters != null) ...filters,
        },
      );

      print("Inventory response: ${response.data}");
      return response.data;
    } catch (e) {
      print("Error getting inventory: $e");
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> transferInventory(
      String sourceWarehouseId,
      String destinationWarehouseId,
      List<Map<String, dynamic>> items,
      ) async {
    try {
      final response = await apiClient.post(
        apiClient.endpoints.inventoryTransfer,
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

  // Collection/Deposit methods
  @override
  Future<Map<String, dynamic>> collectItems(
      String vehicleId,
      String warehouseId,
      List<Map<String, dynamic>> items,
      List<String>? orderIds,
      ) async {
    try {
      final response = await apiClient.post(
        apiClient.endpoints.collect,
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

  @override
  Future<Map<String, dynamic>> depositItems(
      String vehicleId,
      String warehouseId,
      List<Map<String, dynamic>> items,
      List<String>? orderIds,
      List<String>? materialRequestIds,
      ) async {
    try {
      final response = await apiClient.post(
        apiClient.endpoints.deposit,
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

  // Vehicle methods
  @override
  Future<List<dynamic>> getVehicles() async {
    try {
      final response = await apiClient.get(apiClient.endpoints.vehicles);
      print("RAW VEHICLES RESPONSE: ${response.data}");
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
    try {
      final response = await apiClient.post(
        apiClient.endpoints.vehicleAssignment,
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

  // User methods
  @override
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await apiClient.get(apiClient.endpoints.userProfile);
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Gatepass methods
  @override
  Future<Map<String, dynamic>> generateGatepass(String transactionId) async {
    try {
      final response = await apiClient.post(
        apiClient.endpoints.gatepass,
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

  @override
  Future<Map<String, dynamic>> printGatepass(String gatepassId) async {
    try {
      final response = await apiClient.get(
        '${apiClient.endpoints.gatepassPrint}?id=$gatepassId',
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Document methods
  @override
  Future<String> uploadDocument(
      dynamic file,
      String documentType,
      String? referenceId,
      ) async {
    try {
      final fileName = (file as File).path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'document_type': documentType,
        'reference_id': referenceId,
      });

      final response = await apiClient.post(
        apiClient.endpoints.cashHandover,
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

  // Dashboard methods
  @override
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await apiClient.get(apiClient.endpoints.dashboard);
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
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

  // Inventory request methods

  @override
  Future<dynamic> getCollectionRequestById(String id) async {
    try {
      final response = await apiClient.get(apiClient.endpoints.collectionRequestDetail(id));
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<List<InventoryRequest>> getInventoryRequests() async {
    try {
      final response = await apiClient.get(apiClient.endpoints.inventoryRequests);

      if (response.data is List) {
        return (response.data as List)
            .map((json) => InventoryRequest.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      _handleError(e);
      return [];
    }
  }

  @override
  Future<InventoryRequest> createInventoryRequest(InventoryRequest request) async {
    try {
      final response = await apiClient.post(
        apiClient.endpoints.inventoryRequests,
        data: request.toJson(),
      );
      return InventoryRequest.fromJson(response.data);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<InventoryRequest> updateInventoryRequest(String id, InventoryRequest request) async {
    try {
      final response = await apiClient.put(
        '${apiClient.endpoints.inventoryRequests}/$id',
        data: request.toJson(),
      );
      return InventoryRequest.fromJson(response.data);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<void> toggleFavoriteRequest(String requestId, bool isFavorite) async {
    try {
      await apiClient.patch(
        '${apiClient.endpoints.inventoryRequests}/$requestId/favorite',
        data: {'is_favorite': isFavorite},
      );
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getInventoryItems({
    int? warehouseId,
    String? itemType,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};

      if (warehouseId != null) {
        queryParams['warehouse_id'] = warehouseId;
      }
      if (itemType != null) {
        queryParams['item_type'] = itemType;
      }

      final response = await apiClient.get(
        '/api/inventory-items/',
        queryParameters: queryParams,
      );

      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      _handleError(e);
      return [];
    }
  }

  @override
  Future<void> approveInventoryRequest({required String requestId, required String comment}) async {
    try {
      print("Approving inventory request: $requestId with comment: $comment");

      final response = await apiClient.post(
        '/api/inventory-requests/$requestId/approve', // Use direct endpoint
        data: {
          'comment': comment,
          'approved_by': 'Manager', // You can get this from user context
        },
      );

      print("Approval response: ${response.data}");
    } catch (e) {
      print("Error approving inventory request: $e");
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<void> rejectInventoryRequest({required String requestId, required String reason}) async {
    try {
      print("Rejecting inventory request: $requestId with reason: $reason");

      final response = await apiClient.post(
        '/api/inventory-requests/$requestId/reject', // Use direct endpoint
        data: {
          'reason': reason,
          'rejected_by': 'Manager', // You can get this from user context
        },
      );

      print("Rejection response: ${response.data}");
    } catch (e) {
      print("Error rejecting inventory request: $e");
      _handleError(e);
      rethrow;
    }
  }


// Add method to get inventory requests as InventoryRequest objects
  Future<List<InventoryRequest>> getInventoryRequestObjects() async {
    try {
      final response = await apiClient.get(
        '/api/inventory-requests',
        queryParameters: {
          'skip': 0,
          'limit': 100,
        },
      );

      print("Raw inventory requests response: ${response.data}");

      final List<dynamic> data = response.data;
      return data.map((json) => InventoryRequest.fromJson(json)).toList();
    } catch (e) {
      print("Error getting inventory request objects: $e");
      _handleError(e);
      return [];
    }
  }

// Add method to create inventory request from InventoryRequest object
  Future<InventoryRequest> createInventoryRequestObject(InventoryRequest request) async {
    try {
      print("Creating inventory request object: ${request.toJson()}");

      final response = await apiClient.post(
        '/api/inventory-requests',
        data: request.toJson(),
      );

      print("Create response: ${response.data}");
      return InventoryRequest.fromJson(response.data);
    } catch (e) {
      print("Error creating inventory request object: $e");
      _handleError(e);
      rethrow;
    }
  }


  @override
  Future<void> deleteOrder(String orderId) async {
    try {
      await apiClient.delete('${apiClient.endpoints.orders}/$orderId');
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // In ApiService.dart
  @override
  Future<Map<String, dynamic>> updateOrderStatus(String orderId, Map<String, dynamic> statusData) async {
    try {
      final response = await apiClient.put(
        '${apiClient.endpoints.orders}/$orderId/status',
        data: statusData,
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<void> requestOrderApproval(String orderId) async {
    try {
      final response = await apiClient.post(
        '${apiClient.endpoints.orders}$orderId/approve',
        data: {},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to request approval');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<InventoryRequest> updateInventoryRequestObject(String id, InventoryRequest request) {
    // TODO: implement updateInventoryRequestObject
    throw UnimplementedError();
  }

  // Add this to your ApiServiceInterface and ApiService implementation
  @override
  Future<Map<String, dynamic>> submitHandover(Map<String, dynamic> data) async {
    final response = await apiClient.post(
      apiClient.endpoints.cashHandover,
      data: data,
    );
    return response.data;
  }

}