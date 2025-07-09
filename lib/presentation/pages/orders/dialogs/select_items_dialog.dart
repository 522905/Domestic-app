// lib/presentation/pages/orders/dialogs/select_items_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../domain/entities/inventory_item.dart';
import '../../../blocs/order_form/order_form_bloc.dart';

class SelectItemsDialog extends StatefulWidget {
  final List<InventoryItem> availableItems;
  final Map<String, OrderItemQuantity> selectedItems;
  final Function(Map<InventoryItem, int>) onItemsSelected;

  const SelectItemsDialog({
    Key? key,
    required this.availableItems,
    required this.selectedItems,
    required this.onItemsSelected,
  }) : super(key: key);

  @override
  State<SelectItemsDialog> createState() => _SelectItemsDialogState();
}

class _SelectItemsDialogState extends State<SelectItemsDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<InventoryItem> _filteredItems = [];
  Map<InventoryItem, int> _selectedItems = {};
  String _activeCategory = 'All';

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.availableItems;

    // Initialize selected items
    for (final itemQuantity in widget.selectedItems.values) {
      final item = itemQuantity.item;
      final quantity = itemQuantity.quantity;
      _selectedItems[item] = quantity;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.availableItems;
      } else {
        _filteredItems = widget.availableItems
            .where((item) =>
            item.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }

      // Apply category filter
      if (_activeCategory != 'All') {
        _filteredItems = _filteredItems
            .where((item) => item.type == _activeCategory)
            .toList();
      }
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _activeCategory = category;
      if (category == 'All') {
        _filteredItems = widget.availableItems;
      } else {
        _filteredItems = widget.availableItems
            .where((item) => item.type == category)
            .toList();
      }

      // Apply search query filter
      if (_searchController.text.isNotEmpty) {
        _filteredItems = _filteredItems
            .where((item) =>
            item.name.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();
      }
    });
  }

  void _addItem(InventoryItem item) {
    setState(() {
      if (_selectedItems.containsKey(item)) {
        if (_selectedItems[item]! < item.available) {
          _selectedItems[item] = _selectedItems[item]! + 1;
        }
      } else {
        _selectedItems[item] = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(16.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF0E5CA8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Items',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: EdgeInsets.all(16.w),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                onChanged: _filterItems,
              ),
            ),

            // Categories
            SizedBox(
              height: 40.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  _buildCategoryChip('All'),
                  _buildCategoryChip('Cylinders'),
                  _buildCategoryChip('Accessories'),
                  _buildCategoryChip('Other'),
                ],
              ),
            ),

            // Items list
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return _buildItemCard(item);
                },
              ),
            ),

            // Add selected items button
            Padding(
              padding: EdgeInsets.all(16.w),
              child: ElevatedButton(
                onPressed: _selectedItems.isNotEmpty
                    ? () => widget.onItemsSelected(_selectedItems)
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56.h),
                  backgroundColor: const Color(0xFF0E5CA8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  'ADD SELECTED ITEMS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isActive = _activeCategory == category;

    return GestureDetector(
      onTap: () => _filterByCategory(category),
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF7941D).withOpacity(0.2) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isActive ? const Color(0xFFF7941D) : Colors.grey[800],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(InventoryItem item) {
    // Determine stock level color
    Color indicatorColor;
    double level = item.available / (item.available + item.reserved);

    if (level > 0.7) {
      indicatorColor = Colors.green;
    } else if (level > 0.3) {
      indicatorColor = Colors.orange;
    } else {
      indicatorColor = Colors.red;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Stock level indicator
                  Stack(
                    children: [
                      Container(
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: level.clamp(0.0, 1.0),
                        child: Container(
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: indicatorColor,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Available: ${item.available} | Reserved: ${item.reserved}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.add_circle,
                color: const Color(0xFF0E5CA8),
                size: 32.sp,
              ),
              onPressed: () => _addItem(item),
            ),
          ],
        ),
      ),
    );
  }
}