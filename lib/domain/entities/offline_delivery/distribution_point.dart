import 'package:equatable/equatable.dart';

class DistributionPoint extends Equatable {
  final String id;
  final String name;
  final Map<String, dynamic>? physicalSite;
  final bool isAdhoc;
  final bool allowQuickDelivery;
  final bool isActive;
  final int todayTokenCount;

  const DistributionPoint({
    required this.id,
    required this.name,
    this.physicalSite,
    required this.isAdhoc,
    required this.allowQuickDelivery,
    required this.isActive,
    required this.todayTokenCount,
  });

  String? get physicalSiteName =>
      physicalSite != null ? physicalSite!['name'] as String? : null;

  factory DistributionPoint.fromJson(Map<String, dynamic> json) {
    return DistributionPoint(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      physicalSite: json['physical_site'] as Map<String, dynamic>?,
      isAdhoc: json['is_adhoc'] ?? false,
      allowQuickDelivery: json['allow_quick_delivery'] ?? false,
      isActive: json['is_active'] ?? true,
      todayTokenCount: json['today_token_count'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    id, name, physicalSite, isAdhoc, allowQuickDelivery,
    isActive, todayTokenCount,
  ];
}
