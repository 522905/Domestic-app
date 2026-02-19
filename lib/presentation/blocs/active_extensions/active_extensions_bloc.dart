import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/credit_extension/active_extension_summary.dart';
import 'active_extensions_event.dart';
import 'active_extensions_state.dart';

class ActiveExtensionsBloc
    extends Bloc<ActiveExtensionsEvent, ActiveExtensionsState> {
  final ApiServiceInterface apiService;

  ActiveExtensionsBloc({required this.apiService})
      : super(ActiveExtensionsInitial()) {
    on<LoadActiveExtensions>(_onLoadActiveExtensions);
    on<RefreshActiveExtensions>(_onRefreshActiveExtensions);
  }

  Future<void> _onLoadActiveExtensions(
    LoadActiveExtensions event,
    Emitter<ActiveExtensionsState> emit,
  ) async {
    emit(ActiveExtensionsLoading());

    try {
      final response = await apiService.getActiveCreditExtensions();
      final summary = ActiveExtensionSummary.fromJson(response);
      emit(ActiveExtensionsLoaded(summary));
    } catch (e) {
      emit(ActiveExtensionsError(e.toString()));
    }
  }

  Future<void> _onRefreshActiveExtensions(
    RefreshActiveExtensions event,
    Emitter<ActiveExtensionsState> emit,
  ) async {
    try {
      final response = await apiService.getActiveCreditExtensions();
      final summary = ActiveExtensionSummary.fromJson(response);
      emit(ActiveExtensionsLoaded(summary));
    } catch (e) {
      emit(ActiveExtensionsError(e.toString()));
    }
  }
}
