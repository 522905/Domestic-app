import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lpg_distribution_app/core/services/User.dart';
import 'package:path/path.dart';
import '../models/inventory/inventory_request.dart';
import '../network/api_client.dart';
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
      final company = Map<String, dynamic>.from(resp.data['company']);

      final user = Map<String, dynamic>.from(resp.data['user']);

      await User().saveSession(
        access: access,
        refresh: refresh,
        user: user,
        company: company
      );

      await apiClient.setToken(access);
      return resp.data;
    }

    @override
    Future<List<UserCompany>> companyList() async {
      try {
          final response = await apiClient.get(
            apiClient.endpoints.companyList,
        );
        if (response.statusCode == 200) {
          final data = response.data;
          final List<dynamic> allowedCompanies = data['allowed'];
          return allowedCompanies.map((company) => UserCompany.fromJson(company)).toList();
        } else {
          throw Exception('Failed to fetch companies');
        }
      } catch (e) {
        debugPrint('Error fetching companies: $e');
        rethrow;
      }
    }

  @override
  Future<void> switchCompany(int? companyId) async {
    try {
      final refreshToken = await User().getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token found');
      }

      final response = await apiClient.post(
        apiClient.endpoints.switchCompany,
        data: {
          'refresh': refreshToken,
          'company_id': companyId,
        },
      );

      if ( response.statusCode == 200) {
        final data = response.data;

        // Update tokens with new access token (refresh stays same)
        await User().saveTokens(
          token: data['access'],
          refreshToken: refreshToken, // Keep existing refresh token
        );

        // Save company info from API response (not selectedCompany)
        await User().saveCompany(
          companyId: data['company']['id'],
          companyName: data['company']['name'],
          companyShortCode: data['company']['short_code'],
        );

        // Update API client token for future requests
        await apiClient.setToken(data['access']);
      } else {
        throw Exception('Failed to switch company: ${response?.statusMessage}');
      }
    } catch (e) {
      // Let the calling widget handle UI error display
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.logout();
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getOrdersList(
      {
        int offset = 0,
        int limit = 20,
        Map<String, String>? filters,
      }
      ) async {
    try {
      Map<String, dynamic> queryParams = {
        'offset': offset,
        'limit': limit,
        if (filters != null) ...filters,
      };

      final response = await apiClient.get(
        apiClient.endpoints.ordersData,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
            'Failed to fetch orders: ${response.statusCode}'
        );
      }
    } catch (e) {
      _handleError(e);
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final response = await apiClient.get(
        apiClient.endpoints.orderDetails(orderId),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to fetch order details: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e);
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getOrderItems({
    required String orderType,
    String? warehouseId,
  }) async {
    try {
      final queryParams = {
        'order_type': orderType,
      };

      if (warehouseId != null) {
        queryParams['warehouse_id'] = warehouseId;
      }

      final response = await apiClient.get(
        apiClient.endpoints.getOrderItems,
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> orderData) async {
    try {
      final response = await apiClient.post(
        apiClient.endpoints.orders,
        data: orderData,
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> getWarehouses({String? depositType}) async {
    try {
      final response = await apiClient.get(
          apiClient.endpoints.warehouseListApi
      );
      if (response.statusCode == 200) {
        final data = response.data;
        return data;
      }
      throw Exception('Failed to load warehouses');
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> getPartnerList() async {
    try {
      final response = await apiClient.get(
          apiClient.endpoints.partnerListApi
      );
      if (response.statusCode == 200) {
        final data = response.data;
        return data;
      }
      throw Exception('Failed to load warehouses');
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getItemList() async {
    final accessToken = await User().getToken();
    try {
      final response = await apiClient.get(
        apiClient.endpoints.inventoryItemList,
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

    @override
    Future<Map<String, dynamic>> getUnlinkedItemList() async {
      try {
        final response = await apiClient.get(
          apiClient.endpoints.unlinkedItemsList,
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }

    @override
    Future<Map<String, dynamic>> getMaterialRequestList() async {
      try {
        final response = await apiClient.get(
          apiClient.endpoints.getMaterialRequestList,
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }

    @override
    Future<Map<String, dynamic>> getPendingSaleOrderList() async {
      try {
        final response = await apiClient.get(
          apiClient.endpoints.getPendingSaleOrderList,
        );
        return response.data;
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }

  @override
  Future<Map<String, dynamic>> getPendingDeliveryItems(vehicleId ) async {
    try {
      final response = await apiClient.get(
        apiClient.endpoints.getPendingDeliveryItems,
        queryParameters: {
          'vehicle': vehicleId,
        },
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
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
  Future<Map<String, dynamic>> getPartnerAccountBalance() async {
    Map<String, dynamic> queryParams = {};
    final response = await apiClient.get(
      queryParameters: queryParams,
      apiClient.endpoints.partnerAccountBalance,
    );

    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getTransactionDetails(String transactionId) async {
    try {
      final response = await apiClient.get(
        apiClient.endpoints.transactionDetail(transactionId),
      );

      if( response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to fetch transaction details');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getCashierBalance() async {
    final response = await apiClient.get(
      apiClient.endpoints.cashierAccountBalance,
    );

    if (response.data != null) {
      return response.data;
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
    Future<Map<String, dynamic>> stockMaterialRequest() async {
      final response = await apiClient.get(
        apiClient.endpoints.stockMaterialRequestList,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'requests': response.data['data'] !=null
              ? List<Map<String, dynamic>>.from(response.data['data']["material_requests"] ?? [])
              : [],
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
        final response = await apiClient.post(
          apiClient.endpoints.paymentListApi,
          data: transactionData,
        );
        return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> refreshCashData() async {
    try {
      // Change this from PUT to GET
      final response = await apiClient.get(
          apiClient.endpoints.paymentListApi);
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> getCashTransactions() async {
    final response = await apiClient.get(
        apiClient.endpoints.paymentListApi);

    return response.data as List<dynamic>;

  }

  @override
  Future<Map<String, dynamic>> approveTransaction(
    String transactionId) async {
        final response = await apiClient.post(
          apiClient.endpoints.transactionApprove(transactionId),
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
    Future<List<InventoryRequest>> getInventoryRequests() async {
      try {
        final response = await apiClient.get(
            apiClient.endpoints.stockListApi
        );

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
  Future<InventoryRequest> getInventoryRequestDetail(String requestId) async {
    try {
      final response = await apiClient.get(
          apiClient.endpoints.stockDetailApi(requestId)
      );
      if (response.data != null) {
        return InventoryRequest.fromJson(response.data);
      }
      throw Exception('No data received');
    } catch (e) {
      _handleError(e);
      rethrow; // Important: rethrow so bloc can handle the error
    }
  }


    @override
    Future<InventoryRequest> createInventoryRequest(InventoryRequest request) async {
      try {
        Response response;
          response = await apiClient.post(
            apiClient.endpoints.inventoryRequests,
            data: request.toJson(),
          );

        // Check for HTTP status code
        if (response.statusCode == 201) {
          if (response.data is Map<String, dynamic>) {
            return InventoryRequest.fromJson(response.data);
          } else {
            throw Exception('Invalid response format');
          }
        } else {
          // Throw an exception for non-201 status codes
          throw Exception(
            'Failed to create inventory request: ${response.statusCode} - ${response.statusMessage}',
          );
        }
      } catch (e) {
        _handleError(e);
        rethrow;
      }
    }

    @override
    Future<void> approveInventoryRequest({
      required String requestId,
      required String requestType,
    }) async {
      try {
        Response response; // Declare and ensure initialization
          response = await apiClient.post(
            apiClient.endpoints.approveRequestsApi(requestId),
          );
        print("Approval response: ${response.data}");
      } catch (e) {
        print("Error approving inventory request: $e");
        _handleError(e);
        rethrow;
      }
    }

    @override
    Future<void> rejectInventoryRequest({
      required String requestId,
      required String reason,
      required String requestType,
    }) async {
      try {
        late Response response;
          response = await apiClient.post(
            apiClient.endpoints.rejectRequestsApi(requestId),
            data: {
              'reason': reason,
            },
          );
        print("Rejection response: ${response.data}");
      } catch (e) {
        print("Error rejecting inventory request: $e");
        _handleError(e);
        rethrow;
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


  @override
  Future<List<dynamic>> getVehiclesList() async {
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
  Future<dynamic> getCollectionRequestById(String id) async {
    try {
      final response = await apiClient.get(apiClient.endpoints.collectionRequestDetail(id));
      return response.data;
    } catch (e) {
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
    Future<dynamic> requestOrderApproval(String orderId) async {
      try {
        final response = await apiClient.post(
          apiClient.endpoints.autoRelease,
          data: {
            'sales_order_name': orderId,
          },
        );
        if (response.statusCode != 200) {
          throw Exception('Failed to request approval');
        }
        return response.data; // Ensure the response data is returned
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

    @override
    Future<List<dynamic>> getCashAccount() async {
      final response = await apiClient.get(
        queryParameters: {
          'exclude_managed_by_me': true,
          'account_type': 'cash',
        },
        apiClient.endpoints.cashDataAPI,
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Failed to fetch account type');
      }
    }

    @override
    Future<List<dynamic>> getBankAccount() async {
      final response = await apiClient.get(
        queryParameters: {
          'account_type': 'bank',
        },
        apiClient.endpoints.cashDataAPI,
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Failed to fetch account type');
      }
    }

    Future<List<dynamic>> getAccountType() async {
      final response = await apiClient.get(
        queryParameters: {
          'account_type': 'receivable',
        },
        apiClient.endpoints.cashDataAPI,
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Failed to fetch account type');
      }
    }

}