// lib/core/models/order/selectable_order_item.dart
class SelectableOrderItem {
  final String id;
  final String itemCode;
  final String itemName;
  final String description;
  final String type; // 'Filled', 'NFR', etc.
  final int maxQuantity; // actual_qty
  final String availabilityStatus;
  final Map<String, dynamic> metadata;

  SelectableOrderItem({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.description,
    required this.type,
    required this.maxQuantity,
    required this.availabilityStatus,
    required this.metadata,
  });

  String get displayName => itemName.isNotEmpty ? itemName : itemCode;

  bool get isOutOfStock => availabilityStatus == 'Out of Stock' || maxQuantity <= 0;

  factory SelectableOrderItem.fromJson(Map<String, dynamic> json, String bucketType) {
    // Safely convert actual_qty to int
    int projectedQty = 0;
    final projectedQtyValue = json["projected_qty"];
    if (projectedQtyValue != null) {
      if (projectedQtyValue is int) {
        projectedQty = projectedQtyValue;
      } else if (projectedQtyValue is double) {
        projectedQty = projectedQtyValue.toInt();
      } else if (projectedQtyValue is String) {
        projectedQty = int.tryParse(projectedQtyValue) ?? 0;
      }
    }

    return SelectableOrderItem(
      id: json['item_code'] ?? '',
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      description: json['description'] ?? '',
      type: bucketType,
      maxQuantity: projectedQty,
      availabilityStatus: json['availability_status'] ?? 'Unknown',
      metadata: {
        'item_group': json['item_group'],
        'stock_uom': json['stock_uom'],
        'reserved_stock': _safeToInt(json['reserved_stock']),
        'projected_qty': _safeToInt(json['projected_qty']),
        'mappings': json['mappings'] ?? [],
        'availability_status': json['availability_status'],
        'actual_qty': projectedQty,
        ...json,
      },
    );
  }

  // Helper method to safely convert any number type to int
  static int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toApiPayload(int selectedQuantity) {
    return {
      'item_code': itemCode,
      'qty': selectedQuantity,
    };
  }

  SelectableOrderItem copyWith({
    String? id,
    String? itemCode,
    String? itemName,
    String? description,
    String? type,
    int? maxQuantity,
    String? availabilityStatus,
    Map<String, dynamic>? metadata,
  }) {
    return SelectableOrderItem(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      type: type ?? this.type,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      metadata: metadata ?? this.metadata,
    );
  }
}