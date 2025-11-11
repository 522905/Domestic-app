/// Simplified Purchase Invoice model for defect inspection list
class PurchaseInvoice {
  final String name;
  final String postingDate;
  final String supplier;
  final String setWarehouse;
  final double grandTotal;
  final String company;

  PurchaseInvoice({
    required this.name,
    required this.postingDate,
    required this.supplier,
    required this.setWarehouse,
    required this.grandTotal,
    required this.company,
  });

  factory PurchaseInvoice.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoice(
      name: json['name'] ?? '',
      postingDate: json['posting_date'] ?? '',
      supplier: json['supplier'] ?? '',
      setWarehouse: json['set_warehouse'] ?? '',
      grandTotal: (json['grand_total'] ?? 0).toDouble(),
      company: json['company'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'posting_date': postingDate,
      'supplier': supplier,
      'set_warehouse': setWarehouse,
      'grand_total': grandTotal,
      'company': company,
    };
  }
}

/// Pre-populated data when navigating from PI to DIR creation
class DIRPrePopulated {
  final String purchaseInvoice;
  final String warehouse;
  final String purpose;
  final String company;

  DIRPrePopulated({
    required this.purchaseInvoice,
    required this.warehouse,
    required this.purpose,
    required this.company,
  });
}
