import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../core/services/User.dart';
import '../../../domain/entities/offline_delivery/offline_system_status.dart';
import '../../../domain/entities/offline_delivery/distribution_point.dart';
import '../../../domain/entities/offline_delivery/booking_verification.dart';
import '../../../domain/entities/offline_delivery/offline_delivery_token.dart';
import '../../../domain/entities/offline_delivery/offline_delivery_company.dart';
import '../../../domain/entities/offline_delivery/obligation_director.dart';
import '../../../utils/error_handler.dart';
import 'offline_delivery_event.dart';
import 'offline_delivery_state.dart';

class OfflineDeliveryBloc extends Bloc<OfflineDeliveryEvent, OfflineDeliveryState> {
  final ApiServiceInterface _apiService;

  // Cache fields
  OfflineSystemStatus? _cachedStatus;
  List<DistributionPoint> _points = [];
  DistributionPoint? _selectedPoint;
  List<BookingVerification> _verifications = [];
  List<OfflineDeliveryToken> _tokens = [];
  bool _isSupervisor = false;
  DateTime _selectedDate = DateTime.now();
  List<OfflineDeliveryCompany> _companies = [];
  int? _lastSelectedCompanyId;

  // Search
  String _searchQuery = '';
  bool _isTokenSearch = false;

  // Show all verifications toggle
  bool _showAllVerifications = false;

  // Pagination tracking
  String? _nextTokensUrl;
  String? _nextVerificationsUrl;
  bool _hasMoreTokens = false;
  bool _hasMoreVerifications = false;
  bool _isLoadingMoreTokens = false;
  bool _isLoadingMoreVerifications = false;

  // Obligation directors cache
  List<ObligationDirector> _directors = [];

  OfflineDeliveryBloc({required ApiServiceInterface apiService})
      : _apiService = apiService,
        super(OfflineDeliveryInitial()) {
    on<LoadInitialData>(_onLoadInitialData);
    on<PollSystemStatus>(_onPollSystemStatus);
    on<SelectDistributionPoint>(_onSelectDistributionPoint);
    on<LoadTokens>(_onLoadTokens);
    on<RefreshTokens>(_onRefreshTokens);
    on<CreateToken>(_onCreateToken);
    on<DeliverToken>(_onDeliverToken);
    on<LoadVerifications>(_onLoadVerifications);
    on<AttachTokenImages>(_onAttachTokenImages);
    on<CorrectToken>(_onCorrectToken);
    on<QuickDeliver>(_onQuickDeliver);
    on<CreateVerification>(_onCreateVerification);
    on<RetryVerification>(_onRetryVerification);
    on<PollVerifications>(_onPollVerifications);
    on<HandleSilentPush>(_onHandleSilentPush);
    on<SelectDate>(_onSelectDate);
    on<LoadMoreTokens>(_onLoadMoreTokens);
    on<LoadMoreVerifications>(_onLoadMoreVerifications);
    on<SearchTokens>(_onSearchTokens);
    on<SearchVerifications>(_onSearchVerifications);
    on<ToggleShowAllVerifications>(_onToggleShowAll);
    on<LoadObligationDirectors>(_onLoadObligationDirectors);
    on<LookupConsumer>(_onLookupConsumer);
    on<ScanToken>(_onScanToken);
    on<LoadPartnerTokens>(_onLoadPartnerTokens);
  }

  String get _dateString => _selectedDate.toIso8601String().split('T')[0];

  /// Preserve locally-set dacCode values that the API doesn't return
  void _preserveLocalDacCodes(List<BookingVerification> oldList, List<BookingVerification> newList) {
    final dacMap = <String, String>{};
    for (final v in oldList) {
      if (v.dacCode != null && v.dacCode!.isNotEmpty) {
        dacMap[v.id] = v.dacCode!;
      }
    }
    if (dacMap.isEmpty) return;
    for (int i = 0; i < newList.length; i++) {
      final saved = dacMap[newList[i].id];
      if (saved != null && newList[i].dacCode == null) {
        newList[i] = newList[i].copyWith(dacCode: saved);
      }
    }
  }

  void _emitLoaded(Emitter<OfflineDeliveryState> emit) {
    emit(OfflineDeliveryLoaded(
      systemStatus: _cachedStatus!,
      distributionPoints: _points,
      selectedPoint: _selectedPoint,
      verifications: _verifications,
      tokens: _tokens,
      isSupervisor: _isSupervisor,
      selectedDate: _selectedDate,
      hasMoreTokens: _hasMoreTokens,
      hasMoreVerifications: _hasMoreVerifications,
      isLoadingMoreTokens: _isLoadingMoreTokens,
      isLoadingMoreVerifications: _isLoadingMoreVerifications,
      searchQuery: _searchQuery,
      companies: _companies,
      lastSelectedCompanyId: _lastSelectedCompanyId,
      showAllVerifications: _showAllVerifications,
      obligationDirectors: _directors,
    ));
  }

