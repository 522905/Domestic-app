import 'package:dio/dio.dart';

class ApiEndpoints {
  final String baseUrl;

  final String tempUrl = 'http://192.168.168.152:8001'; // Temporary URL for testing

  ApiEndpoints(this.baseUrl);
  // Auth endpoints
  String get login => '$tempUrl/api/users/login/';
  String get logout => '$baseUrl/api/logout';
  String get refresh => '$baseUrl/api/token/refresh/';

  // Dashboard endpoints
  String get dashboard => '$baseUrl/api/dashboard';
  String get pendingCounts => '$baseUrl/api/dashboard/pending-counts';
  String dashboardRoleData(String role, String tab) => '$baseUrl/api/dashboard/$role/$tab';
  String get inventory => '$baseUrl/api/inventory-items';
  String get inventoryRequests => '$baseUrl/api/inventory-requests/';
  String get itemList => '$tempUrl/api/orders/items/';

  // Order endpoints
  String get orders => '$tempUrl/api/orders/sales-order-request/';
  String get ordersList => '$tempUrl/api/orders/sales-order-list/';
  String orderDetail(String id) => '$baseUrl/api/orders/$id';
  String get orderApproval => '$baseUrl/api/approvals/{order_id}/approve';
  String get orderReject => '$baseUrl/api/approvals/{order_id}/reject';

  // Cash endpoints
  String get accountsList => '$tempUrl/api/users/users-list/';
  String get cashSummary => '$tempUrl/api/payments/account-balance/';
  String get cashTransactions => '$tempUrl/api/payments/request/';
  String transactionApproval(String transactionId) => '$tempUrl/api/payments/approve/$transactionId/';
  String transactionReject(String transactionId) => '$tempUrl/api/payments/reject/$transactionId/';
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

  // Warehouse endpoints
  String get warehouses => '$tempUrl/api/orders/warehouse-list/';

  // Vehicle endpoint
  String get vehicles => '$baseUrl/api/vehicles/';

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

  // Documents
  static const String uploadDocument = '/api/documents/upload';

  static String inventoryRequestDetail(String requestId) => '/api/inventory-requests/$requestId';
  static String inventoryRequestApprove(String requestId) => '/api/inventory-requests/$requestId/approve';
  static String inventoryRequestReject(String requestId) => '/api/inventory-requests/$requestId/reject';
  static String inventoryRequestToggleFavorite(String requestId) => '/api/inventory-requests/$requestId/favorite';

  static const String collectionRequestApprove = '/api/collection-requests/approve';
  static const String collectionRequestReject = '/api/collection-requests/reject';

}
