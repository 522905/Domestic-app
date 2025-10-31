// lib/presentation/pages/purchase_invoice/purchase_invoice_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/purchase_invoice/purchase_invoice.dart';
import '../../../core/services/api_service_interface.dart';
import 'purchase_invoice_details_screen.dart';

class PurchaseInvoiceScreen extends StatefulWidget {
  const PurchaseInvoiceScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseInvoiceScreen> createState() => _PurchaseInvoiceScreenState();
}

class _PurchaseInvoiceScreenState extends State<PurchaseInvoiceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ApiServiceInterface _apiService;

  List<PurchaseInvoice> _allInvoices = [];
  List<PurchaseInvoice> _pendingInvoices = [];
  List<PurchaseInvoice> _receivedInvoices = [];

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _apiService = Provider.of<ApiServiceInterface>(context, listen: false);
    _loadInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Call both endpoints separately for better performance
      final pendingInvoices = await _apiService.getPendingInvoices();
      final receivedInvoices = await _apiService.getReceivedInvoices();

      setState(() {
        _pendingInvoices = pendingInvoices;
        _receivedInvoices = receivedInvoices;
        _allInvoices = [...pendingInvoices, ...receivedInvoices]; // Combined for total count if needed
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToDetails(PurchaseInvoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseInvoiceDetailsScreen(
          supplierInvoiceNumber: invoice.supplierInvoiceNumber,
          supplierGstin: invoice.supplierGstin,
          supplierInvoiceDate: invoice.supplierInvoiceDate,
        ),
      ),
    ).then((_) {
      // Refresh data when returning from details
      _loadInvoices();
    });
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = const Color(0xFFFFC107); // Warning Yellow
        displayText = 'Pending';
        break;
      case 'received':
        backgroundColor = const Color(0xFF4CAF50); // Success Green
        displayText = 'Received';
        break;
      case 'completed':
        backgroundColor = const Color(0xFF2196F3); // Info Blue
        displayText = 'Completed';
        break;
      default:
        backgroundColor = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(PurchaseInvoice invoice) {
    final DateFormat dateFormat = DateFormat('dd-MMM-yyyy');
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: InkWell(
        onTap: () => _navigateToDetails(invoice),
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row: Seed code and status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sap Doc: ${invoice.sapDocNumber}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0E5CA8),
                    ),
                  ),
                  _buildStatusBadge(invoice.workflowStatus),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Date: ${dateFormat.format(DateTime.parse(invoice.supplierInvoiceDate))}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ),
                  Text(
                    'Vehicle: ${invoice.vehicleNo}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      invoice.plant,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ),
                  Text(
                    'Total: ${currencyFormat.format(invoice.grandTotal)}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceList(List<PurchaseInvoice> invoices) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0E5CA8),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
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
                'Error loading invoices',
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
                onPressed: _loadInvoices,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E5CA8),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (invoices.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64.w,
                color: const Color(0xFF999999),
              ),
              SizedBox(height: 16.h),
              Text(
                'No invoices found',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Pull to refresh to check for new invoices',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInvoices,
      color: const Color(0xFF0E5CA8),
      child: ListView.builder(
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          return _buildInvoiceCard(invoices[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Purchase Invoice',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0E5CA8),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadInvoices,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
          ),
          tabs: [
            Tab(text: 'Pending (${_pendingInvoices.length})'),
            Tab(text: 'Received (${_receivedInvoices.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInvoiceList(_pendingInvoices),
          _buildInvoiceList(_receivedInvoices),
        ],
      ),
    );
  }
}