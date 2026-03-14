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

  // Pagination tracking
  String? _nextTokensUrl;
  String? _nextVerificationsUrl;
  bool _hasMoreTokens = false;
  bool _hasMoreVerifications = false;
  bool _isLoadingMoreTokens = false;
  bool _isLoadingMoreVerifications = false;

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
  }

  String get _dateString => _selectedDate.toIso8601String().split('T')[0];

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
        _isSupervisor = roleNames.any(
          (r) => r.toUpperCase() == 'GM' || r.toUpperCase() == 'WM',
        );
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
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
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

      // Set evidence_required for supervisor types
      if (creationType == 'SUPERVISOR_OVERRIDE' || creationType == 'OWNERS_REFERENCE') {
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
          _verifications[vIdx] = _verifications[vIdx].copyWith(hasToken: true);
        }
      }

      emit(TokenCreated(token));

      // Emit updated loaded state
      _emitLoaded(emit);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 409) {
        emit(const OfflineDeliveryError('Token already exists for this consumer today'));
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

      final data = <String, dynamic>{
        'cash_collected': event.cashCollected,
      };
      if (event.dacCode != null && event.dacCode!.isNotEmpty) {
        data['dac_code'] = event.dacCode;
      }

      final response = await _apiService.deliverOfflineDeliveryToken(
        event.tokenId,
        data,
      );

      final updatedToken = OfflineDeliveryToken.fromJson(
        response['token'] as Map<String, dynamic>? ?? response,
      );

      // Update in cache
      final index = _tokens.indexWhere((t) => t.id == event.tokenId);
      if (index != -1) {
        _tokens[index] = updatedToken;
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
    if (_selectedPoint == null || _cachedStatus == null) return;

    try {
      final response = await _apiService.getOfflineDeliveryVerificationsPaginated(
        distributionPointId: _selectedPoint!.id,
        date: _dateString,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      final results = (response['results'] ?? []) as List<dynamic>;
      _verifications = results
          .map((json) => BookingVerification.fromJson(json as Map<String, dynamic>))
          .toList();
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
        'cash_collected': event.cashCollected,
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

      final response = await _apiService.createBookingVerification(data);

      final verification = BookingVerification.fromJson(
        response['verification'] as Map<String, dynamic>? ?? response,
      );

      emit(VerificationCreated(verification));

      // Reload all verifications from API to ensure complete list
      try {
        final allVerifications = await _apiService.getOfflineDeliveryVerificationsPaginated(
          distributionPointId: _selectedPoint!.id,
          date: _dateString,
        );
        final results = (allVerifications['results'] ?? []) as List<dynamic>;
        _verifications = results
            .map((json) => BookingVerification.fromJson(json as Map<String, dynamic>))
            .toList();
        _nextVerificationsUrl = allVerifications['next'] as String?;
        _hasMoreVerifications = _nextVerificationsUrl != null;
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
    if (_selectedPoint == null || _cachedStatus == null) return;

    try {
      final response = await _apiService.getOfflineDeliveryVerificationsPaginated(
        distributionPointId: _selectedPoint!.id,
        date: _dateString,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      final results = (response['results'] ?? []) as List<dynamic>;
      _verifications = results
          .map((json) => BookingVerification.fromJson(json as Map<String, dynamic>))
          .toList();
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
    _searchQuery = event.query;
    // Reset pagination and reload
    _verifications = [];
    _nextVerificationsUrl = null;
    _hasMoreVerifications = false;
    if (_selectedPoint != null && _cachedStatus != null) {
      _emitLoaded(emit);
      try {
        final response = await _apiService.getOfflineDeliveryVerificationsPaginated(
          distributionPointId: _selectedPoint!.id,
          date: _dateString,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
        );
        final results = (response['results'] ?? []) as List<dynamic>;
        _verifications = results
            .map((json) => BookingVerification.fromJson(json as Map<String, dynamic>))
            .toList();
        _nextVerificationsUrl = response['next'] as String?;
        _hasMoreVerifications = _nextVerificationsUrl != null;
        _emitLoaded(emit);
      } catch (e) {
        debugPrint('Search verifications failed: $e');
        _emitLoaded(emit);
      }
    }
  }
}
