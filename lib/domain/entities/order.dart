// lib/domain/entities/order.dart
class Order {
  final String id;
  final String orderNumber;
  final String orderType; // Refill, NFR, SV, TV
  final String status; // Pending, Approved, Processing, Completed, Rejected
  final DateTime createdAt;
  final List<OrderItem> items;
  final String warehouseId;
  final String vehicleId;
  final String grandTotal;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.warehouseId,
    required this.vehicleId,
    required this.grandTotal,
  });
}

class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final String unit;
  final double? rate;
  final double? amount;
  final String? description;
  final String? itemCode;
  final String? warehouse;

  // Additional fields for order-level data
  final String ?orderId;
  final String ? orderType;
  final String ?status;
  final DateTime ? createdAt;
  final String ? grandTotal;

  const OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.rate,
    this.amount,
    this.description,
    this.itemCode,
    this.warehouse,
     this.orderId,
     this.orderType,
     this.status,
     this.createdAt,
     this.grandTotal,
  });
}