// lib/core/services/api_service_interface.dart
import 'dart:ffi';

import '../../data/models/sdms/sdms_transaction.dart';
import '../../domain/entities/warehouse.dart';
import '../models/inventory/inventory_request.dart';
import '../models/purchase_invoice/api_response.dart';
import '../models/purchase_invoice/driver.dart';
import '../models/purchase_invoice/purchase_invoice.dart';
import '../models/purchase_invoice/vehicle_history.dart';
import 'User.dart';

abstract class ApiServiceInterface {

  Future<void> initialize(String baseUrl);
  // Auth methods
  Future<Map<String, dynamic>> login(String username, String password);
  Future<List<UserCompany>>companyList();
  Future<void> switchCompany(
        int ? companyId,
    );

  Future<void> logout();
  Future<Map<String, dynamic>> getUserProfile();
  Future<Map<String, dynamic>> getOrderDetail(String orderId);
  // Future<Map<String, dynamic>> refreshCashData();
  Future<dynamic> requestOrderApproval(String orderId);
  Future<dynamic> requestFinalizeOrder(String orderId);

  Future<List<dynamic>> getInventory({
    String? warehouseId,
    String? itemType,
    Map<String, dynamic>? filters,
  });
  Future<Map<String, dynamic>> transferInventory(
      String sourceWarehouseId,
      String destinationWarehouseId,
      List<Map<String, dynamic>> items,
      );

  Future<Map<String, dynamic>> getPartnerAccountBalance();
  Future<Map<String, dynamic>> getCashierBalance();
  Future<Map<String, dynamic>> getAccountsList();
  Future<List<dynamic>> getCashAccount();
  Future<List<dynamic>> getBankAccount();
  Future<List<dynamic>> getAccountType();
  Future<Map<String, dynamic>> getBankList();
  Future<Map<String, dynamic>> stockMaterialRequest();


  Future<List<dynamic>> getCashTransactions();

  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> transactionData);

  // Collection/Deposit methods
  Future<Map<String, dynamic>> collectItems(
      String vehicleId,
      String warehouseId,
      List<Map<String, dynamic>> items,
      List<String>? orderIds,
      );
  Future<Map<String, dynamic>> depositItems(
      String vehicleId,
      String warehouseId,
      List<Map<String, dynamic>> items,
      List<String>? orderIds,
      List<String>? materialRequestIds,
      );

  Future<Map<String, dynamic>> getTransactionDetails(String transactionId);

  Future<List<dynamic>> getWarehouses({String depositType});

  Future<List<dynamic>> getPartnerList();

  Future<List<Map<String, dynamic>>> getItemList();
  Future<Map<String, dynamic>> getUnlinkedItemList();
  Future<Map<String, dynamic>> getMaterialRequestList();
  Future<Map<String, dynamic>> getPendingSaleOrderList();

  // Procurement/Dispatch methods
  Future<Map<String, dynamic>> getEqualERVCalculation({
    required String supplierGstin,
    required String supplierInvoiceDate,
    required String supplierInvoiceNumber,
    required String warehouse,
  });

  Future<List<dynamic>> getVehiclesList();

  Future<Map<String, dynamic>> assignVehicle(
      String vehicleId,
      String warehouseId,
      DateTime validFrom,
      DateTime validUntil,
      );

  // Gatepass methods
  Future<Map<String, dynamic>> generateGatepass(String transactionId);
  Future<Map<String, dynamic>> printGatepass(String gatepassId);

  // Document methods
  Future<String> uploadDocument(
      dynamic file, // Using dynamic here for File to avoid import issues
      String documentType,
      String? referenceId,
      );

  // Dashboard methods
  Future<Map<String, dynamic>> getDashboardData();

  // Order status methods
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData);

  Future<Map<String, dynamic>> getOrdersList({
    int offset,
    int limit,
    Map<String, String>? filters,
});

  Future<void> deleteOrder(String orderId);

  Future<void> approveInventoryRequest({
    required String requestId,
    required String requestType,
  });

