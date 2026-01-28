import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/digital_credit/digital_credit.dart';
import '../../../domain/entities/digital_credit/claim_transfer.dart';
import '../../../domain/entities/digital_credit/claim_result.dart';
import '../../../utils/error_handler.dart';
import 'digital_credit_event.dart';
import 'digital_credit_state.dart';

class DigitalCreditBloc extends Bloc<DigitalCreditEvent, DigitalCreditState> {
  final ApiServiceInterface _apiService;
  List<DigitalCredit> _allCredits = [];
  List<ClaimTransfer> _allTransfers = [];

  // Expose apiService for direct access if needed
  ApiServiceInterface get apiService => _apiService;

  DigitalCreditBloc({required ApiServiceInterface apiService})
      : _apiService = apiService,
        super(DigitalCreditInitial()) {
    on<LoadDigitalCredits>(_onLoadDigitalCredits);
    on<RefreshDigitalCredits>(_onRefreshDigitalCredits);
    on<FilterDigitalCredits>(_onFilterDigitalCredits);
    on<SearchDigitalCredits>(_onSearchDigitalCredits);
    on<LoadCreditDetail>(_onLoadCreditDetail);
    on<CreateDigitalCredit>(_onCreateDigitalCredit);
    on<ClaimCredit>(_onClaimCredit);
    on<RetryCredit>(_onRetryCredit);
    on<LoadPendingTransfers>(_onLoadPendingTransfers);
    on<ApproveTransfer>(_onApproveTransfer);
    on<RejectTransfer>(_onRejectTransfer);
    on<ClearDigitalCreditCache>(_onClearCache);
  }

