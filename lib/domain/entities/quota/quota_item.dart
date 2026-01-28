import 'package:equatable/equatable.dart';
import 'active_bonus.dart';

class QuotaItem extends Equatable {
  final String itemCode;
  final String itemName;
  final int creditLimit;
  final int opening;
  final int bonus;
  final int adjustment;   // Adjustments (can be + or -)
  final int orders;       // Always <= 0
  final int pickups;      // Always <= 0
  final int returns;      // Always >= 0
  final int sdmsSales;    // Always >= 0
  final int closing;
  final int availableBalance;
  final bool isBlocked;
  final List<ActiveBonus> activeBonuses;

  const QuotaItem({
    required this.itemCode,
    required this.itemName,
    required this.creditLimit,
    required this.opening,
    required this.bonus,
    required this.adjustment,
    required this.orders,
    required this.pickups,
    required this.returns,
    required this.sdmsSales,
    required this.closing,
    required this.availableBalance,
    required this.isBlocked,
    required this.activeBonuses,
  });

  // Computed properties
  int get deficit => isBlocked ? availableBalance.abs() : 0;
  bool get isLowBalance => availableBalance > 0 && availableBalance <= 10;
  bool get hasActiveBonuses => activeBonuses.isNotEmpty;

  factory QuotaItem.fromJson(Map<String, dynamic> json) {
    return QuotaItem(
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      creditLimit: json['credit_limit'] ?? 0,
      opening: json['opening'] ?? 0,
      bonus: json['bonus'] ?? 0,
      adjustment: json['adjustments'] ?? 0,  // API uses 'adjustments' (plural)
      orders: json['orders'] ?? 0,
      pickups: json['pickups'] ?? 0,
      returns: json['returns'] ?? 0,
      sdmsSales: json['sdms_sales'] ?? 0,
      closing: json['closing'] ?? 0,
      availableBalance: json['available_balance'] ?? 0,
      isBlocked: json['is_blocked'] ?? false,
      activeBonuses: (json['active_bonuses'] as List?)
          ?.map((bonus) => ActiveBonus.fromJson(bonus))
          .toList() ?? [],
    );
  }

  @override
  List<Object> get props => [
    itemCode, itemName, creditLimit, opening, bonus, adjustment,
    orders, pickups, returns, sdmsSales, closing, availableBalance,
    isBlocked, activeBonuses,
  ];
}
