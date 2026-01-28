import 'package:equatable/equatable.dart';
import 'package:lpg_distribution_app/core/models/inventory/inventory_request.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<InventoryRequest> requests;

  const InventoryLoaded({required this.requests});

  @override
  List<Object> get props => [requests];
}

class InventoryError extends InventoryState {
  final String message;

  const InventoryError({required this.message});

  @override
  List<Object> get props => [message];
}

// New states for detail loading
class InventoryDetailLoading extends InventoryState {}

class InventoryDetailLoaded extends InventoryState {
  final InventoryRequest request;

  const InventoryDetailLoaded({required this.request});

  @override
  List<Object> get props => [request];
}

class InventoryDetailError extends InventoryState {
  final String message;

  const InventoryDetailError({required this.message});

  @override
  List<Object> get props => [message];
}

// Action states for approve/reject operations
class InventoryActionLoading extends InventoryState {
  final String requestId;
  final String action; // 'approve' or 'reject'

  const InventoryActionLoading({
    required this.requestId,
    required this.action,
  });

  @override
  List<Object> get props => [requestId, action];
}

class InventoryActionSuccess extends InventoryState {
  final String message;
  final String requestId;
  final String action;

  const InventoryActionSuccess({
    required this.message,
    required this.requestId,
    required this.action,
  });

  @override
  List<Object> get props => [message, requestId, action];
}

class InventoryCancelSuccess extends InventoryState {
  final String message;
  final String requestId;

  const InventoryCancelSuccess({
    required this.message,
    required this.requestId,
  });

  @override
  List<Object> get props => [message, requestId];
}