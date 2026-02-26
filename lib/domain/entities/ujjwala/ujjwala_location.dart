import 'package:equatable/equatable.dart';

class UjjwalaLocation extends Equatable {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  const UjjwalaLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [latitude, longitude, accuracy, timestamp];

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
      };

  factory UjjwalaLocation.fromJson(Map<String, dynamic> json) =>
      UjjwalaLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracy: (json['accuracy'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  UjjwalaLocation copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return UjjwalaLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
