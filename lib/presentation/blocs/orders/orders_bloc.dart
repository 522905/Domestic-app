// lib/presentation/blocs/orders/orders_bloc.dart
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
    on<RequestOrderApproval>(_onRequestOrderApproval);
    on<LoadOrderDetails>(_onLoadOrderDetails); // NEW HANDLER
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

      // Update internal cache
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
        message: _getErrorMessage(e),
        canRetry: true,
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

      // Combine existing orders with new orders
      final allOrders = List<Order>.from(currentState.orders)..addAll(newOrders);

      // Update internal cache
      _allOrders = allOrders;

      emit(currentState.copyWith(
        orders: allOrders,
        hasMore: hasMore,
        currentOffset: currentState.currentOffset + _pageLimit,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isLoadingMore: false,
      ));
      // Could emit error state or show snackbar - for now just stop loading
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

      // Update internal cache
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
        message: _getErrorMessage(e),
        canRetry: true,
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

  Future<void> _onRequestOrderApproval(RequestOrderApproval event, Emitter<OrdersState> emit) async {
    try {
      // Store the current state before making API call
      OrdersLoaded? currentOrdersState;
      if (state is OrdersLoaded) {
        currentOrdersState = state as OrdersLoaded;
      }

      // Call the approval API
      final response = await apiService.requestOrderApproval(event.orderId);

      // Emit the response state with the API response and current orders
      emit(OrdersLoadedWithResponse(
        response: response,
        orders: currentOrdersState?.orders ?? _allOrders,
      ));

      // Update the order status locally if needed
      _updateOrderStatusLocally(event.orderId, 'Processing');

      // After a brief delay, return to the normal OrdersLoaded state
      await Future.delayed(const Duration(milliseconds: 100));

      if (currentOrdersState != null) {
        // Get the updated orders after status change
        final updatedOrders = _getUpdatedOrdersList(currentOrdersState.orders, event.orderId, 'Processing');

        emit(currentOrdersState.copyWith(
          orders: updatedOrders,
        ));
      }

    } catch (e) {
      emit(OrdersError(
        message: 'Failed to request approval: $e',
        canRetry: true,
      ));
    }
  }

  // NEW METHOD FOR LOADING ORDER DETAILS
  Future<void> _onLoadOrderDetails(LoadOrderDetails event, Emitter<OrdersState> emit) async {
    try {
      emit(OrderDetailsLoading(event.id));

      final response = await apiService.getOrderDetails(event.id);

      // Parse the sales_order_data into Order entity
      final salesOrderData = response['sales_order_data'] as Map<String, dynamic>;
      final detailedOrder = Order.fromJson(salesOrderData);

      emit(OrderDetailsLoaded(
        detailedOrder: detailedOrder,
        orderName: event.id,
      ));
    } catch (e) {
      emit(OrderDetailsError(
        message: _getErrorMessage(e),
        orderName: event.id,
        canRetry: true,
      ));
    }
  }

  List<Order> _getUpdatedOrdersList(List<Order> currentOrders, String orderId, String newStatus) {
    return currentOrders.map((order) {
      if (order.id == orderId) {
        return order.copyWith(status: newStatus);
      }
      return order;
    }).toList();
  }

  void _updateOrderStatusLocally(String orderId, String newStatus) {
    // Update in internal cache
    final orderIndex = _allOrders.indexWhere((order) => order.id == orderId);
    if (orderIndex != -1) {
      _allOrders[orderIndex] = _allOrders[orderIndex].copyWith(status: newStatus);
    }

    // Update current state if it's OrdersLoaded
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      final displayOrderIndex = currentState.orders.indexWhere((order) => order.id == orderId);

      if (displayOrderIndex != -1) {
        final updatedOrders = List<Order>.from(currentState.orders);
        updatedOrders[displayOrderIndex] = updatedOrders[displayOrderIndex].copyWith(status: newStatus);

        emit(currentState.copyWith(orders: updatedOrders));
      }
    }
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

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('No internet')) {
      return 'No internet connection. Please check your network.';
    } else if (error.toString().contains('timeout')) {
      return 'Request timeout. Please try again.';
    } else if (error.toString().contains('404')) {
      return 'Order not found.';
    } else if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    } else if (error.toString().contains('401') || error.toString().contains('403')) {
      return 'Authentication failed. Please login again.';
    } else {
      return 'Failed to load data. Please try again.';
    }
  }

  // Method to add new order (for create order functionality)
  void addNewOrder(Order order) {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;

      // Add to internal cache
      _allOrders.insert(0, order);

      // Add to displayed orders if it matches current filters
      final updatedOrders = List<Order>.from(currentState.orders);
      updatedOrders.insert(0, order);

      emit(currentState.copyWith(orders: updatedOrders));
    }
  }

  // Method to update existing order
  void updateOrder(Order updatedOrder) {
    // Update in internal cache
    final cacheIndex = _allOrders.indexWhere((order) => order.id == updatedOrder.id);
    if (cacheIndex != -1) {
      _allOrders[cacheIndex] = updatedOrder;
    }

    // Update in current state
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

  // Method to remove order
  void removeOrder(String orderId) {
    // Remove from internal cache
    _allOrders.removeWhere((order) => order.id == orderId);

    // Remove from current state
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