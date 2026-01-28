import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/bonus/bonus.dart';
import 'bonus_detail_event.dart';
import 'bonus_detail_state.dart';

class BonusDetailBloc extends Bloc<BonusDetailEvent, BonusDetailState> {
  final ApiServiceInterface apiService;

  BonusDetailBloc({required this.apiService}) : super(const BonusDetailInitial()) {
    on<LoadBonusDetail>(_onLoadBonusDetail);
    on<RefreshBonusDetail>(_onRefreshBonusDetail);
  }

  Future<void> _onLoadBonusDetail(
    LoadBonusDetail event,
    Emitter<BonusDetailState> emit,
  ) async {
    emit(const BonusDetailLoading());
    try {
      final bonusData = await apiService.getBonusDetail(event.bonusId);
      final bonus = Bonus.fromJson(bonusData);
      emit(BonusDetailLoaded(bonus));
    } catch (e) {
      emit(BonusDetailError(e.toString()));
    }
  }

  Future<void> _onRefreshBonusDetail(
    RefreshBonusDetail event,
    Emitter<BonusDetailState> emit,
  ) async {
    // Keep current state while refreshing
    final currentState = state;
    try {
      final bonusData = await apiService.getBonusDetail(event.bonusId);
      final bonus = Bonus.fromJson(bonusData);
      emit(BonusDetailLoaded(bonus));
    } catch (e) {
      // Restore previous state on error or show error
      if (currentState is BonusDetailLoaded) {
        emit(currentState);
      } else {
        emit(BonusDetailError(e.toString()));
      }
    }
  }
}
