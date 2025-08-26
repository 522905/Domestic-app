// File: lib/presentation/widgets/dialogs/warehouse_selector_dialog.dart

import 'package:flutter/material.dart';

class WarehouseSelectorDialog extends StatelessWidget {
  final List<Map<String, dynamic>> warehouses;
  final Function(Map<String, dynamic>) onWarehouseSelected;
  final String? title;

  const WarehouseSelectorDialog({
    Key? key,
    required this.warehouses,
    required this.onWarehouseSelected,
    this.title = 'Select Warehouse',
  }) : super(key: key);

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required List<Map<String, dynamic>> warehouses,
    String? title,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return WarehouseSelectorDialog(
          warehouses: warehouses,
          title: title,
          onWarehouseSelected: (warehouse) {
            Navigator.pop(context, warehouse);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: _WarehouseSelectorContent(
          warehouses: warehouses,
          onWarehouseSelected: onWarehouseSelected,
          title: title ?? 'Select Warehouse',
        ),
      ),
    );
  }
}

class _WarehouseSelectorContent extends StatefulWidget {
  final List<Map<String, dynamic>> warehouses;
  final Function(Map<String, dynamic>) onWarehouseSelected;
  final String title;

  const _WarehouseSelectorContent({
    required this.warehouses,
    required this.onWarehouseSelected,
    required this.title,
  });

  @override
  State<_WarehouseSelectorContent> createState() => _WarehouseSelectorContentState();
}

class _WarehouseSelectorContentState extends State<_WarehouseSelectorContent> {
  String searchQuery = '';
  List<Map<String, dynamic>> filteredWarehouses = [];

  @override
  void initState() {
    super.initState();
    filteredWarehouses = List.from(widget.warehouses);
  }

  void _filterWarehouses(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredWarehouses = widget.warehouses.where((warehouse) {
        final name = (warehouse['name'] ?? '').toString().toLowerCase();
        final type = (warehouse['warehouse_type'] ?? '').toString().toLowerCase();
        final location = (warehouse['location'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery) ||
            type.contains(searchQuery) ||
            location.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Color(0xFF0E5CA8),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: _filterWarehouses,
            decoration: InputDecoration(
              hintText: 'Search warehouse...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        // Warehouse list
        Flexible(
          child: filteredWarehouses.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  searchQuery.isEmpty ? 'No warehouses available' : 'No warehouses found',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            itemCount: filteredWarehouses.length,
            itemBuilder: (context, index) {
              final warehouse = filteredWarehouses[index];
              final isActive = warehouse['is_active'] == true;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive
                        ? Colors.blue.shade100
                        : Colors.grey.shade100,
                    child: Text(
                        '${index + 1}',
                        style: TextStyle(
                            color: isActive
                                ? Colors.blue[800]
                                : Colors.grey[600]
                        )
                    ),
                  ),
                  title: Text(
                    warehouse['name'] ?? 'Unknown Name',
                    style: TextStyle(
                      color: isActive ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type: ${warehouse['warehouse_type']?.toString().toUpperCase() ?? 'UNKNOWN'}',
                        style: TextStyle(
                          color: isActive ? Colors.black54 : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (warehouse['location'] != null &&
                          warehouse['location'].toString().isNotEmpty)
                        Text(
                          'Location: ${warehouse['location']}',
                          style: TextStyle(
                            color: isActive ? Colors.black54 : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'INACTIVE',
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        isActive ? Icons.check_circle : Icons.cancel,
                        color: isActive ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ],
                  ),
                  enabled: isActive,
                  onTap: isActive ? () => widget.onWarehouseSelected(warehouse) : null,
                ),
              );
            },
          ),
        ),

        // Close button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ),
        ),
      ],
    );
  }
}