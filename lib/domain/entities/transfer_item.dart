class TransferItem {
  final String itemId;
  final String itemName;
  final String itemType; // 'filled', 'empty', etc.
  final int quantity;

  TransferItem({
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'itemType': itemType,
      'quantity': quantity,
    };
  }

  factory TransferItem.fromJson(Map<String, dynamic> json) {
    return TransferItem(
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String,
      itemType: json['itemType'] as String,
      quantity: json['quantity'] as int,
    );
  }
}