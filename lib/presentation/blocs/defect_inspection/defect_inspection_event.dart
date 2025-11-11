import 'package:equatable/equatable.dart';
import '../../../core/models/defect_inspection/dir_item.dart';

/// Base event for defect inspection
abstract class DefectInspectionEvent extends Equatable {
  const DefectInspectionEvent();

  @override
  List<Object?> get props => [];
}

// ============ Master Data Events ============

/// Load master data for defect inspection
class LoadMasterDataEvent extends DefectInspectionEvent {
  final String warehouse;
  final String? purchaseInvoice;

  const LoadMasterDataEvent({
    required this.warehouse,
    this.purchaseInvoice,
  });

  @override
  List<Object?> get props => [warehouse, purchaseInvoice];
}

// ============ Purchase Invoice Events ============

/// Load purchase invoices for warehouse
class LoadPurchaseInvoicesEvent extends DefectInspectionEvent {
  final String warehouse;

  const LoadPurchaseInvoicesEvent({
    required this.warehouse,
  });

  @override
  List<Object?> get props => [warehouse];
}

// ============ DIR Creation Events ============

/// Submit DIR for creation
class SubmitDIREvent extends DefectInspectionEvent {
  final CreateDIRRequest request;

  const SubmitDIREvent({
    required this.request,
  });

  @override
  List<Object?> get props => [request];
}

/// Reset DIR creation state
class ResetDIRCreationEvent extends DefectInspectionEvent {
  const ResetDIRCreationEvent();
}

// ============ DIR List Events ============

/// Load inspection reports list
class LoadInspectionReportsEvent extends DefectInspectionEvent {
  final String? warehouse;

  const LoadInspectionReportsEvent({
    this.warehouse,
  });

  @override
  List<Object?> get props => [warehouse];
}

/// Refresh inspection reports list
class RefreshInspectionReportsEvent extends DefectInspectionEvent {
  final String? warehouse;

  const RefreshInspectionReportsEvent({
    this.warehouse,
  });

  @override
  List<Object?> get props => [warehouse];
}

// ============ DIR Detail Events ============

/// Load inspection report detail
class LoadInspectionReportDetailEvent extends DefectInspectionEvent {
  final String dirName;

  const LoadInspectionReportDetailEvent({
    required this.dirName,
  });

  @override
  List<Object?> get props => [dirName];
}

/// Refresh inspection report detail
class RefreshInspectionReportDetailEvent extends DefectInspectionEvent {
  final String dirName;

  const RefreshInspectionReportDetailEvent({
    required this.dirName,
  });

  @override
  List<Object?> get props => [dirName];
}
