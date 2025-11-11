/// DIR Item - represents a single defective cylinder in the inspection report
class DIRItem {
  final String sourceItemCode;
  final String sourceItemName;
  final String targetItemCode;
  final String targetItemName;
  final String cylinderNumber;
  final double tareWeight;
  final double grossWeight;
  final String? faultType;

  DIRItem({
    required this.sourceItemCode,
    required this.sourceItemName,
    required this.targetItemCode,
    required this.targetItemName,
    required this.cylinderNumber,
    required this.tareWeight,
    required this.grossWeight,
    this.faultType,
  });

  /// Auto-calculated net weight
  double get netWeight => grossWeight - tareWeight;

  /// Check if weights are valid
  bool get isWeightValid => tareWeight > 0 && grossWeight > tareWeight;

  Map<String, dynamic> toJson() {
    return {
      'source_item_code': sourceItemCode,
      'target_item_code': targetItemCode,
      'cylinder_number': cylinderNumber,
      'tare_weight': tareWeight,
      'gross_weight': grossWeight,
      if (faultType != null && faultType!.isNotEmpty) 'fault_type': faultType,
    };
  }

  /// Create a copy with updated fields
  DIRItem copyWith({
    String? sourceItemCode,
    String? sourceItemName,
    String? targetItemCode,
    String? targetItemName,
    String? cylinderNumber,
    double? tareWeight,
    double? grossWeight,
    String? faultType,
  }) {
    return DIRItem(
      sourceItemCode: sourceItemCode ?? this.sourceItemCode,
      sourceItemName: sourceItemName ?? this.sourceItemName,
      targetItemCode: targetItemCode ?? this.targetItemCode,
      targetItemName: targetItemName ?? this.targetItemName,
      cylinderNumber: cylinderNumber ?? this.cylinderNumber,
      tareWeight: tareWeight ?? this.tareWeight,
      grossWeight: grossWeight ?? this.grossWeight,
      faultType: faultType ?? this.faultType,
    );
  }
}

/// Request payload for creating DIR
class CreateDIRRequest {
  final String company;
  final String warehouse;
  final String purpose;
  final String? purchaseInvoice;
  final String? postingDate;
  final String? postingTime;
  final List<DIRItem> items;

  CreateDIRRequest({
    required this.company,
    required this.warehouse,
    required this.purpose,
    this.purchaseInvoice,
    this.postingDate,
    this.postingTime,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'warehouse': warehouse,
      'purpose': purpose,
      if (purchaseInvoice != null && purchaseInvoice!.isNotEmpty)
        'purchase_invoice': purchaseInvoice,
      if (postingDate != null) 'posting_date': postingDate,
      if (postingTime != null) 'posting_time': postingTime,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
