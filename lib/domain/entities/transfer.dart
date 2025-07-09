// class Transfer {
//   final String id;
//   final String fromWarehouseId;
//   final String fromWarehouseName;
//   final String toWarehouseId;
//   final String toWarehouseName;
//   final String driverName;
//   final String driverPhone;
//   final String vehicleNumber;
//   final String status; // 'pending', 'handover_approved', 'in_transit', 'delivered', 'completed'
//   final List<TransferItem> items;
//   final DateTime createdAt;
//   final DateTime? handoverApprovedAt;
//   final DateTime? deliveredAt;
//   final DateTime? completedAt;
//   final String? driverPhoto; // Base64 encoded image
//
//   Transfer({
//     required this.id,
//     required this.fromWarehouseId,
//     required this.fromWarehouseName,
//     required this.toWarehouseId,
//     required this.toWarehouseName,
//     required this.driverName,
//     required this.driverPhone,
//     required this.vehicleNumber,
//     required this.status,
//     required this.items,
//     required this.createdAt,
//     this.handoverApprovedAt,
//     this.deliveredAt,
//     this.completedAt,
//     this.driverPhoto,
//   });
//
//   Transfer copyWith({
//     String? status,
//     DateTime? handoverApprovedAt,
//     DateTime? deliveredAt,
//     DateTime? completedAt,
//   }) {
//     return Transfer(
//       id: id,
//       fromWarehouseId: fromWarehouseId,
//       fromWarehouseName: fromWarehouseName,
//       toWarehouseId: toWarehouseId,
//       toWarehouseName: toWarehouseName,
//       driverName: driverName,
//       driverPhone: driverPhone,
//       vehicleNumber: vehicleNumber,
//       status: status ?? this.status,
//       items: items,
//       createdAt: createdAt,
//       handoverApprovedAt: handoverApprovedAt ?? this.handoverApprovedAt,
//       deliveredAt: deliveredAt ?? this.deliveredAt,
//       completedAt: completedAt ?? this.completedAt,
//       driverPhoto: driverPhoto,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'fromWarehouseId': fromWarehouseId,
//       'fromWarehouseName': fromWarehouseName,
//       'toWarehouseId': toWarehouseId,
//       'toWarehouseName': toWarehouseName,
//       'driverName': driverName,
//       'driverPhone': driverPhone,
//       'vehicleNumber': vehicleNumber,
//       'status': status,
//       'items': items.map((item) => item.toJson()).toList(),
//       'createdAt': createdAt.toIso8601String(),
//       'handoverApprovedAt': handoverApprovedAt?.toIso8601String(),
//       'deliveredAt': deliveredAt?.toIso8601String(),
//       'completedAt': completedAt?.toIso8601String(),
//       'driverPhoto': driverPhoto,
//     };
//   }
//
//   factory Transfer.fromJson(Map<String, dynamic> json) {
//     return Transfer(
//       id: json['id'] as String,
//       fromWarehouseId: json['fromWarehouseId'] as String,
//       fromWarehouseName: json['fromWarehouseName'] as String,
//       toWarehouseId: json['toWarehouseId'] as String,
//       toWarehouseName: json['toWarehouseName'] as String,
//       driverName: json['driverName'] as String,
//       driverPhone: json['driverPhone'] as String,
//       vehicleNumber: json['vehicleNumber'] as String,
//       status: json['status'] as String,
//       items: (json['items'] as List)
//           .map((item) => TransferItem.fromJson(item))
//           .toList(),
//       createdAt: DateTime.parse(json['createdAt'] as String),
//       handoverApprovedAt: json['handoverApprovedAt'] != null
//           ? DateTime.parse(json['handoverApprovedAt'] as String)
//           : null,
//       deliveredAt: json['deliveredAt'] != null
//           ? DateTime.parse(json['deliveredAt'] as String)
//           : null,
//       completedAt: json['completedAt'] != null
//           ? DateTime.parse(json['completedAt'] as String)
//           : null,
//       driverPhoto: json['driverPhoto'] as String?,
//     );
//   }
// }
//
// class TransferItem {
//   final String itemId;
//   final String itemName;
//   final String itemType; // 'filled', 'empty', etc.
//   final int quantity;
//   final int? defectiveQuantity; // Optional field for defective items
//   final int? inTransitQuantity; // Optional field for items in transit
//
//   TransferItem({
//     required this.itemId,
//     required this.itemName,
//     required this.itemType,
//     required this.quantity,
//     this.defectiveQuantity,
//     this.inTransitQuantity,
//   });
//
//   Map<String, dynamic> toJson() {
//     return {
//       'itemId': itemId,
//       'itemName': itemName,
//       'itemType': itemType,
//       'quantity': quantity,
//       'defectiveQuantity': defectiveQuantity,
//       'inTransitQuantity': inTransitQuantity,
//     };
//   }
//
//   factory TransferItem.fromJson(Map<String, dynamic> json) {
//     return TransferItem(
//       itemId: json['itemId'] as String,
//       itemName: json['itemName'] as String,
//       itemType: json['itemType'] as String,
//       quantity: json['quantity'] as int,
//       defectiveQuantity: json['defectiveQuantity'] as int?,
//       inTransitQuantity: json['inTransitQuantity'] as int?,
//     );
//   }
// }

