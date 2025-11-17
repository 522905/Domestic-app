import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CollectOrderItem {
  final String id;
  final String itemCode;
  final String itemName;
  final String salesOrder;
  final String salesOrderItem;
  final String status;
  final String transactionDate;
  final String warehouse;
  final int? warehouseId;
  final int maxQuantity; // pending_qty
  final double qtyOrdered;
  final double deliveredQty;
  final Map<String, dynamic> metadata;

  CollectOrderItem({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.salesOrder,
    required this.salesOrderItem,
    required this.status,
    required this.transactionDate,
    required this.warehouse,
    required this.warehouseId,
    required this.maxQuantity,
    required this.qtyOrdered,
    required this.deliveredQty,
    required this.metadata,
  });

  factory CollectOrderItem.fromApiData(Map<String, dynamic> data) {
    return CollectOrderItem(
      id: 'collect_${data['sales_order_item']}',
      itemCode: data['item_code'] ?? '',
      itemName: data['item_name'] ?? data['item_code'] ?? '',
      salesOrder: data['sales_order'] ?? '',
      salesOrderItem: data['sales_order_item'] ?? '',
      status: data['status'] ?? '',
      transactionDate: data['transaction_date'] ?? '',
      warehouse: data['warehouse'] ?? '',
      warehouseId: data['warehouse_id'] as int?,
      maxQuantity: (data['pending_qty'] ?? 0).toInt(),
      qtyOrdered: (data['qty_ordered'] ?? 0).toDouble(),
      deliveredQty: (data['delivered_qty'] ?? 0).toDouble(),
      metadata: {
        ...data,
        'stock_uom': data['stock_uom'],
      },
    );
  }

  String get displayName => itemName.isNotEmpty ? itemName : itemCode;
}

class CollectOrderItemsWidget extends StatefulWidget {
  final Map<String, dynamic> pendingDeliveryData;
  final List<CollectOrderItem> selectedItems;
  final Function(List<CollectOrderItem>) onItemsChanged;
  final Function(String?, int?) onWarehouseSelected;
  final String? activeWarehouse;

  const CollectOrderItemsWidget({
    Key? key,
    required this.pendingDeliveryData,
    required this.selectedItems,
    required this.onItemsChanged,
    required this.onWarehouseSelected,
    this.activeWarehouse,
  }) : super(key: key);

  @override
  State<CollectOrderItemsWidget> createState() => _CollectOrderItemsWidgetState();
}

class _CollectOrderItemsWidgetState extends State<CollectOrderItemsWidget> {
  late List<CollectOrderItem> _availableItems;
  late Map<String, int> _warehouseCounts;
  String? _selectedWarehouseTab;

  @override
  void initState() {
    super.initState();
    _processApiData();
  }

  @override
  void didUpdateWidget(CollectOrderItemsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pendingDeliveryData != widget.pendingDeliveryData) {
      _processApiData();
    }

