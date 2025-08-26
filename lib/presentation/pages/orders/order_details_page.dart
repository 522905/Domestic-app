import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/order.dart';
import '../../blocs/orders/orders_bloc.dart';
import '../../blocs/orders/orders_event.dart';
import '../../blocs/orders/orders_state.dart';

class OrderDetailsPage extends StatefulWidget {
  final Order order;

  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _response;

  void _requestApproval(BuildContext context, Order order) async {
    setState(() {
      _isLoading = true;
      _response = null;
    });

    try {
      // Dispatch the event to request approval using the existing BLoC
      context.read<OrdersBloc>().add(RequestOrderApproval(order.id));

      // Wait for the bloc to emit the response
      final responseState = await context.read<OrdersBloc>().stream.firstWhere(
            (state) => state is OrdersLoadedWithResponse || state is OrdersError,
      );

      if (responseState is OrdersLoadedWithResponse) {
        setState(() {
          _response = responseState.response; // Use the actual API response
        });

        // Don't wait for the normal state transition, let the BLoC handle it

      } else if (responseState is OrdersError) {
        setState(() {
          _response = {"error": responseState.message};
        });
      }
    } catch (e) {
      setState(() {
        _response = {"error": "Failed to request approval: $e"};
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildResponseWidget() {
    if (_response == null) {
      return const SizedBox.shrink();
    }

    if (_response!.containsKey('error')) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade600, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _response!['error'],
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Extract the `message` field from your original API response structure
    final message = _response!['erp_response']?['message'];
    final status = message?['status'] ?? 'Unknown';

    if (status == 'credit_failed') {
      // Handle `credit_failed` response
      final creditResult = message?['credit_result'];
      final creditMessage = creditResult?['message'] ?? 'No message available';
      final requiredAmount = creditResult?['required_amount'] ?? 'N/A';

      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade600, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Credit Failed',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Message: $creditMessage',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.orange.shade700,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Required Amount: $requiredAmount',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'missing_returns') {
      // Handle `missing_returns` response
      final shortages = message?['shortages'] as List<dynamic>? ?? [];

      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade600, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Missing Returns',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            if (shortages.isNotEmpty)
              ...shortages.map((shortage) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Text(
                    'Item Group: ${shortage['item_group']}, Required: ${shortage['required']}, Available: ${shortage['available']}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.red.shade700,
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      );
    } else {
      // Handle success or other responses
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Response',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Status: $status',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            if (_response!.containsKey('message')) ...[
              SizedBox(height: 4.h),
              Text(
                _response!['message'].toString(),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'to deliver and bill':
        return const Color(0xFFFFC107);
      case 'on hold':
        return const Color(0xFFF44336);
      case 'completed':
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'draft':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.order.status);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0E5CA8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
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
                          widget.order.orderNumber,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0E5CA8),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            widget.order.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      widget.order.customerName,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Order Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Information',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0E5CA8),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildDetailRow(
                      'Transaction Date:',
                      DateFormat('MMM d, yyyy').format(widget.order.transactionDate),
                      Icons.calendar_today,
                    ),
                    _buildDetailRow(
                      'Delivery Date:',
                      DateFormat('MMM d, yyyy').format(widget.order.deliveryDate),
                      Icons.local_shipping,
                    ),
                    _buildDetailRow(
                      'Vehicle:',
                      widget.order.vehicle,
                      Icons.directions_car,
                    ),
                    _buildDetailRow(
                      'Warehouse:',
                      widget.order.warehouse,
                      Icons.warehouse,
                    ),
                    _buildDetailRow(
                      'Delivery Status:',
                      widget.order.deliveryStatus,
                      Icons.delivery_dining,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Order Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0E5CA8),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildSummaryRow('Total Quantity:', '${widget.order.totalQty}'),
                    _buildSummaryRow('Delivered:', '${widget.order.perDelivered.toStringAsFixed(1)}%'),
                    _buildSummaryRow('Billed:', '${widget.order.perBilled.toStringAsFixed(1)}%'),
                    Divider(height: 24.h, thickness: 1),
                    _buildSummaryRow(
                      'Grand Total:',
                      '₹${widget.order.grandTotal.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Inventory Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory Information',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0E5CA8),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildDetailRow(
                      'Inventory Status:',
                      widget.order.inventoryStatus,
                      Icons.inventory,
                    ),
                    _buildDetailRow(
                      'Due Date:',
                      DateFormat('MMM d, yyyy').format(widget.order.inventoryDueDate),
                      Icons.schedule,
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            if (_canRequestApproval()) ...[
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _requestApproval(context, widget.order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E5CA8),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    'REQUEST FOR APPROVAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _buildResponseWidget(),
            ],
          ],
        ),
      ),
    );
  }

  bool _canRequestApproval() {
    final status = widget.order.status.toLowerCase();
    return status == 'on hold';
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFF0E5CA8).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0E5CA8),
              size: 16.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTotal ? 0 : 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16.sp : 14.sp,
              color: isTotal ? Colors.grey[800] : Colors.grey[600],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18.sp : 14.sp,
              fontWeight: FontWeight.bold,
              color: isTotal ? const Color(0xFF0E5CA8) : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}