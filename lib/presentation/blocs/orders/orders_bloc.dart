import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/order.dart';
import 'orders_event.dart';
import 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final ApiServiceInterface apiService;
  static const int _pageLimit = 10;
  List<Order> _allOrders = [];

  OrdersBloc({required this.apiService}) : super(const OrdersInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<LoadMoreOrders>(_onLoadMoreOrders);
    on<ApplyFilters>(_onApplyFilters);
    on<ClearFilters>(_onClearFilters);
    on<RefreshOrders>(_onRefreshOrders);
    on<SearchOrders>(_onSearchOrders);
    on<RequestOrderAction>(_onRequestOrderAction);
    on<LoadOrderDetails>(_onLoadOrderDetails);
  }

  Future<void> _onLoadOrders(LoadOrders event, Emitter<OrdersState> emit) async {
    try {
      if (event.refresh) {
        emit(const OrdersLoading());
      } else if (state is OrdersLoaded) {
        final currentState = state as OrdersLoaded;
        emit(currentState.copyWith(isLoadingMore: true));
      }

      final response = await apiService.getOrdersList(
        offset: 0,
        limit: _pageLimit,
        filters: event.filters,
      );

      final orders = _parseOrdersFromResponse(response);
      final availableFilters = _parseFiltersFromResponse(response);
      final hasMore = response['has_more'] ?? false;

      _allOrders = orders;

      emit(OrdersLoaded(
        orders: orders,
        hasMore: hasMore,
        currentOffset: _pageLimit,
        availableFilters: availableFilters,
        appliedFilters: event.filters ?? {},
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(OrdersError(
        message: _extractErrorMessage(e),
        canRetry: _canRetryError(e),
      ));
    }
  }

  Future<void> _onLoadMoreOrders(LoadMoreOrders event, Emitter<OrdersState> emit) async {
    if (state is! OrdersLoaded) return;

    final currentState = state as OrdersLoaded;
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    try {
      emit(currentState.copyWith(isLoadingMore: true));

      final response = await apiService.getOrdersList(
        offset: currentState.currentOffset,
        limit: _pageLimit,
        filters: currentState.appliedFilters.isNotEmpty ? currentState.appliedFilters : null,
      );

      final newOrders = _parseOrdersFromResponse(response);
      final hasMore = response['has_more'] ?? false;

      final allOrders = List<Order>.from(currentState.orders)..addAll(newOrders);
      _allOrders = allOrders;

      emit(currentState.copyWith(
        orders: allOrders,
        hasMore: hasMore,
        currentOffset: currentState.currentOffset + _pageLimit,
        isLoadingMore: false,
      ));
    } catch (e) {
      // For pagination errors, don't show full error state, just stop loading
      emit(currentState.copyWith(
        isLoadingMore: false,
        // Optional: Add an error message field to OrdersLoaded for inline errors
      ));

      // You could also emit a temporary error message here
      // that the UI can show as a snackbar
      print('Load more failed: ${_extractErrorMessage(e)}');
    }
  }

  Future<void> _onApplyFilters(ApplyFilters event, Emitter<OrdersState> emit) async {
    try {
      emit(const OrdersLoading());

      final response = await apiService.getOrdersList(
        offset: 0,
        limit: _pageLimit,
        filters: event.filters,
      );

      final orders = _parseOrdersFromResponse(response);
      final availableFilters = _parseFiltersFromResponse(response);
      final hasMore = response['has_more'] ?? false;

      _allOrders = orders;

      emit(OrdersLoaded(
        orders: orders,
        hasMore: hasMore,
        currentOffset: _pageLimit,
        availableFilters: availableFilters,
        appliedFilters: event.filters,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(OrdersError(
        message: _extractErrorMessage(e),
        canRetry: _canRetryError(e),
      ));
    }
  }

  Future<void> _onClearFilters(ClearFilters event, Emitter<OrdersState> emit) async {
    add(const LoadOrders(refresh: true, filters: {}));
  }

  Future<void> _onRefreshOrders(RefreshOrders event, Emitter<OrdersState> emit) async {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      add(LoadOrders(
        refresh: true,
        filters: currentState.appliedFilters,
      ));
    } else {
      add(const LoadOrders(refresh: true));
    }
  }

  void _onSearchOrders(SearchOrders event, Emitter<OrdersState> emit) {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      emit(currentState.copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onRequestOrderAction(RequestOrderAction event, Emitter<OrdersState> emit) async {
    try {
      OrdersLoaded? currentOrdersState;
      if (state is OrdersLoaded) {
        currentOrdersState = state as OrdersLoaded;
      }

      // Switch on action type to call correct API
      final response = switch (event.actionType) {
        OrderActionType.requestApproval => await apiService.requestOrderApproval(event.orderId),
        OrderActionType.finalize => await apiService.requestFinalizeOrder(event.orderId),
      };

      emit(OrdersLoadedWithResponse(
        response: response,
        orders: currentOrdersState?.orders ?? _allOrders,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      if (currentOrdersState != null) {
        final updatedOrders = _getUpdatedOrdersList(
            currentOrdersState.orders,
            event.orderId,
            'Processing'
        );

        emit(currentOrdersState.copyWith(orders: updatedOrders));
      }
    } catch (e) {
      if (state is OrdersLoaded) {
        final currentState = state as OrdersLoaded;
        emit(OrdersErrorWithRecovery(
          message: _extractErrorMessage(e),
          canRetry: true,
          previousState: currentState,
        ));
      } else {
        emit(OrdersError(
          message: _extractErrorMessage(e),
          canRetry: true,
        ));
      }
    }
  }

  Future<void> _onLoadOrderDetails(LoadOrderDetails event, Emitter<OrdersState> emit) async {
    try {
      List<Order> currentOrders = [];
      bool hasMore = false;
      int currentOffset = 0;
      Map<String, List<FilterOption>> availableFilters = {};
      Map<String, String> appliedFilters = {};
      String? searchQuery;

      if (state is OrdersLoaded) {
        final currentState = state as OrdersLoaded;
        currentOrders = currentState.orders;
        hasMore = currentState.hasMore;
        currentOffset = currentState.currentOffset;
        availableFilters = currentState.availableFilters;
        appliedFilters = currentState.appliedFilters;
        searchQuery = currentState.searchQuery;
      } else {
        currentOrders = _allOrders;
      }

      emit(OrderDetailsLoading(event.id));

      final response = await apiService.getOrderDetails(event.id);

      final salesOrderData = response['sales_order_data'] as Map<String, dynamic>;
      final detailedOrder = Order.fromJson(salesOrderData);

      emit(OrderDetailsLoaded(
        detailedOrder: detailedOrder,
        orderName: event.id,
        orders: currentOrders,
        hasMore: hasMore,
        currentOffset: currentOffset,
        availableFilters: availableFilters,
        appliedFilters: appliedFilters,
        searchQuery: searchQuery,
      ));
    } catch (e) {
      emit(OrderDetailsError(
        message: _extractErrorMessage(e),
        orderName: event.id,
        canRetry: _canRetryError(e),
      ));
    }
  }

  // IMPROVED: Extract error message from Exception thrown by API service
  String _extractErrorMessage(dynamic error) {
    // The API service now throws properly formatted exceptions
    // using ErrorHandler.handleError(), so we just extract the message

    final errorString = error.toString();

    // Remove "Exception: " prefix if present
    if (errorString.startsWith('Exception: ')) {
      return errorString.substring(11);
    }

    // If it's a raw error string, return as-is
    return errorString;
  }

  // NEW: Determine if error is retryable based on type
  bool _canRetryError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network/timeout errors are retryable
    if (errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network')) {
      return true;
    }

    // Server errors (5xx) are potentially retryable
    if (errorString.contains('server error')) {
      return true;
    }

    // Client errors (4xx) are generally not retryable
    // except for 401 (user can retry after re-auth)
    if (errorString.contains('401') || errorString.contains('authentication')) {
      return true;
    }

    // Validation errors (400) are not retryable without changes
    if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('required')) {
      return false;
    }

    // Default to retryable for unknown errors
    return true;
  }

  List<Order> _getUpdatedOrdersList(List<Order> currentOrders, String orderId, String newStatus) {
    return currentOrders.map((order) {
      if (order.id == orderId) {
        return order.copyWith(status: newStatus);
      }
      return order;
    }).toList();
  }

  List<Order> _parseOrdersFromResponse(Map<String, dynamic> response) {
    final data = response['data'] as List? ?? [];
    return data.map((orderData) => Order.fromJson(orderData)).toList();
  }

  Map<String, List<FilterOption>> _parseFiltersFromResponse(Map<String, dynamic> response) {
    final facets = response['facets'] as Map<String, dynamic>? ?? {};
    final Map<String, List<FilterOption>> filters = {};

    facets.forEach((key, value) {
      if (value is List) {
        filters[key] = value
            .map((item) => FilterOption.fromJson(item))
            .where((option) => option.value.isNotEmpty)
            .toList();
      }
    });

    return filters;
  }

  void addNewOrder(Order order) {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      _allOrders.insert(0, order);
      final updatedOrders = List<Order>.from(currentState.orders);
      updatedOrders.insert(0, order);
      emit(currentState.copyWith(orders: updatedOrders));
    }
  }

  void updateOrder(Order updatedOrder) {
    final cacheIndex = _allOrders.indexWhere((order) => order.id == updatedOrder.id);
    if (cacheIndex != -1) {
      _allOrders[cacheIndex] = updatedOrder;
    }

    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      final displayIndex = currentState.orders.indexWhere((order) => order.id == updatedOrder.id);

      if (displayIndex != -1) {
        final updatedOrders = List<Order>.from(currentState.orders);
        updatedOrders[displayIndex] = updatedOrder;
        emit(currentState.copyWith(orders: updatedOrders));
      }
    }
  }

  void removeOrder(String orderId) {
    _allOrders.removeWhere((order) => order.id == orderId);

    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      final updatedOrders = currentState.orders.where((order) => order.id != orderId).toList();
      emit(currentState.copyWith(orders: updatedOrders));
    }
  }

  @override
  Future<void> close() {
    _allOrders.clear();
    return super.close();
  }
}

// Optional: Add this state class to orders_state.dart for better error recovery
class OrdersErrorWithRecovery extends OrdersState {
  final String message;
  final bool canRetry;
  final OrdersLoaded previousState;

  const OrdersErrorWithRecovery({
    required this.message,
    required this.canRetry,
    required this.previousState,
  });

  @override
  List<Object?> get props => [message, canRetry, previousState];
}