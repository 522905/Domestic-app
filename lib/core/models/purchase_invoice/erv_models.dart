// lib/core/models/purchase_invoice/erv_models.dart

/// Helper function to safely parse double values from dynamic types
/// Handles String, int, double, and null values
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Represents a serial number with its details
class SerialDetail {
  final String serialNo;
  final String itemCode;
  final double customNetWeightOfCylinder;
  final String customFaultType;
  final bool fromThisPi;
  final bool isAvailable;

  SerialDetail({
    required this.serialNo,
    required this.itemCode,
    required this.customNetWeightOfCylinder,
    required this.customFaultType,
    required this.fromThisPi,
    required this.isAvailable,
  });

  factory SerialDetail.fromJson(Map<String, dynamic> json) {
    return SerialDetail(
      serialNo: json['serial_no'] ?? '',
      itemCode: json['item_code'] ?? '',
      customNetWeightOfCylinder: _parseDouble(json['custom_net_weight_of_cylinder']),
      customFaultType: json['custom_fault_type'] ?? '',
      fromThisPi: json['from_this_pi'] ?? false,
      isAvailable: json['is_available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serial_no': serialNo,
      'item_code': itemCode,
      'custom_net_weight_of_cylinder': customNetWeightOfCylinder,
      'custom_fault_type': customFaultType,
      'from_this_pi': fromThisPi,
      'is_available': isAvailable,
    };
  }
}

/// Represents a defective item with serials
class DefectiveItem {
  final String itemCode;
  final String itemName;
  final String? mapsToFilled;
  final double availableQty;
  final List<SerialDetail> serials;

  DefectiveItem({
    required this.itemCode,
    required this.itemName,
    this.mapsToFilled,
    required this.availableQty,
    required this.serials,
  });

  factory DefectiveItem.fromJson(Map<String, dynamic> json) {
    return DefectiveItem(
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      mapsToFilled: json['maps_to_filled'],
      availableQty: _parseDouble(json['available_qty']),
      serials: (json['serials'] as List<dynamic>?)
          ?.map((s) => SerialDetail.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'maps_to_filled': mapsToFilled,
      'available_qty': availableQty,
      'serials': serials.map((s) => s.toJson()).toList(),
    };
  }
}

/// Represents an empty item (non-serialized)
class EmptyItem {
  final String itemCode;
  final String itemName;
  final String? mapsToFilled;
  final double availableQty;

  EmptyItem({
    required this.itemCode,
    required this.itemName,
    this.mapsToFilled,
    required this.availableQty,
  });

  factory EmptyItem.fromJson(Map<String, dynamic> json) {
    return EmptyItem(
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      mapsToFilled: json['maps_to_filled'],
      availableQty: _parseDouble(json['available_qty']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'maps_to_filled': mapsToFilled,
      'available_qty': availableQty,
    };
  }
}

/// Represents preselection for defective items
class DefectivePreselection {
  final String itemCode;
  final double qty;
  final List<SerialDetail> serials;

  DefectivePreselection({
    required this.itemCode,
    required this.qty,
    required this.serials,
  });

  factory DefectivePreselection.fromJson(Map<String, dynamic> json) {
    return DefectivePreselection(
      itemCode: json['item_code'] ?? '',
      qty: _parseDouble(json['qty']),
      serials: (json['serials'] as List<dynamic>?)
          ?.map((s) => SerialDetail.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'qty': qty,
      'serials': serials.map((s) => s.toJson()).toList(),
    };
  }
}

/// Represents preselection for empty items
class EmptyPreselection {
  final String itemCode;
  final double qty;

  EmptyPreselection({
    required this.itemCode,
    required this.qty,
  });

  factory EmptyPreselection.fromJson(Map<String, dynamic> json) {
    return EmptyPreselection(
      itemCode: json['item_code'] ?? '',
      qty: _parseDouble(json['qty']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'qty': qty,
    };
  }
}

/// Represents preselections (defective and empty)
class Preselections {
  final DefectivePreselection defective;
  final EmptyPreselection empty;

  Preselections({
    required this.defective,
    required this.empty,
  });

