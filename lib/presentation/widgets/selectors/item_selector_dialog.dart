import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/services/api_service_interface.dart';

class ItemSelectorDialog extends StatefulWidget {
  final List<String> itemTypes;
  final List<String> nfrTypes;
  final Map<String, dynamic>? initialItem;
  final Function(Map<String, dynamic>) onItemAdded;
  final List<Map<String, dynamic>> availableItems;

  const ItemSelectorDialog({
    Key? key,
    required this.itemTypes,
    required this.nfrTypes,
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

        // Show dialog with fetched items
        return showDialog(
          context: context,
          builder: (context) => ItemSelectorDialog(
            itemTypes: itemTypes,
            nfrTypes: nfrTypes,
            initialItem: initialItem,
            onItemAdded: onItemAdded,
            availableItems: items, // Pass fetched items here
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching items: $e')),
        );
      }
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
    } else {
      selectedType = widget.itemTypes.first;
    }
  }

  // Function to filter items based on search text
  void _filterItems(String searchText) {
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
            Text(
              widget.initialItem != null ? 'Edit Item' : 'Select Item',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0E5CA8), // Brand Blue from your guidelines
              ),
            ),
            SizedBox(height: 16.h),
            // Search bar at the top for easier access
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
            // Display filtered items in a list similar to the image
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 400.h, // Limit max height to prevent overflow
                ),
                child: ListView.builder(
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
                                    item['item_name'],
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333), // Dark Gray from guidelines
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Available: ${item['available']}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Color(0xFF666666), // Secondary text color
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Right side with add button
                            ElevatedButton(
                              onPressed: () {
                               final selectedItemData = {
                                    'type': item['stock_uom'] ?? 'Unknown', // Default to 'Unknown' if null
                                    'name': item['item_name'] ?? 'Unnamed Item', // Default to 'Unnamed Item' if null
                                    'itemId': item['name'],
                                    'quantity': 1,
                                    'available': item['available'].toInt(),
                                  };
                                // Show quantity selection dialog before adding
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
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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

            // Cancel button at bottom
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
                child:const Padding(
                  padding: EdgeInsets.all(8.0),
                  child:  Text(
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