import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ItemSelectionPage extends StatefulWidget {
  final Map<String, dynamic> itemListData; // Changed from List to Map
  final Function(List<Map<String, dynamic>>) onItemsSelected;
  final List<Map<String, dynamic>>? initialSelectedItems;

  const ItemSelectionPage({
    Key? key,
    required this.itemListData,
    required this.onItemsSelected,
    this.initialSelectedItems,
  }) : super(key: key);

  @override
  State<ItemSelectionPage> createState() => _ItemSelectionPageState();
}

class _ItemSelectionPageState extends State<ItemSelectionPage> {
  final List<Map<String, dynamic>> _selectedItems = [];
  String _searchQuery = '';
  List<Map<String, dynamic>> _processedItems = [];
  String _dataType = 'unknown';
  String? _selectedFilter;
  List<Map<String, dynamic>> _filterOptions = [];

  @override
  void initState() {
    super.initState();
    _initializeSelectedItems();
    _processItemData();
  }

  void _initializeSelectedItems() {
    if (widget.initialSelectedItems != null) {
      _selectedItems.addAll(widget.initialSelectedItems!);
    }
  }

  void _processItemData() {
    _processedItems.clear();
    _filterOptions.clear();

    if (widget.itemListData.isEmpty) {
      return;
    }

    // Detect data type and process accordingly
    final data = widget.itemListData; // Single Map object

    if (data.containsKey('message') && data['message']?.containsKey('buckets') == true) {
      // Unlinked items data
      _dataType = 'unlinked';
      _processUnlinkedData();
    } else if (data.containsKey('orders') || data.containsKey('summary_by_item_code')) {
      // Sale Order Return data
      _dataType = 'sale_order';
      _processSaleOrderData();
    } else if (data.containsKey('material_requests')) {
      // Material Request data
      _dataType = 'material_request';
      _processMaterialRequestData();
    } else if (data.containsKey('item_row_name') || data.containsKey('material_request')) {
      // Direct material request items
      _dataType = 'material_request_direct';
      _processedItems = [data]; // Wrap single item in array
    } else {
      // Regular item data or unknown format
      _dataType = 'regular';
      _processedItems = [data]; // Wrap single item in array
    }
  }

  void _processUnlinkedData() {
    final data = widget.itemListData; // Single Map object

    if (data['message']?.containsKey('buckets') == true) {
      final buckets = data['message']['buckets'];

      // Process Empty items
      if (buckets['Empty'] != null) {
        for (var item in buckets['Empty']) {
          _processedItems.add({
            ...item,
            'item_name': item['item_name'] ?? item['item_code'],
            'data_type': 'unlinked_empty',
            'max_qty': 999, // Default max for unlinked items
            'bucket_type': 'Empty',
          });
        }
      }

      // Process Defective items
      if (buckets['Defective'] != null) {
        for (var item in buckets['Defective']) {
          _processedItems.add({
            ...item,
            'item_name': item['item_name'] ?? item['item_code'],
            'data_type': 'unlinked_defective',
            'max_qty': 999, // Default max for unlinked items
            'bucket_type': 'Defective',
          });
        }
      }

      // Process facets for filtering
      if (data['message']?.containsKey('facets') == true) {
        final facets = data['message']['facets'];
        if (facets['item_group'] != null) {
          _filterOptions = List<Map<String, dynamic>>.from(facets['item_group']);
        }
      }
    }
  }

  void _processSaleOrderData() {
    final data = widget.itemListData; // Single Map object

    // Add items from orders array
    if (data['orders'] != null) {
      for (var order in data['orders']) {
        _processedItems.add({
          ...order,
          'item_name': order['description'] ?? order['item_code'],
          'data_type': 'sale_order_item',
          'max_qty': order['balance_qty']?.toInt() ?? 0,
        });
      }
    }

    // Add eligible return items from summary
    if (data['summary_by_item_code'] != null) {
      for (var itemCode in data['summary_by_item_code'].keys) {
        var itemData = data['summary_by_item_code'][itemCode];
        if (itemData['eligible_returns'] != null &&
            itemData['eligible_returns']['empty'] != null) {
          for (var emptyItem in itemData['eligible_returns']['empty']) {
            _processedItems.add({
              ...emptyItem,
              'item_name': emptyItem['description'] ?? emptyItem['item_code'],
              'data_type': 'eligible_return',
              'max_qty': 999, // Default max for eligible returns
              'against_item': itemCode,
            });
          }
        }
      }
    }
  }

