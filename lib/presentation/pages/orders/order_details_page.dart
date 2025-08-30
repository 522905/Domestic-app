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
  bool _isRequestingApproval = false;
  Map<String, dynamic>? _approvalResponse;

@override
void initState() {
  super.initState();

  // Check if the state already contains the order details
  final currentState = context.read<OrdersBloc>().state;
  if (currentState is! OrderDetailsLoaded || currentState.detailedOrder.id != widget.order.id) {
    // Load detailed order data if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersBloc>().add(LoadOrderDetails(widget.order.orderNumber));
    });
  }
}

  void _requestApproval(BuildContext context, String orderId) async {
    setState(() {
      _isRequestingApproval = true;
      _approvalResponse = null;
    });

    try {
      context.read<OrdersBloc>().add(RequestOrderApproval(orderId));

      final responseState = await context.read<OrdersBloc>().stream.firstWhere(
            (state) => state is OrdersLoadedWithResponse || state is OrdersError,
      );

      if (responseState is OrdersLoadedWithResponse) {
        setState(() {
          _approvalResponse = responseState.response;
        });
      } else if (responseState is OrdersError) {
        setState(() {
          _approvalResponse = {"error": responseState.message};
        });
      }
    } catch (e) {
      setState(() {
        _approvalResponse = {"error": "Failed to request approval: $e"};
      });
    } finally {
      setState(() {
        _isRequestingApproval = false;
      });
    }
  }


  Widget _buildResponseWidget() {
    if (_approvalResponse == null) {
      return const SizedBox.shrink();
    }

    // --- error at top-level ---
    final rawError = _approvalResponse!['error'];
    if (rawError != null) {
      final errText = rawError is String
          ? rawError
          : (rawError is Map ? (rawError['message']?.toString() ?? rawError.toString()) : rawError.toString());

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
                errText,
                style: TextStyle(color: Colors.red.shade700, fontSize: 14.sp),
              ),
            ),
          ],
        ),
      );
    }

    // --- parse ERP payload safely ---
    final erp = (_approvalResponse!['erp_response'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final message = erp['message'];
    if (message is! Map) {
      // Unknown shape; show whatever we got
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info, color: Colors.green.shade600, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message?.toString() ?? 'No message',
                style: TextStyle(color: Colors.green.shade700, fontSize: 14.sp),
              ),
            ),
          ],
        ),
      );
    }

    final msg = message.cast<String, dynamic>();
    final status = (msg['status'] as String?) ?? 'Unknown';

    // --- credit_failed ---
    if (status == 'credit_failed') {
      final credit = (msg['credit_result'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final creditMessage = credit['message']?.toString() ?? 'No message available';
      final requiredAmount = _fmtNum(credit['required_amount']);

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
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text('Message: $creditMessage', style: TextStyle(fontSize: 14.sp, color: Colors.orange.shade700)),
            SizedBox(height: 4.h),
            Text('Required Amount: $requiredAmount',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
          ],
        ),
      );
    }

    // --- missing_returns ---
    if (status == 'missing_returns') {
      final shortagesList = (msg['shortages'] as List?)
          ?.whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList() ??
          const <Map<String, dynamic>>[];

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
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            if (shortagesList.isEmpty)
              Text('No shortages provided.', style: TextStyle(fontSize: 14.sp, color: Colors.red.shade700))
            else
              ...shortagesList.map((m) {
                final item = _itemLabel(m);
                final required = _fmtNum(m['required']);
                final allocated = _fmtNum(m['already_allocated']);
                final pending = _fmtNum(m['pending']);
                final available = _fmtNum(m['available']);
                return Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14.sp, color: Colors.red.shade700, height: 1.3),
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(Icons.inventory_2, size: 12.sp, color: Colors.red.shade700),
                          ),
                          TextSpan(text: '  '),
                          TextSpan(
                            text: item,
                            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red.shade900),
                          ),
                          const TextSpan(text: '  •  '),

                          TextSpan(text: 'Ordered: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          TextSpan(text: required),

                          const TextSpan(text: '   '),
                          TextSpan(text: 'Allocated: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          TextSpan(text: allocated),

                          const TextSpan(text: '   '),
                          TextSpan(text: 'Pending: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          TextSpan(text: pending),

                          const TextSpan(text: '   '),
                          TextSpan(text: 'Available: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          TextSpan(
                            text: available,
                            style: TextStyle(
                              color: (num.tryParse(available) ?? 0) > 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                );
              }),
          ],
        ),
      );
    }

    // --- default/success/other statuses ---
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
              Text('Response', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
            ],
          ),
          SizedBox(height: 8.h),
          Text('Status: $status',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
        ],
      ),
    );
  }

  String _itemLabel(Map<String, dynamic> m) {
    return (m['item_group'] ??
        m['filled_item_code'] ??
        m['item_code'] ??
        m['sales_order_item'] ??
        'Unknown')
        .toString();
  }

  String _fmtNum(dynamic n) {
    if (n == null) return 'N/A';
    if (n is num) return n % 1 == 0 ? n.toInt().toString() : n.toString();
    final parsed = num.tryParse(n.toString());
    if (parsed == null) return n.toString();
    return parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toString();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'to deliver and bill':
      case 'draft':
        return const Color(0xFFFFC107);
      case 'on hold':
        return const Color(0xFFF44336);
      case 'completed':
      case 'delivered':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF2196F3);
    }
  }

  Widget _buildItemsCard(Order detailedOrder) {
    if (detailedOrder.items.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items (${detailedOrder.items.length})',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0E5CA8)),
            ),
            SizedBox(height: 16.h),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: detailedOrder.items.length,
              separatorBuilder: (context, index) => Divider(height: 16.h),
              itemBuilder: (context, index) {
                final item = detailedOrder.items[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemName,
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Code: ${item.itemCode}',
                                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                              ),
                              if (item.description.isNotEmpty && item.description != item.itemCode) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  item.description,
                                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Qty', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                              Text(
                                '${item.quantity}',
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                              ),
                              if (item.unit.isNotEmpty) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  item.unit,
                                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Rate', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                              Text(
                                '₹${item.rate.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 4.h),
                              Text('Amount', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                              Text(
                                '₹${item.amount.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0E5CA8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (item.warehouse.isNotEmpty || item.itemGroup.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          if (item.itemGroup.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                item.itemGroup,
                                style: TextStyle(fontSize: 10.sp, color: Colors.blue.shade700),
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],
                          if (item.warehouse.isNotEmpty) ...[
                            Icon(Icons.warehouse, size: 12.sp, color: Colors.grey[500]),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                item.warehouse.split(' - ').first,
                                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (item.actualQty > 0 || item.projectedQty > 0) ...[
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (item.actualQty > 0)
                            Text(
                              'Available: ${item.actualQty}',
                              style: TextStyle(fontSize: 11.sp, color: Colors.green.shade600),
                            ),
                          if (item.projectedQty > 0)
                            Text(
                              'Projected: ${item.projectedQty}',
                              style: TextStyle(fontSize: 11.sp, color: Colors.orange.shade600),
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0E5CA8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is OrderDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrderDetailsError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                    SizedBox(height: 16.h),
                    Text(
                      'Failed to load order details',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      state.message,
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    if (state.canRetry) ...[
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: () => context.read<OrdersBloc>().add(LoadOrderDetails(state.orderName)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          // Use API data when available, fallback to widget.order
          final Order displayOrder = state is OrderDetailsLoaded ? state.detailedOrder : widget.order;
          final statusColor = _getStatusColor(displayOrder.status);

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                displayOrder.orderNumber,
                                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0E5CA8)),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                displayOrder.status,
                                style: TextStyle(color: statusColor, fontSize: 12.sp, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          displayOrder.customerName,
                          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                        ),
                        if (displayOrder.connectionType.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E5CA8).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Text(
                              displayOrder.connectionType,
                              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF0E5CA8), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Order Information Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Information',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0E5CA8)),
                        ),
                        SizedBox(height: 16.h),
                        _buildDetailRow('Transaction Date:', DateFormat('MMM d, yyyy').format(displayOrder.transactionDate), Icons.calendar_today),
                        _buildDetailRow('Delivery Date:', DateFormat('MMM d, yyyy').format(displayOrder.deliveryDate), Icons.local_shipping),
                        _buildDetailRow('Vehicle:', displayOrder.vehicle, Icons.directions_car),
                        _buildDetailRow('Warehouse:', displayOrder.warehouse.split(' - ').first, Icons.warehouse),
                        _buildDetailRow('Delivery Status:', displayOrder.deliveryStatus, Icons.delivery_dining),
                        if (displayOrder.billingStatus.isNotEmpty)
                          _buildDetailRow('Billing Status:', displayOrder.billingStatus, Icons.receipt),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Order Summary Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0E5CA8)),
                        ),
                        SizedBox(height: 16.h),
                        _buildSummaryRow('Total Quantity:', '${displayOrder.totalQty}'),
                        _buildSummaryRow('Delivered:', '${displayOrder.perDelivered.toStringAsFixed(1)}%'),
                        _buildSummaryRow('Billed:', '${displayOrder.perBilled.toStringAsFixed(1)}%'),
                        Divider(height: 24.h, thickness: 1),
                        _buildSummaryRow('Grand Total:', '₹${displayOrder.grandTotal.toStringAsFixed(2)}', isTotal: true),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Order Items Card
                _buildItemsCard(displayOrder),

                SizedBox(height: 16.h),

                // Inventory Information Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inventory Information',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0E5CA8)),
                        ),
                        SizedBox(height: 16.h),
                        _buildDetailRow('Inventory Status:', displayOrder.inventoryStatus, Icons.inventory),
                        _buildDetailRow('Due Date:', DateFormat('MMM d, yyyy').format(displayOrder.inventoryDueDate), Icons.schedule),
                        if (displayOrder.createdBy.isNotEmpty)
                          _buildDetailRow('Created By:', displayOrder.createdBy, Icons.person),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                if (_canRequestApproval(displayOrder.status)) ...[
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isRequestingApproval ? null : () => _requestApproval(context, displayOrder.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E5CA8),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                      child: _isRequestingApproval
                          ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : Text(
                        'REQUEST FOR APPROVAL',
                        style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildResponseWidget(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  bool _canRequestApproval(String status) {
    final statusLower = status.toLowerCase();
    return statusLower == 'on hold';
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
            child: Icon(icon, color: const Color(0xFF0E5CA8), size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                SizedBox(height: 2.h),
                Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey[800])),
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