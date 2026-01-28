import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/bonus/bonus.dart';
import '../../../domain/entities/bonus/bonus_list_response.dart';
import '../../../domain/entities/bonus/bonus_filters.dart';
import 'bonus_list_event.dart';
import 'bonus_list_state.dart';

class BonusListBloc extends Bloc<BonusListEvent, BonusListState> {
  final ApiServiceInterface apiService;

  BonusListBloc({required this.apiService}) : super(const BonusListInitial()) {
    on<LoadBonusList>(_onLoadBonusList);
    on<LoadMoreBonuses>(_onLoadMoreBonuses);
    on<UpdateBonusFilters>(_onUpdateBonusFilters);
    on<UpdateBonusStatus>(_onUpdateBonusStatus);
    on<RefreshBonusList>(_onRefreshBonusList);
  }

  Future<void> _onLoadBonusList(
    LoadBonusList event,
    Emitter<BonusListState> emit,
  ) async {
    emit(const BonusListLoading());

    try {
      final filters = const BonusFilters();
      final responseData = await apiService.getBonuses(
        status: filters.status,
        itemCode: filters.itemCode,
        scheme: filters.scheme,
        sort: filters.sort,
        page: filters.page,
        pageSize: filters.pageSize,
      );

      final response = BonusListResponse.fromJson(responseData);

      emit(BonusListLoaded(
        allBonuses: response.results,
        summary: response.summary,
        filters: filters,
        currentPage: response.page,
        hasMorePages: response.hasMorePages,
      ));
    } catch (e) {
      emit(BonusListError(message: e.toString()));
    }
  }

  Future<void> _onLoadMoreBonuses(
    LoadMoreBonuses event,
    Emitter<BonusListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BonusListLoaded) return;
    if (!currentState.hasMorePages || currentState.isLoadingMore) return;

    // Show loading indicator for pagination
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.currentPage + 1;
      final filters = currentState.filters.copyWith(page: nextPage);

      final responseData = await apiService.getBonuses(
        status: filters.status,
        itemCode: filters.itemCode,
        scheme: filters.scheme,
        sort: filters.sort,
        page: filters.page,
        pageSize: filters.pageSize,
      );

      final response = BonusListResponse.fromJson(responseData);

      // Accumulate bonuses from all pages
      final updatedBonuses = List<Bonus>.from(currentState.allBonuses)
        ..addAll(response.results);

      emit(currentState.copyWith(
        allBonuses: updatedBonuses,
        summary: response.summary,
        filters: filters,
        isLoadingMore: false,
        currentPage: response.page,
        hasMorePages: response.hasMorePages,
      ));
    } catch (e) {
      // Restore state without loading indicator
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onUpdateBonusFilters(
    UpdateBonusFilters event,
    Emitter<BonusListState> emit,
  ) async {
    emit(const BonusListLoading());

    try {
      final responseData = await apiService.getBonuses(
        status: event.filters.status,
        itemCode: event.filters.itemCode,
        scheme: event.filters.scheme,
        sort: event.filters.sort,
        page: event.filters.page,
        pageSize: event.filters.pageSize,
      );

      final response = BonusListResponse.fromJson(responseData);

      emit(BonusListLoaded(
        allBonuses: response.results,
        summary: response.summary,
        filters: event.filters,
        currentPage: response.page,
        hasMorePages: response.hasMorePages,
      ));
    } catch (e) {
      emit(BonusListError(
        message: e.toString(),
        filters: event.filters,
      ));
    }
  }

  Future<void> _onUpdateBonusStatus(
    UpdateBonusStatus event,
    Emitter<BonusListState> emit,
  ) async {
    final currentState = state;
    final currentFilters = currentState is BonusListLoaded
        ? currentState.filters
        : const BonusFilters();

    final updatedFilters = currentFilters.copyWith(
      status: event.status,
      page: 1, // Reset to first page when changing status
    );

    add(UpdateBonusFilters(updatedFilters));
  }

  Future<void> _onRefreshBonusList(
    RefreshBonusList event,
    Emitter<BonusListState> emit,
  ) async {
    final currentState = state;
    final currentFilters = currentState is BonusListLoaded
        ? currentState.filters
        : const BonusFilters();

    try {
      final responseData = await apiService.getBonuses(
        status: currentFilters.status,
        itemCode: currentFilters.itemCode,
        scheme: currentFilters.scheme,
        sort: currentFilters.sort,
        page: 1, // Always start from page 1 on refresh
        pageSize: currentFilters.pageSize,
      );

      final response = BonusListResponse.fromJson(responseData);

      emit(BonusListLoaded(
        allBonuses: response.results,
        summary: response.summary,
        filters: currentFilters.copyWith(page: 1),
        currentPage: response.page,
        hasMorePages: response.hasMorePages,
      ));
    } catch (e) {
      // If refresh fails, try to maintain current state or show error
      if (currentState is BonusListLoaded) {
        emit(currentState);
      } else {
        emit(BonusListError(
          message: e.toString(),
          filters: currentFilters,
        ));
      }
    }
  }
}
