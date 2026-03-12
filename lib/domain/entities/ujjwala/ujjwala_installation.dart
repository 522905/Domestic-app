import 'package:equatable/equatable.dart';

class UjjwalaInstallation extends Equatable {
  final int id;
  final String applicationNumber;
  final String consumerNumber;
  final String consumerName;
  final String? consumerPhoto;
  final String mobileNumber;
  final String address;
  final String status;
  final DateTime materialDeliveredDate;
  final DateTime? installationDate;
  final String? kitchenPhotoUrl;
  final String? gatePhotoUrl;
  final String? stovePhotoUrl;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? googleMapsUrl;
  final String? orderId;

  const UjjwalaInstallation({
    required this.id,
    required this.applicationNumber,
    required this.consumerNumber,
    required this.consumerName,
    this.consumerPhoto,
    required this.mobileNumber,
    required this.address,
    required this.status,
    required this.materialDeliveredDate,
    this.installationDate,
    this.kitchenPhotoUrl,
    this.gatePhotoUrl,
    this.stovePhotoUrl,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.googleMapsUrl,
    this.orderId,
  });

  @override
  List<Object?> get props => [
        id,
        applicationNumber,
        consumerNumber,
        consumerName,
        consumerPhoto,
        mobileNumber,
        address,
        status,
        materialDeliveredDate,
        installationDate,
        kitchenPhotoUrl,
        gatePhotoUrl,
        stovePhotoUrl,
        latitude,
        longitude,
        accuracy,
        googleMapsUrl,
        orderId,
      ];

  factory UjjwalaInstallation.fromJson(Map<String, dynamic> json) {
    return UjjwalaInstallation(
      id: json['id'] as int,
      applicationNumber: json['application_number'] ?? '',
      // API returns 'consumer_id' not 'consumer_number'
      consumerNumber: json['consumer_id'] ?? '',
      // API returns 'applicant_name' not 'consumer_name'
      consumerName: json['applicant_name'] ?? '',
      // API returns 'profile_photo_url' not 'consumer_photo'
      consumerPhoto: json['profile_photo_url'] as String?,
      // API returns 'applicant_mobile' not 'mobile_number'
      mobileNumber: json['applicant_mobile'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? '',
      // API returns 'material_delivered_at' not 'material_delivered_date'
      materialDeliveredDate: _parseDate(json['material_delivered_at']),
      installationDate: json['installation_date'] != null
          ? _parseDate(json['installation_date'])
          : null,
      kitchenPhotoUrl: json['kitchen_photo_url'] as String?,
      gatePhotoUrl: json['gate_photo_url'] as String?,
      stovePhotoUrl: json['stove_photo_url'] as String?,
      latitude: json['latitude'] != null
          ? _parseDouble(json['latitude'])
          : null,
      longitude: json['longitude'] != null
          ? _parseDouble(json['longitude'])
          : null,
      accuracy: json['accuracy'] != null
          ? _parseDouble(json['accuracy'])
          : null,
      googleMapsUrl: json['google_maps_url'] as String?,
      orderId: json['order_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'application_number': applicationNumber,
        'consumer_number': consumerNumber,
        'consumer_name': consumerName,
        'consumer_photo': consumerPhoto,
        'mobile_number': mobileNumber,
        'address': address,
        'status': status,
        'material_delivered_date': materialDeliveredDate.toIso8601String(),
        'installation_date': installationDate?.toIso8601String(),
        'kitchen_photo_url': kitchenPhotoUrl,
        'gate_photo_url': gatePhotoUrl,
        'stove_photo_url': stovePhotoUrl,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'google_maps_url': googleMapsUrl,
        'order_id': orderId,
      };

  UjjwalaInstallation copyWith({
    int? id,
    String? applicationNumber,
    String? consumerNumber,
    String? consumerName,
    String? consumerPhoto,
    String? mobileNumber,
    String? address,
    String? status,
    DateTime? materialDeliveredDate,
    DateTime? installationDate,
    String? kitchenPhotoUrl,
    String? gatePhotoUrl,
    String? stovePhotoUrl,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? googleMapsUrl,
    String? orderId,
  }) {
    return UjjwalaInstallation(
      id: id ?? this.id,
      applicationNumber: applicationNumber ?? this.applicationNumber,
      consumerNumber: consumerNumber ?? this.consumerNumber,
      consumerName: consumerName ?? this.consumerName,
      consumerPhoto: consumerPhoto ?? this.consumerPhoto,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
      status: status ?? this.status,
      materialDeliveredDate: materialDeliveredDate ?? this.materialDeliveredDate,
      installationDate: installationDate ?? this.installationDate,
      kitchenPhotoUrl: kitchenPhotoUrl ?? this.kitchenPhotoUrl,
      gatePhotoUrl: gatePhotoUrl ?? this.gatePhotoUrl,
      stovePhotoUrl: stovePhotoUrl ?? this.stovePhotoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      orderId: orderId ?? this.orderId,
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null || dateValue == '') {
      return DateTime.now();
    }
    try {
      return DateTime.parse(dateValue.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
