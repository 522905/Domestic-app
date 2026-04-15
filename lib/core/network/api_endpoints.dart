// import 'package:dio/dio.dart';  // Unused

class ApiEndpoints {
  final String baseUrl;

  final String tempUrl = 'https://lpg.ops.arungas.com';
  // final String tempUrl = 'http://192.168.171.132:9900';

  ApiEndpoints(this.baseUrl);
  // Dashboard endpoints
  String get dashboard => '$baseUrl/api/dashboard';
  String get pendingCounts => '$baseUrl/api/dashboard/pending-counts';
  String dashboardRoleData(String role, String tab) => '$baseUrl/api/dashboard/$role/$tab';
  String get inventory => '$baseUrl/api/inventory-items';
  String get inventoryItemList => '$tempUrl/api/orders/items/';
  String get inventoryList => '$tempUrl/api/stocks/stock-list/';
  String get inventoryRequests => '$tempUrl/api/stocks/stock-requests/';
  String get stockMaterialRequestList => '$tempUrl/api/stocks/stock-material-request-list/';
  // Order endpoints
  String orderDetail(String id) => '$baseUrl/api/orders/$id';
  String get orderApproval => '$baseUrl/api/approvals/{order_id}/approve';
  String get orderReject => '$baseUrl/api/approvals/{order_id}/reject';
  String get autoRelease => '$tempUrl/api/orders/auto-release-sales-order/';
  String get finalizeOrder => '$tempUrl/api/orders/finalize-sales-order/';
  String cancelOrder(String orderId) => '$tempUrl/api/orders/sales-orders/$orderId/cancel/';
  String get accountsList => '$tempUrl/api/users/users-list/';
  String get vehicles => '$tempUrl/api/users/api/masters/vehicles/';

  String get cashList => '$tempUrl/api/payments/list/';

  String get bankList => '$tempUrl/api/payments/bank-list/';
  String get cashHandover => '$baseUrl/api/cash/handover';

  // Inventory endpoints
  String inventoryByWarehouse(String warehouseId) =>
      '$baseUrl/api/inventory/?warehouse_id=$warehouseId';
  String get inventoryTransfer => '$baseUrl/api/inventory/transfer';

  // Collection/Deposit endpoints (placeholders)
  String get collect => '$baseUrl/api/transactions/collect';
  String get deposit => '$baseUrl/api/transactions/deposit';
  String get vehicleAssignment => '$baseUrl/api/vehicles/assign';

  // User endpoints
  String get userProfile => '$baseUrl/api/users/me';

  // Gate-pass endpoints
  String get gatepass => '$baseUrl/api/gatepass/';
  String get gatepassPrint => '$baseUrl/api/gatepass/print';
  String thermalPrintStockRequest(String requestId) => '$tempUrl/api/thermal-printing/stock-requests/$requestId/thermal-print/';
  String thermalPrintPaymentRequest(String transactionId) => '$tempUrl/api/thermal-printing/payment-requests/$transactionId/thermal-print/';

  // Collection request endpoints0
  String get collectionRequests => '$baseUrl/api/inventory-requests/';
// Add these to your ApiEndpoints class
  String collectionRequestDetail(String id) => '$baseUrl/api/inventory-requests/$id';
  String get toggleFavoriteRequest => '$baseUrl/api/inventory-requests/favorite';
  static const String testToken = '/api/direct-test-token';

  //USER API'S
  String get cashDataAPI => '$tempUrl/api/users/api/masters/accounts';
  String get partnerListApi => '$tempUrl/api/users/api/masters/partners/';
  String get warehouseListApi => '$tempUrl/api/users/api/masters/warehouses/';

  //CASH API'S
  String get paymentListApi => '$tempUrl/api/payments/payment-requests/';
  String transactionDetail(String transactionId) => '$tempUrl/api/payments/payment-requests/$transactionId/';
  String transactionApprove(String transactionId) => '$tempUrl/api/payments/payment-requests/$transactionId/approve/';
  String transactionReject(String transactionId) => '$tempUrl/api/payments/payment-requests/$transactionId/reject/';
  String get partnerAccountBalance => '$tempUrl/api/payments/partner-account-balance/';
  String get cashierAccountBalance => '$tempUrl/api/payments/cash-account-balance/';

