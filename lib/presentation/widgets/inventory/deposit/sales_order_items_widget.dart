import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/models/deposit/sales_order_deposit_data.dart';
import '../../../../core/models/deposit/selectable_deposit_item.dart';

class SalesOrderItemsWidget extends StatefulWidget {
  final SalesOrderDepositData depositData;
  final List<SelectableDepositItem> selectedItems;
  final Function(List<SelectableDepositItem>) onItemsChanged;

  const SalesOrderItemsWidget({
    Key? key,
    required this.depositData,
    required this.selectedItems,
    required this.onItemsChanged,
  }) : super(key: key);

  @override
  State<SalesOrderItemsWidget> createState() => _SalesOrderItemsWidgetState();
}

class _SalesOrderItemsWidgetState extends State<SalesOrderItemsWidget> {
  String _searchQuery = '';
  late List<SelectableDepositItem> _availableItems;

  @override
  void initState() {
    super.initState();
    _availableItems = widget.depositData.getSelectableItems();
  }

  List<SelectableDepositItem> get _filteredItems {
    if (_searchQuery.isEmpty) return _availableItems;

    return _availableItems.where((item) {
      final itemName = item.itemName.toLowerCase();
      final itemCode = item.itemCode.toLowerCase();
      return itemName.contains(_searchQuery.toLowerCase()) ||
          itemCode.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  bool _isItemSelected(SelectableDepositItem item) {
    return widget.selectedItems.any((selected) => selected.id == item.id);
  }

  SelectableDepositItem? _getSelectedItem(SelectableDepositItem item) {
    try {
      return widget.selectedItems.firstWhere((selected) => selected.id == item.id);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
        Expanded(child: _buildItemsList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: Colors.blue, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Order Items',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Customer: ${widget.depositData.customer}',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.grey[50],
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search items...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF0E5CA8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildItemsList() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No items available',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(SelectableDepositItem item) {
    final isSelected = _isItemSelected(item);
    final selectedItem = _getSelectedItem(item);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
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
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  child: Icon(
                    item.type.contains('return') ? Icons.autorenew : Icons.receipt_long,
                    color: Colors.blue,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                      Text(
                        'Code: ${item.itemCode}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (item.metadata['against_item'] != null)
                        Text(
                          'Against: ${item.metadata['against_item']}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (item.metadata['sales_order'] != null)
                        Text(
                          'SO: ${item.metadata['sales_order']}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available: ${item.maxQuantity}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isSelected)
                  Text(
                    'Selected: ${selectedItem?.metadata['selected_qty'] ?? 0}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            if (!isSelected)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: item.maxQuantity > 0 ? () => _showQuantityDialog(item) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: const Text('Select'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showQuantityDialog(item),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text('Edit Qty'),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _removeItem(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: const Text('Remove'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showQuantityDialog(SelectableDepositItem item) {
    final selectedItem = _getSelectedItem(item);
    int selectedQty = selectedItem?.metadata['selected_qty'] ?? 1;
    final maxQty = item.maxQuantity;
    late TextEditingController quantityController;

    quantityController = TextEditingController(text: selectedQty.toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Code: ${item.itemCode}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14.sp,
                ),
              ),
              if (item.metadata['against_item'] != null) ...[
                SizedBox(height: 4.h),
                Text(
                  'Against: ${item.metadata['against_item']}',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              Text(
                'Maximum available: $maxQty',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: selectedQty > 1 ? () {
                      setDialogState(() {
                        selectedQty--;
                        quantityController.text = selectedQty.toString();
                      });
                    } : null,
                  ),
                  SizedBox(
                    width: 80.w,
                    child: TextField(
                      controller: quantityController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                      onChanged: (value) {
                        final parsedValue = int.tryParse(value);
                        if (parsedValue != null && parsedValue >= 1 && parsedValue <= maxQty) {
                          setDialogState(() {
                            selectedQty = parsedValue;
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: selectedQty < maxQty ? () {
                      setDialogState(() {
                        selectedQty++;
                        quantityController.text = selectedQty.toString();
                      });
                    } : null,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final finalQty = int.tryParse(quantityController.text) ?? selectedQty;
                if (finalQty >= 1 && finalQty <= maxQty) {
                  _updateItemSelection(item, finalQty);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E5CA8),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateItemSelection(SelectableDepositItem item, int quantity) {
    final updatedItems = List<SelectableDepositItem>.from(widget.selectedItems);

    // Remove existing item if present
    updatedItems.removeWhere((selected) => selected.id == item.id);

    // Add new item with updated quantity
    final newItem = SelectableDepositItem(
      id: item.id,
      itemCode: item.itemCode,
      itemName: item.itemName,
      description: item.description,
      type: item.type,
      maxQuantity: item.maxQuantity,
      metadata: {
        ...item.metadata,
        'selected_qty': quantity,
      },
    );

    updatedItems.add(newItem);
    widget.onItemsChanged(updatedItems);
  }

  void _removeItem(SelectableDepositItem item) {
    final updatedItems = List<SelectableDepositItem>.from(widget.selectedItems);
    updatedItems.removeWhere((selected) => selected.id == item.id);
    widget.onItemsChanged(updatedItems);
  }
}