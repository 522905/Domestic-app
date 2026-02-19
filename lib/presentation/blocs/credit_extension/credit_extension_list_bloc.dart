import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/credit_extension/credit_extension.dart';
import 'credit_extension_list_event.dart';
import 'credit_extension_list_state.dart';

class CreditExtensionListBloc
    extends Bloc<CreditExtensionListEvent, CreditExtensionListState> {
  final ApiServiceInterface apiService;

  CreditExtensionListBloc({required this.apiService})
      : super(CreditExtensionListInitial()) {
    on<LoadCreditExtensions>(_onLoadCreditExtensions);
    on<RefreshCreditExtensions>(_onRefreshCreditExtensions);
    on<FilterByStatus>(_onFilterByStatus);
    on<LoadMoreCreditExtensions>(_onLoadMoreCreditExtensions);
  }

  Future<void> _onLoadCreditExtensions(
    LoadCreditExtensions event,
    Emitter<CreditExtensionListState> emit,
  ) async {
    emit(CreditExtensionListLoading());

    try {
      final response = await apiService.getCreditExtensions(
        status: event.status,
        page: event.page,
        pageSize: 20,
      );

      final extensionsList = (response['results'] as List)
          .map((json) => CreditExtension.fromJson(json))
          .toList();

      final hasMore = response['next'] != null;

      emit(CreditExtensionListLoaded(
        extensions: extensionsList,
        currentStatus: event.status,
        hasMore: hasMore,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(CreditExtensionListError(e.toString()));
    }
  }

  Future<void> _onRefreshCreditExtensions(
    RefreshCreditExtensions event,
    Emitter<CreditExtensionListState> emit,
  ) async {
    try {
      final response = await apiService.getCreditExtensions(
        status: event.status,
        page: 1,
        pageSize: 20,
      );

      final extensionsList = (response['results'] as List)
          .map((json) => CreditExtension.fromJson(json))
          .toList();

      final hasMore = response['next'] != null;

      emit(CreditExtensionListLoaded(
        extensions: extensionsList,
        currentStatus: event.status,
        hasMore: hasMore,
        currentPage: 1,
      ));
    } catch (e) {
      emit(CreditExtensionListError(e.toString()));
    }
  }

  Future<void> _onFilterByStatus(
    FilterByStatus event,
    Emitter<CreditExtensionListState> emit,
  ) async {
    emit(CreditExtensionListLoading());

    try {
      final response = await apiService.getCreditExtensions(
        status: event.status,
        page: 1,
        pageSize: 20,
      );

      final extensionsList = (response['results'] as List)
          .map((json) => CreditExtension.fromJson(json))
          .toList();

      final hasMore = response['next'] != null;

      emit(CreditExtensionListLoaded(
        extensions: extensionsList,
        currentStatus: event.status,
        hasMore: hasMore,
        currentPage: 1,
      ));
    } catch (e) {
      emit(CreditExtensionListError(e.toString()));
    }
  }

  Future<void> _onLoadMoreCreditExtensions(
    LoadMoreCreditExtensions event,
    Emitter<CreditExtensionListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CreditExtensionListLoaded) return;
    if (!currentState.hasMore) return;

    emit(CreditExtensionListLoadingMore(
      currentExtensions: currentState.extensions,
      currentStatus: currentState.currentStatus,
      currentPage: currentState.currentPage,
    ));

    try {
      final nextPage = currentState.currentPage + 1;
      final response = await apiService.getCreditExtensions(
        status: currentState.currentStatus,
        page: nextPage,
        pageSize: 20,
      );

      final newExtensions = (response['results'] as List)
          .map((json) => CreditExtension.fromJson(json))
          .toList();

      final hasMore = response['next'] != null;

      emit(CreditExtensionListLoaded(
        extensions: [...currentState.extensions, ...newExtensions],
        currentStatus: currentState.currentStatus,
        hasMore: hasMore,
        currentPage: nextPage,
      ));
    } catch (e) {
      emit(CreditExtensionListError(e.toString()));
    }
  }
}