  // STOCK API'S
  String get stockListApi => '$tempUrl/api/stocks/stock-requests/';
  String orderDetails(String orderId) => '$tempUrl/api/orders/sales-orders/$orderId/';
  String stockDetailApi(String requestId) => '$tempUrl/api/stocks/stock-requests/$requestId/';
  String approveRequestsApi(String requestId) => '$tempUrl/api/stocks/stock-requests/$requestId/approve/';
  String rejectRequestsApi(String requestId) => '$tempUrl/api/stocks/stock-requests/$requestId/reject/';
  String cancelInventoryRequest(String requestId) => '$tempUrl/api/stocks/stock-requests/$requestId/cancel/';
  String get unlinkedItemsList => '$tempUrl/api/stocks/exchange-return-items/';
  String get getMaterialRequestList => '$tempUrl/api/stocks/pending-material-requests/';
  String get getPendingSaleOrderList => '$tempUrl/api/stocks/pending-sales-orders-returns/';
  String get getPendingDeliveryItems => '$tempUrl/api/stocks/pending-delivery-items/';
  String get getOrderItems => '$tempUrl/api/orders/items-for-order/';
  String get orders => '$tempUrl/api/orders/sales-order-request/';
  String get ordersData => '$tempUrl/api/orders/sales-orders/';

  //Auth API'S
  String get login => '$tempUrl/api/users/auth/login/';
  String get refresh => '$baseUrl/api/users/auth/refresh/';
  String get companyList => '$tempUrl/api/users/auth/companies/';
  String get switchCompany => '$tempUrl/api/users/auth/switch-company/';
  String get logout => '$tempUrl/api/users/auth/logout/';
  String get initiateAadhaar => '$tempUrl/kyc/api/initiate-aadhaar/';
  String get submitAadhaarOtp => '$tempUrl/kyc/api/submit-aadhaar-otp/';
  String get initiatePartner => '$tempUrl/kyc/api/initiate-partner/';
  String get changePassword => '$tempUrl/api/users/auth/change-password/';
  String get sendOTP => '$tempUrl/api/users/auth/forgot-password/request-otp/';
  String get resetPassword => '$tempUrl/api/users/auth/forgot-password/reset-password/';
  String get purchaseInvoices => '$tempUrl/procurement/purchase-invoices/';
  String get validateSeedCode => '$tempUrl/purchase-invoices/validate-seed/';
  String get searchDrivers => '$tempUrl/procurement/drivers/search/';
  String get createDriver => '$tempUrl/procurement/drivers/';
  String get uploadDriverPhoto => 'https://tus.dca.arungas.com/files/';
  String get submitReceive => '$tempUrl/procurement/purchase-invoices/receive/';
  String get submitDispatch => '$tempUrl/procurement/invoices/dispatch/';
  String vehicleHistory(String vehicleNo) => '$tempUrl/procurement/vehicles/$vehicleNo/history/';
  String driverDetials(int driverId) => '$tempUrl/procurement/drivers/$driverId/';
  String get userWarehouses => '$tempUrl/procurement/user/warehouses/';
  String get receivedAPI => '$tempUrl/procurement/invoices/receive/';
  String get pendingInvoices => '$tempUrl/procurement/invoices/pending/';
  String get receivedInvoices => '$tempUrl/procurement/invoices/received/';

  String purchaseInvoiceDetails(String gstin, String invoiceDate, String invoiceNumber) => '$tempUrl/procurement/invoices/$gstin/$invoiceDate/$invoiceNumber/';
  String get ervCalculation => '$tempUrl/procurement/erv-calculation/';
  String get versionCheck => '$tempUrl/api/version/check/';
  String get versionPolicy => '$tempUrl/api/version/policy/';
  String get appConfig => '$tempUrl/app-config';
  String get updateDeviceToken => '$tempUrl/api/users/notifications/register-device/';

  String get sdmsTransactions => '$tempUrl/sdms/api/transactions/';
  String sdmsTransactionDetail(String id) => '$tempUrl/sdms/api/transactions/$id/';
  String get sdmsInvoiceAssign => '$tempUrl/sdms/api/transactions/invoice-assign/';
  String get sdmsCreditPayment => '$tempUrl/sdms/api/transactions/credit-payment/';
  String sdmsRetryTask(String id) => '$tempUrl/sdms/api/transactions/$id/retry-task/';

