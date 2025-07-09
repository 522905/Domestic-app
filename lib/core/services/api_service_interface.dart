// lib/core/services/api_service_interface.dart
import '../models/inventory_request.dart';

abstract class ApiServiceInterface {

  Future<void> initialize(String baseUrl);
  // Auth methods
  Future<Map<String, dynamic>> login(String username, String password);
  Future<void> logout();
  Future<Map<String, dynamic>> getUserProfile();
  Future<Map<String, dynamic>> getOrderDetail(String orderId);
  Future<Map<String, dynamic>> refreshCashData();
  Future<void> requestOrderApproval(String orderId);

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

  Future<Map<String, dynamic>> getCashSummary();
  Future<Map<String, dynamic>> getAccountsList();
  Future<Map<String, dynamic>> getBankList();


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


  // Warehouse methods
  Future<List<dynamic>> getWarehouses();

  Future<List<Map<String, dynamic>>> getItemList();

  // Vehicle methods
  Future<List<dynamic>> getVehicles();

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

  Future<List<dynamic>> getOrdersList();

  Future<void> deleteOrder(String orderId);

  Future<void> approveInventoryRequest({
    required String requestId,
    required String comment,
  });

  Future<void> rejectInventoryRequest({
    required String requestId,
    required String reason,
  });

  Future<List<InventoryRequest>> getInventoryRequests();
  Future<InventoryRequest> createInventoryRequest(InventoryRequest request);
  Future<InventoryRequest> updateInventoryRequest(String id, InventoryRequest request);
  Future<void> toggleFavoriteRequest(String requestId, bool isFavorite);
  Future<List<Map<String, dynamic>>> getInventoryItems({int? warehouseId, String? itemType});
  Future<List<InventoryRequest>> getInventoryRequestObjects();
  Future<InventoryRequest> createInventoryRequestObject(InventoryRequest request);
  Future<InventoryRequest> updateInventoryRequestObject(String id, InventoryRequest request);
  Future<dynamic> getCollectionRequestById(String id);
  Future<Map<String, dynamic>> submitHandover(Map<String, dynamic> data);
  Future<Map<String, dynamic>> approveTransaction(String transactionId);
  Future<Map<String, dynamic>> rejectTransaction(String transactionId, Map<String, dynamic> rejectionData);

}