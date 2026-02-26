import 'package:equatable/equatable.dart';
import 'installation_item.dart';

class LpgOpsInstallation extends Equatable {
  final int id;
  final String dcaApplicationId;
  final String relationshipId;
  final String orderId;
  final String docNumber;
  final String consumerName;
  final String consumerAddress;
  final String status;
  final String statusDisplay;
  final List<InstallationItem> items;
  final String partnerName;
  final String deliveryBoyName;
  final String rpaError;
  final String errorCategory;
  final bool canRetry;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LpgOpsInstallation({
    required this.id,
    required this.dcaApplicationId,
    required this.relationshipId,
    required this.orderId,
    required this.docNumber,
    required this.consumerName,
    required this.consumerAddress,
    required this.status,
    required this.statusDisplay,
    required this.items,
    required this.partnerName,
    required this.deliveryBoyName,
    required this.rpaError,
    required this.errorCategory,
    required this.canRetry,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LpgOpsInstallation.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((item) => InstallationItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return LpgOpsInstallation(
      id: json['id'] as int,
      dcaApplicationId: json['dca_application_id']?.toString() ?? '',
      relationshipId: json['relationship_id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      docNumber: json['doc_number']?.toString() ?? '',
      consumerName: json['consumer_name']?.toString() ?? '',
      consumerAddress: json['consumer_address']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusDisplay: json['status_display']?.toString() ?? json['status']?.toString() ?? '',
      items: itemsList,
      partnerName: json['partner_name']?.toString() ?? '',
      deliveryBoyName: json['delivery_boy_name']?.toString() ?? '',
      rpaError: json['rpa_error']?.toString() ?? '',
      errorCategory: json['error_category']?.toString() ?? '',
      canRetry: json['can_retry'] == true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null || value == '') return DateTime.now();
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  String get displayId => orderId.isNotEmpty ? orderId : docNumber;

  /// Returns the integer disbursement ID for use with the DCA application-detail endpoint.
  /// Parses dcaApplicationId as int, falls back to the LPG Ops internal id.
  int get disbursementId => int.tryParse(dcaApplicationId) ?? id;

  String get errorMessage {
    if (rpaError.isNotEmpty) return rpaError;
    switch (errorCategory) {
      case 'NOT_FOUND':
        return 'Order not found in SDMS';
      case 'PENDING_COMPLETION':
        return 'Order pending completion in SDMS';
      case 'TECHNICAL':
        return 'Technical error — please retry';
      default:
        return 'Unknown error';
    }
  }

  @override
  List<Object?> get props => [
        id,
        dcaApplicationId,
        relationshipId,
        orderId,
        docNumber,
        consumerName,
        consumerAddress,
        status,
        statusDisplay,
        items,
        partnerName,
        deliveryBoyName,
        rpaError,
        errorCategory,
        canRetry,
        createdAt,
        updatedAt,
      ];
}
