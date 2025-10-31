import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/models/deposit/sales_order_deposit_data.dart';
import 'ReturnItemSelectionPage.dart';

class SalesOrderItemsWidget extends StatefulWidget {
  final SalesOrderDepositData depositData;
  final Function(List<SelectedReturn>) onReturnsChanged;

  const SalesOrderItemsWidget({
    Key? key,
    required this.depositData,
    required this.onReturnsChanged,
  }) : super(key: key);

  @override
  State<SalesOrderItemsWidget> createState() => _SalesOrderItemsWidgetState();
}

class _SalesOrderItemsWidgetState extends State<SalesOrderItemsWidget> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main scrollable content
        SingleChildScrollView(
          child: Column(
            children: [
              _buildCustomerHeader(),
              _buildOrderItemsSection(),

              // Divider
              if (widget.depositData.getSelectedReturns().isNotEmpty)
                Container(
                  height: 8.h,
                  color: Colors.grey[100],
                  child: Center(
                    child: Container(
                      height: 1.h,
                      color: Colors.grey[300],
                    ),
                  ),
                ),

              // Selected Returns Section
              if (widget.depositData.getSelectedReturns().isNotEmpty)
                _buildSelectedReturnsSection(),

              // Bottom padding to prevent content from being hidden behind button
              SizedBox(height: 80.h),
            ],
          ),
        ),

        // Fixed bottom button
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Back to Sale Order Deposit',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: Colors.blue, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Customer: ${widget.depositData.customer}',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          color: Colors.grey[50],
          child: Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blue, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'Sales Order Items',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        _buildOrderItemsContent(),
      ],
    );
  }

  Widget _buildOrderItemsContent() {
    final orderItems = widget.depositData.getOrderItems();

    if (orderItems.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48.sp, color: Colors.grey[400]),
            SizedBox(height: 12.h),
            Text(
              'No order items available',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      itemCount: orderItems.length,
      itemBuilder: (context, index) {
        final orderItem = orderItems[index];
        return _buildOrderItemCard(orderItem);
      },
    );
  }

  Widget _buildOrderItemCard(OrderItem orderItem) {
    final toReturnQty = widget.depositData.getToReturnQty(orderItem.salesOrderItem);
    final hasSelections = toReturnQty < orderItem.balanceQty;

    final alreadySelectedFilledQty = widget.depositData.getdeliveryQty(orderItem.salesOrderItem);
    final remainingDeliveredQty = orderItem.deliveredQty - alreadySelectedFilledQty;

    final selectedReturns = widget.depositData.getSelectedReturns()
        .where((r) => r.againstSalesOrderItem == orderItem.salesOrderItem)
        .fold(0.0, (sum, r) => sum + r.qty);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: hasSelections ? Colors.blue.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: Colors.blue,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${orderItem.itemCode} - ${orderItem.itemDescription}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        'SO: ${orderItem.salesOrder}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Quantity Info
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuantityInfo('Ordered', orderItem.qtyOrdered, Colors.blue),
                    _buildQuantityInfo('Delivered', remainingDeliveredQty.toDouble(), Colors.purple),
                    _buildQuantityInfo('Returned', selectedReturns, Colors.green), // Dynamic
                    _buildQuantityInfo('To Return', toReturnQty,
                        toReturnQty > 0 ? Colors.orange : Colors.grey),
                  ],
                ),
              ),
            SizedBox(height: 12.h),
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: toReturnQty > 0 ? () => _navigateToReturnSelection(orderItem) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: toReturnQty > 0 ? Colors.blue : Colors.grey[300],
                  foregroundColor: toReturnQty > 0 ? Colors.white : Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  toReturnQty > 0 ? 'SELECT RETURNS' : 'FULLY RETURNED',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityInfo(String label, double qty, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          qty.toInt().toString(),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedReturnsSection() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          color: Colors.grey[50],
          child: Row(
            children: [
              Icon(Icons.assignment_return, color: Colors.green, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'Selected Returns',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        _buildSelectedReturnsContent(),
      ],
    );
  }

  Widget _buildSelectedReturnsContent() {
    final selectedReturns = widget.depositData.getSelectedReturns();

    if (selectedReturns.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Icon(Icons.assignment_return_outlined, size: 48.sp, color: Colors.grey[400]),
            SizedBox(height: 12.h),
            Text(
              'No returns selected',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Group returns by key characteristics
    final groupedReturns = <String, List<SelectedReturn>>{};

    for (final returnItem in selectedReturns) {
      // Create grouping key based on return item, type, and against item
      String groupKey = '${returnItem.returnItemCode}_${returnItem.returnType}_${returnItem.againstSalesOrderItem}';

      // For defective items, also include defective details in grouping
      if (returnItem.isDefective) {
        groupKey += '_${returnItem.cylinderNumber}_${returnItem.faultType}';
      }

      groupedReturns.putIfAbsent(groupKey, () => []).add(returnItem);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      itemCount: groupedReturns.length,
      itemBuilder: (context, index) {
        final group = groupedReturns.values.elementAt(index);
        return _buildGroupedReturnCard(group);
      },
    );
  }

  Widget _buildGroupedReturnCard(List<SelectedReturn> returnGroup) {
    final firstReturn = returnGroup.first;
    final totalQty = returnGroup.fold(0.0, (sum, item) => sum + item.qty);

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Return type icon
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: firstReturn.isEmpty ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Icon(
                    firstReturn.isEmpty ? Icons.inventory_2_outlined : Icons.inventory,
                    color: Colors.orange,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${firstReturn.returnItemCode} - ${firstReturn.returnItemDescription}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                      Text(
                        'Qty: ${totalQty.toInt()} ',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.delete, size: 20.sp, color: Colors.red),
                      onPressed: () => _removeReturnGroup(returnGroup),
                      padding: EdgeInsets.all(4.w),
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Against: ${firstReturn.againstItemCode} (${firstReturn.againstSalesOrder})',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (firstReturn.isDefective ) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Multiple defective items with different details',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ] else if (firstReturn.isDefective) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Cylinder: ${firstReturn.cylinderNumber} | Fault: ${firstReturn.faultType}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editReturnGroup(List<SelectedReturn> returnGroup) {
    // Edit the first item in the group
    _editReturn(returnGroup.first);
  }

  void _removeReturnGroup(List<SelectedReturn> returnGroup) {
    // Remove all items in the group
    for (final returnItem in returnGroup) {
      widget.depositData.removeSelectedReturn(returnItem.id);
    }
    setState(() {
      widget.onReturnsChanged(widget.depositData.getSelectedReturns());
    });
  }

  Widget _buildSelectedReturnCard(SelectedReturn returnItem) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Return type icon
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: returnItem.isEmpty ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Icon(
                    returnItem.isEmpty ? Icons.inventory : Icons.inventory_2_outlined,
                    color: returnItem.isEmpty ? Colors.green : Colors.orange,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${returnItem.returnItemCode} - ${returnItem.returnItemDescription}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                      Text(
                        'Qty: ${returnItem.qty.toInt()}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: 16.sp, color: Colors.blue),
                      onPressed: () => _editReturn(returnItem),
                      padding: EdgeInsets.all(4.w),
                      constraints: BoxConstraints(),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, size: 16.sp, color: Colors.red),
                      onPressed: () => _removeReturn(returnItem),
                      padding: EdgeInsets.all(4.w),
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Against: ${returnItem.againstItemCode} (${returnItem.againstSalesOrder})',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (returnItem.isDefective) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Cylinder: ${returnItem.cylinderNumber} | Fault: ${returnItem.faultType}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToReturnSelection(OrderItem orderItem) async {
    final eligibleReturns = widget.depositData.getEligibleReturns(orderItem.itemCode);
    final maxQty = widget.depositData.getToReturnQty(orderItem.salesOrderItem);

    // Calculate remaining delivered qty (subtract already selected filled items)
    final alreadySelectedFilledQty = widget.depositData.getdeliveryQty(orderItem.salesOrderItem);
    final remainingDeliveredQty = orderItem.deliveredQty - alreadySelectedFilledQty;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReturnItemSelectionPage(
          orderItem: orderItem.copyWith(deliveredQty: remainingDeliveredQty),
          eligibleReturns: eligibleReturns,
          maxQuantity: maxQty,
        ),
      ),
    );

    if (result != null && result is SelectedReturn) {
      setState(() {
        widget.depositData.addSelectedReturn(result);
        widget.onReturnsChanged(widget.depositData.getSelectedReturns());
      });
    }
  }

  void _editReturn(SelectedReturn returnItem) async {
    // Find the original order item
    final orderItems = widget.depositData.getOrderItems();
    final orderItem = orderItems.firstWhere(
          (item) => item.salesOrderItem == returnItem.againstSalesOrderItem,
    );

    // Calculate remaining delivered qty (subtract already selected, add back what's being edited)
    final alreadySelectedFilledQty = widget.depositData.getdeliveryQty(orderItem.salesOrderItem);
    final remainingDeliveredQty = orderItem.deliveredQty - alreadySelectedFilledQty +
        (returnItem.returnType == 'filled' || returnItem.returnType == 'defective' ? returnItem.qty.toInt() : 0);

    final eligibleReturns = widget.depositData.getEligibleReturns(orderItem.itemCode);
    final maxQty = widget.depositData.getToReturnQty(orderItem.salesOrderItem) + returnItem.qty;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReturnItemSelectionPage(
          orderItem: orderItem.copyWith(deliveredQty: remainingDeliveredQty),
          eligibleReturns: eligibleReturns,
          maxQuantity: maxQty,
          editingReturn: returnItem,
        ),
      ),
    );

    if (result != null && result is SelectedReturn) {
      setState(() {
        widget.depositData.addSelectedReturn(result);
        widget.onReturnsChanged(widget.depositData.getSelectedReturns());
      });
    }
  }

  void _removeReturn(SelectedReturn returnItem) {
    setState(() {
      widget.depositData.removeSelectedReturn(returnItem.id);
      widget.onReturnsChanged(widget.depositData.getSelectedReturns());
    });
  }
}