import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/order.dart';

// Events
abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrdersEvent {
  final String? statusFilter;

  const LoadOrders({this.statusFilter});

  @override
  List<Object?> get props => [statusFilter];
}

class FilterOrders extends OrdersEvent {
  final String? searchQuery;
  final String? statusFilter;
  final String? typeFilter;
  final String? dateFilter;

  const FilterOrders({
    this.searchQuery,
    this.statusFilter,
    this.typeFilter,
    this.dateFilter,
  });

  @override
  List<Object?> get props => [searchQuery, statusFilter, typeFilter, dateFilter];
}

class AddOrder extends OrdersEvent {
  final Order order;

  const AddOrder(this.order);

  @override
  List<Object> get props => [order];
}

class RequestOrderApproval extends OrdersEvent {
  final String orderId;

  const RequestOrderApproval(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class RejectOrder extends OrdersEvent {
  final String orderId;
  final String reason;

  const RejectOrder(this.orderId, this.reason);

  @override
  List<Object> get props => [orderId, reason];
}

class RefreshOrders extends OrdersEvent {}

// States
abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  final String? currentStatusFilter;
  final String? currentSearchQuery;

  const OrdersLoaded({
    required this.orders,
    this.currentStatusFilter,
    this.currentSearchQuery,
  });

  @override
  List<Object?> get props => [orders, currentStatusFilter, currentSearchQuery];
}

class OrdersError extends OrdersState {
  final String message;

  const OrdersError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final ApiServiceInterface apiService;
  List<Order> _allOrders = [];

  OrdersBloc({required this.apiService}) : super(OrdersInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<FilterOrders>(_onFilterOrders);
    on<AddOrder>(_onAddOrder);
    on<RefreshOrders>(_onRefreshOrders);
    on<RequestOrderApproval>(_onRequestOrderApproval);
    // on<RejectOrder>(_onRejectOrder);
  }

    Future<void> _onLoadOrders(LoadOrders event, Emitter<OrdersState> emit) async {
      emit(OrdersLoading());
      try {
        final response = await apiService.getOrdersList();

        final orders = response.map<Order>((data) {
          final items = (data['items'] as List<dynamic>).map<OrderItem>((itemData) {
            return OrderItem(
              id: itemData['id'] ?? '',
              name: itemData['item_name'] ?? '',
              quantity: (itemData['qty'] ?? 0.0).toInt(),
              unit: itemData['unit'] ?? '',
              rate: itemData['rate'] ?? 0.0,
              amount: itemData['amount'] ?? 0.0,
              description: itemData['description'] ?? '',
              itemCode: itemData['item_code'] ?? '',
              warehouse: itemData['warehouse'] ?? '',
              orderId: data['name'] ?? '',
              orderType: 'Sales Order',
              status: data['status'] ?? '',
              createdAt: data['transaction_date'] != null
                  ? DateTime.parse(data['transaction_date'])
                  : DateTime.now(),
              grandTotal: data['grand_total']?.toString() ?? '',
            );
          }).toList();

          return Order(
            id: data['name'] ?? '',
            orderNumber: data['name'] ?? '',
            orderType: 'Sales Order',
            status: data['status'] ?? '',
            createdAt: data['transaction_date'] != null
              ? DateTime.parse(data['transaction_date'])
              : DateTime.now(),
            items: items,
            warehouseId: '',
            vehicleId: '',
            grandTotal: data['grand_total']?.toString() ?? '',
          );
        }).toList();

        _allOrders = orders;
        emit(OrdersLoaded(
          orders: orders,
          currentStatusFilter: event.statusFilter,
        ));
      } catch (e) {
        emit(OrdersError('Failed to load orders: $e'));
      }
    }

  Future<void> _onFilterOrders(FilterOrders event, Emitter<OrdersState> emit) async {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;

      List<Order> filteredOrders = List.from(_allOrders);

      // Apply status filter
      if (event.statusFilter != null && event.statusFilter!.isNotEmpty) {
        filteredOrders = filteredOrders
            .where((order) => order.status.toLowerCase() == event.statusFilter!.toLowerCase())
            .toList();
      }

      // Apply search query filter
      if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
        filteredOrders = filteredOrders.where((order) {
          return order.orderNumber.toLowerCase().contains(event.searchQuery!.toLowerCase()) ||
              order.orderType.toLowerCase().contains(event.searchQuery!.toLowerCase()) ||
              order.items.any((item) => item.name.toLowerCase().contains(event.searchQuery!.toLowerCase()));
        }).toList();
      }

      // Apply type filter
      if (event.typeFilter != null && event.typeFilter!.isNotEmpty) {
        filteredOrders = filteredOrders
            .where((order) => order.orderType.toLowerCase() == event.typeFilter!.toLowerCase())
            .toList();
      }

