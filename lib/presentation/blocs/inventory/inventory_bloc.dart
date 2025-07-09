import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lpg_distribution_app/core/models/inventory_request.dart';
import 'package:lpg_distribution_app/core/services/api_service_interface.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final ApiServiceInterface _apiService;
  List<InventoryRequest> _allRequests = [];

  // Expose apiService for form screens
  ApiServiceInterface get apiService => _apiService;

  InventoryBloc({required ApiServiceInterface apiService})
      : _apiService = apiService,
        super(InventoryInitial()) {
    on<LoadInventoryRequests>(_onLoadInventoryRequests);
    on<SearchInventoryRequests>(_onSearchInventoryRequests);
    on<FilterInventoryRequests>(_onFilterInventoryRequests);
    on<ToggleFavoriteRequest>(_onToggleFavoriteRequest);
    on<AddInventoryRequest>(_onAddInventoryRequest);
    on<RefreshInventoryRequests>(_onRefreshInventoryRequests);
    on<UpdateInventoryRequest>(_onUpdateInventoryRequest);
    on<ApproveInventoryRequest>(_onApproveInventoryRequest);
    on<RejectInventoryRequest>(_onRejectInventoryRequest);
  }

  Future<void> _onApproveInventoryRequest(
      ApproveInventoryRequest event,
      Emitter<InventoryState> emit,
      ) async {
    try {
      // Call the actual API to approve
      await _apiService.approveInventoryRequest(
        requestId: event.requestId,
        comment: event.comment,
      );

      // Update local state
      final updatedRequests = _allRequests.map((request) {
        if (request.id == event.requestId) {
          return request.copyWith(status: 'APPROVED');
        }
        return request;
      }).toList();

      _allRequests = updatedRequests;
      emit(InventoryLoaded(requests: updatedRequests));
    } catch (e) {
      emit(InventoryError(message: 'Failed to approve: $e'));
    }
  }

  Future<void> _onRejectInventoryRequest(
      RejectInventoryRequest event,
      Emitter<InventoryState> emit,
      ) async {
    try {
      // Call the actual API to reject
      await _apiService.rejectInventoryRequest(
        requestId: event.requestId,
        reason: event.reason,
      );

      // Update local state
      final updatedRequests = _allRequests.map((request) {
        if (request.id == event.requestId) {
          return request.copyWith(status: 'REJECTED');
        }
        return request;
      }).toList();

      _allRequests = updatedRequests;
      emit(InventoryLoaded(requests: updatedRequests));
    } catch (e) {
      emit(InventoryError(message: 'Failed to reject: $e'));
    }
  }

  Future<void> _onLoadInventoryRequests(LoadInventoryRequests event, Emitter<InventoryState> emit) async {
    try {
      emit(InventoryLoading());
      final requests = await _apiService.getInventoryRequests();

      // Reverse to show newest first
      _allRequests = requests.reversed.toList();
      emit(InventoryLoaded(requests: _allRequests));
    } catch (e) {
      emit(InventoryError(message: "Failed to load requests: $e"));
    }
  }

  Future<void> _onRefreshInventoryRequests(RefreshInventoryRequests event, Emitter<InventoryState> emit) async {
    try {
      final requests = await _apiService.getInventoryRequests();
      _allRequests = requests;
      emit(InventoryLoaded(requests: requests));
    } catch (e) {
      print("Error refreshing inventory requests: $e");
      // Keep current state on refresh error
      if (state is InventoryLoaded) {
        emit(state as InventoryLoaded);
      } else {
        emit(InventoryError(message: "Failed to refresh: $e"));
      }
    }
  }

  void _onSearchInventoryRequests(SearchInventoryRequests event, Emitter<InventoryState> emit) {
    if (_allRequests.isEmpty) return;

    final query = event.query.toLowerCase();
    if (query.isEmpty) {
      emit(InventoryLoaded(requests: _allRequests));
      return;
    }

    final filteredRequests = _allRequests.where((request) {
      return request.id.toLowerCase().contains(query) ||
          request.warehouseName.toLowerCase().contains(query) ||
          request.requestedBy.toLowerCase().contains(query);
    }).toList();

    emit(InventoryLoaded(requests: filteredRequests));
  }

  void _onFilterInventoryRequests(FilterInventoryRequests event, Emitter<InventoryState> emit) {
    if (_allRequests.isEmpty) return;

    final status = event.status;
    List<InventoryRequest> filteredRequests;

    if (status == null) {
      filteredRequests = List.from(_allRequests);
    } else {
      filteredRequests = _allRequests.where((request) {
        return request.status == status;
      }).toList();
    }

    emit(InventoryLoaded(requests: filteredRequests));
  }

  Future<void> _onToggleFavoriteRequest(ToggleFavoriteRequest event, Emitter<InventoryState> emit) async {
    try {
      await _apiService.toggleFavoriteRequest(event.requestId, event.isFavorite);

      // Update local state
      final updatedRequests = _allRequests.map((request) {
        if (request.id == event.requestId) {
          return request.copyWith(isFavorite: event.isFavorite);
        }
        return request;
      }).toList();

      _allRequests = updatedRequests;

      if (state is InventoryLoaded) {
        final currentRequests = (state as InventoryLoaded).requests;
        final updatedCurrentRequests = currentRequests.map((request) {
          if (request.id == event.requestId) {
            return request.copyWith(isFavorite: event.isFavorite);
          }
          return request;
        }).toList();

        emit(InventoryLoaded(requests: updatedCurrentRequests));
      }
    } catch (e) {
      emit(InventoryError(message: 'Failed to update favorite status'));
    }
  }

  Future<void> _onAddInventoryRequest(AddInventoryRequest event, Emitter<InventoryState> emit) async {
    try {
      final createdRequest = await _apiService.createInventoryRequest(event.request);

      // Insert at beginning (index 0) instead of end
      _allRequests.insert(0, createdRequest);

      if (state is InventoryLoaded) {
        final currentRequests = (state as InventoryLoaded).requests;
        // Add to top of current list too
        emit(InventoryLoaded(requests: [createdRequest, ...currentRequests]));
      } else {
        emit(InventoryLoaded(requests: [createdRequest]));
      }
    } catch (e) {
      emit(InventoryError(message: "Failed to create request: $e"));
    }
  }

  Future<void> _onUpdateInventoryRequest(UpdateInventoryRequest event, Emitter<InventoryState> emit) async {
    try {
      final updatedRequest = await _apiService.updateInventoryRequest(
        event.requestId,
        event.request,
      );

      // Update local state
      final index = _allRequests.indexWhere((r) => r.id == event.requestId);
      if (index != -1) {
        _allRequests[index] = updatedRequest;

        if (state is InventoryLoaded) {
          final currentRequests = (state as InventoryLoaded).requests;
          final currentIndex = currentRequests.indexWhere((r) => r.id == event.requestId);
          if (currentIndex != -1) {
            final updatedCurrentRequests = List<InventoryRequest>.from(currentRequests);
            updatedCurrentRequests[currentIndex] = updatedRequest;
            emit(InventoryLoaded(requests: updatedCurrentRequests));
          }
        }
      }
    } catch (e) {
      emit(InventoryError(message: 'Failed to update request: $e'));
    }
  }
}

class UpdateInventoryRequest extends InventoryEvent {
  final String requestId;
  final InventoryRequest request;

  const UpdateInventoryRequest({
    required this.requestId,
    required this.request,
  });
}
