import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/ujjwala/lpg_ops_installation.dart';
import 'my_installations_event.dart';
import 'my_installations_state.dart';

class MyInstallationsBloc
    extends Bloc<MyInstallationsEvent, MyInstallationsState> {
  final ApiServiceInterface apiService;

  List<LpgOpsInstallation> _allInstallations = [];
  String _scope = 'mine';
  String? _statusFilter;
  Timer? _pollingTimer;

  MyInstallationsBloc({required this.apiService})
      : super(const MyInstallationsInitial()) {
    on<LoadMyInstallations>(_onLoad);
    on<RefreshMyInstallations>(_onRefresh);
    on<ChangeScopeFilter>(_onChangeScopeFilter);
    on<ChangeStatusFilter>(_onChangeStatusFilter);
    on<BulkVerifyInstallations>(_onBulkVerify);
    on<RetryFailedInstallations>(_onRetryFailed);
    on<PollMyInstallations>(_onPoll);
  }

  Future<void> _onLoad(
    LoadMyInstallations event,
    Emitter<MyInstallationsState> emit,
  ) async {
    emit(const MyInstallationsLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    RefreshMyInstallations event,
    Emitter<MyInstallationsState> emit,
  ) async {
    emit(const MyInstallationsLoading());
    _allInstallations = [];
    await _fetchAndEmit(emit);
  }

  Future<void> _onChangeScopeFilter(
    ChangeScopeFilter event,
    Emitter<MyInstallationsState> emit,
  ) async {
    if (_scope == event.scope) return;
    _scope = event.scope;
    _allInstallations = [];
    emit(const MyInstallationsLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onChangeStatusFilter(
    ChangeStatusFilter event,
    Emitter<MyInstallationsState> emit,
  ) async {
    if (_statusFilter == event.status) return;
    _statusFilter = event.status;
    _allInstallations = [];
    emit(const MyInstallationsLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onBulkVerify(
    BulkVerifyInstallations event,
    Emitter<MyInstallationsState> emit,
  ) async {
    try {
      await apiService.bulkVerifyInstallations(event.ids);
      _allInstallations = [];
      await _fetchAndEmit(emit);
    } catch (e) {
      // Re-emit current state on error — caller handles snackbar
      rethrow;
    }
  }

  Future<void> _onRetryFailed(
    RetryFailedInstallations event,
    Emitter<MyInstallationsState> emit,
  ) async {
    try {
      await apiService.retryFailedInstallations(event.ids);
      _allInstallations = [];
      await _fetchAndEmit(emit);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _onPoll(
    PollMyInstallations event,
    Emitter<MyInstallationsState> emit,
  ) async {
    // Silent re-fetch — do NOT emit loading state
    try {
      final response = await apiService.getLpgOpsInstallations(
        scope: _scope,
        status: _statusFilter,
      );
      final installations = response
          .map((json) =>
              LpgOpsInstallation.fromJson(json as Map<String, dynamic>))
          .toList();
      _allInstallations = installations;
      _emitLoaded(emit, installations);
    } catch (_) {
      // Silently ignore poll errors
    }
  }

  Future<void> _fetchAndEmit(Emitter<MyInstallationsState> emit) async {
    try {
      final response = await apiService.getLpgOpsInstallations(
        scope: _scope,
        status: _statusFilter,
      );
      final installations = response
          .map((json) =>
              LpgOpsInstallation.fromJson(json as Map<String, dynamic>))
          .toList();
      _allInstallations = installations;

      if (installations.isEmpty) {
        _stopPolling();
        emit(MyInstallationsEmpty(scope: _scope, statusFilter: _statusFilter));
      } else {
        _emitLoaded(emit, installations);
      }
    } catch (e) {
      _stopPolling();
      emit(MyInstallationsError(message: e.toString()));
    }
  }

  void _emitLoaded(
      Emitter<MyInstallationsState> emit, List<LpgOpsInstallation> installations) {
    final hasPending = installations
        .any((i) => i.status == 'PENDING_VERIFICATION');

    emit(MyInstallationsLoaded(
      installations: installations,
      scope: _scope,
      statusFilter: _statusFilter,
      hasPendingVerification: hasPending,
    ));

    if (hasPending) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  void _startPolling() {
    if (_pollingTimer?.isActive == true) return;
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      add(const PollMyInstallations());
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
