import 'package:equatable/equatable.dart';

class ActiveBonus extends Equatable {
  final int id;
  final DateTime earnedDate;
  final DateTime expiryDate;
  final int quantityEarned;
  final int quantityRemaining;
  final String strategyName;

  const ActiveBonus({
    required this.id,
    required this.earnedDate,
    required this.expiryDate,
    required this.quantityEarned,
    required this.quantityRemaining,
    required this.strategyName,
  });

  // Computed property
  bool get isExpiringSoon =>
      expiryDate.difference(DateTime.now()).inDays <= 2;

  int get daysUntilExpiry =>
      expiryDate.difference(DateTime.now()).inDays;

  factory ActiveBonus.fromJson(Map<String, dynamic> json) {
    return ActiveBonus(
      id: json['id'] ?? 0,
      earnedDate: DateTime.parse(json['earned_date']),
      expiryDate: DateTime.parse(json['expiry_date']),
      quantityEarned: json['quantity_earned'] ?? 0,
      quantityRemaining: json['quantity_remaining'] ?? 0,
      strategyName: json['strategy_name'] ?? '',
    );
  }

  @override
  List<Object> get props => [
    id, earnedDate, expiryDate, quantityEarned,
    quantityRemaining, strategyName,
  ];
}
