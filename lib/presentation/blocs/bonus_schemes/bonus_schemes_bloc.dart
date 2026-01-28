import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/bonus/bonus_scheme.dart';
import 'bonus_schemes_event.dart';
import 'bonus_schemes_state.dart';

class BonusSchemesBloc extends Bloc<BonusSchemesEvent, BonusSchemesState> {
  final ApiServiceInterface apiService;

  BonusSchemesBloc({required this.apiService}) : super(const BonusSchemesInitial()) {
    on<LoadBonusSchemes>(_onLoadBonusSchemes);
    on<RefreshBonusSchemes>(_onRefreshBonusSchemes);
  }

  Future<void> _onLoadBonusSchemes(
    LoadBonusSchemes event,
    Emitter<BonusSchemesState> emit,
  ) async {
    emit(const BonusSchemesLoading());
    try {
      final schemesData = await apiService.getBonusSchemes(
        includeInactive: event.includeInactive,
      );

      final schemes = schemesData
          .map((json) => BonusScheme.fromJson(json as Map<String, dynamic>))
          .toList();

      emit(BonusSchemesLoaded(schemes));
    } catch (e) {
      emit(BonusSchemesError(e.toString()));
    }
  }

  Future<void> _onRefreshBonusSchemes(
    RefreshBonusSchemes event,
    Emitter<BonusSchemesState> emit,
  ) async {
    // Keep current state while refreshing
    final currentState = state;
    try {
      final schemesData = await apiService.getBonusSchemes(
        includeInactive: false,
      );

      final schemes = schemesData
          .map((json) => BonusScheme.fromJson(json as Map<String, dynamic>))
          .toList();

      emit(BonusSchemesLoaded(schemes));
    } catch (e) {
      // Restore previous state on error or show error
      if (currentState is BonusSchemesLoaded) {
        emit(currentState);
      } else {
        emit(BonusSchemesError(e.toString()));
      }
    }
  }
}
