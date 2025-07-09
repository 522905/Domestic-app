// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:lpg_distribution_app/core/models/inventory_request.dart';
// import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_bloc.dart';
// import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_event.dart';
// import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_state.dart';
// import 'package:lpg_distribution_app/presentation/widgets/status_chip.dart';
//
// import '../../../widgets/gatepass_dialog.dart';
// import '../../../widgets/swipeButton.dart';
//
// class CollectionApprovalScreen extends StatefulWidget {
//   final String requestId;
//
//   const CollectionApprovalScreen({
//     Key? key,
//     required this.requestId,
//   }) : super(key: key);
//
//   @override
//   State<CollectionApprovalScreen> createState() => _CollectionApprovalScreenState();
// }
//
// class _CollectionApprovalScreenState extends State<CollectionApprovalScreen> {
//   final _commentController = TextEditingController();
//   bool _isProcessing = false;
//   String? _selectedRejectionReason;
//   bool _isUserAuthorized = false;
//
//   final List<String> _rejectionReasons = [
//     'Insufficient Stock',
//     'Orders Not Eligible',
//     'Vehicle Not Available',
//     'Warehouse Closed',
//     'Other',
//   ];
//
//   String _getMonthName(int month) {
//     const months = [
//       'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
//     ];
//     return months[month - 1];
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _checkUserRole();
//   }
//
//   void _checkUserRole() {
//     setState(() {
//       _isUserAuthorized = true; // Change to false to test delivery boy view
//     });
//   }
//
//   @override
//   void dispose() {
//     _commentController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Collection Approval'),
//         backgroundColor: const Color(0xFF0E5CA8),
//       ),
//       body: FutureBuilder<InventoryRequest>(
//         future: _fetchRequestDetails(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError || !snapshot.hasData) {
//             return Center(child: Text('Error loading request details'));
//           }
//
//           final request = snapshot.data!;
//           return ListView(
//             padding: EdgeInsets.all(16.w),
//             children: [
//               _buildRequestDetails(request),
//               SizedBox(height: 5.h),
//               _buildStockInfo(request),
//               SizedBox(height: 5.h),
//               _buildItemsToCollect(request),
//               SizedBox(height: 5.h),
//               if (_isUserAuthorized && (request.status == 'APPROVED' || request.status == 'REJECTED')) ...[
//                 SizedBox(height: 5.h),
//               ],
//               if (request.status == 'PENDING' && _isUserAuthorized) ...[
//                 _buildCommentSection(),
//                 SizedBox(height: 5.h),
//                 _buildGatepassButton(request),
//                 SizedBox(height: 15.h),
//                 _buildActionButtons(),
//               ] else if (request.status != 'PENDING') ...[
//                 _buildStatusIndicator(request),
//               ] else ...[
//                 _buildDeliveryBoyView(request),
//               ],
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Future<InventoryRequest> _fetchRequestDetails() async {
//     // In real app, fetch from API using widget.requestId
//     // For demo, find in existing state
//     final state = context.read<InventoryBloc>().state;
//     if (state is InventoryLoaded) {
//       return state.requests.firstWhere((r) => r.id == widget.requestId);
//     }
//     throw Exception('Request not found');
//   }
//
//   Widget _buildRequestDetails(InventoryRequest request) {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: EdgeInsets.all(16.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Collection #${request.id}',
//                   style: TextStyle(
//                     fontSize: 18.sp,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 StatusChip(
//                   label: request.status,
//                   color: _getStatusColor(request.status),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16.h),
//             _detailRow('Requested By', request.requestedBy),
//             _detailRow('Role', request.role),
//             _detailRow('Date/Time', request.timestamp),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStockInfo(InventoryRequest request) {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: EdgeInsets.all(16.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Warehouse',
//               style: TextStyle(
//                 fontSize: 18.sp,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 16.h),
//             _detailRow('Name', request.warehouseName),
//             _detailRow('ID', request.warehouseId),
//             Divider(height: 24.h),
//             Text(
//               'Stock Levels',
//               style: TextStyle(
//                 fontSize: 16.sp,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 8.h),
//             _stockRow('14.2kg Domestic Cylinder', 120, 100),
//             _stockRow('5kg Domestic Cylinder', 45, 40),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildItemsToCollect(InventoryRequest request) {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: EdgeInsets.all(16.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Items to Collect',
//               style: TextStyle(
//                 fontSize: 18.sp,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 16.h),
//             _itemRow('14.2kg Domestic Cylinder', request.cylinders14kg),
//             if (request.smallCylinders > 0)
//               _itemRow('5kg Domestic Cylinder', request.smallCylinders),
//             if (request.cylinders19kg > 0)
//               _itemRow('19kg Domestic Cylinder', request.cylinders19kg),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCommentSection() {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: EdgeInsets.all(16.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Remarks',
//               style: TextStyle(
//                 fontSize: 18.sp,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 12.h),
//             TextField(
//               controller: _commentController,
//               maxLines: 1,
//               decoration: InputDecoration(
//                 hintText: 'Add remarks for approval/rejection...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.r),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildActionButtons() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(8.r),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(16.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Action Required',
//               style: TextStyle(
//                 fontSize: 18.sp,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 16.h),
//             _isProcessing
//                 ? Center(
//               child: CircularProgressIndicator(),
//             )
//                 : SwipeActionButton(
//               onReject: () => _showRejectionDialog(),
//               onApprove: () => _showApprovalDialog(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatusIndicator(InventoryRequest request) {
//     final isApproved = request.status == 'APPROVED';
//
//     return Container(
//       padding: EdgeInsets.all(24.h),
//       decoration: BoxDecoration(
//         color: isApproved ? Colors.green.shade50 : Colors.red.shade50,
//         borderRadius: BorderRadius.circular(12.r),
//         border: Border.all(
//           color: isApproved ? Colors.green.shade200 : Colors.red.shade200,
//           width: 1,
//         ),
//       ),
//       child: Column(
//         children: [
//           Icon(
//             isApproved ? Icons.check_circle : Icons.cancel,
//             color: isApproved ? Colors.green : Colors.red,
//             size: 48.sp,
//           ),
//           SizedBox(height: 12.h),
//           Text(
//             isApproved ? 'Collection Approved' : 'Collection Rejected',
//             style: TextStyle(
//               fontSize: 18.sp,
//               fontWeight: FontWeight.bold,
//               color: isApproved ? Colors.green : Colors.red,
//             ),
//           ),
//           SizedBox(height: 8.h),
//           Text(
//             isApproved
//                 ? '${request.id} has been approved.'
//                 : 'Reason: Orders Not Eligible',
//             style: TextStyle(
//               fontSize: 14.sp,
//             ),
//           ),
//           SizedBox(height: 4.h),
//           Text(
//             isApproved
//                 ? 'Warehouse inventory updated.'
//                 : 'Requester has been notified.',
//             style: TextStyle(
//               fontSize: 14.sp,
//             ),
//           ),
//           if (isApproved) ...[
//             SizedBox(height: 4.h),
//             Text(
//               'Gatepass generated.',
//               style: TextStyle(
//                 fontSize: 14.sp,
//               ),
//             ),
//           ],
//           SizedBox(height: 16.h),
//           SizedBox(
//             width: 120.w,
//             child: ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: isApproved ? Colors.green : Colors.red,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(24.r),
//                 ),
//               ),
//               child: const Text('DONE'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDeliveryBoyView(InventoryRequest request) {
//     return Container(
//       padding: EdgeInsets.all(16.w),
//       decoration: BoxDecoration(
//         color: Colors.amber.shade50,
//         borderRadius: BorderRadius.circular(8.r),
//         border: Border.all(color: Colors.amber.shade200),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.access_time,
//                 color: Colors.amber,
//                 size: 24.sp,
//               ),
//               SizedBox(width: 8.w),
//               Text(
//                 'Awaiting approval from Warehouse Manager',
//                 style: TextStyle(
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 16.h),
//           Text(
//             'Your collection request has been submitted and is pending approval. '
//                 'You will be notified once it\'s approved or rejected.',
//             style: TextStyle(
//               fontSize: 14.sp,
//               color: Colors.grey[700],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGatepassButton(InventoryRequest request) {
//     return SizedBox(
//       width: double.infinity,
//       height: 48.h,
//       child: ElevatedButton.icon(
//         icon: const Icon(Icons.receipt_long),
//         label: Text(
//           'GENERATE GATEPASS',
//           style: TextStyle(
//             fontSize: 16.sp,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         onPressed: () {
//           showDialog(
//             context: context,
//             builder: (context) => GatepassDialog(request: request),
//           );
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFF0E5CA8),
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8.r),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _stockRow(String name, int total, int available) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 4.h),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(name),
//           Row(
//             children: [
//               Text(
//                 '$available / $total',
//                 style: TextStyle(
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _itemRow(String name, int quantity) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 4.h),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(name),
//           Text(
//             quantity.toString(),
//             style: TextStyle(
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _detailRow(String label, String value) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 4.h),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 14.sp,
//               color: Colors.grey[600],
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 14.sp,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'PENDING':
//         return const Color(0xFFFFC107);
//       case 'APPROVED':
//         return const Color(0xFF4CAF50);
//       case 'REJECTED':
//         return const Color(0xFFF44336);
//       default:
//         return const Color(0xFF2196F3);
//     }
//   }
//
//   void _showApprovalDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Approve Collection'),
//         content: const Text('Are you sure you want to approve this collection request?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.pop(context);
//               _processApproval();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF4CAF50),
//             ),
//             child: const Text('Approve'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showRejectionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           title: const Text('Rejection Reason'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Specify reason for rejecting collection #CL-1234',
//                 style: TextStyle(
//                   fontSize: 14.sp,
//                   fontWeight: FontWeight.normal,
//                 ),
//               ),
//               SizedBox(height: 16.h),
//               ..._rejectionReasons.map((reason) => RadioListTile<String>(
//                 title: Text(reason),
//                 value: reason,
//                 groupValue: _selectedRejectionReason,
//                 onChanged: (value) {
//                   setState(() => _selectedRejectionReason = value);
//                 },
//               )),
//               TextField(
//                 decoration: InputDecoration(
//                   labelText: 'Additional Comments (Optional)',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8.r),
//                   ),
//                 ),
//                 maxLines: 2,
//               ),
//               SizedBox(height: 8.h),
//               Text(
//                 'Order ID 25-45 has expired status',
//                 style: TextStyle(
//                   fontSize: 12.sp,
//                   color: Colors.grey[600],
//                   fontStyle: FontStyle.italic,
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('CANCEL'),
//             ),
//             ElevatedButton(
//               onPressed: _selectedRejectionReason == null
//                   ? null
//                   : () {
//                 Navigator.pop(context);
//                 _processRejection(_selectedRejectionReason!);
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFFF44336),
//               ),
//               child: const Text('SUBMIT'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _processApproval() async {
//     if (_isProcessing) return; // Prevent multiple submissions
//     setState(() => _isProcessing = true);
//
//     try {
//       // Dispatch the approval event
//       context.read<InventoryBloc>().add(ApproveInventoryRequest(
//         requestId: widget.requestId,
//         comment: _commentController.text.trim(),
//       ));
//
//       // Add a small delay to let the BLoC process the event
//       await Future.delayed(const Duration(milliseconds: 100));
//
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Collection approved successfully'),
//           backgroundColor: Colors.green,
//         ),
//       );
//
//       // Refresh the screen to show the updated status
//       setState(() {});
//     } catch (e, stackTrace) {
//       // Log the error for debugging
//       debugPrint('Approval failed: $e\n$stackTrace');
//
//       // Show error message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to approve collection: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _isProcessing = false);
//     }
//   }
//
//   Future<void> _processRejection(String reason) async {
//     if (_isProcessing) return; // Prevent multiple submissions
//     setState(() => _isProcessing = true);
//
//     try {
//       // Dispatch the rejection event
//       context.read<InventoryBloc>().add(RejectInventoryRequest(
//         requestId: widget.requestId,
//         reason: reason.trim(),
//       ));
//
//       // Add a small delay to let the BLoC process the event
//       await Future.delayed(const Duration(milliseconds: 300));
//
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Collection rejected successfully'),
//           backgroundColor: Colors.red,
//         ),
//       );
//
//       // Refresh the screen to show the updated status
//       setState(() {});
//     } catch (e, stackTrace) {
//       // Log the error for debugging
//       debugPrint('Rejection failed: $e\n$stackTrace');
//
//       // Show error message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to reject collection: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _isProcessing = false);
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/core/models/inventory_request.dart';
import 'package:lpg_distribution_app/utils/status_chip.dart';
import '../../../blocs/inventory/inventory_bloc.dart';
import '../../../blocs/inventory/inventory_event.dart';
import '../../../blocs/inventory/inventory_state.dart';

