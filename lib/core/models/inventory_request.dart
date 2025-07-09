import 'package:equatable/equatable.dart';

class InventoryRequest extends Equatable {
  final String id;
  final String warehouseId;
  final String warehouseName;
  final String requestedBy;
  final String role; // CSE or Driver
  final int cylinders14kg;
  final int cylinders19kg;
  final int smallCylinders;
  final String status; // PENDING, APPROVED, REJECTED
  final String timestamp;
  final bool isFavorite;

  const InventoryRequest({
    required this.id,
    required this.warehouseId,
    required this.warehouseName,
    required this.requestedBy,
    required this.role,
    required this.cylinders14kg,
    required this.cylinders19kg,
    this.smallCylinders = 0,
    required this.status,
    required this.timestamp,
    this.isFavorite = false,
  });

  InventoryRequest copyWith({
    String? id,
    String? warehouseId,
    String? warehouseName,
    String? requestedBy,
    String? role,
    int? cylinders14kg,
    int? cylinders19kg,
    int? smallCylinders,
    String? status,
    String? timestamp,
    bool? isFavorite,
  }) {
    return InventoryRequest(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      requestedBy: requestedBy ?? this.requestedBy,
      role: role ?? this.role,
      cylinders14kg: cylinders14kg ?? this.cylinders14kg,
      cylinders19kg: cylinders19kg ?? this.cylinders19kg,
      smallCylinders: smallCylinders ?? this.smallCylinders,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
    );

  }

  factory InventoryRequest.fromJson(Map<String, dynamic> json) {
    return InventoryRequest(
      id: json['id'] ?? '',
      warehouseId: json['warehouse_id']?.toString() ?? '',
      warehouseName: json['warehouse_name'] ?? '',
      requestedBy: json['requested_by'] ?? '',
      role: json['role'] ?? '',
      cylinders14kg: json['cylinders_14kg'] ?? 0,
      cylinders19kg: json['cylinders_19kg'] ?? 0,
      smallCylinders: json['small_cylinders'] ?? 0,
      status: json['status'] ?? 'PENDING',
      timestamp: json['timestamp'] ?? '',
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'requested_by': requestedBy,
      'role': role,
      'cylinders_14kg': cylinders14kg,
      'cylinders_19kg': cylinders19kg,
      'small_cylinders': smallCylinders,
      'status': status,
      'timestamp': timestamp,
      'is_favorite': isFavorite,
    };
  }

  @override
  List<Object> get props => [
    id, warehouseId, warehouseName, requestedBy, role,
    cylinders14kg, cylinders19kg, smallCylinders, status, timestamp, isFavorite
  ];
}