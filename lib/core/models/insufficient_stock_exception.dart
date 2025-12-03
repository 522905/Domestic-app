import 'dart:ui';

/// Represents a single item with insufficient stock
class StockError {
  final String itemCode;
  final String itemName;
  final int requestedQty;
  final int availableQty;
  final int totalStock;
  final int reservedStock;

  StockError({
    required this.itemCode,
    required this.itemName,
    required this.requestedQty,
    required this.availableQty,
    required this.totalStock,
    required this.reservedStock,
  });

  /// Whether this item has any available stock
  bool get hasAvailableStock => availableQty > 0;

  /// The shortage amount
  int get shortage => requestedQty - availableQty;

  factory StockError.fromJson(Map<String, dynamic> json) {
    return StockError(
      itemCode: json['item_code']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? json['item_code']?.toString() ?? '',
      requestedQty: _safeToInt(json['requested_qty']),
      availableQty: _safeToInt(json['available_qty']),
      totalStock: _safeToInt(json['total_stock']),
      reservedStock: _safeToInt(json['reserved_stock']),
    );
  }

  static int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// Custom exception thrown when order creation fails due to insufficient stock
class InsufficientStockException implements Exception {
  final String message;
  final List<StockError> stockErrors;
  final VoidCallback? onRetry;

  InsufficientStockException({
    required this.message,
    required this.stockErrors,
    this.onRetry,
  });

  /// Returns a map of item_code -> available_qty for easy lookup
  Map<String, int> get availableQuantities {
    return {
      for (var error in stockErrors) error.itemCode: error.availableQty
    };
  }

  /// Whether any item has available stock (user can proceed with reduced quantities)
  bool get canProceedWithAvailable {
    return stockErrors.any((e) => e.hasAvailableStock);
  }

  /// Total items affected
  int get affectedItemCount => stockErrors.length;

  @override
  String toString() {
    return 'InsufficientStockException: $message\n'
        '${stockErrors.map((e) => '- ${e.itemCode}: requested ${e.requestedQty}, available ${e.availableQty}').join('\n')}';
  }

  /// Factory to create from API response data
  factory InsufficientStockException.fromApiResponse(Map<String, dynamic> data) {
    final message = data['message']?.toString() ?? 'Insufficient stock for some items';
    final stockErrorsList = <StockError>[];

    // Parse stock_errors array from response
    if (data['stock_errors'] is List) {
      for (var errorItem in data['stock_errors'] as List) {
        if (errorItem is Map<String, dynamic>) {
          stockErrorsList.add(StockError.fromJson(errorItem));
        }
      }
    }

    return InsufficientStockException(
      message: message,
      stockErrors: stockErrorsList,
    );
  }
}