      emit(OrdersLoaded(
        orders: filteredOrders,
        currentStatusFilter: event.statusFilter ?? currentState.currentStatusFilter,
        currentSearchQuery: event.searchQuery ?? currentState.currentSearchQuery,
      ));
    }
  }

  void _onAddOrder(AddOrder event, Emitter<OrdersState> emit) {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;

      // Check if order already exists to prevent duplicates
      final existingOrderIndex = _allOrders.indexWhere((order) => order.id == event.order.id);
      if (existingOrderIndex != -1) {
        // Update existing order instead of adding duplicate
        _allOrders[existingOrderIndex] = event.order;
      } else {
        // Add to internal cache only if it doesn't exist
        _allOrders.insert(0, event.order);
      }

      // Update displayed orders
      final updatedOrders = List<Order>.from(currentState.orders);
      final existingDisplayIndex = updatedOrders.indexWhere((order) => order.id == event.order.id);

      // Check if new order should be visible based on current filter
      bool shouldShow = true;
      if (currentState.currentStatusFilter != null) {
        shouldShow = event.order.status.toLowerCase() ==
            currentState.currentStatusFilter!.toLowerCase();
      }

      if (shouldShow) {
        if (existingDisplayIndex != -1) {
          // Update existing order in display list
          updatedOrders[existingDisplayIndex] = event.order;
        } else {
          // Add new order to display list
          updatedOrders.insert(0, event.order);
        }
      } else if (existingDisplayIndex != -1) {
        // Remove from display if it no longer matches filter
        updatedOrders.removeAt(existingDisplayIndex);
      }

      emit(OrdersLoaded(
        orders: updatedOrders,
        currentStatusFilter: currentState.currentStatusFilter,
        currentSearchQuery: currentState.currentSearchQuery,
      ));
    }
  }

  Future<void> _onRefreshOrders(RefreshOrders event, Emitter<OrdersState> emit) async {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      add(LoadOrders(statusFilter: currentState.currentStatusFilter));
    } else {
      add(const LoadOrders());
    }
  }

  Future<void> _onRequestOrderApproval(RequestOrderApproval event, Emitter<OrdersState> emit) async {
    try {
      // Call API to request approval
      await apiService.requestOrderApproval(event.orderId);

      // Update order status locally
      _updateOrderStatus(event.orderId, 'Processing', emit);

    } catch (e) {
      emit(OrdersError('Failed to request approval: $e'));
    }
  }

  // Future<void> _onRejectOrder(RejectOrder event, Emitter<OrdersState> emit) async {
  //   try {
  //     // Call API to reject order
  //     await apiService.rejectOrder(event.orderId, event.reason);
  //
  //     // Update order status locally
  //     _updateOrderStatus(event.orderId, 'Rejected', emit);
  //
  //   } catch (e) {
  //     emit(OrdersError('Failed to reject order: $e'));
  //   }
  // }

  void _updateOrderStatus(String orderId, String newStatus, Emitter<OrdersState> emit) {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;

      // Update in internal cache
      final cacheIndex = _allOrders.indexWhere((order) => order.id == orderId);
      if (cacheIndex != -1) {
        _allOrders[cacheIndex] = Order(
          id: _allOrders[cacheIndex].id,
          orderNumber: _allOrders[cacheIndex].orderNumber,
          orderType: _allOrders[cacheIndex].orderType,
          status: newStatus,
          createdAt: _allOrders[cacheIndex].createdAt,
          items: _allOrders[cacheIndex].items,
          warehouseId: _allOrders[cacheIndex].warehouseId,
          vehicleId: _allOrders[cacheIndex].vehicleId,
          grandTotal: _allOrders[cacheIndex].grandTotal,
        );
      }

      // Update in displayed orders
      final displayIndex = currentState.orders.indexWhere((order) => order.id == orderId);
      if (displayIndex != -1) {
        final updatedOrders = List<Order>.from(currentState.orders);
        updatedOrders[displayIndex] = Order(
          id: updatedOrders[displayIndex].id,
          orderNumber: updatedOrders[displayIndex].orderNumber,
          orderType: updatedOrders[displayIndex].orderType,
          status: newStatus,
          createdAt: updatedOrders[displayIndex].createdAt,
          items: updatedOrders[displayIndex].items,
          warehouseId: updatedOrders[displayIndex].warehouseId,
          vehicleId: updatedOrders[displayIndex].vehicleId,
          grandTotal: updatedOrders[displayIndex].grandTotal,
        );

        emit(OrdersLoaded(
          orders: updatedOrders,
          currentStatusFilter: currentState.currentStatusFilter,
          currentSearchQuery: currentState.currentSearchQuery,
        ));
      }
    }
  }
}