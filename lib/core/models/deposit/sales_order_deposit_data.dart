import 'package:lpg_distribution_app/core/models/deposit/selectable_deposit_item.dart';
import 'deposit_data.dart';

class SalesOrderDepositData extends DepositData {
  final String customer;
  final List<Map<String, dynamic>> orders;
  final Map<String, dynamic> summaryByItemCode;
  final double totalBalanceQty;

  // Store selected returns
  List<SelectedReturn> selectedReturns = [];

  SalesOrderDepositData({
    required Map<String, dynamic> rawData,
    required List<Map<String, dynamic>> warehouses,
    required List<Map<String, dynamic>> vehicles,
  }) : customer = rawData['customer'] ?? '',
        orders = List<Map<String, dynamic>>.from(rawData['orders'] ?? []),
        summaryByItemCode = rawData['summary_by_item_code'] ?? {},
        totalBalanceQty = (rawData['total_balance_qty'] ?? 0).toDouble(),
        super(
        depositType: DepositData.salesOrder,
        rawData: rawData,
        warehouses: warehouses,
        vehicles: vehicles,
      );

  // Get individual order items for top component
  List<OrderItem> getOrderItems() {
    return orders.map((order) => OrderItem(
      salesOrder: order['sales_order'] ?? '',
      transactionDate: order['transaction_date'] ?? '',
      status: order['status'] ?? '',
      salesOrderItem: order['sales_order_item'] ?? '',
      itemCode: order['item_code'] ?? '',
      warehouse: order['warehouse'] ?? '',
      qtyOrdered: (order['qty_ordered'] ?? 0).toDouble(),
      qtyReturned: (order['qty_returned'] ?? 0).toDouble(),
      balanceQty: (order['balance_qty'] ?? 0).toDouble(),
      itemDescription: _getItemDescription(order['item_code'] ?? ''),
    )).toList();
  }

  // Calculate "To Return" for specific order item
  double getToReturnQty(String salesOrderItem) {
    final orderItem = orders.firstWhere(
          (order) => order['sales_order_item'] == salesOrderItem,
      orElse: () => <String, dynamic>{},
    );

    if (orderItem.isEmpty) return 0.0;

    final ordered = (orderItem['qty_ordered'] ?? 0).toDouble();
    final returned = (orderItem['qty_returned'] ?? 0).toDouble();
    final selectedForThisItem = selectedReturns
        .where((selected) => selected.againstSalesOrderItem == salesOrderItem)
        .fold(0.0, (sum, selected) => sum + selected.qty);

    return ordered - returned - selectedForThisItem;
  }

  // Get eligible returns for specific item code
  Map<String, List<Map<String, dynamic>>> getEligibleReturns(String itemCode) {
    final itemSummary = summaryByItemCode[itemCode];
    if (itemSummary == null) return {'empty': [], 'defective': []};

    final eligibleReturns = itemSummary['eligible_returns'] as Map<String, dynamic>? ?? {};
    return {
      'empty': List<Map<String, dynamic>>.from(eligibleReturns['empty'] ?? []),
      'defective': List<Map<String, dynamic>>.from(eligibleReturns['defective'] ?? []),
    };
  }

  // Add selected return
  void addSelectedReturn(SelectedReturn selectedReturn) {
    // Remove existing return with same ID if exists
    selectedReturns.removeWhere((existing) => existing.id == selectedReturn.id);
    selectedReturns.add(selectedReturn);
  }

  // Remove selected return
  void removeSelectedReturn(String returnId) {
    selectedReturns.removeWhere((selected) => selected.id == returnId);
  }

  // Get selected returns for display
  List<SelectedReturn> getSelectedReturns() {
    return List<SelectedReturn>.from(selectedReturns);
  }

  String _getItemDescription(String itemCode) {
    final itemSummary = summaryByItemCode[itemCode];
    return itemSummary?['item_description'] ?? itemCode;
  }

  @override
  List<SelectableDepositItem> getSelectableItems() {
    // This method is now less relevant as we're using the new structure
    // But keeping for compatibility
    return [];
  }

  @override
  int getMaxQuantityLimit() => totalBalanceQty.toInt();
}

// Data classes for the new structure
class OrderItem {
  final String salesOrder;
  final String transactionDate;
  final String status;
  final String salesOrderItem;
  final String itemCode;
  final String warehouse;
  final double qtyOrdered;
  final double qtyReturned;
  final double balanceQty;
  final String itemDescription;

  OrderItem({
    required this.salesOrder,
    required this.transactionDate,
    required this.status,
    required this.salesOrderItem,
    required this.itemCode,
    required this.warehouse,
    required this.qtyOrdered,
    required this.qtyReturned,
    required this.balanceQty,
    required this.itemDescription,
  });
}

class SelectedReturn {
  final String id;
  final String returnItemCode;
  final String returnItemDescription;
  final String returnType; // 'empty' or 'defective'
  final double qty;
  final String againstSalesOrder;
  final String againstSalesOrderItem;
  final String againstItemCode;
  final String againstItemDescription;

  // Additional fields for defective returns
  final String? cylinderNumber;
  final double? tareWeight;
  final double? grossWeight;
  final double? netWeight;
  final String? faultType;

  SelectedReturn({
    required this.id,
    required this.returnItemCode,
    required this.returnItemDescription,
    required this.returnType,
    required this.qty,
    required this.againstSalesOrder,
    required this.againstSalesOrderItem,
    required this.againstItemCode,
    required this.againstItemDescription,
    this.cylinderNumber,
    this.tareWeight,
    this.grossWeight,
    this.netWeight,
    this.faultType,
  });

  bool get isDefective => returnType == 'defective';
  bool get isEmpty => returnType == 'empty';
}