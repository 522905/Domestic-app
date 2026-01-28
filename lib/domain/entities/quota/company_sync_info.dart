import 'package:equatable/equatable.dart';

class CompanySyncInfo extends Equatable {
  final int companyId;
  final String companyName;
  final DateTime? lastSync;
  final bool canSync;
  final int secondsUntilSync;

  const CompanySyncInfo({
    required this.companyId,
    required this.companyName,
    this.lastSync,
    required this.canSync,
    required this.secondsUntilSync,
  });

  factory CompanySyncInfo.fromJson(Map<String, dynamic> json) {
    return CompanySyncInfo(
      companyId: json['company_id'] ?? 0,
      companyName: json['company_name'] ?? '',
      lastSync: json['last_sync'] != null
          ? DateTime.parse(json['last_sync'])
          : null,
      canSync: json['can_sync'] ?? false,
      secondsUntilSync: json['seconds_until_sync'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    companyId, companyName, lastSync, canSync, secondsUntilSync,
  ];
}