  factory Preselections.fromJson(Map<String, dynamic> json) {
    return Preselections(
      defective: DefectivePreselection.fromJson(json['defective'] as Map<String, dynamic>),
      empty: EmptyPreselection.fromJson(json['empty'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defective': defective.toJson(),
      'empty': empty.toJson(),
    };
  }
}

/// Represents a required group (for Equal mode)
class RequiredGroup {
  final String filledItemCode;
  final String filledItemName;
  final String purchaseInvoiceItem;
  final double targetQty;
  final double receivedQtyCap;
  final Preselections preselections;

  RequiredGroup({
    required this.filledItemCode,
    required this.filledItemName,
    required this.purchaseInvoiceItem,
    required this.targetQty,
    required this.receivedQtyCap,
    required this.preselections,
  });

  factory RequiredGroup.fromJson(Map<String, dynamic> json) {
    return RequiredGroup(
      filledItemCode: json['filled_item_code'] ?? '',
      filledItemName: json['filled_item_name'] ?? '',
      purchaseInvoiceItem: json['purchase_invoice_item'] ?? '',
      targetQty: _parseDouble(json['target_qty']),
      receivedQtyCap: _parseDouble(json['received_qty_cap']),
      preselections: Preselections.fromJson(json['preselections'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filled_item_code': filledItemCode,
      'filled_item_name': filledItemName,
      'purchase_invoice_item': purchaseInvoiceItem,
      'target_qty': targetQty,
      'received_qty_cap': receivedQtyCap,
      'preselections': preselections.toJson(),
    };
  }
}

/// Represents invoice details
class InvoiceDetails {
  final String purchaseInvoice;
  final String supplier;
  final String supplierName;
  final String warehouse;
  final double grandTotal;
  final String postingDate;
  final String billNo;
  final String billDate;

  InvoiceDetails({
    required this.purchaseInvoice,
    required this.supplier,
    required this.supplierName,
    required this.warehouse,
    required this.grandTotal,
    required this.postingDate,
    required this.billNo,
    required this.billDate,
  });

  factory InvoiceDetails.fromJson(Map<String, dynamic> json) {
    return InvoiceDetails(
      purchaseInvoice: json['purchase_invoice'] ?? '',
      supplier: json['supplier'] ?? '',
      supplierName: json['supplier_name'] ?? '',
      warehouse: json['warehouse'] ?? '',
      grandTotal: _parseDouble(json['grand_total']),
      postingDate: json['posting_date'] ?? '',
      billNo: json['bill_no'] ?? '',
      billDate: json['bill_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchase_invoice': purchaseInvoice,
      'supplier': supplier,
      'supplier_name': supplierName,
      'warehouse': warehouse,
      'grand_total': grandTotal,
      'posting_date': postingDate,
      'bill_no': billNo,
      'bill_date': billDate,
    };
  }
}

/// Represents available items (both defective and empty)
class AvailableItems {
  final List<DefectiveItem> defective;
  final List<EmptyItem> empty;

  AvailableItems({
    required this.defective,
    required this.empty,
  });

  factory AvailableItems.fromJson(Map<String, dynamic> json) {
    return AvailableItems(
      defective: (json['defective'] as List<dynamic>?)
          ?.map((d) => DefectiveItem.fromJson(d as Map<String, dynamic>))
          .toList() ?? [],
      empty: (json['empty'] as List<dynamic>?)
          ?.map((e) => EmptyItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defective': defective.map((d) => d.toJson()).toList(),
      'empty': empty.map((e) => e.toJson()).toList(),
    };
  }
}

/// Represents the ERV calculation response data
class ERVData {
  final String mode; // "equal" or "unequal"
  final InvoiceDetails invoiceDetails;
  final List<RequiredGroup> requiredGroups;
  final AvailableItems availableItems;

  ERVData({
    required this.mode,
    required this.invoiceDetails,
    required this.requiredGroups,
    required this.availableItems,
  });

  factory ERVData.fromJson(Map<String, dynamic> json) {
    return ERVData(
      mode: json['mode'] ?? 'equal',
      invoiceDetails: InvoiceDetails.fromJson(json['invoice_details'] as Map<String, dynamic>),
      requiredGroups: (json['required_groups'] as List<dynamic>?)
          ?.map((g) => RequiredGroup.fromJson(g as Map<String, dynamic>))
          .toList() ?? [],
      availableItems: AvailableItems.fromJson(json['available_items'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'invoice_details': invoiceDetails.toJson(),
      'required_groups': requiredGroups.map((g) => g.toJson()).toList(),
      'available_items': availableItems.toJson(),
    };
  }
}

/// Represents the complete ERV calculation response
class ERVCalculationResponse {
  final bool success;
  final ERVData data;

  ERVCalculationResponse({
    required this.success,
    required this.data,
  });

  factory ERVCalculationResponse.fromJson(Map<String, dynamic> json) {
    return ERVCalculationResponse(
      success: json['success'] ?? false,
      data: ERVData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.toJson(),
    };
  }
}
