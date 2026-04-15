import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/offline_delivery/offline_delivery_token.dart';
import '../../../utils/error_handler.dart';
import 'obligation_collection_event.dart';
import 'obligation_collection_state.dart';

class ObligationCollectionBloc
    extends Bloc<ObligationCollectionEvent, ObligationCollectionState> {
  final ApiServiceInterface _apiService;

  List<OfflineDeliveryToken> _tokens = [];
  int _companyId = 0;
  String _date = '';

  ObligationCollectionBloc({required ApiServiceInterface apiService})
      : _apiService = apiService,
        super(ObligationCollectionInitial()) {
    on<LoadDueCollections>(_onLoadDueCollections);
    on<RefreshCollections>(_onRefreshCollections);
    on<CollectEmpties>(_onCollectEmpties);
    on<CollectCash>(_onCollectCash);
  }

  void _emitLoaded(Emitter<ObligationCollectionState> emit) {
    emit(ObligationCollectionLoaded(
      tokens: _tokens,
      selectedDate: DateTime.tryParse(_date) ?? DateTime.now(),
      companyId: _companyId,
    ));
  }

  Future<void> _onLoadDueCollections(
    LoadDueCollections event,
    Emitter<ObligationCollectionState> emit,
  ) async {
    _companyId = event.companyId;
    _date = event.date;

    try {
      emit(ObligationCollectionLoading());
      final response = await _apiService.getDueCollections(
        event.companyId,
        event.date,
      );
      final results = (response['results'] ?? []) as List<dynamic>;
      _tokens = results
          .map((json) =>
              OfflineDeliveryToken.fromJson(json as Map<String, dynamic>))
          .toList();
      _emitLoaded(emit);
    } catch (e) {
      emit(ObligationCollectionError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onRefreshCollections(
    RefreshCollections event,
    Emitter<ObligationCollectionState> emit,
  ) async {
    if (_companyId == 0 || _date.isEmpty) return;
    try {
      final response = await _apiService.getDueCollections(_companyId, _date);
      final results = (response['results'] ?? []) as List<dynamic>;
      _tokens = results
          .map((json) =>
              OfflineDeliveryToken.fromJson(json as Map<String, dynamic>))
          .toList();
      _emitLoaded(emit);
    } catch (e) {
      debugPrint('Refresh collections failed: $e');
    }
  }

  Future<void> _onCollectEmpties(
    CollectEmpties event,
    Emitter<ObligationCollectionState> emit,
  ) async {
    try {
      emit(EmptiesCollecting());
      final response = await _apiService.collectEmpties(
        event.tokenId,
        event.count,
      );
      final updatedToken = OfflineDeliveryToken.fromJson(
        response['token'] as Map<String, dynamic>? ?? response,
      );

      final index = _tokens.indexWhere((t) => t.id == event.tokenId);
      if (index != -1) {
        _tokens[index] = updatedToken;
      }

      emit(EmptiesCollected(updatedToken));
      _emitLoaded(emit);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Failed to record empty collection';
      if (data is Map<String, dynamic> && data['message'] is String) {
        message = data['message'];
      }
      emit(ObligationCollectionError(message));
      _emitLoaded(emit);
    } catch (e) {
      emit(ObligationCollectionError(ErrorHandler.handleError(e)));
      _emitLoaded(emit);
    }
  }

  Future<void> _onCollectCash(
    CollectCash event,
    Emitter<ObligationCollectionState> emit,
  ) async {
    try {
      emit(CashCollecting());
      final response = await _apiService.collectCash(event.tokenId);
      final updatedToken = OfflineDeliveryToken.fromJson(
        response['token'] as Map<String, dynamic>? ?? response,
      );

      final index = _tokens.indexWhere((t) => t.id == event.tokenId);
      if (index != -1) {
        _tokens[index] = updatedToken;
      }

      emit(CashCollected(updatedToken));
      _emitLoaded(emit);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Failed to record cash collection';
      if (data is Map<String, dynamic> && data['message'] is String) {
        message = data['message'];
      }
      emit(ObligationCollectionError(message));
      _emitLoaded(emit);
    } catch (e) {
      emit(ObligationCollectionError(ErrorHandler.handleError(e)));
      _emitLoaded(emit);
    }
  }
}
