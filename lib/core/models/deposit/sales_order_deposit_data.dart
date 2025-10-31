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
    return orders.map((order) {
      final itemCode = order['item_code'] ?? '';
      return OrderItem(
        salesOrder: order['sales_order'] ?? '',
        transactionDate: order['transaction_date'] ?? '',
        status: order['status'] ?? '',
        salesOrderItem: order['sales_order_item'] ?? '',
        itemCode: itemCode,
        warehouse: order['warehouse'] ?? '',
        qtyOrdered: (order['qty_ordered'] ?? 0).toDouble(),
        qtyReturned: (order['qty_returned'] ?? 0).toDouble(),
        balanceQty: (order['balance_qty'] ?? 0).toDouble(),
        itemDescription: _getItemDescription(itemCode),
        deliveredQty: (order['delivered_qty'] ?? 0).toInt(), // FIXED: Now returns int, not string
      );
    }).toList();
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

  // NEW: Get already selected filled+defective count for a specific order item
  int getdeliveryQty(String salesOrderItem) {
    return selectedReturns
        .where((selected) =>
    selected.againstSalesOrderItem == salesOrderItem &&
        (selected.returnType == 'filled' || selected.returnType == 'defective'))
        .fold(0, (sum, selected) => sum + selected.qty.toInt());
  }

  // Get eligible returns for specific item code
  Map<String, List<Map<String, dynamic>>> getEligibleReturns(String itemCode) {
    final itemSummary = summaryByItemCode[itemCode];
    if (itemSummary == null) return {'empty': [], 'defective': []};

    final eligibleReturns = itemSummary['eligible_returns'] as Map<String, dynamic>? ?? {};
    return {
      'empty': List<Map<String, dynamic>>.from(eligibleReturns['empty'] ?? []),
      'filled': List<Map<String, dynamic>>.from(eligibleReturns['filled'] ?? []),
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

  // Convert SelectedReturn to API item format
  Map<String, dynamic> selectedReturnToItemMap(SelectedReturn selectedReturn) {
    final itemMap = {
      'item_code': selectedReturn.returnItemCode,
      'item_name': selectedReturn.returnItemDescription,
      'qty': selectedReturn.qty,
      'return_type': selectedReturn.returnType,
      'sales_order_ref': selectedReturn.againstSalesOrder,
      'sales_order_detail_ref': selectedReturn.againstSalesOrderItem,
    };

    // Add defective-specific fields including consumer details
    if (selectedReturn.isDefective) {
      itemMap.addAll({
        'cylinder_number': selectedReturn.cylinderNumber!,
        'tare_weight': selectedReturn.tareWeight!,
        'gross_weight': selectedReturn.grossWeight!,
        'net_weight': selectedReturn.netWeight!,
        'fault_type': selectedReturn.faultType!,
        'consumer_number': selectedReturn.consumerNumber!,
        'consumer_name': selectedReturn.consumerName!,
        'consumer_mobile_number': selectedReturn.consumerMobileNumber!,
      });
    }

    return itemMap;
  }

// Convert all selected returns to API items format
  List<Map<String, dynamic>> getSelectedReturnsAsItems() {
    return selectedReturns.map((sr) => selectedReturnToItemMap(sr)).toList();
  }

}

// Add this copyWith method to your existing OrderItem class

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
  final int deliveredQty;

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
    required this.deliveredQty,
  });

  // ADD THIS METHOD
  OrderItem copyWith({
    String? salesOrder,
    String? transactionDate,
    String? status,
    String? salesOrderItem,
    String? itemCode,
    String? warehouse,
    double? qtyOrdered,
    double? qtyReturned,
    double? balanceQty,
    String? itemDescription,
    int? deliveredQty,
  }) {
    return OrderItem(
      salesOrder: salesOrder ?? this.salesOrder,
      transactionDate: transactionDate ?? this.transactionDate,
      status: status ?? this.status,
      salesOrderItem: salesOrderItem ?? this.salesOrderItem,
      itemCode: itemCode ?? this.itemCode,
      warehouse: warehouse ?? this.warehouse,
      qtyOrdered: qtyOrdered ?? this.qtyOrdered,
      qtyReturned: qtyReturned ?? this.qtyReturned,
      balanceQty: balanceQty ?? this.balanceQty,
      itemDescription: itemDescription ?? this.itemDescription,
      deliveredQty: deliveredQty ?? this.deliveredQty,
    );
  }
}

class SelectedReturn {
  final String id;
  final String returnItemCode;
  final String returnItemDescription;
  final String returnType; // 'empty', 'filled', or 'defective'
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

  // Consumer details (mandatory for defective returns)
  final String? consumerNumber;
  final String? consumerName;
  final String? consumerMobileNumber;

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
    this.consumerNumber,
    this.consumerName,
    this.consumerMobileNumber,
  });

  bool get isDefective => returnType == 'defective';
  bool get isEmpty => returnType == 'empty';
  bool get isFilled => returnType == 'filled';
}