// lib/presentation/pages/orders/order_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/order.dart';
import '../../blocs/orders/orders_bloc.dart';

class OrderDetailsPage extends StatelessWidget {
  final Order order;

  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Status color mapping
    Color statusColor;
    switch (order.status) {
      case 'Pending':
        statusColor = const Color(0xFFFFC107);
        break;
      case 'Processing':
        statusColor = const Color(0xFF2196F3);
        break;
      case 'Completed':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'Rejected':
        statusColor = const Color(0xFFF44336);
        break;
      default:
        statusColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order #${order.orderNumber}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0E5CA8),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header with status
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Row(
            //       children: [
            //         Text(
            //           'Order Details :  ',
            //           style: TextStyle(
            //             fontSize: 18.sp,
            //             fontWeight: FontWeight.bold,
            //             color: Colors.grey[800],
            //           ),
            //         ),
            //         Text(
            //           order.orderNumber,
            //           style: TextStyle(
            //             color: Colors.black87,
            //             fontSize: 14.sp,
            //             fontWeight: FontWeight.w500,
            //           ),
            //         ),
            //       ],
            //     ),
            //     Container(
            //       padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            //       decoration: BoxDecoration(
            //         color: statusColor.withOpacity(0.15),
            //         borderRadius: BorderRadius.circular(20),
            //       ),
            //       child: Text(
            //         order.status,
            //         style: TextStyle(
            //           color: statusColor,
            //           fontSize: 14.sp,
            //           fontWeight: FontWeight.w500,
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
            SizedBox(height: 20.h),
            _buildDetailRow('Status:', order.status),
            // Order type
            _buildDetailRow('Order Type:', order.orderType),
            // Order date
            _buildDetailRow(
              'Order Date:',
              DateFormat('MMM d, yyyy • h:mm a').format(order.createdAt),
            ),

            // Warehouse
            _buildDetailRow('Warehouse:', order.items.first.warehouse.toString()),

            _buildDetailRow(
              'Date',
              DateFormat('dd-MM-yyyy').format(order.items.first.createdAt ?? DateTime.now()),
            ),

            // Virtual code
            _buildDetailRow('Grand Total:', order.grandTotal),

            // Divider
            Divider(height: 32.h, thickness: 1),

            // Items section header
            Text(
              'Items:',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12.h),

            // List of items
            ...order.items.map((item) => _buildItemRow(item)).toList(),

            // Action button for pending orders
            if (order.status != 'Completed' &&
            order.status != 'Rejected' )
              Padding(
                padding: EdgeInsets.only(top: 24.h),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _requestApproval(context, order);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E5CA8),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'REQUEST APPROVAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Amount: ${item.amount}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '× ${item.quantity}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _requestApproval(BuildContext context, Order order) {
    // Show confirmation dialog first
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Request'),
        content: const Text(
            'Are you sure you want to request approval for this order again?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close order details page
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Requesting approval...'),
                  duration: Duration(seconds: 2),
                ),
              );

              // Call the request approval event on the bloc
              context.read<OrdersBloc>().add(RequestOrderApproval(order.id));
              Future.delayed(const Duration(seconds: 2), () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Approval request sent successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E5CA8),
            ),
            child: const Text('CONFIRM',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
            ),
          ),
          ),
        ],
      ),
    );
  }
}