  // Digital Credit endpoints
  String get digitalCredits => '$tempUrl/sdms-ops/api/credits/';
  String digitalCreditDetail(String id) => '$tempUrl/sdms-ops/api/credits/$id/';
  String digitalCreditClaim(String id) => '$tempUrl/sdms-ops/api/credits/$id/claim/';
  String digitalCreditRetry(String id) => '$tempUrl/sdms-ops/api/credits/$id/retry/';
  String digitalCreditSwitchCompany(String id) => '$tempUrl/sdms-ops/api/credits/$id/switch-company/';
  String get claimTransfers => '$tempUrl/sdms-ops/api/claim-transfers/';
  String claimTransferApprove(String id) => '$tempUrl/sdms-ops/api/claim-transfers/$id/approve/';
  String claimTransferReject(String id) => '$tempUrl/sdms-ops/api/claim-transfers/$id/reject/';

  // SDMS Claims endpoints (Draft v3)
  // Hot fix 2026-02-12: Added isBeneficiary filter parameter
  String sdmsOrders({
    String tab = 'active',
    int page = 1,
    String? search,
    bool? isBeneficiary,
  }) {
    final params = <String, String>{};
    params['tab'] = tab;

    if (tab == 'history') {
      params['page'] = page.toString();
    }

    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    if (isBeneficiary != null) {
      params['is_beneficiary'] = isBeneficiary.toString();
    }

    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$tempUrl/api/sdms-claims/orders/?$query';
  }

  String sdmsClaimsOrderDetail(String id) => '$tempUrl/api/sdms-claims/orders/$id/';
  String sdmsClaimsOrderClaim(String id) => '$tempUrl/api/sdms-claims/orders/$id/claim/';
  String sdmsClaimsOrderRetry(String id) => '$tempUrl/api/sdms-claims/orders/$id/retry/';
  String sdmsClaimsSwitchCompany(String id) => '$tempUrl/api/sdms-claims/orders/$id/switch-company/';

  // Draft v3: Order-level transfer actions
  String approveOrderTransfer(String orderId) => '$tempUrl/api/sdms-claims/orders/$orderId/approve-transfer/';
  String rejectOrderTransfer(String orderId) => '$tempUrl/api/sdms-claims/orders/$orderId/reject-transfer/';
  String cancelOrderTransfer(String orderId) => '$tempUrl/api/sdms-claims/orders/$orderId/cancel-transfer/'; // For future use

  String get sdmsClaimsPartners => '$tempUrl/api/users/api/masters/partners/';

  // Quota endpoints
  String get quotaLiveSnapshot => '$tempUrl/api/quotas/live-snapshot/';
  String get quotaSync => '$tempUrl/api/quotas/sync/';
  String get quotaDashboard => '$tempUrl/api/quotas/dashboard/';
  String get quotaSystemStatus => '$tempUrl/api/quotas/system-status/';
  String get quotaHistory => '$tempUrl/api/quotas/history/';
  String get quotaHistoryDetail => '$tempUrl/api/quotas/history/detail/';

  // Bonus endpoints
  String get bonusSchemes => '$tempUrl/api/quotas/bonus-schemes/';
  String bonusDetail(int id) => '$tempUrl/api/quotas/bonuses/$id/';
  String get bonuses => '$tempUrl/api/quotas/bonuses/';

  // Credit Extension endpoints
  String get creditExtensions => '$tempUrl/api/quotas/credit-extensions/';
  String creditExtensionDetail(int id) => '$tempUrl/api/quotas/credit-extensions/$id/';
  String get creditExtensionsActive => '$tempUrl/api/quotas/credit-extensions/active/';
  String get creditExtensionsPending => '$tempUrl/api/quotas/credit-extensions/pending/';
  String creditExtensionApprove(int id) => '$tempUrl/api/quotas/credit-extensions/$id/approve/';
  String creditExtensionReject(int id) => '$tempUrl/api/quotas/credit-extensions/$id/reject/';
  String creditExtensionContext(int id) => '$tempUrl/api/quotas/credit-extensions/$id/context/';

  // In your endpoints class
  String get warehouseStock => '$tempUrl/api/stocks/warehouse-balance/';
  String get ledgerData => '$tempUrl/reports/api/general-ledger/';
  String get availableAccounts => '$tempUrl/reports/api/available-accounts/';
  String voucherPDF(String voucherType, String voucherNo) => '$tempUrl/reports/voucher-pdf/?voucher_type=$voucherType&voucher_no=$voucherNo';

