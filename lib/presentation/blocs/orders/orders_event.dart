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

class RequestOrderApproval extends OrdersEvent {
  final String orderId;

  const RequestOrderApproval(this.orderId);

  @override
  List<Object> get props => [orderId];
}