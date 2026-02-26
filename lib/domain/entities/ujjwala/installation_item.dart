import 'package:equatable/equatable.dart';

class InstallationItem extends Equatable {
  final String itemCode;
  final String sdmsItemName;
  final int quantity;
  final double rate;
  final double amount;

  const InstallationItem({
    required this.itemCode,
    required this.sdmsItemName,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  factory InstallationItem.fromJson(Map<String, dynamic> json) {
    return InstallationItem(
      itemCode: json['item_code'] ?? '',
      sdmsItemName: json['sdms_item_name'] ?? '',
      quantity: (json['quantity'] ?? 0) as int,
      rate: _parseDouble(json['rate']),
      amount: _parseDouble(json['amount']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  List<Object?> get props => [itemCode, sdmsItemName, quantity, rate, amount];
}
