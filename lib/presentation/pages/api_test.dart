import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:lpg_distribution_app/core/services/service_provider.dart';

class ApiTestScreen extends StatefulWidget {
  @override
  _ApiTestScreenState createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  bool isLoading = false;
  String resultText = "No data fetched yet";
  List<dynamic> warehouses = [];
  List<dynamic> vehicles = [];
  List<dynamic> inventoryItems = [];
  List<dynamic> inventoryRequests = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API Test'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('API Connection Test', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _fetchWarehouses,
              child: Text('Test Warehouses API'),
            ),
            SizedBox(height: 10),

            ElevatedButton(
              onPressed: _fetchVehicles,
              child: Text('Test Vehicles API'),
            ),
            SizedBox(height: 10),

            ElevatedButton(
              onPressed: _fetchInventory,
              child: Text('Test Inventory API'),
            ),
            SizedBox(height: 10),

              ElevatedButton(
                onPressed: _fetchInventoryRequests,
                child: Text('Test Inventory Requests API'),
              ),
              SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  isLoading = true;
                  resultText = "Refreshing server data...";
                });

                try {
                  final response = await http.get(Uri.parse('http://192.168.168.152:8000/api/refresh-data'));
                  print(response.body);
                  setState(() {
                    resultText = "Server data refreshed: ${response.body}";
                    isLoading = false;
                  });
                } catch (e) {
                  setState(() {
                    resultText = "Error refreshing data: $e";
                    isLoading = false;
                  });
                }
              },
              child: const Text('Refresh Server Data'),
            ),
            SizedBox(height: 20),
            SizedBox(height: 20),

            const Text('Results:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(resultText),
            ),

            if (warehouses.isNotEmpty) ...[
              SizedBox(height: 20),
              Text('Warehouses:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ...warehouses.map((warehouse) => Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(warehouse['name'] ?? 'Unknown'),
                  subtitle: Text(warehouse['address'] ?? 'No address'),
                  trailing: Text('Capacity: ${warehouse['capacity']}'),
                ),
              )).toList(),
            ],

            if (vehicles.isNotEmpty) ...[
              SizedBox(height: 20),
              Text('Vehicles:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ...vehicles.map((vehicle) => Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(vehicle['registration'] ?? 'Unknown'),
                  subtitle: Text('${vehicle['type']} (${vehicle['driver']})'),
                  trailing: Text('Capacity: ${vehicle['capacity']}'),
                ),
              )).toList(),
            ],

            if (inventoryItems.isNotEmpty) ...[
              SizedBox(height: 20),
              Text('Inventory Items:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ...inventoryItems.take(5).map((item) => Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(item['name'] ?? 'Unknown'),
                  subtitle: Text('Type: ${item['item_type']} | SKU: ${item['sku']}'),
                  trailing: Text('Available: ${item['available']}'),
                ),
              )).toList(),
              if (inventoryItems.length > 5)
                Center(child: Text('+ ${inventoryItems.length - 5} more items')),
            ],

            if (inventoryRequests.isNotEmpty) ...[
              SizedBox(height: 20),
              Text('Inventory Requests:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ...inventoryRequests.map((request) => Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('Request ${request['id']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Warehouse: ${request['warehouse_name']}'),
                      Text('14kg: ${request['cylinders_14kg']} | 19kg: ${request['cylinders_19kg']} | 5kg: ${request['small_cylinders']}'),
                    ],
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: request['status'] == 'PENDING' ? Colors.amber :
                      request['status'] == 'APPROVED' ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      request['status'] ?? 'UNKNOWN',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  isThreeLine: true,
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _fetchWarehouses() async {
    setState(() {
      isLoading = true;
      resultText = "Fetching warehouses...";
      warehouses = [];
      vehicles = [];
      inventoryItems = [];
      inventoryRequests = [];
    });

    // try {
    //   final apiService = await ServiceProvider.getApiService();
    //   final data = await apiService.getWarehouses();
    //   setState(() {
    //     warehouses = data;
    //     resultText = "Successfully fetched ${data.length} warehouses";
    //     isLoading = false;
    //   });
    // } catch (e) {
    //   setState(() {
    //     resultText = "Error fetching warehouses: $e";
    //     isLoading = false;
    //   });
    // }
  }

  Future<void> _fetchVehicles() async {
    setState(() {
      isLoading = true;
      resultText = "Fetching vehicles...";
      warehouses = [];
      vehicles = [];
      inventoryItems = [];
      inventoryRequests = [];
    });

    try {
      final apiService = await ServiceProvider.getApiService();
      final data = await apiService.getVehicles();

      setState(() {
        vehicles = data;
        resultText = "Successfully fetched ${data.length} vehicles";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        resultText = "Error fetching vehicles: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _fetchInventory() async {
    setState(() {
      isLoading = true;
      resultText = "Fetching inventory...";
      warehouses = [];
      vehicles = [];
      inventoryItems = [];
      inventoryRequests = [];
    });

    try {
      final apiService = await ServiceProvider.getApiService();
      final data = await apiService.getInventory();

      setState(() {
        inventoryItems = data;
        resultText = "Successfully fetched ${data.length} inventory items";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        resultText = "Error fetching inventory: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _fetchInventoryRequests() async {
    setState(() {
      isLoading = true;
      resultText = "Fetching inventory requests...";
      warehouses = [];
      vehicles = [];
      inventoryItems = [];
      inventoryRequests = [];
    });

    try {
      final apiService = await ServiceProvider.getApiService();
      final data = await apiService.getInventoryRequests();

      setState(() {
        inventoryRequests = data;
        resultText = "Successfully fetched ${data.length} inventory requests";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        resultText = "Error fetching inventory requests: $e";
        isLoading = false;
      });
    }
  }
}