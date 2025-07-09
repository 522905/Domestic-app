// import 'package:equatable/equatable.dart';
//
// import '../../../core/models/inventory_request.dart';
//
// abstract class InventoryEvent extends Equatable {
//   const InventoryEvent();
//
//   @override
//   List<Object?> get props => [];
// }
//
// class LoadInventoryRequests extends InventoryEvent {
//   const LoadInventoryRequests();
// }
//
// class AddInventoryRequest extends InventoryEvent {
//   final InventoryRequest request;
//   const AddInventoryRequest({required this.request});
// }
//
// class FilterInventoryRequests extends InventoryEvent {
//   final String? status;
//   const FilterInventoryRequests({this.status});
// }
//
// class SearchInventoryRequests extends InventoryEvent {
//   final String query;
//   const SearchInventoryRequests({required this.query});
// }
//
// class ToggleFavoriteRequest extends InventoryEvent {
//   final String requestId;
//   final bool isFavorite;
//   const ToggleFavoriteRequest({required this.requestId, required this.isFavorite});
// }
//
// class UpdateInventoryRequest extends InventoryEvent {
//   final String requestId;
//   final InventoryRequest request;
//   const UpdateInventoryRequest({required this.requestId, required this.request});
// }

import 'package:equatable/equatable.dart';
import '../../../core/models/inventory_request.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadInventoryRequests extends InventoryEvent {
  const LoadInventoryRequests();
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

// Approval events (referenced in approval screens)
class ApproveInventoryRequest extends InventoryEvent {
  final String requestId;
  final String comment;

  const ApproveInventoryRequest({
    required this.requestId,
    required this.comment,
  });

  @override
  List<Object> get props => [requestId, comment];
}

class RejectInventoryRequest extends InventoryEvent {
  final String requestId;
  final String reason;

  const RejectInventoryRequest({
    required this.requestId,
    required this.reason,
  });

  @override
  List<Object> get props => [requestId, reason];
}