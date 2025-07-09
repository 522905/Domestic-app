// lib/presentation/widgets/selectors/warehouse_selector_dialog.dart
import 'package:flutter/material.dart';

class WarehouseSelectorDialog extends StatefulWidget {
  final bool isOriginWarehouse;
  final Function(Map<String, dynamic>) onWarehouseSelected;

  const WarehouseSelectorDialog({
    Key? key,
    required this.isOriginWarehouse,
    required this.onWarehouseSelected,
  }) : super(key: key);

  @override
  State<WarehouseSelectorDialog> createState() => _WarehouseSelectorDialogState();

  static Future<void> show(
      BuildContext context,
      bool isOriginWarehouse,
      Function(Map<String, dynamic>) onWarehouseSelected,
      ) {
    return showDialog(
      context: context,
      builder: (context) => WarehouseSelectorDialog(
        isOriginWarehouse: isOriginWarehouse,
        onWarehouseSelected: onWarehouseSelected,
      ),
    );
  }
}

// Add this class implementation
class _WarehouseSelectorDialogState extends State<WarehouseSelectorDialog> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredWarehouses = [];

  // Mock warehouse data - in real app, get from a service or provider
  final List<Map<String, dynamic>> warehouses = [
    {'id': 'WH001', 'name': 'Warehouse 1 (Ludhiana Central)', 'address': 'Industrial Area Phase I, Ludhiana'},
    {'id': 'WH002', 'name': 'Warehouse 2 (Ludhiana North)', 'address': 'Focal Point, Ludhiana'},
    {'id': 'WH003', 'name': 'Warehouse 3 (Chandigarh)', 'address': 'Industrial Area Phase II, Chandigarh'},
    {'id': 'WH004', 'name': 'Warehouse 4 (Jalandhar)', 'address': 'Industrial Estate, Jalandhar'},
    {'id': 'WH005', 'name': 'Warehouse 5 (Amritsar)', 'address': 'Focal Point, Amritsar'},
  ];

  @override
  void initState() {
    super.initState();
    filteredWarehouses = List.from(warehouses);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isOriginWarehouse ? 'Select Origin Warehouse' : 'Select Destination Warehouse',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Search field
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search warehouses',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filterWarehouses,
            ),
            SizedBox(height: 16),

            // Warehouse list
            Flexible(
              child: filteredWarehouses.isEmpty
                  ? Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No warehouses found matching "${searchController.text}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: filteredWarehouses.length,
                itemBuilder: (context, index) => _buildWarehouseItem(filteredWarehouses[index]),
              ),
            ),

            // Cancel button
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CANCEL'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseItem(Map<String, dynamic> warehouse) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange[100],
        child: Icon(Icons.warehouse, color: Colors.orange[800]),
      ),
      title: Text(warehouse['name']),
      subtitle: Text(warehouse['address']),
      onTap: () {
        widget.onWarehouseSelected(warehouse);
        Navigator.pop(context);
      },
    );
  }

  void _filterWarehouses(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredWarehouses = List.from(warehouses);
      } else {
        filteredWarehouses = warehouses.where((warehouse) {
          return warehouse['name'].toLowerCase().contains(query.toLowerCase()) ||
              warehouse['address'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }
}