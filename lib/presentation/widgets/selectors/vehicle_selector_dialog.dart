import 'package:flutter/material.dart';

class VehicleSelectorDialog extends StatelessWidget {
  final List<Map<String, dynamic>> vehicles;
  final Function(Map<String, dynamic>) onVehicleSelected;
  final String? title;

  const VehicleSelectorDialog({
    Key? key,
    required this.vehicles,
    required this.onVehicleSelected,
    this.title = 'Select Vehicle',
  }) : super(key: key);

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required List<Map<String, dynamic>> vehicles,
    String? title,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return VehicleSelectorDialog(
          vehicles: vehicles,
          title: title,
          onVehicleSelected: (vehicle) {
            Navigator.pop(context, vehicle);
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
        child: _VehicleSelectorContent( // ✅ Fixed: proper naming
          vehicles: vehicles,
          onVehicleSelected: onVehicleSelected, // ✅ Fixed: proper naming
          title: title ?? 'Select Vehicle',
        ),
      ),
    );
  }
}

class _VehicleSelectorContent extends StatefulWidget { // ✅ Fixed: proper naming
  final List<Map<String, dynamic>> vehicles;
  final Function(Map<String, dynamic>) onVehicleSelected; // ✅ Fixed: proper naming
  final String title;

  const _VehicleSelectorContent({
    required this.vehicles,
    required this.onVehicleSelected,
    required this.title,
  });

  @override
  State<_VehicleSelectorContent> createState() => _VehicleSelectorContentState();
}

class _VehicleSelectorContentState extends State<_VehicleSelectorContent> {
  String searchQuery = '';
  List<Map<String, dynamic>> filteredVehicles = []; // ✅ Fixed: proper naming

  @override
  void initState() {
    super.initState();
    filteredVehicles = List.from(widget.vehicles);
  }

  void _filterVehicles(String query) { // ✅ Fixed: proper naming
    setState(() {
      searchQuery = query.toLowerCase();
      filteredVehicles = widget.vehicles.where((vehicle) { // ✅ Fixed: using vehicle data
        final vehicleNumber = (vehicle['vehicle_number'] ?? '').toString().toLowerCase();
        final vehicleType = (vehicle['vehicle_type'] ?? '').toString().toLowerCase();
        final partnerName = (vehicle['partner_name'] ?? '').toString().toLowerCase();
        return vehicleNumber.contains(searchQuery) ||
            vehicleType.contains(searchQuery) ||
            partnerName.contains(searchQuery);
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
            onChanged: _filterVehicles,
            decoration: InputDecoration(
              hintText: 'Search Vehicle...', // ✅ Fixed: proper hint text
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        // Vehicle list
        Flexible(
          child: filteredVehicles.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  searchQuery.isEmpty ? 'No vehicles available' : 'No vehicles found',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            itemCount: filteredVehicles.length,
            itemBuilder: (context, index) {
              final vehicle = filteredVehicles[index]; // ✅ Fixed: using vehicle data
              final isActive = vehicle['is_active'] == true;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.orange.shade100 : Colors.grey.shade100,
                    child: Icon(
                      Icons.local_shipping, // ✅ Vehicle icon instead of number
                      color: isActive ? Colors.orange[800] : Colors.grey[600],
                    ),
                  ),
                  title: Text(
                    vehicle['vehicle_number'] ?? 'Unknown Vehicle', // ✅ Show vehicle number
                    style: TextStyle(
                      color: isActive ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type: ${vehicle['vehicle_type']?.toString().toUpperCase() ?? 'UNKNOWN'}', // ✅ Show vehicle type
                        style: TextStyle(
                          color: isActive ? Colors.black54 : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (vehicle['partner_name'] != null &&
                          vehicle['partner_name'].toString().isNotEmpty)
                        Text(
                          'Partner: ${vehicle['partner_name']}',
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
                  onTap: isActive ? () => widget.onVehicleSelected(vehicle) : null,
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