import 'package:lpg_distribution_app/domain/entities/transfer_item.dart';

class Transfer {
  final String id;
  final String fromWarehouseId;
  final String fromWarehouseName;
  final String toWarehouseId;
  final String toWarehouseName;
  final String driverName;
  final String driverPhone;
  final String vehicleNumber;
  final String status; // 'pending', 'handover_approved', 'in_transit', 'delivered', 'completed'
  final List<TransferItem> items;
  final DateTime createdAt;
  final DateTime? handoverApprovedAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final String? driverPhoto; // Base64 encoded image

  Transfer({
    required this.id,
    required this.fromWarehouseId,
    required this.fromWarehouseName,
    required this.toWarehouseId,
    required this.toWarehouseName,
    required this.driverName,
    required this.driverPhone,
    required this.vehicleNumber,
    required this.status,
    required this.items,
    required this.createdAt,
    this.handoverApprovedAt,
    this.deliveredAt,
    this.completedAt,
    this.driverPhoto,
  });

  Transfer copyWith({
    String? status,
    DateTime? handoverApprovedAt,
    DateTime? deliveredAt,
    DateTime? completedAt,
  }) {
    return Transfer(
      id: id,
      fromWarehouseId: fromWarehouseId,
      fromWarehouseName: fromWarehouseName,
      toWarehouseId: toWarehouseId,
      toWarehouseName: toWarehouseName,
      driverName: driverName,
      driverPhone: driverPhone,
      vehicleNumber: vehicleNumber,
      status: status ?? this.status,
      items: items,
      createdAt: createdAt,
      handoverApprovedAt: handoverApprovedAt ?? this.handoverApprovedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      completedAt: completedAt ?? this.completedAt,
      driverPhoto: driverPhoto,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromWarehouseId': fromWarehouseId,
      'fromWarehouseName': fromWarehouseName,
      'toWarehouseId': toWarehouseId,
      'toWarehouseName': toWarehouseName,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehicleNumber': vehicleNumber,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'handoverApprovedAt': handoverApprovedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'driverPhoto': driverPhoto,
    };
  }

  factory Transfer.fromJson(Map<String, dynamic> json) {
    return Transfer(
      id: json['id'] as String,
      fromWarehouseId: json['fromWarehouseId'] as String,
      fromWarehouseName: json['fromWarehouseName'] as String,
      toWarehouseId: json['toWarehouseId'] as String,
      toWarehouseName: json['toWarehouseName'] as String,
      driverName: json['driverName'] as String,
      driverPhone: json['driverPhone'] as String,
      vehicleNumber: json['vehicleNumber'] as String,
      status: json['status'] as String,
      items: (json['items'] as List)
          .map((item) => TransferItem.fromJson(item))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      handoverApprovedAt: json['handoverApprovedAt'] != null
          ? DateTime.parse(json['handoverApprovedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      driverPhoto: json['driverPhoto'] as String?,
    );
  }
}