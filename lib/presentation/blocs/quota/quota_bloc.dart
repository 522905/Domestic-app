import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lpg_distribution_app/core/services/api_service_interface.dart';
import 'package:lpg_distribution_app/utils/error_handler.dart';
import 'quota_event.dart';
import 'quota_state.dart';

class QuotaBloc extends Bloc<QuotaEvent, QuotaState> {
  final ApiServiceInterface apiService;

  QuotaBloc({required this.apiService}) : super(QuotaInitial()) {
    on<LoadQuotaSnapshot>(_onLoadQuotaSnapshot);
    on<RefreshQuotaSnapshot>(_onRefreshQuotaSnapshot);
    on<TriggerQuotaSync>(_onTriggerQuotaSync);
  }

  Future<void> _onLoadQuotaSnapshot(
    LoadQuotaSnapshot event,
    Emitter<QuotaState> emit,
  ) async {
    emit(QuotaLoading());

    try {
      final snapshot = await apiService.getQuotaSnapshot();
      emit(QuotaLoaded(snapshot: snapshot));
    } catch (e) {
      String errorMessage = ErrorHandler.handleError(e);
      final isAccessDenied = e.toString().contains('403') ||
                             e.toString().contains('not a delivery boy');

      // Better error messages for common issues
      if (e.toString().contains('500')) {
        errorMessage = 'Server error. Please contact support or try again later.';
      } else if (e.toString().contains('MultipleObjectsReturned')) {
        errorMessage = 'Database configuration error. Please contact support.';
      }

      emit(QuotaError(
        message: errorMessage,
        isAccessDenied: isAccessDenied,
      ));
    }
  }

  Future<void> _onRefreshQuotaSnapshot(
    RefreshQuotaSnapshot event,
    Emitter<QuotaState> emit,
  ) async {
    // Keep current state while refreshing (don't show loading spinner)
    try {
      final snapshot = await apiService.getQuotaSnapshot();
      emit(QuotaLoaded(snapshot: snapshot));
    } catch (e) {
      String errorMessage = ErrorHandler.handleError(e);
      final isAccessDenied = e.toString().contains('403') ||
                             e.toString().contains('not a delivery boy');

      // Better error messages for common issues
      if (e.toString().contains('500')) {
        errorMessage = 'Server error. Please contact support or try again later.';
      } else if (e.toString().contains('MultipleObjectsReturned')) {
        errorMessage = 'Database configuration error. Please contact support.';
      }

      emit(QuotaError(
        message: errorMessage,
        isAccessDenied: isAccessDenied,
      ));
    }
  }

  Future<void> _onTriggerQuotaSync(
    TriggerQuotaSync event,
    Emitter<QuotaState> emit,
  ) async {
    if (state is! QuotaLoaded) return;

    final currentSnapshot = (state as QuotaLoaded).snapshot;
    emit(QuotaSyncInProgress(snapshot: currentSnapshot));

    try {
      await apiService.triggerQuotaSync();

      // Wait 2 seconds for sync to process, then refresh
      await Future.delayed(const Duration(seconds: 2));

      final snapshot = await apiService.getQuotaSnapshot();
      emit(QuotaLoaded(snapshot: snapshot));
    } catch (e) {
      // On sync error, revert to loaded state with error message shown in UI
      emit(QuotaLoaded(snapshot: currentSnapshot));
      // UI will show snackbar with error
    }
  }
}
