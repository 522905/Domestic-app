// lib/presentation/blocs/orders/orders_event.dart
import 'package:equatable/equatable.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrdersEvent {
  final bool refresh;
  final Map<String, String>? filters;

  const LoadOrders({
    this.refresh = true,
    this.filters,
  });

  @override
  List<Object?> get props => [refresh, filters];
}

class LoadMoreOrders extends OrdersEvent {
  const LoadMoreOrders();
}

class ApplyFilters extends OrdersEvent {
  final Map<String, String> filters;

  const ApplyFilters(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ClearFilters extends OrdersEvent {
  const ClearFilters();
}

class RefreshOrders extends OrdersEvent {
  const RefreshOrders();
}

class SearchOrders extends OrdersEvent {
  final String query;

  const SearchOrders(this.query);

  @override
  List<Object?> get props => [query];
}

class RequestOrderAction extends OrdersEvent {
  final String orderId;
  final OrderActionType actionType;

  const RequestOrderAction(this.orderId, this.actionType);

  @override
  List<Object> get props => [orderId, actionType];
}

enum OrderActionType {
  requestApproval,
  finalize,
  cancel,
}

// NEW EVENT FOR ORDER DETAILS
class LoadOrderDetails extends OrdersEvent {
  final String id;

  const LoadOrderDetails(this.id);

  @override
  List<Object> get props => [id];
}

class ClearOrdersCache extends OrdersEvent {
  const ClearOrdersCache();
}