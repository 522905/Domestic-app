class Vehicle {
  final String id;
  final String vehicleNumber;
  final bool isAvailable;
  final DateTime? cooldownUntil;
  final String? driverName;



  const Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.isAvailable,
    this.cooldownUntil,
    this.driverName,
  });
}