import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import 'vehicle_event.dart';
import 'vehicle_state.dart';

class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final ApiServiceInterface apiService;
  List<Map<String, dynamic>> _cachedVehicles = [];

  VehicleBloc({required this.apiService}) : super(const VehicleInitial()) {
    on<LoadVehicles>(_onLoadVehicles);
    on<RefreshVehicles>(_onRefreshVehicles);
    on<ClearVehicleCache>(_onClearCache);
  }

  Future<void> _onLoadVehicles(LoadVehicles event, Emitter<VehicleState> emit) async {
    // Return cached data if available
    if (_cachedVehicles.isNotEmpty) {
      emit(VehicleLoaded(vehicles: _cachedVehicles));
      return;
    }

    emit(const VehicleLoading());
    try {
      final vehicles = await apiService.getVehiclesList();
      _cachedVehicles = List<Map<String, dynamic>>.from(vehicles);
      emit(VehicleLoaded(vehicles: _cachedVehicles));
    } catch (e) {
      emit(VehicleError(message: e.toString()));
    }
  }

  Future<void> _onRefreshVehicles(RefreshVehicles event, Emitter<VehicleState> emit) async {
    emit(const VehicleLoading());
    try {
      final vehicles = await apiService.getVehiclesList();
      _cachedVehicles = List<Map<String, dynamic>>.from(vehicles);
      emit(VehicleLoaded(vehicles: _cachedVehicles));
    } catch (e) {
      emit(VehicleError(message: e.toString()));
    }
  }

  void _onClearCache(ClearVehicleCache event, Emitter<VehicleState> emit) {
    _cachedVehicles.clear();
    emit(const VehicleInitial());
  }
}