  Future<void> _onLoadDigitalCredits(
    LoadDigitalCredits event,
    Emitter<DigitalCreditState> emit,
  ) async {
    try {
      emit(DigitalCreditLoading());
      final response = await _apiService.getDigitalCredits();
      final credits = (response['results'] as List)
          .map((json) => DigitalCredit.fromJson(json))
          .toList();
      _allCredits = credits;
      emit(DigitalCreditLoaded(credits));
    } catch (e) {
      emit(DigitalCreditError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onRefreshDigitalCredits(
    RefreshDigitalCredits event,
    Emitter<DigitalCreditState> emit,
  ) async {
    // Same as load but preserves current filters if needed
    add(const LoadDigitalCredits());
  }

  Future<void> _onFilterDigitalCredits(
    FilterDigitalCredits event,
    Emitter<DigitalCreditState> emit,
  ) async {
    try {
      emit(DigitalCreditLoading());
      final response = await _apiService.getDigitalCredits(
        dataStatus: event.dataStatus,
        claimStatus: event.claimStatus,
        isMine: event.isMine,
      );
      final credits = (response['results'] as List)
          .map((json) => DigitalCredit.fromJson(json))
          .toList();
      _allCredits = credits;
      emit(DigitalCreditLoaded(credits));
    } catch (e) {
      emit(DigitalCreditError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onSearchDigitalCredits(
    SearchDigitalCredits event,
    Emitter<DigitalCreditState> emit,
  ) async {
    final query = event.query.toLowerCase();
    if (query.isEmpty) {
      emit(DigitalCreditLoaded(_allCredits));
      return;
    }

    final filtered = _allCredits.where((credit) {
      return credit.orderId.toLowerCase().contains(query) ||
          credit.consumerName?.toLowerCase().contains(query) == true;
    }).toList();

    emit(DigitalCreditLoaded(filtered));
  }

  Future<void> _onLoadCreditDetail(
    LoadCreditDetail event,
    Emitter<DigitalCreditState> emit,
  ) async {
    try {
      emit(CreditDetailLoading());
      final response = await _apiService.getDigitalCreditDetail(event.creditId);
      final credit = DigitalCredit.fromJson(response);
      emit(CreditDetailLoaded(credit));
    } catch (e) {
      emit(CreditDetailError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onCreateDigitalCredit(
    CreateDigitalCredit event,
    Emitter<DigitalCreditState> emit,
  ) async {
    try {
      emit(CreditCreating());
      final response = await _apiService.createDigitalCredit(
        orderId: event.orderId,
        orderDate: event.orderDate,
        autoClaim: event.autoClaim,
      );

      // Check for company mismatch error
      if (response.containsKey('error') &&
          response['error'] == 'ORDER_NOT_FOUND_IN_COMPANY') {
        emit(CompanyMismatchError(
          message: response['message'] ?? 'Order not found in current company',
          orderId: response['order_id'] ?? event.orderId,
          orderDate: response['order_date'] ?? event.orderDate,
          currentCompany: response['current_company'] ?? {},
          orderFoundIn: List<Map<String, dynamic>>.from(response['order_found_in'] ?? []),
        ));
        return;
      }

      final credit = DigitalCredit.fromJson(response);
      final message = credit.message ??
          (credit.alreadyExists == true
              ? 'Credit already exists for this order'
              : 'Credit created successfully');

      emit(CreditCreated(credit, message));

      // Refresh list after short delay
      await Future.delayed(const Duration(milliseconds: 300));
      add(const LoadDigitalCredits());
    } catch (e) {
      emit(DigitalCreditError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onClaimCredit(
    ClaimCredit event,
    Emitter<DigitalCreditState> emit,
  ) async {
    try {
      emit(CreditClaiming());
      final response = await _apiService.claimDigitalCredit(event.creditId);
      final result = ClaimResult.fromJson(response);
      emit(CreditClaimSuccess(result));

      // Refresh after claim
      await Future.delayed(const Duration(milliseconds: 300));
      add(LoadCreditDetail(event.creditId));
    } catch (e) {
      emit(DigitalCreditError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onRetryCredit(
    RetryCredit event,
    Emitter<DigitalCreditState> emit,
  ) async {
    try {
      emit(CreditDetailLoading());
      final response = await _apiService.retryDigitalCredit(event.creditId);
      final credit = DigitalCredit.fromJson(response['credit']);
      emit(CreditDetailLoaded(credit));
    } catch (e) {
      emit(CreditDetailError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onLoadPendingTransfers(
    LoadPendingTransfers event,
    Emitter<DigitalCreditState> emit,
  ) async {
    try {
      emit(TransfersLoading());
      final response = await _apiService.getClaimTransfers();
      final transfers = (response['results'] as List)
          .map((json) => ClaimTransfer.fromJson(json))
          .toList();
      _allTransfers = transfers;
      emit(TransfersLoaded(transfers));
    } catch (e) {
      emit(DigitalCreditError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onApproveTransfer(
    ApproveTransfer event,
    Emitter<DigitalCreditState> emit,
  ) async {
    try {
      emit(TransferActionLoading(event.transferId));
      final response = await _apiService.approveClaimTransfer(event.transferId);
      emit(TransferActionSuccess(response['message'] ?? 'Transfer approved'));

      // Refresh transfers list
      await Future.delayed(const Duration(milliseconds: 300));
      add(const LoadPendingTransfers());
    } catch (e) {
      emit(DigitalCreditError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onRejectTransfer(
    RejectTransfer event,
    Emitter<DigitalCreditState> emit,
  ) async {
    try {
      emit(TransferActionLoading(event.transferId));
      final response = await _apiService.rejectClaimTransfer(
        event.transferId,
        reason: event.reason,
      );
      emit(TransferActionSuccess(response['message'] ?? 'Transfer rejected'));

      // Refresh transfers list
      await Future.delayed(const Duration(milliseconds: 300));
      add(const LoadPendingTransfers());
    } catch (e) {
      emit(DigitalCreditError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onClearCache(
    ClearDigitalCreditCache event,
    Emitter<DigitalCreditState> emit,
  ) async {
    _allCredits = [];
    _allTransfers = [];
    emit(DigitalCreditInitial());
  }
}
