import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/inventory_request.dart';
import '../../../blocs/inventory/inventory_bloc.dart';
import '../../../blocs/inventory/inventory_event.dart';

class DepositInventoryScreen extends StatefulWidget {
  const DepositInventoryScreen({Key? key}) : super(key: key);

  @override
  State<DepositInventoryScreen> createState() => _DepositInventoryScreenState();
}

class _DepositInventoryScreenState extends State<DepositInventoryScreen> {
  final Map<String, int> _selectedOrders = {}; // Order ID -> Quantity mapping
  String? _selectedWarehouse;
  String? _selectedWarehouseId;
  bool _selectAll = false;
  bool _isSubmitting = false;

  final Map<String, Map<String, List<Map<String, dynamic>>>> _warehouseOrders = {
    'WH1001': {
      'MATERIAL REQUEST': [
        {
          'orderId': 'Order #R-2574',
          'items': [
            {'name': '14.2kg Cylinders', 'quantity': 8, 'maxQuantity': 8},
          ],
        },
        {
          'orderId': 'Order #R-2576',
          'items': [
            {'name': '14.2kg Cylinders', 'quantity': 12, 'maxQuantity': 12},
            {'name': '5kg Cylinders', 'quantity': 3, 'maxQuantity': 3},
          ],
        },
      ],
      'REFILL ORDERS': [
        {
          'orderId': 'Order #RF-2575',
          'items': [
            {'name': '14.2kg Cylinders', 'quantity': 15, 'maxQuantity': 15},
          ],
        },
      ],
      'UNLINKED': [],
    },
    'WH1002': {
      'MATERIAL REQUEST': [
        {
          'orderId': 'Order #R-3574',
          'items': [
            {'name': '19kg Cylinders', 'quantity': 4, 'maxQuantity': 4},
          ],
        },
      ],
      'REFILL ORDERS': [
        {
          'orderId': 'Order #RF-3575',
          'items': [
            {'name': '14.2kg Cylinders', 'quantity': 7, 'maxQuantity': 7},
          ],
        },
        {
          'orderId': 'Order #RF-3576',
          'items': [
            {'name': '5kg Cylinders', 'quantity': 10, 'maxQuantity': 10},
          ],
        },
      ],
      'UNLINKED': [],
    },
    'WH1003': {
      'MATERIAL REQUEST': [],
      'REFILL ORDERS': [
        {
          'orderId': 'Order #RF-4575',
          'items': [
            {'name': '14.2kg Cylinders', 'quantity': 22, 'maxQuantity': 22},
          ],
        },
      ],
      'UNLINKED': [
        {
          'orderId': 'Order #UN-4577',
          'items': [
            {'name': '19kg Cylinders', 'quantity': 8, 'maxQuantity': 8},
          ],
        },
        {
          'orderId': 'Order #UN-4578',
          'items': [
            {'name': '5kg Cylinders', 'quantity': 14, 'maxQuantity': 14},
          ],
        },
      ],
    },
  };

  final List<UnlinkedItem> _unlinkedItems = [];

  final List<Map<String, dynamic>> _warehouses = [
    {
      'id': 'WH1001',
      'name': 'Whitefield Warehouse',
      'address': '# 4, 3rd St, 1st A Main, Whitefield, Bangalore',
    },
    {
      'id': 'WH1002',
      'name': 'Marathahalli Warehouse',
      'address': '# 8, 2nd St, 9th A Main, Marathahalli, Bangalore',
    },
    {
      'id': 'WH1003',
      'name': 'Koramangala Warehouse',
      'address': '# 12, 5th St, 8th A Main, Koramangala, Bangalore',
    },
  ];

  @override
  void dispose() {
    _isSubmitting = false;
    super.dispose();
  }

