// lib/presentation/pages/purchase_invoice/vehicle_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service_interface.dart';

class VehicleHistoryScreen extends StatefulWidget {
  final String vehicleNo;

  const VehicleHistoryScreen({
    Key? key,
    required this.vehicleNo,
  }) : super(key: key);

  @override
  State<VehicleHistoryScreen> createState() => _VehicleHistoryScreenState();
}

class _VehicleHistoryScreenState extends State<VehicleHistoryScreen> {
  late ApiServiceInterface _apiService;

  List<Map<String, dynamic>> _historyList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiServiceInterface>(context, listen: false);
    _loadVehicleHistory();
  }

  Future<void> _loadVehicleHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _apiService.getVehicleHistory(widget.vehicleNo);

      // Convert response to list of maps
      List<Map<String, dynamic>> history;
      if (response is List) {
        history = List<Map<String, dynamic>>.from(response);
      } else {
        history = [response as Map<String, dynamic>];
      }

      setState(() {
        _historyList = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showDriverDetails(Map<String, dynamic> driverData) async {
    showDialog(
      context: context,
      builder: (context) => DriverDetailsDialog(
        driver: driverData['driver'],
        visitInfo: {
          'latest_visit': driverData['latest_visit'],
          'total_visits': driverData['total_visits'],
        },
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> historyItem) {
    final driver = historyItem['driver'] as Map<String, dynamic>;
    final latestVisit = historyItem['latest_visit'] as String;
    final totalVisits = historyItem['total_visits'] as int;

    final DateFormat dateFormat = DateFormat('dd-MMM-yyyy HH:mm');
    final DateTime visitDate = DateTime.parse(latestVisit);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => _showDriverDetails(historyItem),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Driver Photo
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0E5CA8),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: driver['photo'] != null && driver['photo'].toString().isNotEmpty
                      ? Image.network(
                    driver['photo'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.person,
                        size: 30.w,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                      : Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.person,
                      size: 30.w,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 16.w),

              // Driver Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Driver Name
                    Text(
                      driver['name'] ?? 'Unknown Driver',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // Phone Number
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 14.w,
                          color: const Color(0xFF666666),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          driver['phone_number'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),

                    // Latest Visit
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14.w,
                          color: const Color(0xFF666666),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Last visit: ${dateFormat.format(visitDate)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Visit Count Badge
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E5CA8),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '$totalVisits',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    totalVisits == 1 ? 'Visit' : 'Visits',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),

              SizedBox(width: 8.w),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16.w,
                color: const Color(0xFF0E5CA8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    final totalVisits = _historyList.fold<int>(
        0,
            (sum, item) => sum + (item['total_visits'] as int? ?? 0)
    );
    final totalDrivers = _historyList.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Vehicle: ${widget.vehicleNo}',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0E5CA8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0E5CA8),
        ),
      )
          : _errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.w,
                color: const Color(0xFFF44336),
              ),
              SizedBox(height: 16.h),
              Text(
                'Error loading history',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF666666),
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _loadVehicleHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E5CA8),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : _historyList.isEmpty
          ? Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64.w,
                color: const Color(0xFF999999),
              ),
              SizedBox(height: 16.h),
              Text(
                'No history found',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'This vehicle has no previous visits recorded',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadVehicleHistory,
        color: const Color(0xFF0E5CA8),
        child: Column(
          children: [
            // Summary Card
            Card(
              margin: EdgeInsets.all(16.w),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0E5CA8),
                      const Color(0xFF1976D2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Summary',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.local_shipping,
                                  color: Colors.white,
                                  size: 24.w,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                '$totalVisits',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Total Visits',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.people,
                                  color: Colors.white,
                                  size: 24.w,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                '$totalDrivers',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Unique Drivers',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // History List Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Driver History',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  Text(
                    'Tap for details',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),

            // History List
            Expanded(
              child: ListView.builder(
                itemCount: _historyList.length,
                itemBuilder: (context, index) {
                  return _buildDriverCard(_historyList[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Driver Details Dialog
class DriverDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> driver;
  final Map<String, dynamic> visitInfo;

  const DriverDetailsDialog({
    Key? key,
    required this.driver,
    required this.visitInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Driver Details',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: const Color(0xFF666666),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Driver Photo
            Center(
              child: Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0E5CA8), width: 3),
                ),
                child: ClipOval(
                  child: driver['photo'] != null && driver['photo'].toString().isNotEmpty
                      ? Image.network(
                    driver['photo'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.person,
                        size: 50.w,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                      : Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.person,
                      size: 50.w,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Driver Information
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Name:', driver['name'] ?? 'N/A'),
                  _buildDetailRow('Phone:', driver['phone_number'] ?? 'N/A'),
                  _buildDetailRow('Total Visits for this Vehicle:', visitInfo['total_visits']?.toString() ?? '0'),
                  _buildDetailRow('Overall Visit Count:', driver['visit_count']?.toString() ?? '0'),
                  _buildDetailRow(
                    'Latest Visit:',
                    visitInfo['latest_visit'] != null
                        ? DateFormat('dd-MMM-yyyy HH:mm').format(
                        DateTime.parse(visitInfo['latest_visit']))
                        : 'N/A',
                  ),
                  _buildDetailRow(
                    'Last Seen (Overall):',
                    driver['last_seen_date'] != null
                        ? DateFormat('dd-MMM-yyyy HH:mm').format(
                        DateTime.parse(driver['last_seen_date']))
                        : 'N/A',
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E5CA8),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF333333),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}