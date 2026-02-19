import 'package:equatable/equatable.dart';

class ActiveExtension extends Equatable {
  final int id;
  final String itemCode;
  final String itemName;
  final int approvedQuantity;
  final DateTime validUntil;
  final int quantityRemaining;
  final int daysUntilExpiry;

  const ActiveExtension({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.approvedQuantity,
    required this.validUntil,
    required this.quantityRemaining,
    required this.daysUntilExpiry,
  });

  bool get isExpiringSoon => daysUntilExpiry <= 2;

  factory ActiveExtension.fromJson(Map<String, dynamic> json) {
    return ActiveExtension(
      id: json['id'] ?? 0,
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      approvedQuantity: json['approved_quantity'] ?? 0,
      validUntil: DateTime.parse(json['valid_until']),
      quantityRemaining: json['quantity_remaining'] ?? 0,
      daysUntilExpiry: json['days_until_expiry'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        itemCode,
        itemName,
        approvedQuantity,
        validUntil,
        quantityRemaining,
        daysUntilExpiry,
      ];
}

class ActiveExtensionSummary extends Equatable {
  final List<ActiveExtension> extensions;
  final Map<String, int> totalByItem;

  const ActiveExtensionSummary({
    required this.extensions,
    required this.totalByItem,
  });

  bool get hasExtensions => extensions.isNotEmpty;

  int get totalExtensionCount => extensions.length;

  int getTotalForItem(String itemCode) => totalByItem[itemCode] ?? 0;

  List<ActiveExtension> get expiringSoonExtensions =>
      extensions.where((ext) => ext.isExpiringSoon).toList();

  bool get hasExpiringSoonExtensions => expiringSoonExtensions.isNotEmpty;

  factory ActiveExtensionSummary.fromJson(Map<String, dynamic> json) {
    final extensionsList = (json['extensions'] as List?)
            ?.map((e) => ActiveExtension.fromJson(e))
            .toList() ??
        [];

    final totalByItemMap = (json['total_by_item'] as Map<String, dynamic>?)
            ?.map((key, value) => MapEntry(key, value as int)) ??
        {};

    return ActiveExtensionSummary(
      extensions: extensionsList,
      totalByItem: totalByItemMap,
    );
  }

  factory ActiveExtensionSummary.empty() {
    return const ActiveExtensionSummary(
      extensions: [],
      totalByItem: {},
    );
  }

  @override
  List<Object?> get props => [extensions, totalByItem];
}
