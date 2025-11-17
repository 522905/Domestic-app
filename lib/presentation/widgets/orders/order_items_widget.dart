// lib/presentation/widgets/order/order_items_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/order/selectable_order_item.dart';
import '../../../core/models/order/order_data.dart';
import '../professional_snackbar.dart';

class OrderItemsWidget extends StatefulWidget {
  final OrderData orderData;
  final List<SelectableOrderItem> selectedItems;
  final Function(List<SelectableOrderItem>) onItemsChanged;

  const OrderItemsWidget({
    Key? key,
    required this.orderData,
    required this.selectedItems,
    required this.onItemsChanged,
  }) : super(key: key);

  @override
  State<OrderItemsWidget> createState() => _OrderItemsWidgetState();
}

class _OrderItemsWidgetState extends State<OrderItemsWidget> {
  String _searchQuery = '';
  String? _selectedItemGroupFilter;
  String? _selectedAvailabilityFilter;
  String? _selectedBucketFilter;
  late List<SelectableOrderItem> _availableItems;

  @override
  void initState() {
    super.initState();
    _availableItems = widget.orderData.getSelectableItems();
    _selectedAvailabilityFilter = 'Available';
  }

  @override
  void didUpdateWidget(OrderItemsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderData != widget.orderData) {
      _availableItems = widget.orderData.getSelectableItems();
    }
  }

  List<SelectableOrderItem> get _filteredItems {
    var items = _availableItems;

    // Apply item group filter
    if (_selectedItemGroupFilter != null) {
      items = items.where((item) {
        return item.metadata['item_group'] == _selectedItemGroupFilter;
      }).toList();
    }

    // Apply availability filter
    if (_selectedAvailabilityFilter != null) {
      items = items.where((item) {
        return item.availabilityStatus == _selectedAvailabilityFilter;
      }).toList();
    }

    // Apply bucket filter
    if (_selectedBucketFilter != null) {
      items = items.where((item) {
        return item.type == _selectedBucketFilter;
      }).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final itemName = item.itemName.toLowerCase();
        final itemCode = item.itemCode.toLowerCase();
        final description = item.description.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return itemName.contains(query) ||
            itemCode.contains(query) ||
            description.contains(query);
      }).toList();
    }

    return items;
  }

  bool _isItemSelected(SelectableOrderItem item) {
    return widget.selectedItems.any((selected) => selected.id == item.id);
  }

  SelectableOrderItem? _getSelectedItem(SelectableOrderItem item) {
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
        _buildFilterOptions(),
        Expanded(child: _buildItemsList()),
      ],
    );
  }

  Widget _buildHeader() {
    final orderType = widget.orderData.orderType;
    final color = orderType == 'Refill' ? Colors.blue : Colors.orange;
    final icon = orderType == 'Refill' ? Icons.inventory_2_outlined : Icons.inventory;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$orderType Items',
                  style: TextStyle(
                    color: color,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Select items for your $orderType order',
                  style: TextStyle(
                    color: color,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          if (widget.selectedItems.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${widget.selectedItems.length} selected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
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
          hintText: 'Search items by name, code, or description...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF0E5CA8)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
            },
          )
              : null,
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

  Widget _buildFilterOptions() {
    final itemGroupFilters = widget.orderData.getItemGroupFilters();
    final availabilityFilters = widget.orderData.getAvailabilityFilters();
    final bucketFilters = widget.orderData.getBucketFilters();

    if (itemGroupFilters.isEmpty && availabilityFilters.isEmpty && bucketFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    // Split availability filters into "Available" and others
    final availableFilters = availabilityFilters
        .where((filter) =>
    filter['value']?.toString().toLowerCase() == 'available')
        .toList();

    final otherAvailabilityFilters = availabilityFilters
        .where((filter) =>
    filter['value']?.toString().toLowerCase() != 'available')
        .toList();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 1) All
                _buildFilterChip('All', null, FilterType.all, Colors.grey),
                SizedBox(width: 8.w),

                // 2) Available (forced to second position if it exists)
                if (availableFilters.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: _buildFilterChip(
                      '${availableFilters.first['value']} (${availableFilters.first['count']})',
                      availableFilters.first['value'],
                      FilterType.availability,
                      _getAvailabilityColor(availableFilters.first['value']),
                    ),
                  ),

                // Bucket filters
                ...bucketFilters.map((filter) =>
                    Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: _buildFilterChip(
                        '${filter['value']} (${filter['count']})',
                        filter['value'],
                        FilterType.bucket,
                        Colors.blue,
                      ),
                    ),
                ),

                // Item Group filters
                ...itemGroupFilters.map((filter) =>
                    Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: _buildFilterChip(
                        '${filter['value']} (${filter['count']})',
                        filter['value'],
                        FilterType.itemGroup,
                        Colors.green,
                      ),
                    ),
                ),

                // Remaining availability filters (Filled, Filled Cylinder, Out of Stock, etc.)
                ...otherAvailabilityFilters.map((filter) =>
                    Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: _buildFilterChip(
                        '${filter['value']} (${filter['count']})',
                        filter['value'],
                        FilterType.availability,
                        _getAvailabilityColor(filter['value']),
                      ),
                    ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, FilterType type, Color color) {
    bool isSelected = false;

    switch (type) {
      case FilterType.all:
        isSelected = _selectedItemGroupFilter == null &&
            _selectedAvailabilityFilter == null &&
            _selectedBucketFilter == null;
        break;
      case FilterType.itemGroup:
        isSelected = _selectedItemGroupFilter == value;
        break;
      case FilterType.availability:
        isSelected = _selectedAvailabilityFilter == value;
        break;
      case FilterType.bucket:
        isSelected = _selectedBucketFilter == value;
        break;
    }

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          switch (type) {
            case FilterType.all:
              _selectedItemGroupFilter = null;
              _selectedAvailabilityFilter = null;
              _selectedBucketFilter = null;
              break;
            case FilterType.itemGroup:
              _selectedItemGroupFilter = selected ? value : null;
              _selectedAvailabilityFilter = null;
              _selectedBucketFilter = null;
              break;
            case FilterType.availability:
              _selectedAvailabilityFilter = selected ? value : null;
              _selectedItemGroupFilter = null;
              _selectedBucketFilter = null;
              break;
            case FilterType.bucket:
              _selectedBucketFilter = selected ? value : null;
              _selectedItemGroupFilter = null;
              _selectedAvailabilityFilter = null;
              break;
          }
        });
      },
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(
          color: isSelected ? color : Colors.grey[300]!,
          width: 1,
        ),
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
              widget.orderData.orderType == 'Refill'
                  ? Icons.local_gas_station_outlined
                  : Icons.inventory_2_outlined,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              _searchQuery.isNotEmpty ? 'No items match your search' : 'No items available',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: const Text('Clear search'),
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

  Widget _buildItemCard(SelectableOrderItem item) {
    final isSelected = _isItemSelected(item);
    final selectedItem = _getSelectedItem(item);
    final orderType = widget.orderData.orderType;

    // base color from orderType
    final baseColor = orderType == 'Refill' ? Colors.blue : Colors.orange;

    // final color based on itemCode override
    final color = _getItemColor(item.itemCode, baseColor);

    final isOutOfStock = item.isOutOfStock;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Opacity(
        opacity: isOutOfStock ? 0.6 : 1.0,
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
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    child: Icon(
                      orderType == 'Refill' ? Icons.propane_tank : Icons.propane_tank_outlined,
                      color: color,        // <- will now be red/blue per itemCode
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
                            color: isOutOfStock ? Colors.grey : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Code: ${item.itemCode}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (item.metadata['item_group'] != null)
                          Text(
                            'Group: ${item.metadata['item_group']}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Text(
                              'Stock: ${item.maxQuantity}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: isOutOfStock ? Colors.red[700] : Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: _getAvailabilityColor(item.availabilityStatus).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(
                                  color: _getAvailabilityColor(item.availabilityStatus),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                item.availabilityStatus,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: _getAvailabilityColor(item.availabilityStatus),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: color,
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
              if (!isSelected)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isOutOfStock ? null : () => _showQuantityDialog(item),
                    icon: Icon(
                      isOutOfStock ? Icons.block : Icons.add_shopping_cart,
                      size: 18.sp,
                    ),
                    label: Text(isOutOfStock ? 'Out of Stock' : 'Select Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOutOfStock ? Colors.grey : color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showQuantityDialog(item),
                        icon: Icon(Icons.edit, size: 16.sp),
                        label: Text('Qty: ${selectedItem?.metadata['selected_qty'] ?? 0}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _removeItem(item),
                        icon: Icon(Icons.delete, size: 16.sp),
                        label: const Text('Remove'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvailabilityColor(String status) {
    switch (status.toLowerCase()) {
      case 'in stock':
        return Colors.green;
      case 'out of stock':
        return Colors.red;
      case 'low stock':
        return Colors.orange;
      case 'limited stock':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Color _getItemColor(String itemCode, Color defaultColor) {
    switch (itemCode) {
      case 'M00087':
      case 'M00104':
        return Colors.red;
      case 'M00218':
        return Colors.blue;
      default:
        return defaultColor;
    }
  }

  void _showQuantityDialog(SelectableOrderItem item) {
    final selectedItem = _getSelectedItem(item);
    int selectedQty = selectedItem?.metadata['selected_qty'] ?? 1;
    final maxQty = item.maxQuantity;
    late TextEditingController quantityController;

    // Don't allow selection if out of stock
    if (item.isOutOfStock) {
      context.showErrorSnackBar('${item.displayName} is out of stock');
      return;
    }

    quantityController = TextEditingController(text: selectedQty.toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: const Text(
            'Select Quantity',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    children: [
                      Text(
                        item.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Code: ${item.itemCode}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: _getAvailabilityColor(item.availabilityStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(
                            color: _getAvailabilityColor(item.availabilityStatus),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          item.availabilityStatus,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: _getAvailabilityColor(item.availabilityStatus),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Maximum available:',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      '$maxQty',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: selectedQty > 1 ? () {
                          setDialogState(() {
                            selectedQty--;
                            quantityController.text = selectedQty.toString();
                          });
                        } : null,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    SizedBox(
                      width: 80.w,
                      child: TextField(
                        controller: quantityController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
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
                    SizedBox(width: 16.w),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: selectedQty < maxQty ? () {
                          setDialogState(() {
                            selectedQty++;
                            quantityController.text = selectedQty.toString();
                          });
                        } : null,
                      ),
                    ),
                  ],
                ),
                if (maxQty == 0) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 20.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'This item is currently out of stock',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12.sp,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: maxQty == 0 ? null : () {
                final finalQty = int.tryParse(quantityController.text) ?? selectedQty;
                if (finalQty >= 1 && finalQty <= maxQty) {
                  _updateItemSelection(item, finalQty);
                  Navigator.pop(context);

                  // Show success message
                  context.showSuccessSnackBar('Added $finalQty × ${item.displayName}');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E5CA8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(selectedItem != null ? 'Update' : 'Add to Order'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateItemSelection(SelectableOrderItem item, int quantity) {
    final updatedItems = List<SelectableOrderItem>.from(widget.selectedItems);

    // Remove existing item if present
    updatedItems.removeWhere((selected) => selected.id == item.id);

    // Add new item with updated quantity
    final newItem = SelectableOrderItem(
      id: item.id,
      itemCode: item.itemCode,
      itemName: item.itemName,
      description: item.description,
      type: item.type,
      maxQuantity: item.maxQuantity,
      availabilityStatus: item.availabilityStatus,
      metadata: {
        ...item.metadata,
        'selected_qty': quantity,
      },
    );

    updatedItems.add(newItem);
    widget.onItemsChanged(updatedItems);
  }

  void _removeItem(SelectableOrderItem item) {
    final updatedItems = List<SelectableOrderItem>.from(widget.selectedItems);
    updatedItems.removeWhere((selected) => selected.id == item.id);
    widget.onItemsChanged(updatedItems);

    // Show removal message
    context.showWarningSnackBar('Removed ${item.displayName} from order');
  }
}

enum FilterType {
  all,
  availability,
  itemGroup,
  bucket,
}