class CollectionApprovalScreen extends StatefulWidget {
  final String requestId;

  const CollectionApprovalScreen({
    Key? key,
    required this.requestId,
  }) : super(key: key);

  @override
  State<CollectionApprovalScreen> createState() => _CollectionApprovalScreenState();
}

class _CollectionApprovalScreenState extends State<CollectionApprovalScreen> {
  final _commentController = TextEditingController();
  bool _isProcessing = false;
  String? _selectedRejectionReason;
  bool _isUserAuthorized = false;

  final List<String> _rejectionReasons = [
    'Insufficient Stock',
    'Orders Not Eligible',
    'Vehicle Not Available',
    'Warehouse Closed',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  void _checkUserRole() {
    setState(() {
      _isUserAuthorized = true; // Change based on actual user role
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Approval'),
        backgroundColor: const Color(0xFF0E5CA8),
      ),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          if (state is InventoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InventoryLoaded) {
            final request = state.requests.firstWhere(
                  (r) => r.id == widget.requestId,
              orElse: () => throw Exception('Request not found'),
            );

            return ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _buildRequestDetails(request),
                SizedBox(height: 16.h),
                _buildStockInfo(request),
                SizedBox(height: 16.h),
                _buildItemsToCollect(request),
                SizedBox(height: 16.h),
                if (request.status == 'PENDING' && _isUserAuthorized) ...[
                  _buildCommentSection(),
                  SizedBox(height: 16.h),
                  _buildActionButtons(),
                ] else if (request.status != 'PENDING') ...[
                  _buildStatusIndicator(request),
                ] else ...[
                  _buildDeliveryBoyView(request),
                ],
              ],
            );
          }

          if (state is InventoryError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          return const Center(child: Text('No data available'));
        },
      ),
    );
  }

  Widget _buildRequestDetails(InventoryRequest request) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Collection #${request.id}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StatusChip(
                  label: request.status,
                  color: _getStatusColor(request.status),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _detailRow('Requested By', request.requestedBy),
            _detailRow('Role', request.role),
            _detailRow('Date/Time', request.timestamp),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfo(InventoryRequest request) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Warehouse',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _detailRow('Name', request.warehouseName),
            _detailRow('ID', request.warehouseId),
            Divider(height: 24.h),
            Text(
              'Stock Levels',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            _stockRow('14.2kg Domestic Cylinder', 120, 100),
            _stockRow('5kg Domestic Cylinder', 45, 40),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsToCollect(InventoryRequest request) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items to Collect',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _itemRow('14.2kg Domestic Cylinder', request.cylinders14kg),
            if (request.smallCylinders > 0)
              _itemRow('5kg Domestic Cylinder', request.smallCylinders),
            if (request.cylinders19kg > 0)
              _itemRow('19kg Domestic Cylinder', request.cylinders19kg),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remarks',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add remarks for approval/rejection...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action Required',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _isProcessing
                ? const Center(child: CircularProgressIndicator())
                : Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: Text('REJECT', style: TextStyle(fontSize: 16.sp)),
                    onPressed: () => _showRejectionDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: Text('APPROVE', style: TextStyle(fontSize: 16.sp)),
                    onPressed: () => _showApprovalDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(InventoryRequest request) {
    final isApproved = request.status == 'APPROVED';

    return Container(
      padding: EdgeInsets.all(24.h),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isApproved ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isApproved ? Icons.check_circle : Icons.cancel,
            color: isApproved ? Colors.green : Colors.red,
            size: 48.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            isApproved ? 'Collection Approved' : 'Collection Rejected',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isApproved ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: 120.w,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isApproved ? Colors.green : Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
              child: const Text('DONE'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryBoyView(InventoryRequest request) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.amber, size: 24.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Awaiting approval from Warehouse Manager',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Your collection request has been submitted and is pending approval.',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _stockRow(String name, int total, int available) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text('$available / $total', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _itemRow(String name, int quantity) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text(quantity.toString(), style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.grey[600])),
          Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFFC107);
      case 'APPROVED':
        return const Color(0xFF4CAF50);
      case 'REJECTED':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF2196F3);
    }
  }

  void _showApprovalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Collection'),
        content: const Text('Are you sure you want to approve this collection request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processApproval();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rejection Reason'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Specify reason for rejecting collection ${widget.requestId}'),
              SizedBox(height: 16.h),
              ..._rejectionReasons.map((reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedRejectionReason,
                onChanged: (value) => setState(() => _selectedRejectionReason = value),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: _selectedRejectionReason == null
                  ? null
                  : () {
                Navigator.pop(context);
                _processRejection(_selectedRejectionReason!);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336)),
              child: const Text('SUBMIT'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processApproval() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      context.read<InventoryBloc>().add(ApproveInventoryRequest(
        requestId: widget.requestId,
        comment: _commentController.text.trim(),
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collection approved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve collection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _processRejection(String reason) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      context.read<InventoryBloc>().add(RejectInventoryRequest(
        requestId: widget.requestId,
        reason: reason.trim(),
      ));

      await Future.delayed(const Duration(milliseconds: 300));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collection rejected successfully'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject collection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}