  void _showWarehouseSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Warehouse',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search warehouse...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _warehouses.length,
                itemBuilder: (context, index) {
                  final warehouse = _warehouses[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text('W', style: TextStyle(color: Colors.blue)),
                    ),
                    title: Text(warehouse['name']),
                    subtitle: Text(warehouse['address']),
                    onTap: () {
                      setState(() {
                        _selectedWarehouse = warehouse['name'];
                        _selectedWarehouseId = warehouse['id'];
                        _selectedOrders.clear(); // Clear selected orders when warehouse changes
                        _selectAll = false;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E5CA8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('SELECT WAREHOUSE'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQuantityEditDialog(String orderId, Map<String, dynamic> orderData) {
    // Get the current quantity
    int currentQuantity = _selectedOrders[orderId] ?? orderData['items'][0]['quantity'];
    int maxQuantity = orderData['items'][0]['maxQuantity'];
    int tempQuantity = currentQuantity;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Quantity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Order: $orderId'),
                    const SizedBox(height: 8),
                    Text('Item: ${orderData['items'][0]['name']}'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: tempQuantity > 1 ? () {
                            setState(() {
                              tempQuantity--;
                            });
                          } : null,
                        ),
                        Container(
                          width: 80,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: TextEditingController(text: tempQuantity.toString()),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (value) {
                              int? newQty = int.tryParse(value);
                              if (newQty != null && newQty >= 1 && newQty <= maxQuantity) {
                                setState(() {
                                  tempQuantity = newQty;
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: tempQuantity < maxQuantity ? () {
                            setState(() {
                              tempQuantity++;
                            });
                          } : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Maximum available: $maxQuantity',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0E5CA8)),
                              foregroundColor: const Color(0xFF0E5CA8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              this.setState(() {
                                _selectedOrders[orderId] = tempQuantity;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0E5CA8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSelectItemsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildItemTile('Empty 14.2kg Cylinders'),
                    _buildItemTile('Empty 5kg Cylinders'),
                    _buildItemTile('Empty 19kg Commercial Cylinder'),
                    _buildItemTile('Defective Regulator'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

    Widget _buildItemTile(String itemName) {
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: const Icon(Icons.inventory, color: Colors.grey),
        ),
        title: Text(itemName),
        subtitle: Text('Type: ${itemName.contains('Cylinder') ? 'Empty' : 'Defective'}'),
        onTap: () {
          Navigator.pop(context); // Close the item selection dialog
          _showQuantityDialog(itemName); // Show quantity dialog
        },
      );
    }

  void _showQuantityDialog(String itemName) {
    int quantity = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Enter Quantity'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Selected: $itemName'),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: quantity > 1
                            ? () {
                          setState(() {
                            quantity--;
                          });
                        }
                            : null,
                      ),
                      Container(
                        width: 50,
                        child: TextField(
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(text: quantity.toString()),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                quantity = int.tryParse(value) ?? 1;
                                if (quantity < 1) quantity = 1;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() {
                            quantity++;
                          });
                        },
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
                    // Add the item to unlinked items
                    _addUnlinkedItem(itemName, quantity);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E5CA8),
                  ),
                  child: const Text('ADD',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addUnlinkedItem(String itemName, int quantity) {
    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a warehouse first')),
      );
      return;
    }

    // Generate unique order ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final orderId = 'Order #UN-$timestamp';

    // Create item structure that matches your data model
    final newUnlinkedOrder = {
      'orderId': orderId,
      'items': [
        {
          'name': itemName.replaceAll('Empty ', '').replaceAll('Defective ', ''),
          'quantity': quantity,
          'maxQuantity': quantity
        }
      ]
    };

    setState(() {
      // Add to UNLINKED category in the selected warehouse
      _warehouseOrders[_selectedWarehouseId]!['UNLINKED']!.add(newUnlinkedOrder);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $quantity $itemName to unlinked items'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildUnlinkedItemsCard() {
    if (_unlinkedItems.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Unlinked Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  color: Color(0xFF0E5CA8),
                  onPressed: _showSelectItemsDialog,
                ),
              ],
            ),
            Divider(),
            ..._unlinkedItems.map((item) => _buildUnlinkedItemRow(item)),
          ],
        ),
      ),
    );
  }
// Widget to display a single unlinked item with edit/delete options:
  Widget _buildUnlinkedItemRow(UnlinkedItem item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(item.name),
          ),
          Text(
            'Qty: ${item.quantity}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.edit, size: 20),
            onPressed: () => _editUnlinkedItem(item.name, item.quantity),
            padding: EdgeInsets.all(4),
            constraints: BoxConstraints(),
          ),
          IconButton(
            icon: Icon(Icons.delete, size: 20),
            onPressed: () => _removeUnlinkedItem(item),
            padding: EdgeInsets.all(4),
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _editUnlinkedItem(String orderId, int newQuantity) {
    if (_selectedWarehouseId == null) return;

    setState(() {
      final unlinkedItems = _warehouseOrders[_selectedWarehouseId]!['UNLINKED']!;

      for (int i = 0; i < unlinkedItems.length; i++) {
        if (unlinkedItems[i]['orderId'] == orderId) {
          // Update quantity in both fields
          unlinkedItems[i]['items'][0]['quantity'] = newQuantity;
          unlinkedItems[i]['items'][0]['maxQuantity'] = newQuantity;
          break;
        }
      }
    });
  }

  void _removeUnlinkedItem(UnlinkedItem item) {
    setState(() {
      _unlinkedItems.remove(item);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${item.name}'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showConfirmDepositDialog() {
    final summary = _calculateDepositSummary();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Confirm Deposit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Are you sure you want to submit this  request?'),
                const SizedBox(height: 16),
                Text(
                  'Warehouse: $_selectedWarehouse',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                ...summary.entries.map((e) => Text('${e.key}: ${e.value}')),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0E5CA8)),
                          foregroundColor: const Color(0xFF0E5CA8),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showSuccessDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E5CA8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Deposit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog() {

    if (_isSubmitting) {
      print("Already submitting - ignoring duplicate call");
      return;
    }
    _isSubmitting = true;
    // Generate a truly unique ID by including more of the timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final requestId = 'DP-$timestamp';

    // Create the request object first
    final summary = _calculateDepositSummary();
    final newRequest = InventoryRequest(
      id: requestId, // Completely unique ID
      warehouseId: _selectedWarehouseId ?? '',
      warehouseName: _selectedWarehouse ?? 'Unknown',
      requestedBy: 'Current User',
      role: 'CSE',
      cylinders14kg: summary['14.2kg Cylinders'] ?? 0,
      cylinders19kg: summary['19kg Cylinders'] ?? 0,
      smallCylinders: summary['5kg Cylinders'] ?? 0,
      status: 'PENDING',
      timestamp: DateTime.now().toString().substring(0, 16),
      isFavorite: false,
    );

    // Add to bloc OUTSIDE the dialog builder to ensure it happens exactly once
    print("Adding deposit request with ID: $requestId to bloc");
    context.read<InventoryBloc>().add(AddInventoryRequest(request: newRequest));

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) { // Use dialogContext to avoid context issues
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button from closing dialog
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Deposit Request Submitted',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Request ID $requestId',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Simply close both screens
                        context.read<InventoryBloc>().add(LoadInventoryRequests());// Return to inventory list
                        Navigator.pop(dialogContext); // Close dialog
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

    Map<String, int> _calculateDepositSummary() {
      Map<String, int> summary = {};

      // Add items from selected orders
      _selectedOrders.forEach((orderId, quantity) {
        // Find the order in the warehouse data
        for (var category in _warehouseOrders[_selectedWarehouseId]!.keys) {
          for (var order in _warehouseOrders[_selectedWarehouseId]![category]!) {
            if (order['orderId'] == orderId) {
              for (var item in order['items']) {
                summary[item['name']] = (summary[item['name']] ?? 0) + quantity;
              }
            }
          }
        }
      });

      // Add unlinked items
      for (var item in _unlinkedItems) {
        // Extract the item name (e.g., "14.2kg Cylinders" from "Empty 14.2kg Cylinders")
        String itemName;
        if (item.name.contains('14.2kg')) {
          itemName = '14.2kg Cylinders';
        } else if (item.name.contains('5kg')) {
          itemName = '5kg Cylinders';
        } else if (item.name.contains('19kg')) {
          itemName = '19kg Cylinders';
        } else {
          itemName = item.name; // For items like Defective Regulator
        }

        summary[itemName] = (summary[itemName] ?? 0) + item.quantity;
      }

      return summary;
    }

  // Calculate all available orders for Select All functionality
  int _getOrderCountForWarehouse() {
    if (_selectedWarehouseId == null) return 0;

    int count = 0;
    final warehouseData = _warehouseOrders[_selectedWarehouseId] ?? {};
    warehouseData.forEach((_, orders) {
      count += orders.length;
    });

    return count;
  }

  // Update Select All based on current selections
  void _updateSelectAllState() {
    setState(() {
      int totalOrders = _getOrderCountForWarehouse();
      _selectAll = totalOrders > 0 && _selectedOrders.length == totalOrders;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit Inventory'),
        backgroundColor: const Color(0xFF0E5CA8),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.warehouse, color: Color(0xFF0E5CA8)),
                  title: Text(
                    _selectedWarehouse ?? 'Warehouse',
                    style: TextStyle(
                      color: _selectedWarehouse != null ? Colors.black : Colors.grey,
                    ),
                  ),
                  subtitle: Text(
                    _selectedWarehouse != null
                        ? _warehouses.firstWhere((w) => w['name'] == _selectedWarehouse,
                        orElse: () => {'address': 'Unknown'})['address']
                        : 'Select warehouse',
                    style: TextStyle(
                      color: _selectedWarehouse != null ? Colors.blue : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF0E5CA8)),
                  onTap: _showWarehouseSelectionDialog,
                ),
                if (_selectedWarehouseId != null) ...[
                  const Divider(height: 1),
                  InkWell(
                    onTap: _showSelectItemsDialog,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline, color: Color(0xFF0E5CA8)),
                          SizedBox(width: 12),
                          Text(
                            'Add items manually for unlinked deposit',
                            style: TextStyle(color: Color(0xFF0E5CA8)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_selectedWarehouseId != null) ...[
            // Select All checkbox
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectAll,
                    onChanged: (bool? value) {
                      setState(() {
                        _selectAll = value ?? false;
                        final warehouseData = _warehouseOrders[_selectedWarehouseId] ?? {};

                        if (_selectAll) {
                          // Select all orders
                          warehouseData.forEach((category, orders) {
                            for (var order in orders) {
                              _selectedOrders[order['orderId']] = order['items'][0]['quantity'];
                            }
                          });
                        } else {
                          // Deselect all orders
                          _selectedOrders.clear();
                        }
                      });
                    },
                  ),
                  const Text('Select All'),
                  const Spacer(),
                  Text('Available Orders: ${_getOrderCountForWarehouse()}'),
                ],
              ),
            ),

            // Sales Orders List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Sales Orders by Category
                  ...(_warehouseOrders[_selectedWarehouseId] ?? {}).entries.expand((entry) {
                    return [
                      if (entry.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ...entry.value.map((order) => _buildOrderTile(order)),
                    ];
                  }),
                ],
              ),
            ),

            // Deposit Summary
            if (_selectedOrders.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deposit Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._calculateDepositSummary().entries.map((entry) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      );
                    }),
                    Divider(
                      color: Colors.grey.shade300,
                      height: 10,
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     const Text('Orders Selected:'),
                    //     Text('${_selectedOrders.length}',
                    //         style: const TextStyle(fontWeight: FontWeight.bold)),
                    //   ],
                    // ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Items:'),
                        Text(
                          '${_calculateDepositSummary().values.fold(0, (sum, qty) => sum + qty)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedOrders.isNotEmpty && _selectedWarehouse != null
                      ? _showConfirmDepositDialog
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E5CA8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'SUBMIT DEPOSIT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Text(
                  'Please select a warehouse to view available orders',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          _buildUnlinkedItemsCard(),
        ],
      ),
    );
  }

  Widget _buildOrderTile(Map<String, dynamic> order) {
    final isSelected = _selectedOrders.containsKey(order['orderId']);
    final currentQuantity = _selectedOrders[order['orderId']] ?? order['items'][0]['quantity'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF0E5CA8) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          unselectedWidgetColor: Colors.grey.shade400,
        ),
        child: CheckboxListTile(
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedOrders[order['orderId']] = order['items'][0]['quantity'];
              } else {
                _selectedOrders.remove(order['orderId']);
              }
              // Update select all checkbox state
              _updateSelectAllState();
            });
          },
          title: Text(order['orderId']),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...order['items'].map<Widget>((item) {
                return Text(
                  // If this is the first item and this order is selected, show the edited quantity
                  item == order['items'][0] && isSelected
                      ? '${currentQuantity} x  ${item['name']}'
                      : '${item['quantity']} x  ${item['name']}',
                  style: const TextStyle(fontSize: 12),
                );
              }).toList(),
            ],
          ),
          activeColor: const Color(0xFF0E5CA8),
          checkColor: Colors.white,
          secondary: isSelected ?
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF0E5CA8)),
            onPressed: () => _showQuantityEditDialog(order['orderId'], order),
          ) : null,
        ),
      ),
    );
  }
}

class UnlinkedItem {
  final String name;
  final int quantity;

  UnlinkedItem({required this.name, required this.quantity});
}