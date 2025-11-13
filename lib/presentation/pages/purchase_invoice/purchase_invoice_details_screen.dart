// lib/presentation/pages/purchase_invoice/purchase_invoice_details_screen.dart
import 'package:flutter/material.dart';
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

  const PurchaseInvoiceDetailsScreen({
    Key? key,
    required this.supplierGstin,
    required this.supplierInvoiceDate,
    required this.supplierInvoiceNumber,
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
        _warehouse = details['inevent']['warehouse']['name'] ?? '';
        _erpDataName = details['erp_data']['name'] ?? '';
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

  List<Map<String, dynamic>> _getItemData(Map<String, dynamic> data) {
    List<dynamic> items = data['erp_data']?['items'] ?? [];
    return items.map((item) => {
      'item_code': item['item_code'] ?? '',
      'item_name': item['item_name'] ?? '',
      'qty': item['qty']?.toString() ?? '0',
    }).toList();
  }

  String _getTransportContact(Map<String, dynamic> data) {
    return data['workflow']?['transport_contact_phone'] ?? '';
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
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
    );
  }

   Widget _buildActionButtons() {
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

    return Padding(
      padding: EdgeInsets.all(5.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          SizedBox(height: 12.h),
          ...items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item['item_name'],
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    item['item_code'],
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ),
                Text(
                  'Qty: ${item['qty']}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0E5CA8),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  // Update _buildVehicleInfoSection method in purchase_invoice_details_screen.dart
  Widget _buildVehicleInfoSection() {
    final vehicleNo = _getVehicleNo(_invoiceDetails);
    final transportContact = _getTransportContact(_invoiceDetails);
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
        padding: EdgeInsets.all(5.w),
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
              _buildDetailRow('Driver Phone:', driverPhone),
            if (transportContact.isNotEmpty)
              _buildDetailRow('Transport Contact:', transportContact),
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
          widget.supplierInvoiceNumber,
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
                            ],
                          ),
                          SizedBox(height: 16.h),
                            _buildDetailRow(
                                'Date:',
                                _getSupplierInvoiceDate(_invoiceDetails).isNotEmpty
                                  ? dateFormat.format(DateTime.parse(_getSupplierInvoiceDate(_invoiceDetails))) : ''
                            ),
                          _buildDetailRow('Invoice:', _getSupplierInvoiceNumber(_invoiceDetails), isBold: true),
                          _buildDetailRow('SAP Doc Number:', _getSapDocNumber(_invoiceDetails)),
                          _buildDetailRow('Company', _getCompany(_invoiceDetails)),
                          _buildDetailRow('Supplier:', '${_getSupplierName(_invoiceDetails)} (${_getSupplierGstin(_invoiceDetails)})'),
                          _buildDetailRow('Vehicle:', _getVehicleNo(_invoiceDetails)),
                          _buildDetailRow(
                              'Grand Total:',
                              currencyFormat.format(_getGrandTotal(_invoiceDetails)),
                              isBold: true
                          ),
                          _buildDetailRow('Address', _getSupplierAddress(_invoiceDetails), isBold: true),
                          _buildItemsSection(),
                        ],
                      ),
                    ),
                  ),
                  // Vehicle Info Section
                  _buildVehicleInfoSection(),
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