/// Defect Inspection Report - List view model
class InspectionReport {
  final String name;
  final String postingDate;
  final String postingTime;
  final String purpose;
  final String warehouse;
  final String? purchaseInvoice;
  final int docstatus;

  InspectionReport({
    required this.name,
    required this.postingDate,
    required this.postingTime,
    required this.purpose,
    required this.warehouse,
    this.purchaseInvoice,
    required this.docstatus,
  });

  factory InspectionReport.fromJson(Map<String, dynamic> json) {
    return InspectionReport(
      name: json['name'] ?? '',
      postingDate: json['posting_date'] ?? '',
      postingTime: json['posting_time'] ?? '',
      purpose: json['purpose'] ?? '',
      warehouse: json['warehouse'] ?? '',
      purchaseInvoice: json['purchase_invoice'],
      docstatus: json['docstatus'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'posting_date': postingDate,
      'posting_time': postingTime,
      'purpose': purpose,
      'warehouse': warehouse,
      'purchase_invoice': purchaseInvoice,
      'docstatus': docstatus,
    };
  }

  /// Get human-readable status based on docstatus
  String get status {
    switch (docstatus) {
      case 0:
        return 'Draft';
      case 1:
        return 'Submitted';
      case 2:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}

/// Defect Inspection Report - Detail view model
class InspectionReportDetail {
  final String name;
  final String postingDate;
  final String postingTime;
  final String purpose;
  final String warehouse;
  final String? purchaseInvoice;
  final String company;
  final int docstatus;
  final List<InspectionReportItem> items;
  final List<InspectionReportLink> links;

  InspectionReportDetail({
    required this.name,
    required this.postingDate,
    required this.postingTime,
    required this.purpose,
    required this.warehouse,
    this.purchaseInvoice,
    required this.company,
    required this.docstatus,
    required this.items,
    required this.links,
  });

  factory InspectionReportDetail.fromJson(Map<String, dynamic> json) {
    return InspectionReportDetail(
      name: json['name'] ?? '',
      postingDate: json['posting_date'] ?? '',
      postingTime: json['posting_time'] ?? '',
      purpose: json['purpose'] ?? '',
      warehouse: json['warehouse'] ?? '',
      purchaseInvoice: json['purchase_invoice'],
      company: json['company'] ?? '',
      docstatus: json['docstatus'] ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => InspectionReportItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      links: (json['links'] as List<dynamic>?)
              ?.map((link) => InspectionReportLink.fromJson(link as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'posting_date': postingDate,
      'posting_time': postingTime,
      'purpose': purpose,
      'warehouse': warehouse,
      'purchase_invoice': purchaseInvoice,
      'company': company,
      'docstatus': docstatus,
      'items': items.map((item) => item.toJson()).toList(),
      'links': links.map((link) => link.toJson()).toList(),
    };
  }

  /// Get human-readable status based on docstatus
  String get status {
    switch (docstatus) {
      case 0:
        return 'Draft';
      case 1:
        return 'Submitted';
      case 2:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}

/// Individual item in the inspection report
class InspectionReportItem {
  final int idx;
  final String sourceItemCode;
  final String targetItemCode;
  final String cylinderNumber;
  final double tareWeight;
  final double grossWeight;
  final double netWeight;
  final String? faultType;
  final double qty;
  final String uom;

  InspectionReportItem({
    required this.idx,
    required this.sourceItemCode,
    required this.targetItemCode,
    required this.cylinderNumber,
    required this.tareWeight,
    required this.grossWeight,
    required this.netWeight,
    this.faultType,
    required this.qty,
    required this.uom,
  });

  factory InspectionReportItem.fromJson(Map<String, dynamic> json) {
    return InspectionReportItem(
      idx: json['idx'] ?? 0,
      sourceItemCode: json['source_item_code'] ?? '',
      targetItemCode: json['target_item_code'] ?? '',
      cylinderNumber: json['cylinder_number'] ?? '',
      tareWeight: (json['tare_weight'] ?? 0).toDouble(),
      grossWeight: (json['gross_weight'] ?? 0).toDouble(),
      netWeight: (json['net_weight'] ?? 0).toDouble(),
      faultType: json['fault_type'],
      qty: (json['qty'] ?? 1).toDouble(),
      uom: json['uom'] ?? 'Nos',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idx': idx,
      'source_item_code': sourceItemCode,
      'target_item_code': targetItemCode,
      'cylinder_number': cylinderNumber,
      'tare_weight': tareWeight,
      'gross_weight': grossWeight,
      'net_weight': netWeight,
      'fault_type': faultType,
      'qty': qty,
      'uom': uom,
    };
  }
}

/// Linked document (e.g., Stock Entry)
class InspectionReportLink {
  final String purpose;
  final String linkDoctype;
  final String linkName;

  InspectionReportLink({
    required this.purpose,
    required this.linkDoctype,
    required this.linkName,
  });

  factory InspectionReportLink.fromJson(Map<String, dynamic> json) {
    return InspectionReportLink(
      purpose: json['purpose'] ?? '',
      linkDoctype: json['link_doctype'] ?? '',
      linkName: json['link_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purpose': purpose,
      'link_doctype': linkDoctype,
      'link_name': linkName,
    };
  }
}
