import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lpg_distribution_app/core/models/inventory/inventory_request.dart';
import 'package:lpg_distribution_app/core/services/api_service_interface.dart';
import '../../../utils/error_handler.dart';
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
    on<LoadInventoryRequestDetail>(_onLoadInventoryRequestDetail);
    on<SearchInventoryRequests>(_onSearchInventoryRequests);
    on<FilterInventoryRequests>(_onFilterInventoryRequests);
    on<ToggleFavoriteRequest>(_onToggleFavoriteRequest);
    on<AddInventoryRequest>(_onAddInventoryRequest);
    on<RefreshInventoryRequests>(_onRefreshInventoryRequests);
    on<UpdateInventoryRequest>(_onUpdateInventoryRequest);
    on<ApproveInventoryRequest>(_onApproveInventoryRequest);
    on<RejectInventoryRequest>(_onRejectInventoryRequest);
    on<ClearInventoryCache>(_onClearInventoryCache);
  }

  Future<void> _onLoadInventoryRequestDetail(
      LoadInventoryRequestDetail event,
      Emitter<InventoryState> emit,
      ) async {
    try {
      emit(InventoryDetailLoading());
      final requestDetail = await _apiService.getInventoryRequestDetail(event.requestId);
      emit(InventoryDetailLoaded(request: requestDetail));
    } catch (e) {
      emit(InventoryDetailError(message: ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onApproveInventoryRequest(
      ApproveInventoryRequest event,
      Emitter<InventoryState> emit,
      ) async {
    try {
      await _apiService.approveInventoryRequest(
        requestId: event.requestId,
        requestType: event.requestType,
      );

      final updatedRequests = _allRequests.map((request) {
        if (request.id == event.requestId) {
          return request.copyWith(status: 'APPROVED');
        }
        return request;
      }).toList();

      _allRequests = updatedRequests;
      emit(InventoryLoaded(requests: updatedRequests));
    } catch (e) {
      emit(InventoryError(message: ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onRejectInventoryRequest(
      RejectInventoryRequest event,
      Emitter<InventoryState> emit,
      ) async {
    try {
      await _apiService.rejectInventoryRequest(
        requestId: event.requestId,
        reason: event.reason,
        requestType: event.requestType,
      );

      final updatedRequests = _allRequests.map((request) {
        if (request.id == event.requestId) {
          return request.copyWith(status: 'REJECTED');
        }
        return request;
      }).toList();

      _allRequests = updatedRequests;
      emit(InventoryLoaded(requests: updatedRequests));
    } catch (e) {
      emit(InventoryError(message: ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onLoadInventoryRequests(
      LoadInventoryRequests event,
      Emitter<InventoryState> emit
      ) async {
    try {
      emit(InventoryLoading());
      final requests = await _apiService.getInventoryRequests();

      // Sort by timestamp - newest first (better than just reversing)
      requests.sort((a, b) {
        final dateA = DateTime.parse(a.timestamp);
        final dateB = DateTime.parse(b.timestamp);
        return dateB.compareTo(dateA); // Newest first
      });

      _allRequests = requests;
      emit(InventoryLoaded(requests: _allRequests));
    } catch (e) {
      emit(InventoryError(message: ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onRefreshInventoryRequests(
      RefreshInventoryRequests event,
      Emitter<InventoryState> emit
      ) async {
    try {
      // Don't emit loading state for refresh to avoid UI flicker
      final requests = await _apiService.getInventoryRequests();

      // Sort by timestamp - newest first (better than just reversing)
      requests.sort((a, b) {
        final dateA = DateTime.parse(a.timestamp);
        final dateB = DateTime.parse(b.timestamp);
        return dateB.compareTo(dateA); // Newest first
      });

      _allRequests = requests;
      emit(InventoryLoaded(requests: _allRequests));
    } catch (e) {
      print("Error refreshing inventory requests: $e");
      // If refresh fails, keep current state if available, otherwise show error
      if (state is InventoryLoaded) {
        // Keep the current state - don't re-emit the same state
        return;
      } else {
        emit(InventoryError(message: ErrorHandler.handleError(e)));
      }
    }
  }

  void _onSearchInventoryRequests(
      SearchInventoryRequests event,
      Emitter<InventoryState> emit
      ) {
    if (_allRequests.isEmpty) return;

    final query = event.query.toLowerCase();
    if (query.isEmpty) {
      emit(InventoryLoaded(requests: _allRequests));
      return;
    }

    final filteredRequests = _allRequests.where((request) {
      return request.id.toLowerCase().contains(query) ||
          request.warehouse.toLowerCase().contains(query) ||
          request.requestedBy.toLowerCase().contains(query);
    }).toList();

    emit(InventoryLoaded(requests: filteredRequests));
  }

  void _onFilterInventoryRequests(
      FilterInventoryRequests event,
      Emitter<InventoryState> emit
      ) {
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

  Future<void> _onToggleFavoriteRequest(
      ToggleFavoriteRequest event,
      Emitter<InventoryState> emit
      ) async {
    try {
      await _apiService.toggleFavoriteRequest(event.requestId, event.isFavorite);

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
      emit(InventoryError(message: ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onAddInventoryRequest(
      AddInventoryRequest event,
      Emitter<InventoryState> emit
      ) async {
    try {
      final createdRequest = await _apiService.createInventoryRequest(event.request);

      // Add to the beginning of _allRequests (newest first)
      _allRequests.insert(0, createdRequest);

      // Always emit the updated list with the new request at the top
      emit(InventoryLoaded(requests: List.from(_allRequests)));

    } catch (e) {
      emit(InventoryError(message: ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onUpdateInventoryRequest(
      UpdateInventoryRequest event,
      Emitter<InventoryState> emit
      ) async {
    try {
      final updatedRequest = await _apiService.updateInventoryRequest(
        event.requestId,
        event.request,
      );

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
      emit(InventoryError(message: ErrorHandler.handleError(e)));
    }
  }

  void _onClearInventoryCache(ClearInventoryCache event, Emitter<InventoryState> emit) {
    _allRequests = [];
    emit(InventoryInitial());
  }
}