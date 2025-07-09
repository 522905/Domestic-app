class Vehicle {
  final String id;
  final String registrationNumber;
  final bool isAvailable;
  final DateTime? cooldownUntil;

  const Vehicle({
    required this.id,
    required this.registrationNumber,
    required this.isAvailable,
    this.cooldownUntil,
  });
}