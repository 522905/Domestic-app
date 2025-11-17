import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lpg_distribution_app/core/services/User.dart';
import '../../data/models/sdms/sdms_transaction.dart';
import 'package:lpg_distribution_app/core/services/version_manager.dart';
import '../../utils/error_handler.dart';
import '../models/inventory/inventory_request.dart';
import '../models/purchase_invoice/api_response.dart';
import '../models/purchase_invoice/purchase_invoice.dart';
import '../network/api_client.dart';
import 'api_service_interface.dart';
import '../models/api_validation_exception.dart';

class ApiService implements ApiServiceInterface {
  late String baseUrl;

  final ApiClient apiClient;

  ApiService(this.apiClient);

  @override
  Future<void> initialize(String baseUrl) async {
    this.baseUrl = baseUrl;
    await apiClient.init(baseUrl);
  }

  void _handleError(dynamic error) {
    if (error is DioException) {
      if (error.error is SessionExpiredException) {
        debugPrint('SESSION EXPIRED: ${error.message}');
      } else if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        debugPrint('NETWORK ERROR: ${error.message}');
      } else if (error.response != null) {
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (statusCode == 426) {
          Map<String, dynamic>? payload;
          if (data is Map<String, dynamic>) {
            payload = Map<String, dynamic>.from(data);
          } else if (data is String && data.isNotEmpty) {
            try {
              final decoded = jsonDecode(data);
              if (decoded is Map<String, dynamic>) {
                payload = decoded;
              }
            } catch (_) {
              // ignore parsing failures and continue with a null payload
            }
          }

          final versionManager = VersionManager();
          final updateStatus = versionManager.createBlockedStatusFromResponse(payload);
          versionManager.setCurrentStatus(updateStatus, rawPayload: payload);

          throw UpdateRequiredException(updateStatus);
        }

        debugPrint('SERVER ERROR [$statusCode]: $data');

        if (data is Map<String, dynamic> &&
            data.containsKey('validation_details') &&
            data['validation_details'] is Map<String, dynamic>) {

          final validationDetails = data['validation_details'] as Map<String, dynamic>;

          if (validationDetails.containsKey('errors') &&
              validationDetails['errors'] is List) {

            final errorsList = validationDetails['errors'] as List;

            if (errorsList.isNotEmpty) {
              final validationErrors = errorsList.map((errorItem) {
                return ValidationError(
                  message: errorItem['message']?.toString() ?? 'Unknown error',
                  code: errorItem['code']?.toString() ?? 'UNKNOWN',
                );
              }).toList();

              // Extract balance_info if available
              Map<String, dynamic>? balanceInfo;
              if (validationDetails.containsKey('balance_info')) {
                balanceInfo = Map<String, dynamic>.from(validationDetails['balance_info']);
              }

              throw ApiValidationException(
                title: data['error']?.toString() ?? 'Validation Failed',
                errors: validationErrors,
                balanceInfo: balanceInfo,
              );
            }
          }
        }
      } else {
        debugPrint('UNKNOWN ERROR: ${error.message}');
      }
    } else {
      debugPrint('UNEXPECTED ERROR: $error');
    }

