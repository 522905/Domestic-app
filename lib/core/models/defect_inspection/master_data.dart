/// Master data for defect inspection - contains filled items with stock and defective options
class MasterDataResponse {
  final String warehouse;
  final String? purchaseInvoice;
  final List<FilledItemMasterData> items;

  MasterDataResponse({
    required this.warehouse,
    this.purchaseInvoice,
    required this.items,
  });

  factory MasterDataResponse.fromJson(Map<String, dynamic> json) {
    return MasterDataResponse(
      warehouse: json['warehouse'] ?? '',
      purchaseInvoice: json['purchase_invoice'],
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => FilledItemMasterData.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouse': warehouse,
      'purchase_invoice': purchaseInvoice,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

/// Filled item with available stock and valid defective options
class FilledItemMasterData {
  final String sourceItemCode;
  final String sourceItemName;
  final double availableStock;
  final List<DefectiveOption> defectiveOptions;

  FilledItemMasterData({
    required this.sourceItemCode,
    required this.sourceItemName,
    required this.availableStock,
    required this.defectiveOptions,
  });

  factory FilledItemMasterData.fromJson(Map<String, dynamic> json) {
    return FilledItemMasterData(
      sourceItemCode: json['source_item_code'] ?? '',
      sourceItemName: json['source_item_name'] ?? '',
      availableStock: (json['available_stock'] ?? 0).toDouble(),
      defectiveOptions: (json['defective_options'] as List<dynamic>?)
              ?.map((opt) => DefectiveOption.fromJson(opt as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source_item_code': sourceItemCode,
      'source_item_name': sourceItemName,
      'available_stock': availableStock,
      'defective_options': defectiveOptions.map((opt) => opt.toJson()).toList(),
    };
  }
}

/// Defective item option (target item for conversion)
class DefectiveOption {
  final String itemCode;
  final String itemName;
  final String description;

  DefectiveOption({
    required this.itemCode,
    required this.itemName,
    required this.description,
  });

  factory DefectiveOption.fromJson(Map<String, dynamic> json) {
    return DefectiveOption(
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'description': description,
    };
  }
}