// Add this to your interface
  Future<InventoryRequest> getInventoryRequestDetail(String requestId);

  Future<void> rejectInventoryRequest({
    required String requestId,
    required String reason,
    required String requestType,
  });

  Future<List<InventoryRequest>> getInventoryRequests();
  Future<InventoryRequest> createInventoryRequest(InventoryRequest request);
  Future<InventoryRequest> updateInventoryRequest(String id, InventoryRequest request);
  Future<void> toggleFavoriteRequest(String requestId, bool isFavorite);
  // Future<List<Map<String, dynamic>>> getInventoryItems({int? warehouseId, String? itemType});
  Future<List<InventoryRequest>> getInventoryRequestObjects();
  Future<InventoryRequest> createInventoryRequestObject(InventoryRequest request);
  Future<InventoryRequest> updateInventoryRequestObject(String id, InventoryRequest request);
  Future<dynamic> getCollectionRequestById(String id);
  Future<Map<String, dynamic>> submitHandover(Map<String, dynamic> data);
  Future<Map<String, dynamic>> approveTransaction(String transactionId);
  Future<Map<String, dynamic>> rejectTransaction(String transactionId, Map<String, dynamic> rejectionData);
  Future<Map<String, dynamic>>getPendingDeliveryItems(
      String vehicleId,
  );
  Future<Map<String, dynamic>> getOrderItems({
    required String orderType,
    String? warehouseId,  // Add this optional parameter
  });
  Future<Map<String, dynamic>> getOrderDetails(String orderId);
  Future<Map<String, dynamic>> initiateAadhaar(String aadhaarNumber, String phoneNumber);
  Future<Map<String, dynamic>> submitAadhaarOtp(String aadhaarNumber, String refId, String otp, String phoneNumber);
  Future<Map<String, dynamic>> initiatePartner(String panNumber);
  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword);
  Future<Map<String, dynamic>> sendOTP(Map<String, String> data);
  Future<Map<String, dynamic>> resetPassword(Map<String, String> data);
  // Add these method signatures to your existing ApiServiceInterface

  // Purchase Invoice Methods
  Future<List<PurchaseInvoice>> getPendingInvoices();
  Future<List<PurchaseInvoice>> getReceivedInvoices();
  Future<Map<String, dynamic>> getInvoiceDetails(
      String gstin,
      String invoiceDate,
      String invoiceNumber
  );
  Future<List<Map<String, dynamic>>> searchDrivers(String query);
  Future<String> uploadDriverPhoto(String filePath);
  Future<dynamic> getVehicleHistory(String vehicleNo);
  Future<Map<String, dynamic>> getDriverDetails(int driverId);
  Future<List<Map<String, dynamic>>> getAvailableItems();
  Future<ApiResponse> submitReceiveVehicle(Map<String, dynamic> payload);
  Future<ApiResponse> submitDispatchVehicle(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> updateDeviceToken(String fcmToken, String deviceId);
  Future<List<SDMSTransaction>> getSDMSTransactions({
    String? status,
    String? actionType,
    String? fromDate,
    String? toDate,
  });
  Future<SDMSTransaction> getSDMSTransactionDetail(String transactionId);
  Future<SDMSApiResponse> createInvoiceAssign(String orderId);
  Future<SDMSApiResponse> createCreditPayment(String orderId);
  Future<void> retryTask(String transactionId);
  Future<Map<String, dynamic>> checkAppVersion();
  Future<Map<String, dynamic>> getWarehouseStock({String? warehouseId});
  Future<Map<String, dynamic>> getGeneralLedger({
    required String fromDate,
    required String toDate,
    String? accountNames,
  });
  Future<Map<String, dynamic>> getAvailableAccounts();
  Future<List<int>> getVoucherPDF({
    required String voucherType,
    required String voucherNo,
  });
}