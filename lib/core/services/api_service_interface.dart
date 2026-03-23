// lib/core/services/api_service_interface.dart
// import 'dart:ffi';  // Unused
// import 'dart:io';  // Unused

import '../../data/models/sdms/sdms_transaction.dart';
// import '../../domain/entities/warehouse.dart';  // Unused
import '../../domain/entities/quota/quota_snapshot.dart';
import '../../domain/entities/credit_extension/credit_extension_context.dart';
import '../models/inventory/inventory_request.dart';
import '../models/purchase_invoice/api_response.dart';
// import '../models/purchase_invoice/driver.dart';  // Unused
import '../models/purchase_invoice/purchase_invoice.dart';
// import '../models/purchase_invoice/vehicle_history.dart';  // Unused
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
  Future<dynamic> cancelOrder(String orderId);

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
  Future<List<int>> thermalPrintStockRequest(
    String requestId,
    String formatType,
    String deviceIdentifier,
    int paperWidthMm,
  );
  Future<List<int>> thermalPrintPaymentRequest(
    String transactionId,
    String deviceIdentifier,
    int paperWidthMm,
  );
  Future<List<int>> thermalPrintOfflineDeliveryToken(
    String tokenId,
    String deviceIdentifier,
    int paperWidthMm,
  );
  Future<List<int>> thermalPrintBookingVerification(
    String verificationId,
    String deviceIdentifier,
    int paperWidthMm,
  );

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

  Future<InventoryRequest> cancelInventoryRequest(String requestId);

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

  // Digital Credit methods
  Future<Map<String, dynamic>> getDigitalCredits({
    String? dataStatus,
    String? claimStatus,
    String? fromDate,
    String? toDate,
    bool? isMine,
  });
  Future<Map<String, dynamic>> createDigitalCredit({
    required String orderId,
    required String orderDate,
    bool autoClaim = false,
  });
  Future<Map<String, dynamic>> getDigitalCreditDetail(String id);
  Future<Map<String, dynamic>> claimDigitalCredit(String id);
  Future<Map<String, dynamic>> retryDigitalCredit(String id);
  Future<Map<String, dynamic>> switchCreditCompany(String id, int targetCompanyId);
  Future<Map<String, dynamic>> getClaimTransfers();
  Future<Map<String, dynamic>> approveClaimTransfer(String id);
  Future<Map<String, dynamic>> rejectClaimTransfer(String id, {String? reason});

  // SDMS Claims methods (Draft v3)
  // Hot fix 2026-02-12: Added isBeneficiary filter parameter
  Future<Map<String, dynamic>> getSdmsOrders({
    String tab = 'active',
    int page = 1,
    String? search,
    bool? isBeneficiary,
  });

  // Backwards compatibility - filter methods for unclaimed browse
  Future<Map<String, dynamic>> getSdmsClaimsOrders({
    String? orderCategory,
    String? dataStatus,
    String? claimStatus,
    String? settlementStatus,
    String? source,
    String? fromDate,
    String? toDate,
    bool? isMine,
  });

  Future<Map<String, dynamic>> getSdmsClaimsOrderDetail(String id);
  Future<Map<String, dynamic>> createSdmsClaimsOrder({
    required String orderId,
    bool claimForSelf = true,
    int? intendedPartner,
    String? consumerNumber,
  });
  Future<Map<String, dynamic>> claimSdmsOrder(String id);
  Future<Map<String, dynamic>> retrySdmsOrder(String id);
  Future<Map<String, dynamic>> switchOrderCompany(String id, int companyId);

  // Draft v3: Order-level transfer actions
  Future<Map<String, dynamic>> approveOrderTransfer(String orderId);
  Future<Map<String, dynamic>> rejectOrderTransfer(String orderId, {String? reason});

  Future<Map<String, dynamic>> getPartners({String? search});

  // Quota methods
  Future<QuotaSnapshot> getQuotaSnapshot();
  Future<Map<String, dynamic>> triggerQuotaSync();
  Future<Map<String, dynamic>> getQuotaDashboard();
  Future<Map<String, dynamic>> getQuotaHistory({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? itemCode,
    String sort = '-entry_date',
    int page = 1,
    int pageSize = 30,
  });
  Future<Map<String, dynamic>> getQuotaHistoryDetail({
    required DateTime entryDate,
    required String itemCode,
  });

  // Bonus methods
  Future<List<dynamic>> getBonusSchemes({bool includeInactive = false});
  Future<Map<String, dynamic>> getBonuses({
    String status = 'all',
    String? itemCode,
    String? scheme,
    String sort = '-earned_date',
    int page = 1,
    int pageSize = 20,
  });
  Future<Map<String, dynamic>> getBonusDetail(int id);

  // Credit Extension methods - Partner
  Future<Map<String, dynamic>> createCreditExtension({
    required String itemCode,
    required int requestedQuantity,
    required String justification,
    String? audioPath,  // Optional audio file path
  });

  Future<Map<String, dynamic>> getCreditExtensions({
    String? status,
    int page = 1,
    int pageSize = 20,
  });

  Future<Map<String, dynamic>> getCreditExtensionDetail(int id);
  Future<Map<String, dynamic>> getActiveCreditExtensions();

  // Credit Extension methods - GM
  Future<Map<String, dynamic>> getPendingCreditExtensions({
    int? partnerId,
    String? itemCode,
  });

  Future<Map<String, dynamic>> approveCreditExtension({
    required int extensionId,
    required int approvedQuantity,
    DateTime? validUntil,
  });

  Future<Map<String, dynamic>> rejectCreditExtension({
    required int extensionId,
    required String rejectionReason,
  });

  Future<CreditExtensionContext> getCreditExtensionContext(int id);

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

  // ERV Calculation Method
  Future<Map<String, dynamic>> getERVCalculation({
    required String supplierGstin,
    required String supplierInvoiceDate,
    required String supplierInvoiceNumber,
    required String warehouse,
    String mode = 'equal',
  });

  // Ujjwala Installation methods
  Future<List<dynamic>> getPendingUjjwalaInstallations();
  Future<List<dynamic>> searchUjjwalaInstallations(String query);
  Future<Map<String, dynamic>> submitUjjwalaInstallation({
    required int installationId,
    required String kitchenPhotoUrl,
    required String gatePhotoUrl,
    required String stovePhotoUrl,
    required double latitude,
    required double longitude,
    required double accuracy,
  });

  Future<List<dynamic>> getUjjwalaServiceAreas();

  Future<List<dynamic>> getUjjwalaInstallationHistory(int installationId);

  Future<List<dynamic>> getMyUjjwalaUploads({String? status});

  // LPG Ops Backend Ujjwala methods
  Future<Map<String, dynamic>> getUjjwalaApplicationDetail(int disbursementId);
  Future<Map<String, dynamic>> submitUjjwalaInstallationV2({
    required int disbursementId,
    required String kitchenPhotoUrl,
    required String gatePhotoUrl,
    required String stovePhotoUrl,
    required String latitude,
    required String longitude,
    required String accuracy,
  });
  Future<List<dynamic>> getLpgOpsInstallations({String scope = 'mine', String? status, bool? reimbursed});
  Future<Map<String, dynamic>> bulkVerifyInstallations(List<int> installationIds);
  Future<Map<String, dynamic>> retryFailedInstallations(List<int> installationIds);
  Future<Map<String, dynamic>> getReimbursementPreview(int warehouseId);
  Future<Map<String, dynamic>> createReimbursement({required int warehouseId, required int qty});
  Future<List<dynamic>> getReimbursementBatches();

  // Offline Delivery methods
  Future<Map<String, dynamic>> getOfflineDeliveryStatus();
  Future<List<dynamic>> getOfflineDeliveryDistributionPoints();
  Future<Map<String, dynamic>> getOfflineDeliveryTokensPaginated({String? distributionPointId, String? date, String? status, String? search});
  Future<Map<String, dynamic>> getOfflineDeliveryVerificationsPaginated({String? distributionPointId, String? date, String? status, String? search, bool? showAll});
  Future<Map<String, dynamic>> getOfflineDeliveryNextPage(String nextUrl);
  Future<Map<String, dynamic>> getOfflineDeliveryTokenDetail(String tokenId);
  Future<Map<String, dynamic>> createOfflineDeliveryToken(Map<String, dynamic> data);
  Future<Map<String, dynamic>> deliverOfflineDeliveryToken(String tokenId, Map<String, dynamic> data);
  Future<Map<String, dynamic>> correctOfflineDeliveryToken(String tokenId, Map<String, dynamic> data);
  Future<Map<String, dynamic>> attachOfflineDeliveryTokenImages(String tokenId, Map<String, dynamic> data);
  Future<Map<String, dynamic>> quickDeliverOfflineDelivery(Map<String, dynamic> data);
  Future<Map<String, dynamic>> createBookingVerification(Map<String, dynamic> data);
  Future<Map<String, dynamic>> retryBookingVerification(String verificationId);
  Future<List<dynamic>> getOfflineDeliveryCompanies();
}