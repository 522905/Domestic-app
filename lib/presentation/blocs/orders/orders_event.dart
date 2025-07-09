// lib/presentation/blocs/orders/orders_event.dart
import 'package:equatable/equatable.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class FetchOrders extends OrdersEvent {
  final Map<String, dynamic>? filters;
  final int page;
  final int pageSize;

  const FetchOrders({
    this.filters,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [filters, page, pageSize];
}

class ApproveOrder extends OrdersEvent {
  final String orderId;
  final String comment;

  const ApproveOrder({
    required this.orderId,
    required this.comment,
  });

  @override
  List<Object?> get props => [orderId, comment];
}

class RejectOrder extends OrdersEvent {
  final String orderId;
  final String reason;

  const RejectOrder({
    required this.orderId,
    required this.reason,
  });

  @override
  List<Object?> get props => [orderId, reason];
}