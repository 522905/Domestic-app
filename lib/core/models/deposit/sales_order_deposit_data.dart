import 'package:lpg_distribution_app/core/models/deposit/selectable_deposit_item.dart';

import 'deposit_data.dart';

class SalesOrderDepositData extends DepositData {
  final String customer;
  final List<Map<String, dynamic>> orders;
  final Map<String, dynamic> summaryByItemCode;
  final double totalBalanceQty;

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

  @override
  List<SelectableDepositItem> getSelectableItems() {
    final items = <SelectableDepositItem>[];

    // Process eligible returns from summary_by_item_code
    summaryByItemCode.forEach((originalItemCode, itemSummary) {
      final eligibleReturns = itemSummary['eligible_returns'] as Map<String, dynamic>? ?? {};
      final balanceQty = (itemSummary['balance_qty'] ?? 0).toInt();
      final itemDescription = itemSummary['item_description'] ?? originalItemCode;

      // Find the corresponding sales order details for this item code
      final relatedOrder = orders.firstWhere(
            (order) => order['item_code'] == originalItemCode,
        orElse: () => <String, dynamic>{},
      );

      // Process empty returns
      final emptyReturns = eligibleReturns['empty'] as List<dynamic>? ?? [];
      for (var emptyReturn in emptyReturns) {
        final returnItemCode = emptyReturn['item_code'] ?? '';
        final returnDescription = emptyReturn['description'] ?? returnItemCode;

        items.add(SelectableDepositItem(
          id: 'empty_return_${originalItemCode}_${returnItemCode}',
          itemCode: returnItemCode,
          itemName: returnDescription,
          description: returnDescription,
          type: 'empty_return',
          maxQuantity: balanceQty, // Use balance quantity from summary
          metadata: {
            'original_item_code': originalItemCode,
            'original_item_description': itemDescription,
            'return_type': 'empty',
            'against_item': originalItemCode,
            'balance_qty': balanceQty,
            // Include sales order details if available
            if (relatedOrder.isNotEmpty) ...{
              'sales_order': relatedOrder['sales_order'],
              'sales_order_item': relatedOrder['sales_order_item'],
              'transaction_date': relatedOrder['transaction_date'],
              'status': relatedOrder['status'],
              'warehouse': relatedOrder['warehouse'],
              'qty_ordered': relatedOrder['qty_ordered'],
              'qty_returned': relatedOrder['qty_returned'],
            },
          },
        ));
      }

      // Process defective returns
      final defectiveReturns = eligibleReturns['defective'] as List<dynamic>? ?? [];
      for (var defectiveReturn in defectiveReturns) {
        final returnItemCode = defectiveReturn['item_code'] ?? '';
        final returnDescription = defectiveReturn['description'] ?? returnItemCode;

        items.add(SelectableDepositItem(
          id: 'defective_return_${originalItemCode}_${returnItemCode}',
          itemCode: returnItemCode,
          itemName: returnDescription,
          description: returnDescription,
          type: 'defective_return',
          maxQuantity: balanceQty, // Use balance quantity from summary
          metadata: {
            'original_item_code': originalItemCode,
            'original_item_description': itemDescription,
            'return_type': 'defective',
            'against_item': originalItemCode,
            'balance_qty': balanceQty,
            // Include sales order details if available
            if (relatedOrder.isNotEmpty) ...{
              'sales_order': relatedOrder['sales_order'],
              'sales_order_item': relatedOrder['sales_order_item'],
              'transaction_date': relatedOrder['transaction_date'],
              'status': relatedOrder['status'],
              'warehouse': relatedOrder['warehouse'],
              'qty_ordered': relatedOrder['qty_ordered'],
              'qty_returned': relatedOrder['qty_returned'],
            },
          },
        ));
      }
    });

    return items;
  }

  @override
  int getMaxQuantityLimit() => totalBalanceQty.toInt();

  // Helper method to get original item information
  String getOriginalItemDescription(String itemCode) {
    final itemSummary = summaryByItemCode[itemCode];
    return itemSummary?['item_description'] ?? itemCode;
  }

  // Helper method to get balance quantity for an item
  int getBalanceQuantity(String itemCode) {
    final itemSummary = summaryByItemCode[itemCode];
    return (itemSummary?['balance_qty'] ?? 0).toInt();
  }
}