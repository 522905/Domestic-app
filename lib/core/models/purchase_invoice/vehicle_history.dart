// lib/core/models/purchase_invoice/vehicle_history.dart
class VehicleHistory {
  final Driver driver;
  final String latestVisit;
  final int totalVisits;

  VehicleHistory({
    required this.driver,
    required this.latestVisit,
    required this.totalVisits,
  });

  factory VehicleHistory.fromJson(Map<String, dynamic> json) {
    return VehicleHistory(
      driver: Driver.fromJson(json['driver']),
      latestVisit: json['latest_visit'],
      totalVisits: json['total_visits'],
    );
  }
}

class Driver {
  final int id;
  final String name;
  final String phoneNumber;
  final String? photo;
  final int visitCount;
  final String lastSeenDate;

  Driver({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.photo,
    required this.visitCount,
    required this.lastSeenDate,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      photo: json['photo'],
      visitCount: json['visit_count'],
      lastSeenDate: json['last_seen_date'],
    );
  }
}