/// Service order line item (e.g., cylinder issue/collect)
class OrderItem {
  final String itemCode;
  final String itemName;
  final int quantity;
  final double amount;
  final String direction; // ISSUE or COLLECT

  OrderItem({
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    required this.amount,
    required this.direction,
  });

  bool get isIssue => direction == 'ISSUE';
  bool get isCollect => direction == 'COLLECT';

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String,
      quantity: json['quantity'] as int? ?? 1,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      direction: json['direction'] as String? ?? 'ISSUE',
    );
  }

  OrderItem copyWith({
    String? itemCode,
    String? itemName,
    int? quantity,
    double? amount,
    String? direction,
  }) {
    return OrderItem(
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
    );
  }
}
