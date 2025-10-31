import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/utils/currency_utils.dart';
import '../../../core/services/User.dart';
import '../../../domain/entities/order.dart';
import '../../blocs/orders/orders_bloc.dart';
import '../../blocs/orders/orders_event.dart';
import '../../blocs/orders/orders_state.dart';
import '../cash/forms/cash_deposit_page.dart';
import 'forms/order_countdown_timmer.dart';

class OrderDetailsPage extends StatefulWidget {
  final Order? order;
  final String? orderId;

  const OrderDetailsPage({
    Key? key,
    this.order,
    this.orderId,
  }) : assert(order != null || orderId != null, 'Either order or orderId must be provided'),
        super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  bool _isRequestingApproval = false;
  Map<String, dynamic>? _approvalResponse;
  List<String>? userRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = context.read<OrdersBloc>().state;
      if (widget.order != null) {
        // Order object provided, check if we need to load full details
        if (currentState is! OrderDetailsLoaded || currentState.detailedOrder.id != widget.order!.id) {
          context.read<OrdersBloc>().add(LoadOrderDetails(widget.order!.orderNumber));
        }
        _fetchUserRole();
      } else if (widget.orderId != null) {
        // Only orderId provided, load from scratch
        context.read<OrdersBloc>().add(LoadOrderDetails(widget.orderId!));
      }
    });
  }

  Future<void> _fetchUserRole() async {
    final roles = await User().getUserRoles();

    setState(() {
      userRole = roles.map((role) => role.role).toList();
    });
  }

  void _requestOrderAction(BuildContext context, String orderId, OrderActionType actionType) async {
    setState(() {
      _isRequestingApproval = true;
      _approvalResponse = null;
    });

    try {
      context.read<OrdersBloc>().add(RequestOrderAction(orderId, actionType));

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
        _approvalResponse = {"error": "Failed to process request: $e"};
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

    // Top-level error
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
              child: Text(errText, style: TextStyle(color: Colors.red.shade700, fontSize: 14.sp)),
            ),
          ],
        ),
      );
    }

    // Parse ERP payload
    final erp = (_approvalResponse!['erp_response'] as Map?)?.cast<String, dynamic>();

    // Handle simple success response (e.g., finalize might just return success)
    if (erp == null) {
      final simpleMessage = _approvalResponse!['message']?.toString() ?? 'Operation completed successfully';
      return _buildSuccessCard(simpleMessage);
    }

    final message = erp['message'];

    // If message is not a Map, show as simple success
    if (message is! Map) {
      return _buildSuccessCard(message?.toString() ?? 'Operation completed successfully');
    }

    final msg = message.cast<String, dynamic>();
    final status = (msg['status'] as String?) ?? 'success';

    switch (status) {
      case 'credit_failed':
        return _buildCreditFailedCard(msg);
      case 'missing_returns':
        return _buildMissingReturnsCard(msg);
      case 'success':
      case 'completed':
        return _buildSuccessCard(msg['message']?.toString() ?? 'Operation completed successfully');
      default:
        return _buildSuccessCard('Status: $status');
    }
  }

  Widget _buildSuccessCard(String message) {
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
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.green.shade700, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditFailedCard(Map<String, dynamic> msg) {
    final credit = (msg['credit_result'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final creditMessage = credit['message']?.toString() ?? 'Credit validation failed';
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
              Text('Credit Failed', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
            ],
          ),
          SizedBox(height: 8.h),
          Text(creditMessage, style: TextStyle(fontSize: 14.sp, color: Colors.orange.shade700)),
          SizedBox(height: 4.h),
          Text('Required Amount: $requiredAmount', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
        ],
      ),
    );
  }

  Widget _buildMissingReturnsCard(Map<String, dynamic> msg) {
    final shortagesList = (msg['shortages'] as List?)
        ?.whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList() ?? const <Map<String, dynamic>>[];

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
              Text('Missing Returns', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
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
                      const TextSpan(text: '  '),
                      TextSpan(text: item, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red.shade900)),
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
                          color: (num.tryParse(available) ?? 0) > 0 ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Items (${detailedOrder.items.length})',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0E5CA8)),
                ),
              ],
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
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                item.itemName,
                                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Rate', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                              Text(
                                '₹${item.rate.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                '₹ ${formatIndianNumber(item.amount.toInt().toString())}',
                                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0E5CA8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (item.warehouse.isNotEmpty || item.itemGroup.isNotEmpty) ...[
                      Text(
                        amountToWords(item.amount.toInt()),
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          if (userRole?.contains('Delivery Boy') ?? false) ...[
                            ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CashDepositPage(initialAmount: item.amount), // Navigate to cash page with deposit mode
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0E5CA8),
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Text(
                                'Cash Deposit',
                                style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                         ]
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

          // final Order displayOrder = state is OrderDetailsLoaded ? state.detailedOrder : widget.order;

          final Order? displayOrder = state is OrderDetailsLoaded ? state.detailedOrder : widget.order;

          if (displayOrder == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0E5CA8).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Text(
                                  displayOrder.connectionType,
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF0E5CA8),
                                      fontWeight: FontWeight.w600
                                  ),
                                ),
                              ),
                              // Show countdown only for Refill orders
                              if (_isRefillOrder(displayOrder)) ...[
                                SizedBox(width: 8.w),
                                OrderCountdownTimer(
                                  createdAt: displayOrder.creationDate,
                                  //TODO update this get from api simply
                                  limitMinutes: 90,
                                ),
                              ],
                            ],
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
                        _buildDetailRow('Created:', DateFormat('MMM d, yyyy • h:mm a').format(displayOrder.creationDate), Icons.access_time),  // ADD THIS
                        _buildDetailRow('Transaction Date:', DateFormat('MMM d, yyyy').format(displayOrder.transactionDate), Icons.calendar_today),
                        _buildDetailRow('Delivery Date:', DateFormat('MMM d, yyyy').format(displayOrder.deliveryDate), Icons.local_shipping),
                        _buildDetailRow('Vehicle:', displayOrder.vehicle.isEmpty ? 'Not Assigned' : displayOrder.vehicle, Icons.directions_car),
                        _buildDetailRow('Warehouse:', displayOrder.warehouse.isEmpty ? 'Not Assigned' : displayOrder.warehouse.split(' - ').first, Icons.warehouse),
                        _buildDetailRow('Delivery Status:', displayOrder.deliveryStatus, Icons.delivery_dining),
                        if (displayOrder.billingStatus.isNotEmpty)
                          _buildDetailRow('Billing Status:', displayOrder.billingStatus, Icons.receipt),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

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
                      onPressed: _isRequestingApproval
                          ? null
                          : () => _requestOrderAction(context, displayOrder.id, OrderActionType.requestApproval),
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

                if ( displayOrder.status != "On Hold" &&
                    displayOrder.status != "To Bill" &&
                    displayOrder.perDelivered > 1) ...[
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isRequestingApproval
                          ? null
                          : () => _requestOrderAction(context, displayOrder.id, OrderActionType.finalize),                      style: ElevatedButton.styleFrom(
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
                        'Finalize Order',
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

  bool _isRefillOrder(Order order) {
  final orderType = order.connectionType.toLowerCase();
    return orderType.contains('refill') || orderType.contains('refil');
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