  // DEFECT INSPECTION API'S
  String get defectMasterData => '$tempUrl/defects/api/v1/master-data/';
  String get defectPurchaseInvoices => '$tempUrl/defects/api/v1/purchase-invoices/';
  String get defectInspectionReports => '$tempUrl/defects/api/v1/inspection-reports/';
  String get defectInspectionReportsList => '$tempUrl/defects/api/v1/inspection-reports/list/';
  String defectInspectionReportDetail(String name) => '$tempUrl/defects/api/v1/inspection-reports/$name/';

  // UJJWALA INSTALLATION API'S
  final String dcaUrl = 'https://dca.arungas.com';
  String get ujjwalaPendingInstallations => '$dcaUrl/api/ujjwala-v3/installations/pending/';
  String get ujjwalaSearchInstallations => '$dcaUrl/api/ujjwala-v3/installations/search/';
  String ujjwalaMyUploads({String? status}) {
    final base = '$dcaUrl/api/ujjwala-v3/installations/my-uploads/';
    return status != null ? '$base?status=$status' : base;
  }

  String ujjwalaApplicationDetail(int disbursementId) =>
      '$dcaUrl/api/ujjwala-v3/installations/$disbursementId/application-detail/';
  String get ujjwalaServiceAreas => '$dcaUrl/api/ujjwala-v3/installations/service-areas/';
  String ujjwalaInstallationHistory(int id) =>
      '$dcaUrl/api/ujjwala-v3/installations/$id/history/';

  // LPG Ops Backend Ujjwala (new)
  String get ujjwalaLpgInstallations => '$tempUrl/api/ujjwala/installations/';
  String ujjwalaInstallationSubmit(int id) => '$tempUrl/api/ujjwala-v3/installations/$id/submit/';
  String get ujjwalaBulkVerify => '$tempUrl/api/ujjwala/installations/bulk-verify/';
  String get ujjwalaRetryFailed => '$tempUrl/api/ujjwala/installations/retry/';
  String get ujjwalaReimbursementsPreview => '$tempUrl/api/ujjwala/reimbursements/preview/';
  String get ujjwalaReimbursements => '$tempUrl/api/ujjwala/reimbursements/';

  // Offline Delivery
  String get offlineDeliveryStatus => '$tempUrl/api/offline-delivery/status/';
  String get offlineDeliveryDistributionPoints => '$tempUrl/api/offline-delivery/distribution-points/';
  String get offlineDeliveryBookingVerifications => '$tempUrl/api/offline-delivery/booking-verifications/';
  String offlineDeliveryBookingVerificationDetail(String id) => '$tempUrl/api/offline-delivery/booking-verifications/$id/';
  String offlineDeliveryBookingVerificationRetry(String id) => '$tempUrl/api/offline-delivery/booking-verifications/$id/retry/';
  String offlineDeliveryBookingVerificationPrint(String id) => '$tempUrl/api/offline-delivery/booking-verifications/$id/print/';
  String get offlineDeliveryTokens => '$tempUrl/api/offline-delivery/tokens/';
  String offlineDeliveryTokenDetail(String id) => '$tempUrl/api/offline-delivery/tokens/$id/';
  String offlineDeliveryTokenDeliver(String id) => '$tempUrl/api/offline-delivery/tokens/$id/deliver/';
  String offlineDeliveryTokenCorrect(String id) => '$tempUrl/api/offline-delivery/tokens/$id/correct/';
  String offlineDeliveryTokenAttachImages(String id) => '$tempUrl/api/offline-delivery/tokens/$id/attach-images/';
  String get offlineDeliveryQuickDeliver => '$tempUrl/api/offline-delivery/tokens/quick-deliver/';
  String offlineDeliveryTokenPrint(String id) => '$tempUrl/api/offline-delivery/tokens/$id/print/';
  String get offlineDeliveryCompanies => '$tempUrl/api/offline-delivery/companies/';
  String get offlineDeliveryDirectors => '$tempUrl/api/offline-delivery/directors/';
  String get offlineDeliveryLookup => '$tempUrl/api/offline-delivery/lookup/';
  String get offlineDeliveryCollectionsDue => '$tempUrl/api/offline-delivery/collections/due/';
  String offlineDeliveryTokenCollectEmpties(String id) => '$tempUrl/api/offline-delivery/tokens/$id/collect-empties/';
  String offlineDeliveryTokenCollectCash(String id) => '$tempUrl/api/offline-delivery/tokens/$id/collect-cash/';
  String get offlineDeliveryTokenScan => '$tempUrl/api/offline-delivery/tokens/scan/';
  String get offlineDeliveryMyPartner => '$tempUrl/api/offline-delivery/tokens/my-partner/';
}