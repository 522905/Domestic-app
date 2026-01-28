import 'package:equatable/equatable.dart';

enum BonusStatus {
  active,
  fullyConsumed,
  expired,
  voided;

  static BonusStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return BonusStatus.active;
      case 'fully_consumed':
        return BonusStatus.fullyConsumed;
      case 'expired':
        return BonusStatus.expired;
      case 'voided':
        return BonusStatus.voided;
      default:
        return BonusStatus.active;
    }
  }
}

enum ExpiryUrgency {
  expiringToday,
  expiringTomorrow,
  expiringSoon;

  static ExpiryUrgency? fromString(String? urgency) {
    if (urgency == null) return null;
    switch (urgency.toLowerCase()) {
      case 'expiring_today':
        return ExpiryUrgency.expiringToday;
      case 'expiring_tomorrow':
        return ExpiryUrgency.expiringTomorrow;
      case 'expiring_soon':
        return ExpiryUrgency.expiringSoon;
      default:
        return null;
    }
  }
}

class Bonus extends Equatable {
  final int id;
  final String itemCode;
  final String itemName;
  final DateTime earnedDate;
  final DateTime expiryDate;
  final int quantityEarned;
  final int quantityConsumed;
  final int quantityRemaining;
  final BonusStatus status;
  final String statusDisplay;
  final double consumptionPercentage;
  final int? daysUntilExpiry;
  final ExpiryUrgency? expiryUrgency;
  final String strategyName;

  // For detail view only
  final BonusStrategy? strategy;
  final BonusSourceMetrics? sourceMetrics;
  final DateTime? createdAt;

  const Bonus({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.earnedDate,
    required this.expiryDate,
    required this.quantityEarned,
    required this.quantityConsumed,
    required this.quantityRemaining,
    required this.status,
    required this.statusDisplay,
    required this.consumptionPercentage,
    this.daysUntilExpiry,
    this.expiryUrgency,
    required this.strategyName,
    this.strategy,
    this.sourceMetrics,
    this.createdAt,
  });

  // Computed properties
  bool get isExpiringSoon => expiryUrgency != null;
  bool get isActive => status == BonusStatus.active;
  bool get isFullyConsumed => status == BonusStatus.fullyConsumed;
  bool get isExpired => status == BonusStatus.expired;
  bool get hasSourceMetrics => sourceMetrics != null;

  factory Bonus.fromJson(Map<String, dynamic> json) {
    return Bonus(
      id: json['id'] ?? 0,
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      earnedDate: DateTime.parse(json['earned_date']),
      expiryDate: DateTime.parse(json['expiry_date']),
      quantityEarned: json['quantity_earned'] ?? 0,
      quantityConsumed: json['quantity_consumed'] ?? 0,
      quantityRemaining: json['quantity_remaining'] ?? 0,
      status: BonusStatus.fromString(json['status'] ?? 'active'),
      statusDisplay: json['status_display'] ?? '',
      consumptionPercentage: (json['consumption_percentage'] ?? 0).toDouble(),
      daysUntilExpiry: json['days_until_expiry'],
      expiryUrgency: ExpiryUrgency.fromString(json['expiry_urgency']),
      strategyName: json['strategy_name'] ?? '',
      strategy: json['strategy'] != null
          ? BonusStrategy.fromJson(json['strategy'])
          : null,
      sourceMetrics: json['source_metrics'] != null
          ? BonusSourceMetrics.fromJson(json['source_metrics'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        itemCode,
        itemName,
        earnedDate,
        expiryDate,
        quantityEarned,
        quantityConsumed,
        quantityRemaining,
        status,
        statusDisplay,
        consumptionPercentage,
        daysUntilExpiry,
        expiryUrgency,
        strategyName,
        strategy,
        sourceMetrics,
        createdAt,
      ];
}

class BonusStrategy extends Equatable {
  final int id;
  final String name;
  final String description;

  const BonusStrategy({
    required this.id,
    required this.name,
    required this.description,
  });

  factory BonusStrategy.fromJson(Map<String, dynamic> json) {
    return BonusStrategy(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  @override
  List<Object> get props => [id, name, description];
}

class BonusSourceMetrics extends Equatable {
  final int pickups;
  final int returns;
  final int netPickups;
  final int otpSales;
  final int overrideSales;
  final int confirmedSales;
  final double postingRatio;
  final int bonusCalculated;

  const BonusSourceMetrics({
    required this.pickups,
    required this.returns,
    required this.netPickups,
    required this.otpSales,
    required this.overrideSales,
    required this.confirmedSales,
    required this.postingRatio,
    required this.bonusCalculated,
  });

  factory BonusSourceMetrics.fromJson(Map<String, dynamic> json) {
    return BonusSourceMetrics(
      pickups: json['pickups'] ?? 0,
      returns: json['returns'] ?? 0,
      netPickups: json['net_pickups'] ?? 0,
      otpSales: json['otp_sales'] ?? 0,
      overrideSales: json['override_sales'] ?? 0,
      confirmedSales: json['confirmed_sales'] ?? 0,
      postingRatio: (json['posting_ratio'] ?? 0).toDouble(),
      bonusCalculated: json['bonus_calculated'] ?? 0,
    );
  }

  @override
  List<Object> get props => [
        pickups,
        returns,
        netPickups,
        otpSales,
        overrideSales,
        confirmedSales,
        postingRatio,
        bonusCalculated,
      ];
}
