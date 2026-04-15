import 'package:equatable/equatable.dart';
import 'offline_delivery_company.dart';

class ObligationDirector extends Equatable {
  final int id;
  final OfflineDeliveryCompany? company;
  final String name;
  final String role;
  final bool isActive;

  const ObligationDirector({
    required this.id,
    this.company,
    required this.name,
    required this.role,
    this.isActive = true,
  });

  factory ObligationDirector.fromJson(Map<String, dynamic> json) {
    return ObligationDirector(
      id: json['id'] as int,
      company: json['company'] != null
          ? OfflineDeliveryCompany.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  @override
  List<Object?> get props => [id, company, name, role, isActive];
}
