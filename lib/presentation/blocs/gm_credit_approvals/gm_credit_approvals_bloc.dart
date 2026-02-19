import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/credit_extension/credit_extension.dart';
import 'gm_credit_approvals_event.dart';
import 'gm_credit_approvals_state.dart';

class GmCreditApprovalsBloc
    extends Bloc<GmCreditApprovalsEvent, GmCreditApprovalsState> {
  final ApiServiceInterface apiService;

  GmCreditApprovalsBloc({required this.apiService})
      : super(GmCreditApprovalsInitial()) {
    on<LoadPendingApprovals>(_onLoadPendingApprovals);
    on<RefreshPendingApprovals>(_onRefreshPendingApprovals);
    on<ApproveExtension>(_onApproveExtension);
    on<RejectExtension>(_onRejectExtension);
    on<FilterApprovals>(_onFilterApprovals);
  }

  Future<void> _onLoadPendingApprovals(
    LoadPendingApprovals event,
    Emitter<GmCreditApprovalsState> emit,
  ) async {
    emit(GmCreditApprovalsLoading());

    try {
      final response = await apiService.getPendingCreditExtensions(
        partnerId: event.partnerId,
        itemCode: event.itemCode,
      );

      final approvalsList = (response['results'] as List)
          .map((json) => CreditExtension.fromJson(json))
          .toList();

      emit(GmCreditApprovalsLoaded(
        pendingApprovals: approvalsList,
        currentPartnerId: event.partnerId,
        currentItemCode: event.itemCode,
      ));
    } catch (e) {
      emit(GmCreditApprovalsError(e.toString()));
    }
  }

  Future<void> _onRefreshPendingApprovals(
    RefreshPendingApprovals event,
    Emitter<GmCreditApprovalsState> emit,
  ) async {
    try {
      final response = await apiService.getPendingCreditExtensions();

      final approvalsList = (response['results'] as List)
          .map((json) => CreditExtension.fromJson(json))
          .toList();

      emit(GmCreditApprovalsLoaded(
        pendingApprovals: approvalsList,
      ));
    } catch (e) {
      emit(GmCreditApprovalsError(e.toString()));
    }
  }

  Future<void> _onApproveExtension(
    ApproveExtension event,
    Emitter<GmCreditApprovalsState> emit,
  ) async {
    // Add debug log at the very start
    print('🔵 BLoC: _onApproveExtension called for extension ${event.extensionId}');
    print('   Current state: ${state.runtimeType}');

    final currentState = state;

    // Only emit processing state if we're in Loaded state
    if (currentState is GmCreditApprovalsLoaded) {
      emit(GmCreditApprovalsProcessing(
        pendingApprovals: currentState.pendingApprovals,
        processingExtensionId: event.extensionId,
      ));
    }

    try {
      print('🔵 BLoC: Calling API service...');
      print('   Quantity: ${event.approvedQuantity}');
      print('   Valid Until: ${event.validUntil}');

      final response = await apiService.approveCreditExtension(
        extensionId: event.extensionId,
        approvedQuantity: event.approvedQuantity,
        validUntil: event.validUntil,
      );

      print('✅ BLoC: Approval successful - $response');

      // Remove approved extension from list if we have a loaded state
      final updatedList = currentState is GmCreditApprovalsLoaded
          ? currentState.pendingApprovals
              .where((ext) => ext.id != event.extensionId)
              .toList()
          : <CreditExtension>[];

      emit(GmCreditApprovalsSuccess(
        message: 'Extension approved successfully',
        updatedApprovals: updatedList,
      ));

      // Reload the list
      add(const RefreshPendingApprovals());
    } catch (e) {
      print('❌ BLoC: Approval failed - $e');

      String errorMessage = 'Failed to approve extension';
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Extension not found';
      } else if (e.toString().contains('403')) {
        errorMessage = 'You do not have permission to approve';
      } else if (e.toString().contains('Network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().isNotEmpty) {
        errorMessage = e.toString();
      }

      emit(GmCreditApprovalsError(errorMessage));
      // Restore previous state only if it was a loaded state
      if (currentState is GmCreditApprovalsLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onRejectExtension(
    RejectExtension event,
    Emitter<GmCreditApprovalsState> emit,
  ) async {
    // Add debug log at the very start
    print('🔴 BLoC: _onRejectExtension called for extension ${event.extensionId}');
    print('   Current state: ${state.runtimeType}');

    final currentState = state;

    // Only emit processing state if we're in Loaded state
    if (currentState is GmCreditApprovalsLoaded) {
      emit(GmCreditApprovalsProcessing(
        pendingApprovals: currentState.pendingApprovals,
        processingExtensionId: event.extensionId,
      ));
    }

    try {
      print('🔴 BLoC: Calling API service...');
      print('   Reason: ${event.rejectionReason}');

      final response = await apiService.rejectCreditExtension(
        extensionId: event.extensionId,
        rejectionReason: event.rejectionReason,
      );

      print('✅ BLoC: Rejection successful - $response');

      // Remove rejected extension from list if we have a loaded state
      final updatedList = currentState is GmCreditApprovalsLoaded
          ? currentState.pendingApprovals
              .where((ext) => ext.id != event.extensionId)
              .toList()
          : <CreditExtension>[];

      emit(GmCreditApprovalsSuccess(
        message: 'Extension rejected successfully',
        updatedApprovals: updatedList,
      ));

      // Reload the list
      add(const RefreshPendingApprovals());
    } catch (e) {
      print('❌ BLoC: Rejection failed - $e');

      String errorMessage = 'Failed to reject extension';
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Extension not found';
      } else if (e.toString().contains('403')) {
        errorMessage = 'You do not have permission to reject';
      } else if (e.toString().contains('Network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().isNotEmpty) {
        errorMessage = e.toString();
      }

      emit(GmCreditApprovalsError(errorMessage));
      // Restore previous state only if it was a loaded state
      if (currentState is GmCreditApprovalsLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onFilterApprovals(
    FilterApprovals event,
    Emitter<GmCreditApprovalsState> emit,
  ) async {
    emit(GmCreditApprovalsLoading());

    try {
      final response = await apiService.getPendingCreditExtensions(
        partnerId: event.partnerId,
        itemCode: event.itemCode,
      );

      final approvalsList = (response['results'] as List)
          .map((json) => CreditExtension.fromJson(json))
          .toList();

      emit(GmCreditApprovalsLoaded(
        pendingApprovals: approvalsList,
        currentPartnerId: event.partnerId,
        currentItemCode: event.itemCode,
      ));
    } catch (e) {
      emit(GmCreditApprovalsError(e.toString()));
    }
  }
}
