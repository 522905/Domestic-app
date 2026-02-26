import 'package:equatable/equatable.dart';
import '../../../core/models/inventory/inventory_request.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadInventoryRequests extends InventoryEvent {
  const LoadInventoryRequests();
}

class LoadInventoryRequestDetail extends InventoryEvent {
  final String requestId;

  const LoadInventoryRequestDetail({required this.requestId});

  @override
  List<Object> get props => [requestId];
}

class RefreshInventoryRequests extends InventoryEvent {
  const RefreshInventoryRequests();
}

class SearchInventoryRequests extends InventoryEvent {
  final String query;
  const SearchInventoryRequests({required this.query});
  @override
  List<Object> get props => [query];
}

class FilterInventoryRequests extends InventoryEvent {
  final String? status;
  const FilterInventoryRequests({this.status});
  @override
  List<Object?> get props => [status];
}

class AddInventoryRequest extends InventoryEvent {
  final InventoryRequest request;
  const AddInventoryRequest({required this.request});
  @override
  List<Object> get props => [request];
}

class UpdateInventoryRequest extends InventoryEvent {
  final String requestId;
  final InventoryRequest request;
  const UpdateInventoryRequest({
    required this.requestId,
    required this.request,
  });
  @override
  List<Object> get props => [requestId, request];
}

class ToggleFavoriteRequest extends InventoryEvent {
  final String requestId;
  final bool isFavorite;
  const ToggleFavoriteRequest({
    required this.requestId,
    required this.isFavorite,
  });
  @override
  List<Object> get props => [requestId, isFavorite];
}

class ApproveInventoryRequest extends InventoryEvent {
  final String requestId;
  final String requestType;
  const ApproveInventoryRequest({
    required this.requestId,
    required this.requestType,
  });
  @override
  List<Object> get props => [requestId, requestType];
}

class RejectInventoryRequest extends InventoryEvent {
  final String requestId;
  final String reason;
  final String requestType;
  const RejectInventoryRequest({
    required this.requestId,
    required this.reason,
    required this.requestType,
  });
  @override
  List<Object> get props => [requestId, reason, requestType];
}

class CancelInventoryRequest extends InventoryEvent {
  final String requestId;

  const CancelInventoryRequest({required this.requestId});

  @override
  List<Object> get props => [requestId];
}

// Filter by request type only
class FilterInventoryRequestsByType extends InventoryEvent {
  final String requestType; // 'COLLECT' or 'DEPOSIT'

  const FilterInventoryRequestsByType({required this.requestType});

  @override
  List<Object?> get props => [requestType];
}

// Filter by status and optionally exclude transfers
class FilterInventoryRequestsByStatusAndType extends InventoryEvent {
  final String status;
  final bool excludeTransfer;

  const FilterInventoryRequestsByStatusAndType({
    required this.status,
    this.excludeTransfer = false,
  });

  @override
  List<Object?> get props => [status, excludeTransfer];
}

/// Sets the active tab filter in the BLoC so refreshes preserve the correct tab view.
class SetInventoryFilter extends InventoryEvent {
  final String filterName; // 'All' | 'Pending' | 'Collect' | 'Deposit'
  const SetInventoryFilter({required this.filterName});
  @override
  List<Object> get props => [filterName];
}

class ClearInventoryCache extends InventoryEvent {
  const ClearInventoryCache();
}

// Event to reload details after approval/rejection
class LoadInventoryDetails extends InventoryEvent {
  final String requestId;

  const LoadInventoryDetails({required this.requestId});

  @override
  List<Object> get props => [requestId];
}