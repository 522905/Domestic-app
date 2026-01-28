import 'package:equatable/equatable.dart';

class BonusSummary extends Equatable {
  final int totalActive;
  final int totalActiveQuantity;
  final int totalConsumed;
  final int totalConsumedQuantity;
  final int totalExpired;
  final int totalExpiredQuantity;
  final int expiringSoon;
  final int expiringSoonQuantity;

  const BonusSummary({
    required this.totalActive,
    required this.totalActiveQuantity,
    required this.totalConsumed,
    required this.totalConsumedQuantity,
    required this.totalExpired,
    required this.totalExpiredQuantity,
    required this.expiringSoon,
    required this.expiringSoonQuantity,
  });

  // Computed properties
  bool get hasExpiringSoon => expiringSoon > 0;
  bool get hasActiveBonuses => totalActive > 0;
  int get totalBonuses => totalActive + totalConsumed + totalExpired;

  factory BonusSummary.fromJson(Map<String, dynamic> json) {
    return BonusSummary(
      totalActive: json['total_active'] ?? 0,
      totalActiveQuantity: json['total_active_quantity'] ?? 0,
      totalConsumed: json['total_consumed'] ?? 0,
      totalConsumedQuantity: json['total_consumed_quantity'] ?? 0,
      totalExpired: json['total_expired'] ?? 0,
      totalExpiredQuantity: json['total_expired_quantity'] ?? 0,
      expiringSoon: json['expiring_soon'] ?? 0,
      expiringSoonQuantity: json['expiring_soon_quantity'] ?? 0,
    );
  }

  @override
  List<Object> get props => [
        totalActive,
        totalActiveQuantity,
        totalConsumed,
        totalConsumedQuantity,
        totalExpired,
        totalExpiredQuantity,
        expiringSoon,
        expiringSoonQuantity,
      ];
}
