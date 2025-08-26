class SelectableDepositItem {
  final String id;
  final String itemCode;
  final String itemName;
  final String description;
  final String type;
  final int maxQuantity;
  final Map<String, dynamic> metadata;

  SelectableDepositItem({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.description,
    required this.type,
    required this.maxQuantity,
    required this.metadata,
  });

  String get displayName => itemName.isNotEmpty ? itemName : itemCode;

  Map<String, dynamic> toApiPayload(int selectedQuantity) {
    final payload = {
      "item_code": itemCode,
      "qty": selectedQuantity,
    };

    // Add type-specific fields
    if (metadata['sales_order_item'] != null) {
      payload["sales_order_item"] = metadata['sales_order_item'];
    }
    if (metadata['material_request'] != null) {
      payload["material_request"] = metadata['material_request'];
    }
    if (metadata['item_row_name'] != null) {
      payload["item_row_name"] = metadata['item_row_name'];
    }

    return payload;
  }
}