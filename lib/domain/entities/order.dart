// lib/domain/entities/order.dart
class Order {
  final String id;
  final String orderNumber;
  final String customerName;
  final String warehouse;
  final String vehicle;
  final String status;
  final String deliveryStatus;
  final DateTime transactionDate;
  final DateTime deliveryDate;
  final double grandTotal;
  final int totalQty;
  final double perDelivered;
  final double perBilled;
  final String inventoryStatus;
  final DateTime inventoryDueDate;

  Order({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.warehouse,
    required this.vehicle,
    required this.status,
    required this.deliveryStatus,
    required this.transactionDate,
    required this.deliveryDate,
    required this.grandTotal,
    required this.totalQty,
    required this.perDelivered,
    required this.perBilled,
    required this.inventoryStatus,
    required this.inventoryDueDate,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['name'] ?? '',
      orderNumber: json['name'] ?? '',
      customerName: json['customer_name'] ?? json['customer'] ?? '',
      warehouse: json['set_warehouse'] ?? '',
      vehicle: json['custom_vehicle'] ?? '',
      status: json['status'] ?? '',
      deliveryStatus: json['delivery_status'] ?? '',
      transactionDate: _parseDate(json['transaction_date']),
      deliveryDate: _parseDate(json['delivery_date']),
      grandTotal: _parseDouble(json['grand_total']),
      totalQty: _parseInt(json['total_qty']),
      perDelivered: _parseDouble(json['per_delivered']),
      perBilled: _parseDouble(json['per_billed']),
      inventoryStatus: json['custom_inventory_status'] ?? '',
      inventoryDueDate: _parseDate(json['custom_inventory_due_date']),
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null || dateValue == '') {
      return DateTime.now();
    }
    try {
      return DateTime.parse(dateValue.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Order copyWith({
    String? id,
    String? orderNumber,
    String? customerName,
    String? warehouse,
    String? vehicle,
    String? status,
    String? deliveryStatus,
    DateTime? transactionDate,
    DateTime? deliveryDate,
    double? grandTotal,
    int? totalQty,
    double? perDelivered,
    double? perBilled,
    String? inventoryStatus,
    DateTime? inventoryDueDate,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      warehouse: warehouse ?? this.warehouse,
      vehicle: vehicle ?? this.vehicle,
      status: status ?? this.status,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      transactionDate: transactionDate ?? this.transactionDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      grandTotal: grandTotal ?? this.grandTotal,
      totalQty: totalQty ?? this.totalQty,
      perDelivered: perDelivered ?? this.perDelivered,
      perBilled: perBilled ?? this.perBilled,
      inventoryStatus: inventoryStatus ?? this.inventoryStatus,
      inventoryDueDate: inventoryDueDate ?? this.inventoryDueDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}