import 'package:equatable/equatable.dart';

class InventoryRequest extends Equatable {
  final String? vehicle;
  final String id;
  final String warehouseId;
  final String warehouse;
  final String requestedBy;
  final String requestType;
  final String status;
  final String timestamp;
  final bool isFavorite;
  final String? customerName;
  final String? stockEntryType;
  final String? targetWarehouse;
  final List<Map<String, dynamic>>? items;
  final bool? approved;
  final String? approvedBy;
  final String? approvedAt;
  final bool? rejected;
  final String? rejectedBy;
  final String? rejectedAt;
  final String? rejectionReason;
  final String? sourceWarehouse;
  final List<Map<String, dynamic>>? driverInfo;
  final bool? regularDeliveryPartner;
  final String? imageUrl;
  final String? remarks;
  final int? itemsCount;

  const InventoryRequest({
    required this.vehicle,
    required this.warehouse,
    required this.items,
    this.id = '',
    this.warehouseId = '',
    this.requestedBy = '',
    this.requestType = 'Inventory',
    this.status = 'PENDING',
    this.timestamp = '',
    this.isFavorite = false,
    this.customerName,
    this.stockEntryType,
    this.targetWarehouse,
    this.approved,
    this.approvedBy,
    this.approvedAt,
    this.rejected,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
    this.driverInfo,
    this.imageUrl,
    this.regularDeliveryPartner,
    this.sourceWarehouse,
    this.remarks,
    this.itemsCount,
  });

  const InventoryRequest.full({
    required this.id,
    required this.warehouseId,
    required this.warehouse,
    required this.requestedBy,
    required this.requestType,
    required this.status,
    required this.timestamp,
    this.vehicle,
    this.isFavorite = false,
    this.customerName,
    this.stockEntryType,
    this.targetWarehouse,
    this.items,
    this.approved,
    this.approvedBy,
    this.approvedAt,
    this.rejected,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
    this.driverInfo,
    this.imageUrl,
    this.regularDeliveryPartner,
    this.sourceWarehouse,
    this.remarks,
    this.itemsCount,
  });

  InventoryRequest copyWith({
    String? id,
    String? warehouseId,
    String? warehouse,
    String? requestedBy,
    String? requestType,
    String? status,
    String? timestamp,
    bool? isFavorite,
    String? customerName,
    String? stockEntryType,
    String? targetWarehouse,
    List<Map<String, dynamic>>? items,
    bool? approved,
    String? approvedBy,
    String? approvedAt,
    bool? rejected,
    String? rejectedBy,
    String? rejectedAt,
    String? rejectionReason,
    String? sourceWarehouse,
    List<Map<String, dynamic>>? driverInfo,
    bool? regularDeliveryPartner,
    String? imageUrl,
    String? remarks,
    String? vehicle,
    int? itemsCount,
  }) {
    return InventoryRequest.full(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouse: warehouse ?? this.warehouse,
      requestedBy: requestedBy ?? this.requestedBy,
      requestType: requestType ?? this.requestType,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
      customerName: customerName ?? this.customerName,
      stockEntryType: stockEntryType ?? this.stockEntryType,
      targetWarehouse: targetWarehouse ?? this.targetWarehouse,
      items: items ?? this.items,
      approved: approved ?? this.approved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejected: rejected ?? this.rejected,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      sourceWarehouse: sourceWarehouse ?? this.sourceWarehouse,
      driverInfo: driverInfo ?? this.driverInfo,
      regularDeliveryPartner: regularDeliveryPartner ?? this.regularDeliveryPartner,
      imageUrl: imageUrl ?? this.imageUrl,
      remarks: remarks ?? this.remarks,
      vehicle: vehicle ?? this.vehicle,
      itemsCount: itemsCount ?? this.itemsCount,
    );
  }

  factory InventoryRequest.fromJson(Map<String, dynamic> json) {
    // Handle both list response and detail response
    return InventoryRequest.full(
      id: json['id']?.toString() ?? '',
      warehouseId: json['warehouse']?.toString() ?? json['warehouse_id']?.toString() ?? '',
      warehouse: json['warehouse_name']?.toString() ?? json['warehouse']?.toString() ?? '',
      requestedBy: json['requested_by_name']?.toString() ?? json['created_by']?.toString() ?? '',
      requestType: json['request_type']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      timestamp: json['created_at']?.toString() ?? '',
      vehicle: json['vehicle_number']?.toString() ,
      isFavorite: json['is_favorite'] ?? false,
      customerName: json['custom_customer']?.toString(),
      stockEntryType: json['stock_entry_type']?.toString(),
      targetWarehouse: json['target_warehouse']?.toString(),
      // Handle items array (detail response) or items_count (list response)
      items: json['items'] != null
          ? (json['items'] as List?)
          ?.map((item) {
        // Transform item_code to item_name for consistency
        final itemMap = Map<String, dynamic>.from(item);
        if (itemMap.containsKey('item_code') && !itemMap.containsKey('item_name')) {
          itemMap['item_name'] = itemMap['item_code'];
        }
        return itemMap;
      })
          .toList()
          : null,
      itemsCount: json['items_count'],
      approved: json['approved'],
      approvedBy: json['approved_by']?.toString(),
      approvedAt: json['approved_at']?.toString(),
      rejected: json['rejected'],
      rejectedBy: json['rejected_by']?.toString(),
      rejectedAt: json['rejected_at']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      sourceWarehouse: json['source_warehouse']?.toString(),
      driverInfo: (json['driver_info'] as List?)
          ?.map((item) => Map<String, dynamic>.from(item))
          .toList(),
      regularDeliveryPartner: json['regular_delivery_partner'] ?? false,
      imageUrl: json['image_url']?.toString(),
      remarks: json['remarks']?.toString() ?? json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'warehouse_id': warehouseId,
      'warehouse': warehouse,
      'requested_by': requestedBy,
      'request_type': requestType,
      'status': status,
      'timestamp': timestamp,
      'is_favorite': isFavorite,
      'custom_customer': customerName,
      'stock_entry_type': stockEntryType,
      'target_warehouse': targetWarehouse,
      'items': items,
      'items_count': itemsCount,
      'approved': approved,
      'approved_by': approvedBy,
      'approved_at': approvedAt,
      'rejected': rejected,
      'rejected_by': rejectedBy,
      'rejected_at': rejectedAt,
      'rejection_reason': rejectionReason,
      'source_warehouse': sourceWarehouse,
      'driver_info': driverInfo,
      'regular_delivery_partner': regularDeliveryPartner,
      'image_url': imageUrl,
      'remarks': remarks,
      'vehicle': vehicle,
    };
  }

  @override
  List<Object?> get props => [
    id,
    warehouseId,
    warehouse,
    requestedBy,
    requestType,
    status,
    timestamp,
    isFavorite,
    customerName,
    stockEntryType,
    targetWarehouse,
    items,
    itemsCount,
    approved,
    approvedBy,
    approvedAt,
    rejected,
    rejectedBy,
    rejectedAt,
    rejectionReason,
    sourceWarehouse,
    driverInfo,
    regularDeliveryPartner,
    imageUrl,
    remarks,
    vehicle,
  ];
}