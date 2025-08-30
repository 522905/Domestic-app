// lib/presentation/blocs/orders/orders_state.dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/order.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  final bool hasMore;
  final int currentOffset;
  final bool isLoadingMore;
  final Map<String, List<FilterOption>> availableFilters;
  final Map<String, String> appliedFilters;
  final String? searchQuery;

  const OrdersLoaded({
    required this.orders,
    required this.hasMore,
    required this.currentOffset,
    this.isLoadingMore = false,
    this.availableFilters = const {},
    this.appliedFilters = const {},
    this.searchQuery,
  });

  @override
  List<Object?> get props => [
    orders,
    hasMore,
    currentOffset,
    isLoadingMore,
    availableFilters,
    appliedFilters,
    searchQuery,
  ];

  OrdersLoaded copyWith({
    List<Order>? orders,
    bool? hasMore,
    int? currentOffset,
    bool? isLoadingMore,
    Map<String, List<FilterOption>>? availableFilters,
    Map<String, String>? appliedFilters,
    String? searchQuery,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      hasMore: hasMore ?? this.hasMore,
      currentOffset: currentOffset ?? this.currentOffset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      availableFilters: availableFilters ?? this.availableFilters,
      appliedFilters: appliedFilters ?? this.appliedFilters,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasFiltersApplied => appliedFilters.isNotEmpty || (searchQuery?.isNotEmpty ?? false);

  List<Order> get filteredOrders {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return orders;
    }

    return orders.where((order) {
      final query = searchQuery!.toLowerCase();
      return order.orderNumber.toLowerCase().contains(query) ||
          order.customerName.toLowerCase().contains(query) ||
          order.vehicle.toLowerCase().contains(query) ||
          order.warehouse.toLowerCase().contains(query);
    }).toList();
  }
}

class OrdersError extends OrdersState {
  final String message;
  final bool canRetry;

  const OrdersError({
    required this.message,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, canRetry];
}

class OrdersLoadedWithResponse extends OrdersState {
  final dynamic response;
  final List<Order> orders;

  const OrdersLoadedWithResponse({
    required this.response,
    this.orders = const [],
  });

  @override
  List<Object?> get props => [response, orders];
}

// NEW STATES FOR ORDER DETAILS
class OrderDetailsLoading extends OrdersState {
  final String orderName;

  const OrderDetailsLoading(this.orderName);

  @override
  List<Object> get props => [orderName];
}

class OrderDetailsLoaded extends OrdersState {
  final Order detailedOrder;
  final String orderName;

  const OrderDetailsLoaded({
    required this.detailedOrder,
    required this.orderName,
  });

  @override
  List<Object> get props => [detailedOrder, orderName];
}

class OrderDetailsError extends OrdersState {
  final String message;
  final String orderName;
  final bool canRetry;

  const OrderDetailsError({
    required this.message,
    required this.orderName,
    this.canRetry = true,
  });

  @override
  List<Object> get props => [message, orderName, canRetry];
}

class FilterOption {
  final String value;
  final int count;

  const FilterOption({
    required this.value,
    required this.count,
  });

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      value: json['value']?.toString() ?? '',
      count: json['count'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterOption && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}