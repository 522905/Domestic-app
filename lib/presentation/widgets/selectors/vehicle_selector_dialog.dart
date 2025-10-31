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
    final size = MediaQuery.of(context).size;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: size.height * 0.60,
          maxWidth: size.width * 0.95,
        ),
        child: _VehicleSelectorContent(
          vehicles: vehicles,
          onVehicleSelected: onVehicleSelected,
          title: title ?? 'Select Vehicle',
        ),
      ),
    );
  }
}

class _VehicleSelectorContent extends StatefulWidget {
  final List<Map<String, dynamic>> vehicles;
  final Function(Map<String, dynamic>) onVehicleSelected;
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
  List<Map<String, dynamic>> filteredVehicles = [];

  @override
  void initState() {
    super.initState();
    filteredVehicles = List.from(widget.vehicles);
  }

  void _filterVehicles(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredVehicles = widget.vehicles.where((vehicle) {
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
    final size = MediaQuery.of(context).size;
    final horizontalMargin = size.width * 0.05; // responsive margin

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              maxHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(8.0),
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
                        Flexible(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                        hintText: 'Search Vehicle...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // Vehicle list
                  Expanded(
                    child: filteredVehicles.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 4),
                          Text(
                            searchQuery.isEmpty
                                ? 'No vehicles available'
                                : 'No vehicles found',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredVehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = filteredVehicles[index];
                        final isActive = vehicle['is_active'] == true;

                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: horizontalMargin,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isActive
                                  ? Colors.orange.shade100
                                  : Colors.grey.shade100,
                              child: Icon(
                                Icons.local_shipping,
                                color: isActive
                                    ? Colors.orange[800]
                                    : Colors.grey[600],
                              ),
                            ),
                            title: Text(
                              vehicle['vehicle_number'] ?? 'Unknown Vehicle',
                              style: TextStyle(
                                color: isActive ? Colors.black : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Type: ${vehicle['vehicle_type']?.toString().toUpperCase() ?? 'UNKNOWN'}',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.black54
                                        : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                if (vehicle['partner_name'] != null &&
                                    vehicle['partner_name'].toString().isNotEmpty)
                                  Text(
                                    'Partner: ${vehicle['partner_name']}',
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.black54
                                          : Colors.grey,
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius:
                                      BorderRadius.circular(10),
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
                                const SizedBox(width: 4),
                                Icon(
                                  isActive
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: isActive
                                      ? Colors.green
                                      : Colors.red,
                                  size: 20,
                                ),
                              ],
                            ),
                            enabled: isActive,
                            onTap: isActive
                                ? () => widget.onVehicleSelected(vehicle)
                                : null,
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
              ),
            ),
          ),
        );
      },
    );
  }
}
