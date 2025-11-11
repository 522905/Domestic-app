import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/defect_service.dart';
import '../../../utils/error_handler.dart';
import 'defect_inspection_event.dart';
import 'defect_inspection_state.dart';

/// BLoC for managing defect inspection operations
class DefectInspectionBloc extends Bloc<DefectInspectionEvent, DefectInspectionState> {
  final DefectService _defectService;

  // Expose service for direct access if needed
  DefectService get defectService => _defectService;

  DefectInspectionBloc({
    required DefectService defectService,
  })  : _defectService = defectService,
        super(const DefectInspectionInitial()) {
    // Register event handlers
    on<LoadMasterDataEvent>(_onLoadMasterData);
    on<LoadPurchaseInvoicesEvent>(_onLoadPurchaseInvoices);
    on<SubmitDIREvent>(_onSubmitDIR);
    on<ResetDIRCreationEvent>(_onResetDIRCreation);
    on<LoadInspectionReportsEvent>(_onLoadInspectionReports);
    on<RefreshInspectionReportsEvent>(_onRefreshInspectionReports);
    on<LoadInspectionReportDetailEvent>(_onLoadInspectionReportDetail);
    on<RefreshInspectionReportDetailEvent>(_onRefreshInspectionReportDetail);
  }

  /// Load master data for defect inspection
  Future<void> _onLoadMasterData(
    LoadMasterDataEvent event,
    Emitter<DefectInspectionState> emit,
  ) async {
    try {
      emit(const MasterDataLoading());

      final masterData = await _defectService.getMasterData(
        warehouse: event.warehouse,
        purchaseInvoice: event.purchaseInvoice,
      );

      emit(MasterDataLoaded(masterData: masterData));
    } catch (e) {
      emit(MasterDataError(message: ErrorHandler.handleError(e)));
    }
  }

  /// Load purchase invoices for warehouse
  Future<void> _onLoadPurchaseInvoices(
    LoadPurchaseInvoicesEvent event,
    Emitter<DefectInspectionState> emit,
  ) async {
    try {
      emit(const PurchaseInvoicesLoading());

      final purchaseInvoices = await _defectService.getPurchaseInvoices(
        warehouse: event.warehouse,
      );

      emit(PurchaseInvoicesLoaded(purchaseInvoices: purchaseInvoices));
    } catch (e) {
      emit(PurchaseInvoicesError(message: ErrorHandler.handleError(e)));
    }
  }

  /// Submit DIR for creation
  Future<void> _onSubmitDIR(
    SubmitDIREvent event,
    Emitter<DefectInspectionState> emit,
  ) async {
    try {
      emit(const DIRSubmitting());

      final dirName = await _defectService.createDIR(event.request);

      emit(DIRSubmitted(
        dirName: dirName,
        message: 'Defect Inspection Report created successfully',
      ));
    } on DIRValidationException catch (e) {
      // Specific handling for validation errors
      emit(DIRSubmissionError(
        message: e.message,
        details: e.details?.toString(),
      ));
    } catch (e) {
      emit(DIRSubmissionError(
        message: ErrorHandler.handleError(e),
      ));
    }
  }

  /// Reset DIR creation state
  Future<void> _onResetDIRCreation(
    ResetDIRCreationEvent event,
    Emitter<DefectInspectionState> emit,
  ) async {
    emit(const DefectInspectionInitial());
  }

  /// Load inspection reports list
  Future<void> _onLoadInspectionReports(
    LoadInspectionReportsEvent event,
    Emitter<DefectInspectionState> emit,
  ) async {
    try {
      emit(const InspectionReportsLoading());

      final reports = await _defectService.getInspectionReports(
        warehouse: event.warehouse,
      );

      emit(InspectionReportsLoaded(reports: reports));
    } catch (e) {
      emit(InspectionReportsError(message: ErrorHandler.handleError(e)));
    }
  }

  /// Refresh inspection reports list
  Future<void> _onRefreshInspectionReports(
    RefreshInspectionReportsEvent event,
    Emitter<DefectInspectionState> emit,
  ) async {
    try {
      // Keep current reports visible during refresh
      if (state is InspectionReportsLoaded) {
        final currentReports = (state as InspectionReportsLoaded).reports;
        emit(InspectionReportsRefreshing(currentReports: currentReports));
      } else {
        emit(const InspectionReportsLoading());
      }

      final reports = await _defectService.getInspectionReports(
        warehouse: event.warehouse,
      );

      emit(InspectionReportsLoaded(reports: reports));
    } catch (e) {
      emit(InspectionReportsError(message: ErrorHandler.handleError(e)));
    }
  }

  /// Load inspection report detail
  Future<void> _onLoadInspectionReportDetail(
    LoadInspectionReportDetailEvent event,
    Emitter<DefectInspectionState> emit,
  ) async {
    try {
      emit(const InspectionReportDetailLoading());

      final reportDetail = await _defectService.getInspectionReportDetail(
        name: event.dirName,
      );

      emit(InspectionReportDetailLoaded(reportDetail: reportDetail));
    } on NotFoundException catch (e) {
      emit(InspectionReportDetailError(message: e.message));
    } catch (e) {
      emit(InspectionReportDetailError(message: ErrorHandler.handleError(e)));
    }
  }

  /// Refresh inspection report detail
  Future<void> _onRefreshInspectionReportDetail(
    RefreshInspectionReportDetailEvent event,
    Emitter<DefectInspectionState> emit,
  ) async {
    try {
      // Keep current detail visible during refresh
      if (state is InspectionReportDetailLoaded) {
        final currentDetail = (state as InspectionReportDetailLoaded).reportDetail;
        emit(InspectionReportDetailRefreshing(currentDetail: currentDetail));
      } else {
        emit(const InspectionReportDetailLoading());
      }

      final reportDetail = await _defectService.getInspectionReportDetail(
        name: event.dirName,
      );

      emit(InspectionReportDetailLoaded(reportDetail: reportDetail));
    } on NotFoundException catch (e) {
      emit(InspectionReportDetailError(message: e.message));
    } catch (e) {
      emit(InspectionReportDetailError(message: ErrorHandler.handleError(e)));
    }
  }
}
