import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/services/api_service_interface.dart';
import '../professional_snackbar.dart';

class ItemSelectorDialog extends StatefulWidget {

  final Map<String, dynamic>? initialItem;
  final Function(Map<String, dynamic>) onItemAdded;
  final List<Map<String, dynamic>> availableItems;

  const ItemSelectorDialog({
    Key? key,
    this.initialItem,
    required this.onItemAdded,
    required this.availableItems,
  }) : super(key: key);

  @override
  State<ItemSelectorDialog> createState() => _ItemSelectorDialogState();

  static Future<void> show(
      BuildContext context,
      List<String> itemTypes,
      List<String> nfrTypes,
      Function(Map<String, dynamic>) onItemAdded, {
        Map<String, dynamic>? initialItem,
      }) async {
    try {

      // Fetch items dynamically
      final apiService = context.read<ApiServiceInterface>();
      final items = await apiService.getItemList();


      if (items.isEmpty) {
        context.showInfoSnackBar('No items available from API');
        return;
      }

      // Show dialog with fetched items
      return showDialog(
        context: context,
        builder: (context) => ItemSelectorDialog(
          initialItem: initialItem,
          onItemAdded: onItemAdded,
          availableItems: items, // Pass fetched items here
        ),
      );
    } catch (e) {
      context.showErrorSnackBar('Error fetching items: $e');
    }
  }

  // Static method for DepositInventoryScreen usage
  static Future<void> showForDeposit(
      BuildContext context,
      List<Map<String, dynamic>> availableItems,
      Function(Map<String, dynamic>) onItemAdded, {
        Map<String, dynamic>? initialItem,
      }) {

    if (availableItems.isEmpty) {
      context.showInfoSnackBar('No items available');
      return Future.value();
    }

    return showDialog(
      context: context,
      builder: (context) => ItemSelectorDialog(
        initialItem: initialItem,
        onItemAdded: onItemAdded,
        availableItems: availableItems,
      ),
    );
  }
}

class _ItemSelectorDialogState extends State<ItemSelectorDialog> {
  late String selectedType;
  String? selectedNfrType;
  int quantity = 1;
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> availableItems = [];
  List<Map<String, dynamic>> filteredItems = [];

  @override
  void initState() {
    super.initState();

    filteredItems = List.from(widget.availableItems);

    // Initialize with values if editing
    if (widget.initialItem != null) {
      selectedType = widget.initialItem!['type'];
      selectedNfrType = widget.initialItem!['nfrType'];
      quantity = widget.initialItem!['quantity'];
    }
  }

  // Function to filter items based on search text
  void _filterItems(String searchText) {
    print('🔍 Filtering items with search text: "$searchText"');

    if (searchText.isEmpty) {
      setState(() {
        filteredItems = List.from(widget.availableItems);
      });
    } else {
      setState(() {
        filteredItems = widget.availableItems.where((item) =>
            item['item_name'].toString().toLowerCase().contains(searchText.toLowerCase())
        ).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialItem != null ? 'Edit Item' : 'Select Item',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E5CA8),
                  ),
                ),
                // Debug info badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${filteredItems.length} items',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Search bar
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF0E5CA8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Color(0xFFE5E5E5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Color(0xFF0E5CA8), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _filterItems,
            ),
            SizedBox(height: 16.h),

            // Items list with better debugging
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 400.h,
                ),
                child: filteredItems.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 16.h),
                      Text(
                        widget.availableItems.isEmpty
                            ? 'No items loaded from API'
                            : 'No items match your search',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16.sp,
                        ),
                      ),
                      if (widget.availableItems.isEmpty) ...[
                        SizedBox(height: 8.h),
                        Text(
                          'Check console for API errors',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8.h),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        side: BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Row(
                          children: [
                            // Left side with item details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['item_name'] ?? 'Unknown Item',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Text(
                                        'Available: ${item['available'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Text(
                                        'ID: ${item['name'] ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Right side with add button
                            ElevatedButton(
                              onPressed: () {
                                final selectedItemData = {
                                  'type': item['stock_uom'] ?? 'Unknown',
                                  'name': item['item_name'] ?? 'Unnamed Item',
                                  'itemId': item['name'],
                                  'quantity': 1,
                                  'available': (item['available'] ?? 0).toInt(),
                                };
                                _showQuantityDialog(selectedItemData);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Color(0xFF0E5CA8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  side: BorderSide(color: Color(0xFF0E5CA8)),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                              ),
                              child: const Text(
                                'Add',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Cancel button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF0E5CA8),
                ),
                child: Text(
                  'CANCEL',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to select quantity before adding item
  void _showQuantityDialog(Map<String, dynamic> item) {
    int selectedQuantity = 1;
    final int availableQuantity = item['available'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Select Quantity'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${item['name']}'),
                SizedBox(height: 16.h),
                Text(
                  'Available: $availableQuantity',
                  style: TextStyle(color: Color(0xFF666666)),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: Color(0xFF0E5CA8)),
                      onPressed: selectedQuantity > 1 ? () {
                        setState(() {
                          selectedQuantity--;
                        });
                      } : null,
                    ),
                    Container(
                      width: 60.w,
                      child: TextField(
                        controller: TextEditingController(text: selectedQuantity.toString()),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                        ),
                        onChanged: (value) {
                          final parsedValue = int.tryParse(value) ?? 1;
                          setState(() {
                            selectedQuantity = parsedValue.clamp(1, availableQuantity);
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: Color(0xFF0E5CA8)),
                      onPressed: selectedQuantity < availableQuantity ? () {
                        setState(() {
                          selectedQuantity++;
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
                child: Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Update the quantity and pass back to parent
                  item['quantity'] = selectedQuantity;
                  widget.onItemAdded(item);
                  Navigator.pop(context); // Close quantity dialog
                  Navigator.pop(context); // Close item selector dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0E5CA8),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'CONFIRM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}