  Future<void> _onLoadInitialData(
    LoadInitialData event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    try {
      emit(OfflineDeliveryLoading());

      final results = await Future.wait([
        _apiService.getOfflineDeliveryStatus(),
        _apiService.getOfflineDeliveryDistributionPoints(),
        _apiService.getOfflineDeliveryCompanies(),
      ]);

      _cachedStatus = OfflineSystemStatus.fromJson(results[0] as Map<String, dynamic>);
      _points = (results[1] as List<dynamic>)
          .map((json) => DistributionPoint.fromJson(json as Map<String, dynamic>))
          .toList();
      _companies = (results[2] as List<dynamic>)
          .map((json) => OfflineDeliveryCompany.fromJson(json as Map<String, dynamic>))
          .toList();

      // Check user roles for supervisor access
      try {
        final roleNames = await User().getRoleNames();
        debugPrint('[OFFLINE] User roles: $roleNames');
        _isSupervisor = roleNames.any((r) {
          final lower = r.toLowerCase();
          return lower == 'general manager' || lower == 'warehouse manager';
        });
        debugPrint('[OFFLINE] isSupervisor: $_isSupervisor');
      } catch (e) {
        debugPrint('Failed to load user roles: $e');
      }

      _emitLoaded(emit);

      // If a distribution point was previously selected (e.g. after retry),
      // reload tokens and verifications for it
      if (_selectedPoint != null) {
        add(const LoadTokens());
        if (_cachedStatus!.isAssisted || _cachedStatus!.isVerified) {
          add(const LoadVerifications());
        }
      }
    } catch (e) {
      debugPrint('[OFFLINE INIT] error type: ${e.runtimeType}, error: $e');
      emit(OfflineDeliveryError(ErrorHandler.handleError(e)));
    }
  }

  /// Silent polling - does NOT emit loading state
  Future<void> _onPollSystemStatus(
    PollSystemStatus event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    try {
      final response = await _apiService.getOfflineDeliveryStatus();
      _cachedStatus = OfflineSystemStatus.fromJson(response);

      // Only emit if we have a loaded state
      if (state is OfflineDeliveryLoaded) {
        _emitLoaded(emit);
      }
    } catch (e) {
      // Silent failure during polling — keep current state
      debugPrint('Poll status failed: $e');
    }
  }

  Future<void> _onSelectDistributionPoint(
    SelectDistributionPoint event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    if (_points.isEmpty) return;
    _selectedPoint = _points.firstWhere(
      (p) => p.id == event.pointId,
      orElse: () => _points.first,
    );

    if (_cachedStatus != null) {
      _emitLoaded(emit);

      // Auto-load tokens for the selected point
      add(const LoadTokens());

      // Also load verifications for ASSISTED/VERIFIED modes
      if (_cachedStatus!.isAssisted || _cachedStatus!.isVerified) {
        add(const LoadVerifications());
      }
    }
  }

  Future<void> _onSelectDate(
    SelectDate event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    _selectedDate = event.date;
    if (_cachedStatus != null) {
      _emitLoaded(emit);
    }

    add(const LoadTokens());
    if (_cachedStatus != null &&
        (_cachedStatus!.isAssisted || _cachedStatus!.isVerified)) {
      add(const LoadVerifications());
    }
  }

  Future<void> _onLoadTokens(
    LoadTokens event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    if (_selectedPoint == null || _cachedStatus == null) return;

    try {
      final response = await _apiService.getOfflineDeliveryTokensPaginated(
        distributionPointId: _selectedPoint!.id,
        date: _dateString,
        search: (_isTokenSearch && _searchQuery.isNotEmpty) ? _searchQuery : null,
      );

      final results = (response['results'] ?? []) as List<dynamic>;
      _tokens = results
          .map((json) => OfflineDeliveryToken.fromJson(json as Map<String, dynamic>))
          .toList();
      _nextTokensUrl = response['next'] as String?;
      _hasMoreTokens = _nextTokensUrl != null;

      _emitLoaded(emit);
    } catch (e) {
      debugPrint('[TOKENS] load failed: ${e.runtimeType} - $e');
      emit(OfflineDeliveryError(ErrorHandler.handleError(e)));
    }
  }

