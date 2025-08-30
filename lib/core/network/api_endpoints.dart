import 'package:dio/dio.dart';

class ApiEndpoints {
  final String baseUrl;

  // final String tempUrl = 'http://192.168.168.152:8001';
  final String tempUrl = 'http://192.168.171.34:9900';

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
  String get accountsList => '$tempUrl/api/users/users-list/';
  String get vehicles => '$tempUrl/api/users/api/masters/vehicles/';

  String transactionApprove(String transactionId) =>
      '$tempUrl/api/payments/payment-requests/$transactionId/approve/';

  String transactionReject(String transactionId) =>
      '$tempUrl/api/payments/payment-requests/$transactionId/reject/';

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
  String get partnerAccountBalance => '$tempUrl/api/payments/partner-account-balance/';
  String get cashierAccountBalance => '$tempUrl/api/payments/cash-account-balance/';

  // STOCK API'S
  String get stockListApi => '$tempUrl/api/stocks/stock-requests/';
  String stockDetailApi(String requestId) => '$tempUrl/api/stocks/stock-requests/$requestId/';
  String approveRequestsApi(String requestId) => '$tempUrl/api/stocks/stock-requests/$requestId/approve/';
  String rejectRequestsApi(String requestId) => '$tempUrl/api/stocks/stock-requests/$requestId/reject/';
  String get unlinkedItemsList => '$tempUrl/api/stocks/exchange-return-items/';
  String get getMaterialRequestList => '$tempUrl/api/stocks/pending-material-requests/';
  String get getPendingSaleOrderList => '$tempUrl/api/stocks/pending-sales-orders-returns/';
  String get getPendingDeliveryItems => '$tempUrl/api/stocks/pending-delivery-items/';
  String get getOrderItems => '$tempUrl/api/orders/items-for-order/';
  String get orders => '$tempUrl/api/orders/sales-order-request/';
  String get ordersData => '$tempUrl/api/orders/sales-orders/';
  String orderDetails(String orderId) => '$tempUrl/api/orders/sales-orders/$orderId/';

  //Auth API'S
  String get login => '$tempUrl/api/users/auth/login/';
  String get refresh => '$baseUrl/api/users/auth/refresh/';
  String get companyList => '$tempUrl/api/users/auth/companies/';
  String get switchCompany => '$tempUrl/api/users/auth/switch-company/';
  String get logout => '$baseUrl/api/logout';

}
