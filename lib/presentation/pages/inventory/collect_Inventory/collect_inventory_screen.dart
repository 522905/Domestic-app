import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/inventory_request.dart';
import '../../../blocs/inventory/inventory_bloc.dart';
import '../../../blocs/inventory/inventory_event.dart';

class CollectInventoryScreen extends StatefulWidget {
  const CollectInventoryScreen({Key? key}) : super(key: key);

  @override
  State<CollectInventoryScreen> createState() => _CollectInventoryScreenState();
}

class _CollectInventoryScreenState extends State<CollectInventoryScreen> {
  final Map<String, int> _selectedOrders = {};
  String? _selectedWarehouse;
  String? _selectedWarehouseId;
  bool _isSubmitting = false;
  bool _isLoading = true;

  // This will be loaded from API
  Map<String, List<Map<String, dynamic>>> _warehouseOrders = {};
  List<Map<String, dynamic>> _warehouses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apiService = context.read<InventoryBloc>().apiService;

      final warehouses = await apiService.getWarehouses();
      final inventoryItems = await apiService.getInventoryItems();

      setState(() {
        _warehouses = List<Map<String, dynamic>>.from(warehouses);
        _warehouseOrders = _buildWarehouseOrdersFromApi(
            List<Map<String, dynamic>>.from(inventoryItems)
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  Map<String, List<Map<String, dynamic>>> _buildWarehouseOrdersFromApi(
      List<Map<String, dynamic>> inventoryItems) {
    // Transform API data into the format expected by the UI
    Map<String, List<Map<String, dynamic>>> result = {};

    for (var warehouse in _warehouses) {
      final warehouseId = warehouse['id'].toString();
      result[warehouseId] = [];

      // Filter items for this warehouse
      final warehouseItems = inventoryItems
          .where((item) => item['warehouse_id'].toString() == warehouseId)
          .toList();

      // Create mock orders from available inventory
      int orderIndex = 1;
      for (var item in warehouseItems) {
        if (item['available'] > 0) {
          result[warehouseId]!.add({
            'orderId': 'Order #UR-${warehouseId}${orderIndex.toString().padLeft(3, '0')}',
            'items': [
              {
                'name': item['name'],
                'quantity': item['available'],
                'maxQuantity': item['available'],
              },
            ],
            'status': 'RELEASED',
          });
          orderIndex++;
        }
      }
    }

    return result;
  }

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
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Warehouse',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if (_warehouses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No warehouses available'),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _warehouses.length,
                  itemBuilder: (context, index) {
                    final warehouse = _warehouses[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: const Text('W', style: TextStyle(color: Colors.blue)),
                      ),
                      title: Text(warehouse['name']),
                      subtitle: Text(warehouse['address'] ?? ''),
                      onTap: () {
                        setState(() {
                          _selectedWarehouse = warehouse['name'];
                          _selectedWarehouseId = warehouse['id'].toString();
                          _selectedOrders.clear();
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

  void _showQuantityEditDialog(String orderId, int currentQuantity, int maxQuantity) {
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
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Order: $orderId'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: tempQuantity > 1
                              ? () {
                            setState(() {
                              tempQuantity--;
                            });
                          }
                              : null,
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
                          onPressed: tempQuantity < maxQuantity
                              ? () {
                            setState(() {
                              tempQuantity++;
                            });
                          }
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Maximum available: $maxQuantity',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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

  void _showSubmitConfirmationDialog() {
    final summary = _calculateCollectionSummary();

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
                      'Confirm Collection',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Center(
                    child: Text('Are you sure you want to submit this request?')),
                const SizedBox(height: 8),
                Text(
                  'From: ${_selectedWarehouse ?? 'Unknown'}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                ...summary.entries.map((entry) => Text('${entry.key}: ${entry.value}')),
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
                          Navigator.pop(context);
                          _submitCollection();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E5CA8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Confirm'),
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

  Future<void> _submitCollection() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final requestId = 'CL-$timestamp';

      final summary = _calculateCollectionSummary();
      final newRequest = InventoryRequest(
        id: requestId,
        warehouseId: _selectedWarehouseId ?? '',
        warehouseName: _selectedWarehouse ?? 'Unknown',
        requestedBy: 'Current User',
        role: 'CSE',
        cylinders14kg: summary['14.2kg Cylinder'] ?? 0,
        cylinders19kg: summary['19kg Commercial Cylinder'] ?? 0,
        smallCylinders: summary['5kg Cylinder'] ?? 0,
        status: 'PENDING',
        timestamp: DateTime.now().toString().substring(0, 16),
        isFavorite: false,
      );

      // Add to bloc (this will call the API)
      context.read<InventoryBloc>().add(AddInventoryRequest(request: newRequest));

      _showSuccessDialog(requestId);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit collection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(String requestId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
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
                    'Collection Request Submitted',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        setState(() {
                          _isSubmitting = false;
                        });
                        Navigator.pop(dialogContext);
                        Navigator.pop(context, true); // Return success indicator
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

  Map<String, int> _calculateCollectionSummary() {
    Map<String, int> summary = {};

    if (_selectedWarehouseId != null) {
      final warehouseOrders = _warehouseOrders[_selectedWarehouseId] ?? [];

      for (var order in warehouseOrders) {
        if (_selectedOrders.containsKey(order['orderId'])) {
          for (var item in order['items']) {
            String itemName = item['name'];
            int adjustedQuantity = _selectedOrders[order['orderId']]!;
            summary[itemName] = (summary[itemName] ?? 0) + adjustedQuantity;
          }
        }
      }
    }

    return summary;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Collect Inventory'),
          backgroundColor: const Color(0xFF0E5CA8),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collect Inventory'),
        backgroundColor: const Color(0xFF0E5CA8),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Warehouse Selection Card
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
            child: ListTile(
              leading: const Icon(Icons.warehouse, color: Color(0xFF0E5CA8)),
              title: Text(
                _selectedWarehouse ?? 'Select Warehouse',
                style: TextStyle(
                  color: _selectedWarehouse != null ? Colors.black : Colors.grey,
                ),
              ),
              subtitle: Text(
                _selectedWarehouse != null
                    ? _warehouses
                    .firstWhere((w) => w['name'] == _selectedWarehouse,
                    orElse: () => {'address': 'Unknown'})['address'] ?? ''
                    : 'Choose warehouse to collect from',
                style: TextStyle(
                  color: _selectedWarehouse != null ? Colors.blue : Colors.orange,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showWarehouseSelectionDialog,
            ),
          ),

          // Orders List
          if (_selectedWarehouseId != null) ...[
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _warehouseOrders[_selectedWarehouseId]?.length ?? 0,
                itemBuilder: (context, index) {
                  final order = _warehouseOrders[_selectedWarehouseId]![index];
                  final isSelected = _selectedOrders.containsKey(order['orderId']);
                  final maxQuantity = order['items'][0]['maxQuantity'];
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
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedOrders[order['orderId']] = order['items'][0]['quantity'];
                          } else {
                            _selectedOrders.remove(order['orderId']);
                          }
                        });
                      },
                      title: Text(order['orderId']),
                      subtitle: Text('${currentQuantity} x ${order['items'][0]['name']}'),
                      activeColor: const Color(0xFF0E5CA8),
                      checkColor: Colors.white,
                      secondary: isSelected
                          ? IconButton(
                        icon: const Icon(Icons.edit),
                        color: const Color(0xFF0E5CA8),
                        onPressed: () => _showQuantityEditDialog(
                          order['orderId'],
                          currentQuantity,
                          maxQuantity,
                        ),
                      )
                          : null,
                    ),
                  );
                },
              ),
            ),

            // Collection Summary
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
                      'Collection Summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._calculateCollectionSummary().entries.map((entry) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${entry.key}:'),
                        Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )),
                    const Divider(height: 16, color: Colors.grey),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Quantity:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${_calculateCollectionSummary().values.fold(0, (a, b) => a + b)} Items',
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
                  onPressed: _selectedOrders.isNotEmpty && _selectedWarehouse != null && !_isSubmitting
                      ? _showSubmitConfirmationDialog
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E5CA8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'SUBMIT COLLECTION',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Text(
                  'Please select a warehouse to view available orders',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}