  /// Silent refresh — no loading state emitted
  Future<void> _onRefreshTokens(
    RefreshTokens event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    if (_selectedPoint == null || _cachedStatus == null) return;

    try {
      final response = await _apiService.getOfflineDeliveryTokensPaginated(
        distributionPointId: _selectedPoint!.id,
        date: _dateString,
        search: (_isTokenSearch && _searchQuery.isNotEmpty) ? _searchQuery : null,
      );

      final results = (response['results'] ?? []) as List<dynamic>;
      _tokens = results
          .map((json) => OfflineDeliveryToken.fromJson(json as Map<String, dynamic>))
          .toList();
      _nextTokensUrl = response['next'] as String?;
      _hasMoreTokens = _nextTokensUrl != null;

      if (state is OfflineDeliveryLoaded) {
        _emitLoaded(emit);
      }
    } catch (e) {
      debugPrint('Refresh tokens failed: $e');
    }
  }

  Future<void> _onLoadMoreTokens(
    LoadMoreTokens event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    if (_nextTokensUrl == null || _isLoadingMoreTokens) return;

    try {
      _isLoadingMoreTokens = true;
      _emitLoaded(emit);

      final response = await _apiService.getOfflineDeliveryNextPage(_nextTokensUrl!);
      final results = (response['results'] ?? []) as List<dynamic>;
      final newTokens = results
          .map((json) => OfflineDeliveryToken.fromJson(json as Map<String, dynamic>))
          .toList();

      _tokens.addAll(newTokens);
      _nextTokensUrl = response['next'] as String?;
      _hasMoreTokens = _nextTokensUrl != null;
      _isLoadingMoreTokens = false;

      _emitLoaded(emit);
    } catch (e) {
      _isLoadingMoreTokens = false;
      debugPrint('Load more tokens failed: $e');
      if (_cachedStatus != null) {
        _emitLoaded(emit);
      }
    }
  }