    if (oldWidget.activeWarehouse != widget.activeWarehouse) {
      if (widget.activeWarehouse != null && _warehouseCounts.containsKey(widget.activeWarehouse)) {
        setState(() {
          _selectedWarehouseTab = widget.activeWarehouse;
        });
      }
    }
  }

  void _processApiData() {
    _availableItems = [];
    _warehouseCounts = {};

    final rows = widget.pendingDeliveryData['rows'] as List? ?? [];

    for (var row in rows) {
      final item = CollectOrderItem.fromApiData(row);
      _availableItems.add(item);

      // Count items per warehouse
      _warehouseCounts[item.warehouse] = (_warehouseCounts[item.warehouse] ?? 0) + 1;
    }

    // UPDATED LOGIC: Check if active warehouse exists in available warehouses first
    if (widget.activeWarehouse != null && _warehouseCounts.containsKey(widget.activeWarehouse)) {
      _selectedWarehouseTab = widget.activeWarehouse;
    } else if (_selectedWarehouseTab == null && _warehouseCounts.isNotEmpty) {
      // Only select first warehouse if no warehouse tab was selected before
      _selectedWarehouseTab = _warehouseCounts.keys.first;
    }
  }

  List<CollectOrderItem> get _filteredItems {
    if (_selectedWarehouseTab == null) return [];

    // Show only items from selected warehouse tab
    return _availableItems.where((item) {
      return item.warehouse == _selectedWarehouseTab;
    }).toList();
  }

  bool _isItemSelected(CollectOrderItem item) {
    return widget.selectedItems.any((selected) => selected.id == item.id);
  }

  CollectOrderItem? _getSelectedItem(CollectOrderItem item) {
    try {
      return widget.selectedItems.firstWhere((selected) => selected.id == item.id);
    } catch (e) {
      return null;
    }
  }

  void _handleItemSelection(CollectOrderItem item) {
    // If no warehouse is active, set this item's warehouse as active
    if (widget.activeWarehouse == null) {
      widget.onWarehouseSelected(item.warehouse, item.warehouseId);
      _showQuantityDialog(item);
      return;
    }

    // If item is from different warehouse, show warning
    if (item.warehouse != widget.activeWarehouse) {
      _showWarehouseSwitchDialog(item);
      return;
    }

    // Item is from active warehouse, proceed normally
    _showQuantityDialog(item);
  }

  void _showWarehouseSwitchDialog(CollectOrderItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Switch Warehouse?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You are currently collecting from:'),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  widget.activeWarehouse ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text('Switching to:'),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  item.warehouse,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'This will clear your current selections and switch to the new warehouse.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14.sp,
                ),
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
                Navigator.pop(context);
                // Clear current selections and switch warehouse
                widget.onItemsChanged([]);
                widget.onWarehouseSelected(item.warehouse, item.warehouseId);
                _selectedWarehouseTab = item.warehouse;
                setState(() {});
                // Then show quantity dialog for the new item
                _showQuantityDialog(item);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Switch'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildWarehouseTabs(),
        Expanded(child: _buildItemsList()),
      ],
    );
  }

  Widget _buildHeader() {
    final customer = widget.pendingDeliveryData['customer'] ?? '';
    final totalPendingQty = widget.pendingDeliveryData['total_pending_qty'] ?? 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping, color: Colors.orange, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Delivery Items',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (customer.isNotEmpty)
                  Text(
                    'Customer: $customer',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11.sp,
                    ),
                  ),
                Text(
                  'Total: $totalPendingQty items',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseTabs() {
    if (_warehouseCounts.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        itemCount: _warehouseCounts.length,
        itemBuilder: (context, index) {
          final warehouseName = _warehouseCounts.keys.elementAt(index);
          final itemCount = _warehouseCounts[warehouseName]!;
          final isSelected = _selectedWarehouseTab == warehouseName;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedWarehouseTab = warehouseName;
              });

              // If user has items selected from a different warehouse, show warning
              if (widget.activeWarehouse != null &&
                  widget.activeWarehouse != warehouseName &&
                  widget.selectedItems.isNotEmpty) {
                _showWarehouseSwitchWarning(warehouseName);
              }
            },
            child: Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0E5CA8) : Colors.grey[200],
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0E5CA8) : Colors.grey[300]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      size: 14.sp,
                      color: Colors.white,
                    ),
                  if (isSelected) SizedBox(width: 4.w),
                  Text(
                    _getShortWarehouseName(warehouseName),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : const Color(0xFF0E5CA8),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '$itemCount',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: isSelected ? const Color(0xFF0E5CA8) : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getShortWarehouseName(String warehouse) {
    // Extract meaningful part of warehouse name
    if (warehouse.contains('-')) {
      return warehouse.split('-')[0].trim();
    }
    return warehouse.length > 15 ? '${warehouse.substring(0, 15)}...' : warehouse;
  }

  void _showWarehouseSwitchWarning(String newWarehouse) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Switch Warehouse?'),
          content: Text(
            'You have items selected from ${widget.activeWarehouse}. Switching to $newWarehouse will clear your current selections.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Clear selections and switch
                widget.onItemsChanged([]);
                widget.onWarehouseSelected(null, null);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Switch'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemsList() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 12.h),
            Text(
              'No pending deliveries for this warehouse',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildCompactItemCard(item);
      },
    );
  }

  Widget _buildCompactItemCard(CollectOrderItem item) {
    final isSelected = _isItemSelected(item);
    final selectedItem = _getSelectedItem(item);
    final isEnabled = widget.activeWarehouse == null || item.warehouse == widget.activeWarehouse;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(
          color: isSelected ? Colors.orange : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First Row: Item Name and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: isEnabled ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(item.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                  child: Text(
                    item.status.replaceAll(' and ', ' & '),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: _getStatusColor(item.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),

            // Second Row: SO and Code
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SO: ${item.salesOrder}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Code: ${item.itemCode}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),

            // Third Row: Quantities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending: ${item.maxQuantity}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Ordered: ${item.qtyOrdered.toInt()}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
                if (isSelected)
                  Text(
                    'Selected: ${selectedItem?.metadata['selected_qty'] ?? 0}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),

            // Button Row
            if (!isSelected)
              SizedBox(
                width: double.infinity,
                height: 32.h,
                child: ElevatedButton(
                  onPressed: isEnabled && item.maxQuantity > 0
                      ? () => _handleItemSelection(item)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEnabled ? Colors.orange : Colors.grey[400],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    isEnabled ? 'Select' : 'Disabled',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 32.h,
                      child: OutlinedButton(
                        onPressed: () => _showQuantityDialog(item),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text('Edit', style: TextStyle(fontSize: 11.sp)),
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: SizedBox(
                      height: 32.h,
                      child: ElevatedButton(
                        onPressed: () => _removeItem(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text('Remove', style: TextStyle(fontSize: 11.sp)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'to deliver and bill':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _showQuantityDialog(CollectOrderItem item) {
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
              Text('Code: ${item.itemCode}'),
              Text('SO: ${item.salesOrder}'),
              SizedBox(height: 16.h),
              Text('Pending quantity: $maxQty'),
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
                    width: 60.w,
                    child: TextField(
                      controller: quantityController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                      onTap: () {
                        quantityController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: quantityController.text.length,
                        );
                      },
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

  void _updateItemSelection(CollectOrderItem item, int quantity) {
    final updatedItems = List<CollectOrderItem>.from(widget.selectedItems);

    // Remove existing item if present
    updatedItems.removeWhere((selected) => selected.id == item.id);

    // Add new item with updated quantity
    final newItem = CollectOrderItem(
      id: item.id,
      itemCode: item.itemCode,
      itemName: item.itemName,
      salesOrder: item.salesOrder,
      salesOrderItem: item.salesOrderItem,
      status: item.status,
      transactionDate: item.transactionDate,
      warehouse: item.warehouse,
      warehouseId: item.warehouseId,
      maxQuantity: item.maxQuantity,
      qtyOrdered: item.qtyOrdered,
      deliveredQty: item.deliveredQty,
      metadata: {
        ...item.metadata,
        'selected_qty': quantity,
      },
    );

    updatedItems.add(newItem);
    widget.onItemsChanged(updatedItems);
  }

  void _removeItem(CollectOrderItem item) {
    final updatedItems = List<CollectOrderItem>.from(widget.selectedItems);
    updatedItems.removeWhere((selected) => selected.id == item.id);
    widget.onItemsChanged(updatedItems);

    // If no items left from this warehouse, clear active warehouse
    if (!updatedItems.any((selected) => selected.warehouse == item.warehouse)) {
      widget.onWarehouseSelected(null, null);
    }
  }
}