  void _processMaterialRequestData() {
    final data = widget.itemListData; // Single Map object

    if (data['material_requests'] != null) {
      for (var request in data['material_requests']) {
        _processedItems.add({
          ...request,
          'item_name': request['item_code'],
          'data_type': 'material_request',
          'max_qty': request['pending_qty']?.toInt() ?? 0,
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    var items = _processedItems;

    // Apply filter
    if (_selectedFilter != null && _dataType == 'unlinked') {
      items = items.where((item) {
        return item['item_group'] == _selectedFilter;
      }).toList();
    }

    // Apply search
    if (_searchQuery.isEmpty) return items;

    return items.where((item) {
      final itemName = (item['item_name'] ?? item['item_code'] ?? '').toString().toLowerCase();
      final itemCode = (item['item_code'] ?? '').toString().toLowerCase();
      return itemName.contains(_searchQuery.toLowerCase()) ||
          itemCode.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Items'),
        backgroundColor: const Color(0xFF0E5CA8),
        foregroundColor: Colors.white,
        actions: [
          if (_selectedItems.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Text(
                    '${_selectedItems.length} items',
                    style: TextStyle(
                      color: const Color(0xFF0E5CA8),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // Filter options (for unlinked items)
          if (_dataType == 'unlinked' && _filterOptions.isNotEmpty)
            _buildFilterOptions(),

          // Items content
          Expanded(
            child: _buildItemsList(),
          ),

          // Selected items summary and action buttons
          if (_selectedItems.isNotEmpty)
            _buildBottomSection(),
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // All option
            _buildFilterChip('All', null),
            SizedBox(width: 8.w),
            // Filter options from facets
            ..._filterOptions.map((filter) =>
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
    if (_processedItems.isEmpty) {
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

    return Column(
      children: [
        _buildDataTypeHeader(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              final item = _filteredItems[index];
              return _buildItemCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDataTypeHeader() {
    String title = '';
    String subtitle = '';
    IconData icon = Icons.inventory;
    Color color = Colors.grey;

    switch (_dataType) {
      case 'unlinked':
        title = 'Unlinked Items';
        subtitle = 'Select items from inventory buckets';
        icon = Icons.inventory_2;
        color = Colors.green;
        break;
      case 'sale_order':
        title = 'Sale Order Items';
        subtitle = 'Select items from sale orders for deposit';
        icon = Icons.receipt_long;
        color = Colors.blue;
        break;
      case 'material_request':
      case 'material_request_direct':
        title = 'Material Request Items';
        subtitle = 'Select items from material requests';
        icon = Icons.assignment;
        color = Colors.orange;
        break;
      default:
        title = 'Available Items';
        subtitle = 'Select items for deposit';
        icon = Icons.inventory;
        color = Colors.green;
    }

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
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
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

  Widget _buildItemCard(Map<String, dynamic> item) {
    final isSelected = _selectedItems.any((selected) =>
    _getItemIdentifier(selected) == _getItemIdentifier(item)
    );

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isSelected ? _getItemColor(item) : Colors.transparent,
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
                    color: _getItemColor(item).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  child: Icon(
                    _getItemIcon(item),
                    color: _getItemColor(item),
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['item_name'] ?? item['item_code'] ?? 'Unknown Item',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                      Text(
                        'Code: ${item['item_code'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (item['data_type'] == 'eligible_return' && item['against_item'] != null)
                        Text(
                          'Against: ${item['against_item']}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (item['bucket_type'] != null)
                        Container(
                          margin: EdgeInsets.only(top: 4.h),
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: item['bucket_type'] == 'Empty'
                                ? Colors.blue.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            item['bucket_type'],
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: item['bucket_type'] == 'Empty'
                                  ? Colors.blue.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (item['item_group'] != null && _dataType == 'unlinked')
                        Text(
                          'Group: ${item['item_group']}',
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
                    decoration: BoxDecoration(
                      color: _getItemColor(item),
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

            if (_shouldShowQuantityInfo(item)) ...[
              SizedBox(height: 12.h),
              // _buildQuantityInfo(item),
            ],

            SizedBox(height: 12.h),

            if (!isSelected)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (item['max_qty'] ?? 0) > 0
                      ? () => _showQuantityDialog(item)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getItemColor(item),
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
                        foregroundColor: _getItemColor(item),
                        side: BorderSide(color: _getItemColor(item)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: const Text('Edit Qty'),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _removeSelectedItem(item),
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

  Widget _buildBottomSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Items (${_selectedItems.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                ..._selectedItems.take(3).map((item) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['item_name'] ?? item['item_code'] ?? 'Unknown Item',
                          style: TextStyle(fontSize: 14.sp),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Qty: ${item['selected_qty']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                )),
                if (_selectedItems.length > 3)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      '... and ${_selectedItems.length - 3} more items',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                // Total quantity
                if (_selectedItems.isNotEmpty) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Quantity:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: const Color(0xFF0E5CA8),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E5CA8),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${_selectedItems.fold(0, (sum, item) => sum + (item['selected_qty'] as int))}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedItems.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: const Text('Clear All'),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onItemsSelected(_selectedItems);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E5CA8),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Confirm Selection (${_selectedItems.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(Map<String, dynamic> item) {
    int maxQty = item['max_qty'] ?? 0;
    int selectedQty = 1;
    late TextEditingController quantityController;

    // Check if item is already selected
    final existingItem = _selectedItems.firstWhere(
          (selected) => _getItemIdentifier(selected) == _getItemIdentifier(item),
      orElse: () => {},
    );

    if (existingItem.isNotEmpty) {
      selectedQty = existingItem['selected_qty'];
    }

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
                item['item_name'] ?? item['item_code'] ?? 'Unknown Item',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Code: ${item['item_code'] ?? 'N/A'}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14.sp,
                ),
              ),
              if (item['bucket_type'] != null) ...[
                SizedBox(height: 4.h),
                Text(
                  'Type: ${item['bucket_type']}',
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
                  Container(
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
                  final newItem = {
                    ...item,
                    'selected_qty': finalQty,
                    // Add compatibility fields for existing code
                    'itemId': item['item_code'],
                    'quantity': finalQty,
                    'item_name': item['item_name'] ?? item['item_code'],
                  };

                  setState(() {
                    // Remove existing item if it exists
                    _selectedItems.removeWhere((selected) =>
                    _getItemIdentifier(selected) == _getItemIdentifier(item)
                    );
                    _selectedItems.add(newItem);
                  });
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

  void _removeSelectedItem(Map<String, dynamic> item) {
    setState(() {
      _selectedItems.removeWhere((selected) =>
      _getItemIdentifier(selected) == _getItemIdentifier(item)
      );
    });
  }

  // Helper methods
  String _getItemIdentifier(Map<String, dynamic> item) {
    // Create unique identifier based on item type
    if (item['sales_order_item'] != null) {
      return 'sale_${item['sales_order_item']}';
    } else if (item['item_row_name'] != null) {
      return 'mr_${item['item_row_name']}';
    } else if (item['data_type'] == 'eligible_return') {
      return 'return_${item['item_code']}_${item['against_item']}';
    } else if (item['data_type']?.startsWith('unlinked') == true) {
      return 'unlinked_${item['item_code']}_${item['bucket_type']}';
    } else {
      return 'item_${item['item_code'] ?? item['name'] ?? 'unknown'}';
    }
  }

  Color _getItemColor(Map<String, dynamic> item) {
    switch (item['data_type']) {
      case 'sale_order_item':
        return Colors.blue;
      case 'eligible_return':
        return Colors.orange;
      case 'material_request':
        return Colors.orange;
      case 'unlinked_empty':
        return Colors.green;
      case 'unlinked_defective':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  IconData _getItemIcon(Map<String, dynamic> item) {
    switch (item['data_type']) {
      case 'sale_order_item':
        return Icons.receipt_long;
      case 'eligible_return':
        return Icons.inventory_2_rounded;
      case 'material_request':
        return Icons.assignment;
      case 'unlinked_empty':
        return Icons.inventory_2;
      case 'unlinked_defective':
        return Icons.warning;
      default:
        return Icons.inventory;
    }
  }

  bool _shouldShowQuantityInfo(Map<String, dynamic> item) {
    return item['data_type'] == 'sale_order_item' ||
        item['data_type'] == 'material_request' ||
        item['data_type']?.startsWith('unlinked') == true;
  }
}