  Future<void> _onCreateToken(
    CreateToken event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    if (_cachedStatus == null) return;

    try {
      emit(TokenCreating());

      final creationType = event.creationType ?? 'STANDARD';

      final data = <String, dynamic>{
        'creation_type': creationType,
        'distribution_point_id': event.distributionPointId,
        'idempotency_key': event.idempotencyKey,
        'company_id': event.companyId,
      };
      _lastSelectedCompanyId = event.companyId;
      if (event.consumerId != null && event.consumerId!.isNotEmpty) {
        data['consumer_id'] = event.consumerId;
      }
      if (event.consumerNumber != null && event.consumerNumber!.isNotEmpty) {
        data['consumer_number'] = event.consumerNumber;
      }
      if (event.orderNumber != null && event.orderNumber!.isNotEmpty) {
        data['order_number'] = event.orderNumber;
      }
      if (event.dacCode != null && event.dacCode!.isNotEmpty) {
        data['dac_code'] = event.dacCode;
      }
      if (event.remark != null && event.remark!.isNotEmpty) {
        data['remark'] = event.remark;
      }
      if (event.bookingVerificationId != null && event.bookingVerificationId!.isNotEmpty) {
        data['booking_verification_id'] = event.bookingVerificationId;
      }
      if (event.overrideReason != null && event.overrideReason!.isNotEmpty) {
        data['override_reason'] = event.overrideReason;
      }
      if (event.consumerNameManual != null && event.consumerNameManual!.isNotEmpty) {
        data['consumer_name_manual'] = event.consumerNameManual;
      }

      // Obligation-specific fields
      if (event.initiationSource != null && event.initiationSource!.isNotEmpty) {
        data['initiation_source'] = event.initiationSource;
      }
      if (event.sourceDeliveryRecordId != null) {
        data['source_delivery_record_id'] = event.sourceDeliveryRecordId;
      }
      if (event.directedById != null) {
        data['directed_by_id'] = event.directedById;
      }
      if (event.deliveryType != null && event.deliveryType!.isNotEmpty) {
        data['delivery_type'] = event.deliveryType;
      }
      if (event.itemCode != null && event.itemCode!.isNotEmpty) {
        data['item_code'] = event.itemCode;
      }
      if (event.quantity != null) {
        data['quantity'] = event.quantity;
      }
      if (event.assignedToId != null) {
        data['assigned_to_id'] = event.assignedToId;
      }
      if (event.emptyArrangement != null && event.emptyArrangement!.isNotEmpty) {
        data['empty_arrangement'] = event.emptyArrangement;
      }
      if (event.emptiesDueDate != null && event.emptiesDueDate!.isNotEmpty) {
        data['empties_due_date'] = event.emptiesDueDate;
      }
      if (event.cashArrangement != null && event.cashArrangement!.isNotEmpty) {
        data['cash_arrangement'] = event.cashArrangement;
      }
      if (event.cashDueDate != null && event.cashDueDate!.isNotEmpty) {
        data['cash_due_date'] = event.cashDueDate;
      }

      // Set evidence_required for supervisor types
      if (creationType == 'SUPERVISOR_OVERRIDE' || creationType == 'OBLIGATION') {
        data['evidence_required'] = true;
      }

      final response = await _apiService.createOfflineDeliveryToken(data);
      final token = OfflineDeliveryToken.fromJson(
        response['token'] as Map<String, dynamic>? ?? response,
      );

      // Add to cache
      _tokens.insert(0, token);

      // Update verification's hasToken if created from a verification
      if (event.bookingVerificationId != null && event.bookingVerificationId!.isNotEmpty) {
        final vIdx = _verifications.indexWhere((v) => v.id == event.bookingVerificationId);
        if (vIdx != -1) {
          _verifications[vIdx] = _verifications[vIdx].copyWith(hasToken: true, tokenId: token.id);
        }
      }

      emit(TokenCreated(token));

      // Emit updated loaded state
      _emitLoaded(emit);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 409) {
        final data = e.response?.data;
        String message = 'Token already exists for this consumer today';
        if (data is Map<String, dynamic>) {
          if (data['error'] is String) message = data['error'];
          else if (data['message'] is String) message = data['message'];
        }
        emit(OfflineDeliveryError(message));
      } else if (statusCode == 400) {
        final data = e.response?.data;
        String message = 'Validation error';
        if (data is Map<String, dynamic>) {
          final errors = <String>[];
          data.forEach((key, value) {
            if (value is List) {
              errors.add('$key: ${value.join(', ')}');
            } else if (value is String) {
              errors.add(value);
            }
          });
          if (errors.isNotEmpty) message = errors.join('\n');
        }
        emit(OfflineDeliveryError(message));
      } else {
        emit(OfflineDeliveryError(ErrorHandler.handleError(e)));
      }
      // Restore loaded state so UI is not stuck
      if (_cachedStatus != null) {
        _emitLoaded(emit);
      }
    } catch (e) {
      emit(OfflineDeliveryError(ErrorHandler.handleError(e)));
      if (_cachedStatus != null) {
        _emitLoaded(emit);
      }
    }
  }

  Future<void> _onDeliverToken(
    DeliverToken event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    if (_cachedStatus == null) return;

    try {
      emit(TokenDelivering());

      final data = <String, dynamic>{};
      if (event.cashCollected != null) {
        data['cash_collected'] = event.cashCollected;
      }
      if (event.dacCode != null && event.dacCode!.isNotEmpty) {
        data['dac_code'] = event.dacCode;
      }
      if (event.emptiesCollected != null) {
        data['empties_collected'] = event.emptiesCollected;
      }

      final response = await _apiService.deliverOfflineDeliveryToken(
        event.tokenId,
        data,
      );

      final updatedToken = OfflineDeliveryToken.fromJson(
        response['token'] as Map<String, dynamic>? ?? response,
      );

      // Update in cache (or add if from scan flow)
      final index = _tokens.indexWhere((t) => t.id == event.tokenId);
      if (index != -1) {
        _tokens[index] = updatedToken;
      } else {
        _tokens.insert(0, updatedToken);
      }

      final message = response['message'] as String? ?? 'Token delivered successfully';
      emit(TokenDelivered(token: updatedToken, message: message));

      _emitLoaded(emit);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400) {
        final data = e.response?.data;
        String message = 'Cannot deliver token';
        if (data is Map<String, dynamic> && data['message'] is String) {
          message = data['message'];
        }
        emit(OfflineDeliveryError(message));
      } else {
        emit(OfflineDeliveryError(ErrorHandler.handleError(e)));
      }
      if (_cachedStatus != null) {
        _emitLoaded(emit);
      }
    } catch (e) {
      emit(OfflineDeliveryError(ErrorHandler.handleError(e)));
      if (_cachedStatus != null) {
        _emitLoaded(emit);
      }
    }
  }

  Future<void> _onLoadVerifications(
    LoadVerifications event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    if (_cachedStatus == null) return;

    try {
      final response = await _apiService.getOfflineDeliveryVerificationsPaginated(
        distributionPointId: _selectedPoint?.id,
        date: _dateString,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        showAll: _showAllVerifications ? true : null,
      );

      final results = (response['results'] ?? []) as List<dynamic>;
      final oldVerifications = _verifications;
      _verifications = results
          .map((json) => BookingVerification.fromJson(json as Map<String, dynamic>))
          .toList();
      _preserveLocalDacCodes(oldVerifications, _verifications);
      _nextVerificationsUrl = response['next'] as String?;
      _hasMoreVerifications = _nextVerificationsUrl != null;

      _emitLoaded(emit);
    } catch (e) {
      debugPrint('[VERIFY BLOC] load failed: ${e.runtimeType} - $e');
      emit(OfflineDeliveryError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onLoadMoreVerifications(
    LoadMoreVerifications event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    if (_nextVerificationsUrl == null || _isLoadingMoreVerifications) return;

    try {
      _isLoadingMoreVerifications = true;
      _emitLoaded(emit);

      final response = await _apiService.getOfflineDeliveryNextPage(_nextVerificationsUrl!);
      final results = (response['results'] ?? []) as List<dynamic>;
      final newVerifications = results
          .map((json) => BookingVerification.fromJson(json as Map<String, dynamic>))
          .toList();

      _verifications.addAll(newVerifications);
      _nextVerificationsUrl = response['next'] as String?;
      _hasMoreVerifications = _nextVerificationsUrl != null;
      _isLoadingMoreVerifications = false;

      _emitLoaded(emit);
    } catch (e) {
      _isLoadingMoreVerifications = false;
      debugPrint('Load more verifications failed: $e');
      if (_cachedStatus != null) {
        _emitLoaded(emit);
      }
    }
  }

  Future<void> _onAttachTokenImages(
    AttachTokenImages event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    if (_cachedStatus == null) return;

    try {
      emit(ImagesAttaching());

      final data = <String, dynamic>{};
      if (event.referenceImage1Url != null) {
        data['reference_image_1'] = event.referenceImage1Url;
      }
      if (event.referenceImage2Url != null) {
        data['reference_image_2'] = event.referenceImage2Url;
      }

      final response = await _apiService.attachOfflineDeliveryTokenImages(
        event.tokenId, data,
      );

      final updatedToken = OfflineDeliveryToken.fromJson(
        response['token'] as Map<String, dynamic>? ?? response,
      );

      final index = _tokens.indexWhere((t) => t.id == event.tokenId);
      if (index != -1) {
        _tokens[index] = updatedToken;
      } else {
        // Token from scan flow — add to cache so detail sheet can find it
        _tokens.insert(0, updatedToken);
      }

      emit(ImagesAttached(updatedToken));
      _emitLoaded(emit);
    } catch (e) {
      emit(OfflineDeliveryError(ErrorHandler.handleError(e)));
      if (_cachedStatus != null) {
        _emitLoaded(emit);
      }
    }
  }

  Future<void> _onCorrectToken(
    CorrectToken event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    if (_cachedStatus == null) return;

    try {
      emit(TokenCorrecting());

      final data = <String, dynamic>{};
      if (event.consumerId != null && event.consumerId!.isNotEmpty) {
        data['consumer_id'] = event.consumerId;
      }
      if (event.consumerNumber != null && event.consumerNumber!.isNotEmpty) {
        data['consumer_number'] = event.consumerNumber;
      }
      if (event.orderNumber != null && event.orderNumber!.isNotEmpty) {
        data['order_number'] = event.orderNumber;
      }
      if (event.dacCode != null && event.dacCode!.isNotEmpty) {
        data['dac_code'] = event.dacCode;
      }

      final response = await _apiService.correctOfflineDeliveryToken(
        event.tokenId, data,
      );

      final updatedToken = OfflineDeliveryToken.fromJson(
        response['token'] as Map<String, dynamic>? ?? response,
      );

      final index = _tokens.indexWhere((t) => t.id == event.tokenId);
      if (index != -1) {
        _tokens[index] = updatedToken;
      }

      emit(TokenCorrected(updatedToken));
      _emitLoaded(emit);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400) {
        final data = e.response?.data;
        String message = 'Correction failed';
        if (data is Map<String, dynamic> && data['message'] is String) {
          message = data['message'];
        }
        emit(OfflineDeliveryError(message));
      } else {
        emit(OfflineDeliveryError(ErrorHandler.handleError(e)));
      }
      if (_cachedStatus != null) {
        _emitLoaded(emit);
      }
    } catch (e) {
      emit(OfflineDeliveryError(ErrorHandler.handleError(e)));
      if (_cachedStatus != null) {
        _emitLoaded(emit);
      }
    }
  }

  Future<void> _onQuickDeliver(
    QuickDeliver event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    if (_cachedStatus == null) return;

    try {
      emit(QuickDelivering());

      final data = <String, dynamic>{
        'distribution_point_id': event.distributionPointId,
        'idempotency_key': event.idempotencyKey,
        'company_id': event.companyId,
      };
      _lastSelectedCompanyId = event.companyId;
      if (event.cashCollected != null) {
        data['cash_collected'] = event.cashCollected;
      }
      if (event.consumerId != null && event.consumerId!.isNotEmpty) {
        data['consumer_id'] = event.consumerId;
      }
      if (event.consumerNumber != null && event.consumerNumber!.isNotEmpty) {
        data['consumer_number'] = event.consumerNumber;
      }
      if (event.orderNumber != null && event.orderNumber!.isNotEmpty) {
        data['order_number'] = event.orderNumber;
      }
      if (event.dacCode != null && event.dacCode!.isNotEmpty) {
        data['dac_code'] = event.dacCode;
      }
      if (event.referenceImage1Url != null) {
        data['reference_image_1'] = event.referenceImage1Url;
      }

      final response = await _apiService.quickDeliverOfflineDelivery(data);

      final token = OfflineDeliveryToken.fromJson(
        response['token'] as Map<String, dynamic>? ?? response,
      );

      _tokens.insert(0, token);

      final message = response['message'] as String? ?? 'Quick delivery completed';
      emit(QuickDelivered(token: token, message: message));
      _emitLoaded(emit);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400) {
        final data = e.response?.data;
        String message = 'Quick delivery failed';
        if (data is Map<String, dynamic>) {
          final errors = <String>[];
          data.forEach((key, value) {
            if (value is List) {
              errors.add('$key: ${value.join(', ')}');
            } else if (value is String) {
              errors.add(value);
            }
          });
          if (errors.isNotEmpty) message = errors.join('\n');
        }
        emit(OfflineDeliveryError(message));
      } else {
        emit(OfflineDeliveryError(ErrorHandler.handleError(e)));
      }
      if (_cachedStatus != null) {
        _emitLoaded(emit);
      }
    } catch (e) {
      emit(OfflineDeliveryError(ErrorHandler.handleError(e)));
      if (_cachedStatus != null) {
        _emitLoaded(emit);
      }
    }
  }

  Future<void> _onCreateVerification(
    CreateVerification event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    if (_cachedStatus == null) return;

    try {
      emit(VerificationCreating());

      final data = <String, dynamic>{
        'idempotency_key': event.idempotencyKey,
        'company_id': event.companyId,
      };
      if (event.distributionPointId != null && event.distributionPointId!.isNotEmpty) {
        data['distribution_point_id'] = event.distributionPointId;
      }
      _lastSelectedCompanyId = event.companyId;
      if (event.consumerId != null && event.consumerId!.isNotEmpty) {
        data['consumer_id'] = event.consumerId;
      }
      if (event.consumerNumber != null && event.consumerNumber!.isNotEmpty) {
        data['consumer_number'] = event.consumerNumber;
      }
      if (event.orderNumber != null && event.orderNumber!.isNotEmpty) {
        data['order_number'] = event.orderNumber;
      }
      if (event.dacCode != null && event.dacCode!.isNotEmpty) {
        data['dac_code'] = event.dacCode;
      }

      final response = await _apiService.createBookingVerification(data);

      var verification = BookingVerification.fromJson(
        response['verification'] as Map<String, dynamic>? ?? response,
      );

      // Preserve dacCode locally since API may not return it
      final sentDacCode = event.dacCode;
      if (sentDacCode != null && sentDacCode.isNotEmpty && verification.dacCode == null) {
        verification = verification.copyWith(dacCode: sentDacCode);
      }

      emit(VerificationCreated(verification));

      // Reload all verifications from API to ensure complete list
      try {
        final allVerifications = await _apiService.getOfflineDeliveryVerificationsPaginated(
          distributionPointId: _selectedPoint?.id,
          date: _dateString,
          showAll: _showAllVerifications ? true : null,
        );
        final results = (allVerifications['results'] ?? []) as List<dynamic>;
        final oldVerifications = _verifications;
        _verifications = results
            .map((json) => BookingVerification.fromJson(json as Map<String, dynamic>))
            .toList();
        _preserveLocalDacCodes(oldVerifications, _verifications);
        _nextVerificationsUrl = allVerifications['next'] as String?;
        _hasMoreVerifications = _nextVerificationsUrl != null;

        // Also preserve dacCode for the newly created verification
        if (sentDacCode != null && sentDacCode.isNotEmpty) {
          final idx = _verifications.indexWhere((v) => v.id == verification.id);
          if (idx != -1 && _verifications[idx].dacCode == null) {
            _verifications[idx] = _verifications[idx].copyWith(dacCode: sentDacCode);
          }
        }
      } catch (_) {
        // Fallback: insert locally if reload fails
        if (!_verifications.any((v) => v.id == verification.id)) {
          _verifications.insert(0, verification);
        }
      }

      _emitLoaded(emit);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400) {
        final data = e.response?.data;
        String message = 'Verification failed';
        if (data is Map<String, dynamic>) {
          final errors = <String>[];
          data.forEach((key, value) {
            if (value is List) {
              errors.add('$key: ${value.join(', ')}');
            } else if (value is String) {
              errors.add(value);
            }
          });
          if (errors.isNotEmpty) message = errors.join('\n');
        }
        emit(OfflineDeliveryError(message));
      } else {
        emit(OfflineDeliveryError(ErrorHandler.handleError(e)));
      }
      if (_cachedStatus != null) {
        _emitLoaded(emit);
      }
    } catch (e) {
      emit(OfflineDeliveryError(ErrorHandler.handleError(e)));
      if (_cachedStatus != null) {
        _emitLoaded(emit);
      }
    }
  }

  Future<void> _onRetryVerification(
    RetryVerification event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    if (_cachedStatus == null) return;

    try {
      final response = await _apiService.retryBookingVerification(event.verificationId);

      final updatedVerification = BookingVerification.fromJson(
        response['verification'] as Map<String, dynamic>? ?? response,
      );

      final index = _verifications.indexWhere((v) => v.id == event.verificationId);
      if (index != -1) {
        _verifications[index] = updatedVerification;
      }

      _emitLoaded(emit);
    } catch (e) {
      emit(OfflineDeliveryError(ErrorHandler.handleError(e)));
      if (_cachedStatus != null) {
        _emitLoaded(emit);
      }
    }
  }

  /// Silent polling for verifications — no loading state
  Future<void> _onPollVerifications(
    PollVerifications event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    if (_cachedStatus == null) return;

    try {
      final response = await _apiService.getOfflineDeliveryVerificationsPaginated(
        distributionPointId: _selectedPoint?.id,
        date: _dateString,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        showAll: _showAllVerifications ? true : null,
      );

      final results = (response['results'] ?? []) as List<dynamic>;
      final oldVerifications = _verifications;
      _verifications = results
          .map((json) => BookingVerification.fromJson(json as Map<String, dynamic>))
          .toList();
      _preserveLocalDacCodes(oldVerifications, _verifications);
      _nextVerificationsUrl = response['next'] as String?;
      _hasMoreVerifications = _nextVerificationsUrl != null;

      if (state is OfflineDeliveryLoaded) {
        _emitLoaded(emit);
      }
    } catch (e) {
      debugPrint('Poll verifications failed: $e');
    }
  }

  Future<void> _onHandleSilentPush(
    HandleSilentPush event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    switch (event.resource) {
      case 'system_status':
        add(const PollSystemStatus());
        break;
      case 'distribution_point':
        // Re-fetch points and emit loaded
        try {
          final response = await _apiService.getOfflineDeliveryDistributionPoints();
          _points = response
              .map((json) => DistributionPoint.fromJson(json as Map<String, dynamic>))
              .toList();
          if (_selectedPoint != null) {
            _selectedPoint = _points.firstWhere(
              (p) => p.id == _selectedPoint!.id,
              orElse: () => _points.isNotEmpty ? _points.first : _selectedPoint!,
            );
          }
          if (_cachedStatus != null) {
            _emitLoaded(emit);
          }
        } catch (e) {
          debugPrint('Silent push distribution_point refresh failed: $e');
        }
        break;
      case 'booking_verification':
        add(const PollVerifications());
        break;
      case 'delivery_token':
        add(const RefreshTokens());
        break;
      default:
        debugPrint('Unknown silent push resource: ${event.resource}');
    }
  }

  Future<void> _onSearchTokens(
    SearchTokens event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    _isTokenSearch = true;
    _searchQuery = event.query;
    // Reset pagination and reload
    _tokens = [];
    _nextTokensUrl = null;
    _hasMoreTokens = false;
    if (_selectedPoint != null && _cachedStatus != null) {
      _emitLoaded(emit);
      try {
        final response = await _apiService.getOfflineDeliveryTokensPaginated(
          distributionPointId: _selectedPoint!.id,
          date: _dateString,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
        );
        final results = (response['results'] ?? []) as List<dynamic>;
        _tokens = results
            .map((json) => OfflineDeliveryToken.fromJson(json as Map<String, dynamic>))
            .toList();
        _nextTokensUrl = response['next'] as String?;
        _hasMoreTokens = _nextTokensUrl != null;
        _emitLoaded(emit);
      } catch (e) {
        debugPrint('Search tokens failed: $e');
        _emitLoaded(emit);
      }
    }
  }

  Future<void> _onSearchVerifications(
    SearchVerifications event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    _isTokenSearch = false;
    _searchQuery = event.query;
    // Reset pagination and reload
    final oldVerifications = _verifications;
    _verifications = [];
    _nextVerificationsUrl = null;
    _hasMoreVerifications = false;
    if (_cachedStatus != null) {
      _emitLoaded(emit);
      try {
        final response = await _apiService.getOfflineDeliveryVerificationsPaginated(
          distributionPointId: _selectedPoint?.id,
          date: _dateString,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          showAll: _showAllVerifications ? true : null,
        );
        final results = (response['results'] ?? []) as List<dynamic>;
        _verifications = results
            .map((json) => BookingVerification.fromJson(json as Map<String, dynamic>))
            .toList();
        _preserveLocalDacCodes(oldVerifications, _verifications);
        _nextVerificationsUrl = response['next'] as String?;
        _hasMoreVerifications = _nextVerificationsUrl != null;
        _emitLoaded(emit);
      } catch (e) {
        debugPrint('Search verifications failed: $e');
        _emitLoaded(emit);
      }
    }
  }

  Future<void> _onToggleShowAll(
    ToggleShowAllVerifications event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    _showAllVerifications = event.showAll;
    if (_cachedStatus == null) return;
    _emitLoaded(emit);
    add(const LoadVerifications());
  }

  Future<void> _onLoadObligationDirectors(
    LoadObligationDirectors event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    try {
      final results = await _apiService.getObligationDirectors(event.companyId);
      _directors = results
          .map((json) => ObligationDirector.fromJson(json as Map<String, dynamic>))
          .toList();
      if (_cachedStatus != null) {
        _emitLoaded(emit);
      }
    } catch (e) {
      debugPrint('Load obligation directors failed: $e');
    }
  }

  Future<void> _onLookupConsumer(
    LookupConsumer event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    try {
      emit(ConsumerLookupLoading());
      final response = await _apiService.lookupConsumer(event.consumerNumber);
      final records = (response['results'] ?? []) as List<dynamic>;
      emit(ConsumerLookupResult(
        records.map((r) => r as Map<String, dynamic>).toList(),
      ));
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Lookup failed';
      if (data is Map<String, dynamic> && data['message'] is String) {
        message = data['message'];
      }
      emit(ConsumerLookupError(message));
    } catch (e) {
      emit(ConsumerLookupError(ErrorHandler.handleError(e)));
    }
    if (_cachedStatus != null) {
      _emitLoaded(emit);
    }
  }

  Future<void> _onScanToken(
    ScanToken event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    try {
      emit(TokenScanning());
      final response = await _apiService.scanToken(
        uuid: event.uuid,
        tokenNumber: event.tokenNumber,
        distributionPointId: event.distributionPointId,
      );
      final token = OfflineDeliveryToken.fromJson(response);
      // Update cache so detail sheet can find it with fresh available_actions
      final index = _tokens.indexWhere((t) => t.id == token.id);
      if (index != -1) {
        _tokens[index] = token;
      } else {
        _tokens.insert(0, token);
      }
      emit(TokenScanned(token));
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Token not found';
      if (statusCode == 404) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          message = data['detail']?.toString() ?? data['message']?.toString() ?? 'Token not found';
        }
      } else if (statusCode == 400) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          final errors = <String>[];
          data.forEach((key, value) {
            if (value is List) {
              errors.add('${value.join(', ')}');
            } else if (value is String) {
              errors.add(value);
            }
          });
          message = errors.isNotEmpty ? errors.join('\n') : 'Invalid request';
        }
      } else {
        message = ErrorHandler.handleError(e);
      }
      emit(TokenScanError(message));
    } catch (e) {
      emit(TokenScanError(ErrorHandler.handleError(e)));
    }
    if (_cachedStatus != null) {
      _emitLoaded(emit);
    }
  }

  Future<void> _onLoadPartnerTokens(
    LoadPartnerTokens event,
    Emitter<OfflineDeliveryState> emit,
  ) async {
    try {
      emit(PartnerTokensLoading());
      final response = await _apiService.getMyPartnerTokens(
        event.companyId,
        status: event.status,
      );
      final results = (response['results'] ?? []) as List<dynamic>;
      final tokens = results
          .map((json) => OfflineDeliveryToken.fromJson(json as Map<String, dynamic>))
          .toList();
      emit(PartnerTokensLoaded(tokens));
    } catch (e) {
      debugPrint('Load partner tokens failed: $e');
      emit(PartnerTokensLoaded(const []));
    }
  }
}
