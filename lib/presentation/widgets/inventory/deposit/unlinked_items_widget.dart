import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/models/deposit/selectable_deposit_item.dart';
import '../../../../core/models/deposit/unlinked_deposit_data.dart';

class UnlinkedItemsWidget extends StatefulWidget {
  final UnlinkedDepositData depositData;
  final List<SelectableDepositItem> selectedItems;
  final Function(List<SelectableDepositItem>) onItemsChanged;

  const UnlinkedItemsWidget({
    Key? key,
    required this.depositData,
    required this.selectedItems,
    required this.onItemsChanged,
  }) : super(key: key);

  @override
  State<UnlinkedItemsWidget> createState() => _UnlinkedItemsWidgetState();
}

class _UnlinkedItemsWidgetState extends State<UnlinkedItemsWidget> {
  String _searchQuery = '';
  String? _selectedFilter;
  late List<SelectableDepositItem> _availableItems;

  @override
  void initState() {
    super.initState();
    _availableItems = widget.depositData.getSelectableItems();
  }

  List<SelectableDepositItem> get _filteredItems {
    var items = _availableItems;

    // Apply filter
    if (_selectedFilter != null) {
      items = items.where((item) {
        return item.metadata['item_group'] == _selectedFilter;
      }).toList();
    }

    // Apply search
    if (_searchQuery.isEmpty) return items;

    return items.where((item) {
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
        _buildFilterOptions(),
        Expanded(child: _buildItemsList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2, color: Colors.green, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlinked Items',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Select items from inventory buckets',
                  style: TextStyle(
                    color: Colors.green,
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

  Widget _buildFilterOptions() {
    final filterOptions = widget.depositData.getItemGroupFilters();

    if (filterOptions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', null),
            SizedBox(width: 8.w),
            ...filterOptions.map((filter) =>
                Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: _buildFilterChip(
                      '${filter['value']} (${filter['count']})',
                      filter['value']
                  ),
                )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : null;
        });
      },
      selectedColor: const Color(0xFF0E5CA8).withOpacity(0.2),
      checkmarkColor: const Color(0xFF0E5CA8),
    );
  }

  Widget _buildItemsList() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
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
    final bucketType = item.metadata['bucket_type'];

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.transparent,
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  child: Icon(
                    item.type == 'unlinked_defective' ? Icons.warning : Icons.inventory_2,
                    color: item.type == 'unlinked_defective' ? Colors.red : Colors.green,
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
                      if (bucketType != null)
                        Container(
                          margin: EdgeInsets.only(top: 4.h),
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: bucketType == 'Empty'
                                ? Colors.blue.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            bucketType,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: bucketType == 'Empty'
                                  ? Colors.blue.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
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
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                      color: Colors.green,
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
                child: ElevatedButton(
                  onPressed: () => _showQuantityDialog(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text('Qty: ${selectedItem?.metadata['selected_qty'] ?? 0}'),
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
              if (item.metadata['bucket_type'] != null) ...[
                SizedBox(height: 4.h),
                Text(
                  'Type: ${item.metadata['bucket_type']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.sp,
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