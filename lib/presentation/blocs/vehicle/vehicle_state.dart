abstract class VehicleState {
  const VehicleState();
}

class VehicleInitial extends VehicleState {
  const VehicleInitial();
}

class VehicleLoading extends VehicleState {
  const VehicleLoading();
}

class VehicleLoaded extends VehicleState {
  final List<Map<String, dynamic>> vehicles;

  const VehicleLoaded({required this.vehicles});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehicleLoaded && other.vehicles == vehicles;
  }

  @override
  int get hashCode => vehicles.hashCode;
}

class VehicleError extends VehicleState {
  final String message;

  const VehicleError({required this.message});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehicleError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}