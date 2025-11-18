abstract class VehicleEvent {
  const VehicleEvent();
}

class LoadVehicles extends VehicleEvent {
  const LoadVehicles();
}

class RefreshVehicles extends VehicleEvent {
  const RefreshVehicles();
}

class ClearVehicleCache extends VehicleEvent {
  const ClearVehicleCache();
}

