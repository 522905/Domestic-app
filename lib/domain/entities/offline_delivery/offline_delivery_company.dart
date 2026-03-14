import 'package:equatable/equatable.dart';

class OfflineDeliveryCompany extends Equatable {
  final int id;
  final String name;
  final String shortCode;
  final String? sdmsDistCode;

  const OfflineDeliveryCompany({
    required this.id,
    required this.name,
    required this.shortCode,
    this.sdmsDistCode,
  });

  factory OfflineDeliveryCompany.fromJson(Map<String, dynamic> json) {
    return OfflineDeliveryCompany(
      id: json['id'] as int,
      name: json['name'] ?? '',
      shortCode: json['short_code'] ?? '',
      sdmsDistCode: json['sdms_dist_code'],
    );
  }

  @override
  List<Object?> get props => [id, name, shortCode, sdmsDistCode];
}