    final formattedError = ErrorHandler.handleError(error);
    throw Exception(formattedError);
  }

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
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
        company: company,
        novu: resp.data['novu'],
      );

      // Check roles immediately after saving session
      final userRoles = await User().getUserRoles();
      if (userRoles.isEmpty) {
        // Clear the session since roles are invalid
        // await User().clearTokens();
        throw Exception('No user roles assigned. Please contact administrator.');
      }

      await apiClient.setToken(access);
      return resp.data;
    } catch (e) {
      _handleError(e);
      rethrow; // This will never be reached but keeps the signature consistent
    }
  }

  // FIXED: Changed to throw error instead of returning empty map
  @override
  Future<Map<String, dynamic>> getOrdersList({
    int offset = 0,
    int limit = 20,
    Map<String, String>? filters,
  }) async {
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
        throw Exception('Failed to fetch orders: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e);
      rethrow; // Important: Let the UI handle the formatted error
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
      rethrow; // Changed from returning empty map
    }
  }

  // FIXED: Changed to throw error instead of returning empty list
  @override
  Future<List<dynamic>> getInventory({
    String? warehouseId,
    String? itemType,
    Map<String, dynamic>? filters,
  }) async {
    try {
      String endpoint = warehouseId != null
          ? '${apiClient.endpoints.inventory}/$warehouseId'
          : apiClient.endpoints.inventory;

      print("Getting inventory from $endpoint");

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
      _handleError(e);
      rethrow; // Changed from returning empty list
    }
  }

  // FIXED: Changed to throw error instead of returning empty list
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
      throw Exception('Invalid response format for inventory requests');
    } catch (e) {
      _handleError(e);
      rethrow; // Changed from returning empty list
    }
  }

  // FIXED: Enhanced error handling for create operations
  @override
  Future<InventoryRequest> createInventoryRequest(InventoryRequest request) async {
    try {
      final response = await apiClient.post(
        apiClient.endpoints.inventoryRequests,
        data: request.toJson(),
      );

      // Check for HTTP status code
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return InventoryRequest.fromJson(response.data);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        // Extract error message from response for 400 errors
        if (response.statusCode == 400 && response.data != null) {
          final errorMsg = ErrorHandler.handleError(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
              )
          );
          throw Exception(errorMsg);
        }
        throw Exception(
          'Failed to create inventory request: ${response.statusCode} - ${response.statusMessage}',
        );
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // FIXED: Better error handling for transaction creation
  @override
  Future<Map<String, dynamic>> createTransaction(
      Map<String, dynamic> transactionData) async {
    try {
      final response = await apiClient.post(
        apiClient.endpoints.paymentListApi,
        data: transactionData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create transaction: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // FIXED: Better error handling for submit operations
  @override
  Future<ApiResponse> submitDispatchVehicle(Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.post(
        apiClient.endpoints.submitDispatch,
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: response.data['message'] ?? 'Vehicle dispatched successfully',
          data: response.data,
        );
      } else {
        // For 400 errors, extract validation messages
        if (response.statusCode == 400 && response.data != null) {
          final errorMsg = ErrorHandler.handleError(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
              )
          );
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: 'Validation Error',
            error: errorMsg,
          );
        }

        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to dispatch vehicle',
          error: response.data['error'] ?? 'Unknown error',
        );
      }
    } on DioException catch (e) {
      // Use ErrorHandler for DioExceptions
      final errorMsg = ErrorHandler.handleError(e);
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Request Failed',
        error: errorMsg,
      );
    } catch (e) {
      _handleError(e);
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Unexpected error occurred',
        error: e.toString(),
      );
    }
  }

      @override
      Future<Map<String, dynamic>> initiateAadhaar(String aadhaarNumber, String phoneNumber) async {
        final response = await apiClient.post(
          apiClient.endpoints.initiateAadhaar,
          data: {
            'aadhaar_number': aadhaarNumber,
            'phone_number': phoneNumber,
          },
        );
        return response.data;
      }

      @override
      Future<Map<String, dynamic>> submitAadhaarOtp(String aadhaarNumber, String refId, String otp, String phoneNumber) async {
        final response = await apiClient.post(
          apiClient.endpoints.submitAadhaarOtp,
          data: {
            'aadhaar_number': aadhaarNumber,
            'ref_id': refId,
            'otp': otp,
            'phone_number': phoneNumber,
          },
        );
        return response.data;
      }

      @override
      Future<Map<String, dynamic>> initiatePartner(String panNumber) async {
        final response = await apiClient.post(
          apiClient.endpoints.initiatePartner, // Add this endpoint
          data: {
            'pan_number': panNumber,
          },
        );
        return response.data;
      }

      @override
      Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
          final response = await apiClient.post(
            apiClient.endpoints.changePassword, // Add this endpoint
            data: {
              'old_password': oldPassword,
              'new_password': newPassword,
            },
          );
          return response.data;
        }

    @override
    Future<Map<String, dynamic>> sendOTP(Map<String, String> data) async {
      final response = await apiClient.post(
        apiClient.endpoints.sendOTP, // Add this endpoint
        data: {
          'username': data['aadhar_number'],
        },
      );
      return response.data;
    }

    @override
    Future<Map<String, dynamic>> resetPassword(Map<String, String> data) async {
      final response = await apiClient.post(
        apiClient.endpoints.resetPassword, // Add this endpoint
        data: {
          'username': data['aadhar_number'],
          'otp': data['otp'],
          'new_password': data['new_password'],
        },
      );
      return response.data;
    }

    @override
     Future<Map<String, dynamic>> checkAppVersion() async {
    final user = User();
    final token = await user.getToken();

    final response = await apiClient.get(
      apiClient.endpoints.appConfig,
      options: Options(
        headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          // Token will be added automatically by your apiClient if available
        },
      ),
    );
    return response.data;
  }

    @override
    Future<Map<String, dynamic>> getGeneralLedger({
      required String fromDate,
      required String toDate,
      String? accountNames,
    }) async {
      final params = <String, String>{
        'from_date': fromDate,
        'to_date': toDate,
      };

      if (accountNames != null && accountNames.isNotEmpty) {
        params['account_names'] = accountNames;
      }

      final response = await apiClient.get(
        apiClient.endpoints.ledgerData,
        queryParameters: params,
      );

      return response.data;
    }

  @override
  Future<Map<String, dynamic>> getAvailableAccounts() async {
    final response = await apiClient.get(
      apiClient.endpoints.availableAccounts,
    );

    return response.data;
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
  Future<Map<String, dynamic>> getWarehouseStock({String? warehouseId}) async {

    final response = await apiClient.get(
      apiClient.endpoints.warehouseStock,
      queryParameters: {
        'warehouse_id': warehouseId,
      },
    );

    return response.data;
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
          sdmsUserCode: data['company']['sdms_user_code'],
        );

        // After saving company info, add this if novu exists in response
        if (data.containsKey('novu') && data['novu'] != null) {
          await User().saveNovu(
            applicationIdentifier: data['novu']['applicationIdentifier'] ?? '',
            subscriberId: data['novu']['subscriberId'] ?? '',
            subscriberHash: data['novu']['subscriberHash'],
          );
        }

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

  // @override
  // Future<Map<String, dynamic>> createOrder(
  //     Map<String, dynamic> orderData) async {
  //   try {
  //     final response = await apiClient.post(
  //       apiClient.endpoints.orders,
  //       data: orderData,
  //     );
  //     return response.data;
  //   } catch (e) {
  //     _handleError(e);
  //     rethrow;
  //   }
  // }

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
  Future<List<int>> getVoucherPDF({
    required String voucherType,
    required String voucherNo,
  }) async {
    try {
      print('Fetching PDF: $voucherType - $voucherNo');

      final response = await apiClient.get(
        apiClient.endpoints.voucherPDF(voucherType, voucherNo),
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) {
            return status != null && status < 500; // Accept all responses < 500
          },
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        // Check if response is actually bytes
        if (response.data is List<int>) {
          return response.data as List<int>;
        } else if (response.data is String) {
          // Server returned text/HTML instead of PDF
          throw Exception('Server returned error: ${response.data}');
        } else {
          throw Exception('Invalid response format: ${response.data.runtimeType}');
        }
      } else if (response.statusCode == 404) {
        throw Exception('PDF not available for this voucher');
      } else {
        // Try to extract error message from response
        String errorMsg = 'Failed to load PDF: ${response.statusCode}';
        if (response.data is String) {
          errorMsg += '\n${response.data}';
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('PDF fetch error: $e');
      if (e is DioException) {
        if (e.response?.data is String) {
          throw Exception('Server error: ${e.response?.data}');
        }
        throw Exception('Network error: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> updateDeviceToken(String fcmToken, String deviceId) async {
    try {
      final response = await apiClient.post(
        apiClient.endpoints.updateDeviceToken,
        data: {
          'platform': 'fcm',
          'token': fcmToken,
          'device_id': deviceId,
        },
      );
       return response.data;
    } catch (e) {
      print('Error updating device token: $e');
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
    Future<Map<String, dynamic>> getEqualERVCalculation({
      required String supplierGstin,
      required String supplierInvoiceDate,
      required String supplierInvoiceNumber,
      required String warehouse,
    }) async {
      try {
        final response = await apiClient.get(
          '/procurement/equal-erv-calculation/',
          queryParameters: {
            'supplier_gstin': supplierGstin,
            'supplier_invoice_date': supplierInvoiceDate,
            'supplier_invoice_number': supplierInvoiceNumber,
            'warehouse': warehouse,
          },
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
    Future<dynamic> requestFinalizeOrder(String orderId) async {
      try {
        final response = await apiClient.post(
          apiClient.endpoints.finalizeOrder,
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
    Future<dynamic> cancelOrder(String orderId) async {
      try {
        final response = await apiClient.post(
          apiClient.endpoints.cancelOrder(orderId),
        );
        if (response.statusCode != 200) {
          throw Exception('Failed to cancel order');
        }
        return response.data;
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

  // Purchase Invoice Methods
  @override
  Future<List<PurchaseInvoice>> getPendingInvoices() async {
    try {
      final response = await apiClient.get(
        apiClient.endpoints.pendingInvoices,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PurchaseInvoice.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch pending invoices: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<List<PurchaseInvoice>> getReceivedInvoices() async {
    try {
      final response = await apiClient.get(
        apiClient.endpoints.receivedInvoices,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PurchaseInvoice.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch received invoices: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getInvoiceDetails(
    String gstin,
    String invoiceDate,
    String invoiceNumber
    ) async {
    try {
      final response = await apiClient.get(
        apiClient.endpoints.purchaseInvoiceDetails(gstin, invoiceDate, invoiceNumber),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to fetch invoice details: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchDrivers(String query) async {
    try {
      final response = await apiClient.get(
        apiClient.endpoints.searchDrivers,
        queryParameters: {
          'q': query,
        },
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else if (response.data['results'] != null) {
          return List<Map<String, dynamic>>.from(response.data['results']);
        }
        return [];
      }
     else {
        throw Exception('Failed to search drivers: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }


  @override
  Future<String> uploadDriverPhoto(String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await apiClient.post(
        apiClient.endpoints.uploadDriverPhoto,
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['url'] ?? '';
      } else {
        throw Exception('Failed to upload photo: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // In your API implementation
  @override
  Future<dynamic> getVehicleHistory(String vehicleNo) async {
    try {
      final response = await apiClient.get(
        apiClient.endpoints.vehicleHistory(vehicleNo),
      );

      if (response.statusCode == 200) {
        return response.data; // Return raw response
      } else {
        throw Exception('Failed to fetch vehicle history: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getDriverDetails(int driverId) async {
    try {
      final response = await apiClient.get(
        apiClient.endpoints.driverDetials(driverId),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to fetch driver profile: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableItems() async {
    try {
      final response = await apiClient.get(
        apiClient.endpoints.receivedAPI,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to fetch available items: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<ApiResponse> submitReceiveVehicle(Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.post(
        apiClient.endpoints.receivedAPI,
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: response.data['message'] ?? 'Vehicle received successfully',
          data: response.data,
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.data['message'] ?? 'Failed to receive vehicle',
          error: response.data['error'] ?? 'Unknown error',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        return ApiResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to receive vehicle',
          error: errorData['error'] ?? e.message ?? 'Network error',
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Network error occurred',
          error: e.message ?? 'Connection failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected error occurred',
        error: e.toString(),
      );
    }
  }

  @override
  Future<List<SDMSTransaction>> getSDMSTransactions({
    String? status,
    String? actionType,
    String? fromDate,
    String? toDate,
  }) async {
    Map<String, dynamic> queryParams = {};

    if (status != null && status.isNotEmpty) {
      queryParams['process_status'] = status;
    }
    if (actionType != null && actionType.isNotEmpty) {
      queryParams['action_type'] = actionType;
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams['created_at__date__gte'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      queryParams['created_at__date__lte'] = toDate;
    }

    final response = await apiClient.get(
      apiClient.endpoints.sdmsTransactions,
      queryParameters: queryParams,
    );

    final List<dynamic> data = response.data;
    return data.map((json) => SDMSTransaction.fromJson(json)).toList();
  }

  @override
  Future<SDMSTransaction> getSDMSTransactionDetail(String transactionId) async {
    final response = await apiClient.get(
      apiClient.endpoints.sdmsTransactionDetail(transactionId),
    );
    return SDMSTransaction.fromJson(response.data);
  }

  @override
  Future<SDMSApiResponse> createInvoiceAssign(String orderId) async {
    final response = await apiClient.post(
      apiClient.endpoints.sdmsInvoiceAssign,
      data: {'order_id': orderId},
    );
    return SDMSApiResponse.fromJson(response.data);
  }

  @override
  Future<SDMSApiResponse> createCreditPayment(String orderId) async {
    final response = await apiClient.post(
      apiClient.endpoints.sdmsCreditPayment,
      data: {'order_id': orderId},
    );
    return SDMSApiResponse.fromJson(response.data);
  }

  @override
  Future<void> retryTask(String transactionId) async {
    await apiClient.post(
      apiClient.endpoints.sdmsRetryTask(transactionId),
    );
  }

  // @override
  Future<Map<String, dynamic>> getERVCalculation({
    required String supplierGstin,
    required String supplierInvoiceDate,
    required String supplierInvoiceNumber,
    required String warehouse,
    String mode = 'equal',
  }) async {
    try {
      final queryParams = {
        'supplier_gstin': supplierGstin,
        'supplier_invoice_date': supplierInvoiceDate,
        'supplier_invoice_number': supplierInvoiceNumber,
        'warehouse': warehouse,
        'mode': mode,
      };

      final response = await apiClient.get(
        apiClient.endpoints.ervCalculation,
        queryParameters: queryParams,
      );

      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

}