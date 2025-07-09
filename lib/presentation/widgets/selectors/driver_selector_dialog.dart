// lib/presentation/widgets/selectors/driver_selector_dialog.dart
import 'package:flutter/material.dart';

class DriverSelectorDialog extends StatefulWidget {
  final List<Map<String, dynamic>> drivers;
  final Function(Map<String, dynamic>) onDriverSelected;

  const DriverSelectorDialog({
    Key? key,
    required this.drivers,
    required this.onDriverSelected,
  }) : super(key: key);

  @override
  State<DriverSelectorDialog> createState() => _DriverSelectorDialogState();

  static Future<void> show(
      BuildContext context,
      List<Map<String, dynamic>> drivers,

      Function(Map<String, dynamic>) onDriverSelected,
      ) {
    return showDialog(
      context: context,
      builder: (context) => DriverSelectorDialog(
        drivers: drivers,
        onDriverSelected: onDriverSelected,
      ),
    );
  }
}

class _DriverSelectorDialogState extends State<DriverSelectorDialog> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredDrivers = [];

  @override
  void initState() {
    super.initState();
    filteredDrivers = List.from(widget.drivers);
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Driver',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or vehicle number',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filterDrivers,
            ),
            SizedBox(height: 16),

            Flexible(
              child: filteredDrivers.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No drivers found matching "${searchController.text}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: filteredDrivers.length,
                itemBuilder: (context, index) => _buildDriverItem(filteredDrivers[index]),
              ),
            ),

            const SizedBox(height: 16),
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

  Widget _buildDriverItem(Map<String, dynamic> driver) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue[100],
        child: Icon(Icons.person, color: Colors.blue[800]),
      ),
      title: Text(driver['name']),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vehicle: ${driver['vehicle']}'),
          Text('Phone: ${driver['phone']}'),
        ],
      ),
      onTap: () {
        widget.onDriverSelected(driver);
        Navigator.pop(context);
      },
    );
  }

  void _filterDrivers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredDrivers = List.from(widget.drivers);
      } else {
        filteredDrivers = widget.drivers.where((driver) {
          return driver['name'].toLowerCase().contains(query.toLowerCase()) ||
              driver['vehicle'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }
}