// lib/presentation/pages/purchase_invoice/purchase_invoice_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../core/models/defect_inspection/purchase_invoice.dart';
import '../defect_inspection/dir_creation_screen.dart';
import 'dispatch_vehicle_screen_enhanced.dart';
import 'receive_vehicle_screen.dart';
import 'vehicle_history_screen.dart';

class PurchaseInvoiceDetailsScreen extends StatefulWidget {
  final String supplierGstin;
  final String supplierInvoiceDate;
  final String supplierInvoiceNumber;
  final List<String> userRoles;

  const PurchaseInvoiceDetailsScreen({
    Key? key,
    required this.supplierGstin,
    required this.supplierInvoiceDate,
    required this.supplierInvoiceNumber,
    this.userRoles = const [],
  }) : super(key: key);

  @override
  State<PurchaseInvoiceDetailsScreen> createState() => _PurchaseInvoiceDetailsScreenState();
}

class _PurchaseInvoiceDetailsScreenState extends State<PurchaseInvoiceDetailsScreen> {
  late ApiServiceInterface _apiService;

  Map<String, dynamic> _invoiceDetails = {};
  bool _isLoading = true;
  String _errorMessage = '';
  bool _hasVehicleHistory = false;
  String _warehouse = '' ;
  String _erpDataName = '' ;

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiServiceInterface>(context, listen: false);
    _loadInvoiceDetails();
  }

  Future<void> _loadInvoiceDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final details = await _apiService.getInvoiceDetails(
        widget.supplierGstin,
        widget.supplierInvoiceDate,
        widget.supplierInvoiceNumber,
      );

      // Check if vehicle has history
      final vehicleNo = _getVehicleNo(details);
      if (vehicleNo.isNotEmpty) {
        try {
          final history = await _apiService.getVehicleHistory(vehicleNo);
          _hasVehicleHistory = history.isNotEmpty;
        } catch (e) {
          _hasVehicleHistory = false;
        }
      }

      setState(() {
        _invoiceDetails = details;
        _warehouse = details['workflow']?['inevent']?['warehouse']?['name'] ?? '';
        _erpDataName = details['erp_data']?['name'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Helper methods to extract data from nested structure
  String _getVehicleNo(Map<String, dynamic> data) {
    return data['erp_data']?['vehicle_no'] ?? '';
  }

  String _getWorkflowStatus(Map<String, dynamic> data) {
    return data['workflow']?['workflow_status'] ?? 'pending';
  }

  String _getSupplierInvoiceNumber(Map<String, dynamic> data) {
    return data['erp_data']?['bill_no'] ?? '';
  }

  String _getSupplierInvoiceDate(Map<String, dynamic> data) {
    return data['erp_data']?['bill_date'] ?? '';
  }
  String _getCompany(Map<String, dynamic> data) {
    return data['erp_data']?['company'] ?? '';
  }
  String _getSupplierAddress(Map<String, dynamic> data) {
return data['erp_data']?['address_display'] ?? '';
  }

  String _getSupplierName(Map<String, dynamic> data) {
    return data['erp_data']?['supplier_name'] ?? '';
  }

  String _getSupplierGstin(Map<String, dynamic> data) {
    return data['erp_data']?['supplier_gstin'] ?? '';
  }

  double _getGrandTotal(Map<String, dynamic> data) {
    return data['erp_data']?['grand_total']?.toDouble() ?? 0.0;
  }

  String _getSapDocNumber(Map<String, dynamic> data) {
    return data['erp_data']?['custom_sap_doc_number'] ?? '';
  }

  String _getLoadType(Map<String, dynamic> data) {
    return data['erp_data']?['custom_load_type_summary'] ?? '';
  }

  List<Map<String, dynamic>> _getItemData(Map<String, dynamic> data) {
    List<dynamic> items = data['erp_data']?['items'] ?? [];
    return items.map((item) => {
      'item_code': item['item_code'] ?? '',
      'item_name': item['item_name'] ?? '',
      'qty': item['qty']?.toString() ?? '0',
    }).toList();
  }

  String _getTransportName(Map<String, dynamic> data) {
    return data['transport']?['transport_name'] ?? '';
  }
    String _getTransportContact(Map<String, dynamic> data) {
    return data['transport']?['transport_contact_phone'] ?? '';
  }

  String _getWarehouseName(Map<String, dynamic> data) {
    return data['workflow']?['inevent']?['warehouse']?['warehouse_label'] ?? '';
  }

  String _getDriverName(Map<String, dynamic> data) {
    return data['workflow']?['inevent']?['driver']?['name'] ?? '';
  }

  String _getDriverPhone(Map<String, dynamic> data) {
    return data['workflow']?['inevent']?['driver']?['phone_number'] ?? '';
  }

  Widget _buildCopyableDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Row(
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120.w,
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
          child: Row(
            children: [
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
              IconButton(
                icon: Icon(Icons.copy, size: 16.w),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied!')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatAddress(String address) {
    if (address.isEmpty) return '';
    return address
        .replaceAll('<br>', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = const Color(0xFFFFC107);
        displayText = 'Pending';
        break;
      case 'received':
        backgroundColor = const Color(0xFF4CAF50);
        displayText = 'Received';
        break;
      case 'completed':
        backgroundColor = const Color(0xFF2196F3);
        displayText = 'Completed';
        break;
      default:
        backgroundColor = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120.w,
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
                    fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 0.5, color: const Color(0xFFE0E0E0)),
      ],
    );
  }

   Widget _buildActionButtons() {
    // Hide all action buttons for Delivery Boy
    if (widget.userRoles.contains('Delivery Boy')) {
      return const SizedBox.shrink();
    }

    final status = _getWorkflowStatus(_invoiceDetails);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Create Defect Report Button - Always visible
        if(status == 'received' ) ... [
          ElevatedButton.icon(
            onPressed: () => _navigateToDIRCreation(),
            icon: const Icon(Icons.error_outline),
            label: Text(
              'Create Defect Report',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF57C00), // Orange color for defect reports
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 2,
              minimumSize: Size(double.infinity, 50.h),
            ),
          ),
        ],
          // Only show Receive/Dispatch buttons if status is pending or received
          if (status == 'pending' || status == 'received') ...[
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () {
                if (status == 'pending') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceiveVehicleScreen(
                        supplierGstin: widget.supplierGstin,
                        supplierInvoiceDate: widget.supplierInvoiceDate,
                        supplierInvoiceNumber: widget.supplierInvoiceNumber,
                      ),
                    ),
                  ).then((_) => _loadInvoiceDetails());
                } else if (status == 'received') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DispatchVehicleScreenEnhanced(
                        supplierGstin: widget.supplierGstin,
                        supplierInvoiceDate: widget.supplierInvoiceDate,
                        supplierInvoiceNumber: widget.supplierInvoiceNumber,
                        // invoiceItems: _getItemData(_invoiceDetails),
                        warehouse: _warehouse,
                        // warehouse: 'Focal Point - AI',
                      ),
                    ),
                  ).then((_) => _loadInvoiceDetails());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E5CA8),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 2,
                minimumSize: Size(double.infinity, 50.h),
              ),
              child: Text(
                status == 'pending' ? 'Receive Vehicle' : 'Dispatch Vehicle',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    final items = _getItemData(_invoiceDetails);

    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: const Color(0xFF0E5CA8), size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  'Items (${items.length})',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...items.map((item) => Card(
            margin: EdgeInsets.only(bottom: 12.h),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Code - Most Prominent
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E5CA8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          item['item_code'],
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0E5CA8),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Quantity Badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'Qty: ${item['qty']}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  // Item Name
                  Text(
                    item['item_name'],
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF333333),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          )).toList(),
          ],
        ),
      ),
    );
  }

  // Update _buildVehicleInfoSection method in purchase_invoice_details_screen.dart
  Widget _buildVehicleInfoSection() {
    // Hide vehicle information for Delivery Boy
    if (widget.userRoles.contains('Delivery Boy')) {
      return const SizedBox.shrink();
    }

    final vehicleNo = _getVehicleNo(_invoiceDetails);
    final transportContact = _getTransportContact(_invoiceDetails);
    final transportName = _getTransportName(_invoiceDetails);
    final warehouseName = _getWarehouseName(_invoiceDetails);
    final driverName = _getDriverName(_invoiceDetails);
    final driverPhone = _getDriverPhone(_invoiceDetails);
    final driverId = _getDriverId(_invoiceDetails);


    if (vehicleNo.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.all(16.w),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Vehicle Information',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                if (_hasVehicleHistory)  // Add this condition
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VehicleHistoryScreen(
                            vehicleNo: vehicleNo,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.history,
                      color: Color(0xFF0E5CA8),
                    ),
                    label: Text(
                      'History',
                      style: TextStyle(
                        color: const Color(0xFF0E5CA8),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            _buildDetailRow('Vehicle No:', vehicleNo, isBold: true),
            if (warehouseName.isNotEmpty)
              _buildDetailRow('Warehouse:', warehouseName),
            if (driverName.isNotEmpty)
              _buildDetailRow('Driver:', driverName),
            if (driverPhone.isNotEmpty)
              _buildCopyableDetailRow('Driver Phone:', driverPhone),
            if (transportName.isNotEmpty)
              _buildDetailRow('Transport Name:', transportName),
            if (transportContact.isNotEmpty)
              _buildCopyableDetailRow('Transport Contact:', transportContact),
            if (driverId != null)
              TextButton.icon(
                onPressed: () => _showDriverDetails(driverId),
                icon: const Icon(
                  Icons.person,
                  color: Color(0xFF0E5CA8),
                ),
                label: Text(
                  'Driver Details',
                  style: TextStyle(
                    color: const Color(0xFF0E5CA8),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Driver Details Card
  Widget _buildDriverDetailsCard() {
    // Hide for Delivery Boy
    if (widget.userRoles.contains('Delivery Boy')) {
      return const SizedBox.shrink();
    }

    final vehicleNo = _getVehicleNo(_invoiceDetails);
    final driverName = _getDriverName(_invoiceDetails);
    final driverPhone = _getDriverPhone(_invoiceDetails);
    final driverId = _getDriverId(_invoiceDetails);

    // Don't show if no driver info
    if (vehicleNo.isEmpty && driverName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin:EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: const Color(0xFF0E5CA8), size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  'Driver Details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                if (_hasVehicleHistory) ...[
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VehicleHistoryScreen(vehicleNo: vehicleNo),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history, color: Color(0xFF0E5CA8)),
                    label: Text(
                      'History',
                      style: TextStyle(
                        color: const Color(0xFF0E5CA8),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 8.h),
            if (vehicleNo.isNotEmpty)
              _buildDetailRow('Vehicle No:', vehicleNo, isBold: true),
            if (driverName.isNotEmpty)
              _buildDetailRow('Driver:', driverName),
            if (driverPhone.isNotEmpty)
              _buildCopyableDetailRow('Driver Phone:', driverPhone),
            if (driverId != null)
              TextButton.icon(
                onPressed: () => _showDriverDetails(driverId),
                icon: const Icon(Icons.person, color: Color(0xFF0E5CA8)),
                label: Text(
                  'View Driver Details',
                  style: TextStyle(
                    color: const Color(0xFF0E5CA8),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Transport Details Card
  Widget _buildTransportDetailsCard() {
    // Hide for Delivery Boy
    if (widget.userRoles.contains('Delivery Boy')) {
      return const SizedBox.shrink();
    }

    final transportName = _getTransportName(_invoiceDetails);
    final transportContact = _getTransportContact(_invoiceDetails);

    // Don't show if no transport info
    if (transportName.isEmpty && transportContact.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: const Color(0xFF0E5CA8), size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  'Transport Details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            if (transportName.isNotEmpty)
              _buildDetailRow('Transport Name:', transportName),
            if (transportContact.isNotEmpty)
              _buildCopyableDetailRow('Transport Contact:', transportContact),
          ],
        ),
      ),
    );
  }

// Add these helper methods:

  int? _getDriverId(Map<String, dynamic> data) {
    return data['workflow']?['inevent']?['driver']?['id'];
  }

  Future<void> _showDriverDetails(int driverId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _apiService.getDriverDetails(driverId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF0E5CA8),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Loading driver details...',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48.w,
                      color: const Color(0xFFF44336),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Failed to load driver details',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF666666),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E5CA8),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }

            final driver = snapshot.data!;
            return Container(
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
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Driver Photo
                  if (driver['photo'] != null && driver['photo'].toString().isNotEmpty)
                    Center(
                      child: Container(
                        width: 120.w,
                        height: 120.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0E5CA8),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            driver['photo'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person,
                              size: 60,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ),
                    ),

                  SizedBox(height: 20.h),

                  // Driver Information
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    child: Column(
                      children: [
                        _buildDriverDetailRow('Name:', driver['name'] ?? 'N/A'),
                        _buildDriverDetailRow('Phone:', driver['phone_number'] ?? 'N/A'),
                        _buildDriverDetailRow('Visit Count:', driver['visit_count']?.toString() ?? '0'),
                        _buildDriverDetailRow(
                            'Last Seen:',
                            driver['last_seen_date'] != null
                                ? DateFormat('dd-MMM-yyyy HH:mm').format(
                                DateTime.parse(driver['last_seen_date'])
                            )
                                : 'N/A'
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E5CA8),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDriverDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
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

  Future<void> _navigateToDIRCreation() async {
    final supplierInvoiceNumber = _getSupplierInvoiceNumber(_invoiceDetails);
    final company = _getCompany(_invoiceDetails);

    if (supplierInvoiceNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice details not loaded yet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }


    final prePopulated = DIRPrePopulated(
      purchaseInvoice: _erpDataName,
      warehouse: _warehouse,
      purpose: 'Same Load Defectives',
      company: company.isNotEmpty ? company : 'ATSPL',
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DIRCreationScreen(prePopulated: prePopulated),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Defect report created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadInvoiceDetails(); // Refresh invoice details
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd-MMM-yyyy');
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          _getSapDocNumber(_invoiceDetails).isNotEmpty
              ? _getSapDocNumber(_invoiceDetails)
              : widget.supplierInvoiceNumber,
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
                'Error loading details',
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
                onPressed: _loadInvoiceDetails,
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
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Invoice Summary Card
                  Card(
                    margin: EdgeInsets.all(16.w),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Invoice Summary',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                              _buildStatusBadge(_getWorkflowStatus(_invoiceDetails)),
                              _buildStatusBadge(_getLoadType(_invoiceDetails)),

                            ],
                          ),
                          SizedBox(height: 16.h),
                            _buildDetailRow(
                                'Date:',
                                _getSupplierInvoiceDate(_invoiceDetails).isNotEmpty
                                  ? dateFormat.format(DateTime.parse(_getSupplierInvoiceDate(_invoiceDetails))) : ''
                            ),
                          _buildDetailRow('SAP Doc Num.: ', _getSapDocNumber(_invoiceDetails), isBold: true),
                          _buildDetailRow('Load Type: ', _getLoadType(_invoiceDetails), isBold: true),
                          _buildDetailRow('Invoice:', _getSupplierInvoiceNumber(_invoiceDetails)),
                          _buildDetailRow('Company', _getCompany(_invoiceDetails)),
                          _buildDetailRow('Supplier:', '${_getSupplierName(_invoiceDetails)} (${_getSupplierGstin(_invoiceDetails)})'),
                          _buildDetailRow('Vehicle:', _getVehicleNo(_invoiceDetails)),
                          _buildDetailRow(
                              'Grand Total:',
                              currencyFormat.format(_getGrandTotal(_invoiceDetails)),
                              isBold: true
                          ),
                          _buildDetailRow('Address:', _formatAddress(_getSupplierAddress(_invoiceDetails)), isBold: true),
                        ],
                      ),
                    ),
                  ),
                  // Items Card
                  _buildItemsSection(),
                  // Driver Details Card
                  _buildDriverDetailsCard(),
                  // Transport Details Card
                  _buildTransportDetailsCard(),
                ],
              ),
            ),
          ),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }
}