import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/quota/quota_history_response.dart';
import '../../../domain/entities/quota/quota_history_detail_response.dart';
import '../../../domain/entities/quota/quota_history_filters.dart';
import '../../../utils/error_handler.dart';
import 'quota_history_event.dart';
import 'quota_history_state.dart';

class QuotaHistoryBloc extends Bloc<QuotaHistoryEvent, QuotaHistoryState> {
  final ApiServiceInterface apiService;
  final String? initialItemCode;

  QuotaHistoryBloc({
    required this.apiService,
    this.initialItemCode,
  }) : super(const QuotaHistoryInitial()) {
    on<LoadQuotaHistory>(_onLoadQuotaHistory);
    on<LoadMoreHistory>(_onLoadMoreHistory);
    on<UpdateHistoryFilters>(_onUpdateHistoryFilters);
    on<UpdateHistorySort>(_onUpdateHistorySort);
    on<LoadHistoryDetail>(_onLoadHistoryDetail);
  }

  Future<void> _onLoadQuotaHistory(
    LoadQuotaHistory event,
    Emitter<QuotaHistoryState> emit,
  ) async {
    // If refresh and already loaded, keep showing data while refreshing
    if (!event.refresh || state is! QuotaHistoryLoaded) {
      emit(const QuotaHistoryLoading());
    }

    try {
      final filters = state is QuotaHistoryLoaded
          ? (state as QuotaHistoryLoaded).filters
          : QuotaHistoryFilters(itemCode: initialItemCode);

      // Debug: Log what filters are being used
      print('QuotaHistoryBloc - Loading with filters:');
      print('  initialItemCode from constructor: $initialItemCode');
      print('  filters.itemCode: ${filters.itemCode}');
      print('  filters.dateFrom: ${filters.dateFrom}');
      print('  filters.dateTo: ${filters.dateTo}');

      final responseData = await apiService.getQuotaHistory(
        dateFrom: filters.dateFrom,
        dateTo: filters.dateTo,
        itemCode: filters.itemCode,
        sort: filters.sort,
        page: 1,
        pageSize: 30,
      );

      final response = QuotaHistoryResponse.fromJson(responseData);

      // Debug: Log received entries
      print('QuotaHistoryBloc - Received ${response.results.length} entries');
      for (var entry in response.results) {
        print('  Entry: ${entry.entryDate} - ${entry.itemName} - ${entry.itemCode}');
      }

      emit(QuotaHistoryLoaded(
        allEntries: response.results,
        aggregates: response.aggregates,
        filters: filters,
        currentPage: 1,
        hasMorePages: response.hasNextPage,
      ));
    } catch (e) {
      final errorMessage = ErrorHandler.handleError(e);
      emit(QuotaHistoryError(
        message: errorMessage,
        filters: state is QuotaHistoryLoaded ? (state as QuotaHistoryLoaded).filters : null,
      ));
    }
  }

  Future<void> _onLoadMoreHistory(
    LoadMoreHistory event,
    Emitter<QuotaHistoryState> emit,
  ) async {
    if (state is! QuotaHistoryLoaded) return;

    final currentState = state as QuotaHistoryLoaded;
    if (!currentState.hasMorePages || currentState.isLoadingMore) return;

    // Show loading indicator for pagination
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.currentPage + 1;
      final responseData = await apiService.getQuotaHistory(
        dateFrom: currentState.filters.dateFrom,
        dateTo: currentState.filters.dateTo,
        itemCode: currentState.filters.itemCode,
        sort: currentState.filters.sort,
        page: nextPage,
        pageSize: 30,
      );

      final response = QuotaHistoryResponse.fromJson(responseData);

      emit(QuotaHistoryLoaded(
        allEntries: [...currentState.allEntries, ...response.results],
        aggregates: response.aggregates,
        filters: currentState.filters,
        currentPage: nextPage,
        hasMorePages: response.hasNextPage,
        isLoadingMore: false,
      ));
    } catch (e) {
      // Revert to previous state on error
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onUpdateHistoryFilters(
    UpdateHistoryFilters event,
    Emitter<QuotaHistoryState> emit,
  ) async {
    emit(const QuotaHistoryLoading());

    try {
      final responseData = await apiService.getQuotaHistory(
        dateFrom: event.filters.dateFrom,
        dateTo: event.filters.dateTo,
        itemCode: event.filters.itemCode,
        sort: event.filters.sort,
        page: 1,
        pageSize: 30,
      );

      final response = QuotaHistoryResponse.fromJson(responseData);

      emit(QuotaHistoryLoaded(
        allEntries: response.results,
        aggregates: response.aggregates,
        filters: event.filters,
        currentPage: 1,
        hasMorePages: response.hasNextPage,
      ));
    } catch (e) {
      final errorMessage = ErrorHandler.handleError(e);
      emit(QuotaHistoryError(
        message: errorMessage,
        filters: event.filters,
      ));
    }
  }

  Future<void> _onUpdateHistorySort(
    UpdateHistorySort event,
    Emitter<QuotaHistoryState> emit,
  ) async {
    if (state is! QuotaHistoryLoaded) return;

    final currentState = state as QuotaHistoryLoaded;
    final updatedFilters = currentState.filters.copyWith(sort: event.sort);

    emit(const QuotaHistoryLoading());

    try {
      final responseData = await apiService.getQuotaHistory(
        dateFrom: updatedFilters.dateFrom,
        dateTo: updatedFilters.dateTo,
        itemCode: updatedFilters.itemCode,
        sort: updatedFilters.sort,
        page: 1,
        pageSize: 30,
      );

      final response = QuotaHistoryResponse.fromJson(responseData);

      emit(QuotaHistoryLoaded(
        allEntries: response.results,
        aggregates: response.aggregates,
        filters: updatedFilters,
        currentPage: 1,
        hasMorePages: response.hasNextPage,
      ));
    } catch (e) {
      final errorMessage = ErrorHandler.handleError(e);
      emit(QuotaHistoryError(
        message: errorMessage,
        filters: updatedFilters,
      ));
    }
  }

  Future<void> _onLoadHistoryDetail(
    LoadHistoryDetail event,
    Emitter<QuotaHistoryState> emit,
  ) async {
    // Save current state to restore after emitting detail
    final previousState = state;
    try {
      final response = await apiService.getQuotaHistoryDetail(
        entryDate: event.entryDate,
        itemCode: event.itemCode,
      );
      final detailResponse = QuotaHistoryDetailResponse.fromJson(response);
      final dateStr = event.entryDate.toIso8601String().split('T')[0];
      emit(QuotaHistoryDetailLoaded(
        entryDate: dateStr,
        itemCode: event.itemCode,
        entries: detailResponse.transactions,
      ));
    } catch (e) {
      debugPrint('Load history detail failed: $e');
    }
    // Re-emit previous loaded state so the main list isn't lost
    if (previousState is QuotaHistoryLoaded) {
      emit(previousState);
    }
  }
}
