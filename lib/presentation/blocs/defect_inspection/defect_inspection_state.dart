import 'package:equatable/equatable.dart';
import '../../../core/models/defect_inspection/master_data.dart';
import '../../../core/models/defect_inspection/purchase_invoice.dart';
import '../../../core/models/defect_inspection/defect_inspection_report.dart';

/// Base state for defect inspection
abstract class DefectInspectionState extends Equatable {
  const DefectInspectionState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DefectInspectionInitial extends DefectInspectionState {
  const DefectInspectionInitial();
}

// ============ Master Data States ============

/// Loading master data
class MasterDataLoading extends DefectInspectionState {
  const MasterDataLoading();
}

/// Master data loaded successfully
class MasterDataLoaded extends DefectInspectionState {
  final MasterDataResponse masterData;

  const MasterDataLoaded({
    required this.masterData,
  });

  @override
  List<Object?> get props => [masterData];
}

/// Master data load failed
class MasterDataError extends DefectInspectionState {
  final String message;

  const MasterDataError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

// ============ Purchase Invoice States ============

/// Loading purchase invoices
class PurchaseInvoicesLoading extends DefectInspectionState {
  const PurchaseInvoicesLoading();
}

/// Purchase invoices loaded successfully
class PurchaseInvoicesLoaded extends DefectInspectionState {
  final List<PurchaseInvoice> purchaseInvoices;

  const PurchaseInvoicesLoaded({
    required this.purchaseInvoices,
  });

  @override
  List<Object?> get props => [purchaseInvoices];
}

/// Purchase invoices load failed
class PurchaseInvoicesError extends DefectInspectionState {
  final String message;

  const PurchaseInvoicesError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

// ============ DIR Creation States ============

/// Submitting DIR
class DIRSubmitting extends DefectInspectionState {
  const DIRSubmitting();
}

/// DIR submitted successfully
class DIRSubmitted extends DefectInspectionState {
  final String dirName;
  final String message;

  const DIRSubmitted({
    required this.dirName,
    required this.message,
  });

  @override
  List<Object?> get props => [dirName, message];
}

/// DIR submission failed
class DIRSubmissionError extends DefectInspectionState {
  final String message;
  final String? details;

  const DIRSubmissionError({
    required this.message,
    this.details,
  });

  @override
  List<Object?> get props => [message, details];
}

// ============ DIR List States ============

/// Loading inspection reports
class InspectionReportsLoading extends DefectInspectionState {
  const InspectionReportsLoading();
}

/// Inspection reports loaded successfully
class InspectionReportsLoaded extends DefectInspectionState {
  final List<InspectionReport> reports;

  const InspectionReportsLoaded({
    required this.reports,
  });

  @override
  List<Object?> get props => [reports];
}

/// Inspection reports load failed
class InspectionReportsError extends DefectInspectionState {
  final String message;

  const InspectionReportsError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

/// Refreshing inspection reports
class InspectionReportsRefreshing extends DefectInspectionState {
  final List<InspectionReport> currentReports;

  const InspectionReportsRefreshing({
    required this.currentReports,
  });

  @override
  List<Object?> get props => [currentReports];
}

// ============ DIR Detail States ============

/// Loading inspection report detail
class InspectionReportDetailLoading extends DefectInspectionState {
  const InspectionReportDetailLoading();
}

/// Inspection report detail loaded successfully
class InspectionReportDetailLoaded extends DefectInspectionState {
  final InspectionReportDetail reportDetail;

  const InspectionReportDetailLoaded({
    required this.reportDetail,
  });

  @override
  List<Object?> get props => [reportDetail];
}

/// Inspection report detail load failed
class InspectionReportDetailError extends DefectInspectionState {
  final String message;

  const InspectionReportDetailError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

/// Refreshing inspection report detail
class InspectionReportDetailRefreshing extends DefectInspectionState {
  final InspectionReportDetail currentDetail;

  const InspectionReportDetailRefreshing({
    required this.currentDetail,
  });

  @override
  List<Object?> get props => [currentDetail];
}
