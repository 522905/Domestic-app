// lib/core/models/purchase_invoice.dart
class PurchaseInvoice {
  final String supplierGstin;
  final String supplierInvoiceDate;
  final String supplierInvoiceNumber;
  final String supplierName;
  final String vehicleNo;
  final double grandTotal;
  final String sapDocNumber;
  final String plant;
  final String statusType;
  final String workflowStatus;
  final String workflowStatusDisplay;
  final String? postingStatus;
  final bool postingFailed;
  final int? workflowId;
  final String? transportName;
  final String? transportContactPhone;
  final String? outByDate;
  final bool locked;
  final String? lockType;
  final String? createdAt;

  PurchaseInvoice({
    required this.supplierGstin,
    required this.supplierInvoiceDate,
    required this.supplierInvoiceNumber,
    required this.supplierName,
    required this.vehicleNo,
    required this.grandTotal,
    required this.sapDocNumber,
    required this.plant,
    required this.statusType,
    required this.workflowStatus,
    required this.workflowStatusDisplay,
    this.postingStatus,
    required this.postingFailed,
    this.workflowId,
    this.transportName,
    this.transportContactPhone,
    this.outByDate,
    required this.locked,
    this.lockType,
    this.createdAt,
  });

  factory PurchaseInvoice.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoice(
      supplierGstin: json['supplier_gstin'] ?? '',
      supplierInvoiceDate: json['supplier_invoice_date'] ?? '',
      supplierInvoiceNumber: json['supplier_invoice_number'] ?? '',
      supplierName: json['supplier_name'] ?? '',
      vehicleNo: json['vehicle_no'] ?? '',
      grandTotal: (json['grand_total'] ?? 0.0).toDouble(),
      sapDocNumber: json['sap_doc_number'] ?? '',
      plant: json['plant'] ?? '',
      statusType: json['status_type'] ?? 'pending',
      workflowStatus: json['workflow_status'] ?? 'pending',
      workflowStatusDisplay: json['workflow_status_display'] ?? 'Pending',
      postingStatus: json['posting_status'],
      postingFailed: json['posting_failed'] ?? false,
      workflowId: json['workflow_id'],
      transportName: json['transport_name'],
      transportContactPhone: json['transport_contact_phone'],
      outByDate: json['out_by_date'],
      locked: json['locked'] ?? false,
      lockType: json['lock_type'],
      createdAt: json['created_at'],
    );
  }
}