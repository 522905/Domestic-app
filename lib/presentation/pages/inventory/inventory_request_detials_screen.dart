import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/core/models/inventory_request.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_bloc.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_state.dart';
import 'package:lpg_distribution_app/utils/status_chip.dart';

class InventoryRequestDetailsPage extends StatelessWidget {
  final String requestId;

  const InventoryRequestDetailsPage({
    Key? key,
    required this.requestId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: const Color(0xFF0E5CA8),
      ),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          if (state is InventoryLoaded) {
            final request = state.requests.firstWhere(
                  (r) => r.id == requestId,
              orElse: () => null!,
            );

            if (request == null) {
              return const Center(child: Text('Request not found'));
            }

            return ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _buildHeader(request),
                SizedBox(height: 16.h),
                _buildRequestInfo(request),
                SizedBox(height: 16.h),
                _buildCylinderDetails(request),
                SizedBox(height: 16.h),
                _buildStatusHistory(request),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildHeader(InventoryRequest request) {
    Color statusColor;
    switch (request.status) {
      case 'PENDING':
        statusColor = const Color(0xFFFFC107);
        break;
      case 'APPROVED':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'REJECTED':
        statusColor = const Color(0xFFF44336);
        break;
      default:
        statusColor = const Color(0xFF2196F3);
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.id,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  request.warehouseName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            StatusChip(
              label: request.status,
              color: statusColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestInfo(InventoryRequest request) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request Information',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            _infoRow('Requested By', request.requestedBy),
            _infoRow('Role', request.role),
            _infoRow('Date/Time', request.timestamp),
          ],
        ),
      ),
    );
  }

  Widget _buildCylinderDetails(InventoryRequest request) {
    final total = request.cylinders14kg + request.cylinders19kg + request.smallCylinders;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cylinder Details',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            _cylinderRow('14.2 kg Cylinders', request.cylinders14kg),
            _cylinderRow('19 kg Cylinders', request.cylinders19kg),
            _cylinderRow('Small Cylinders', request.smallCylinders),
            Divider(height: 16.h),
            _cylinderRow('Total', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHistory(InventoryRequest request) {
    // In a real app, this would show the history of status changes
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status History',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                request.status == 'APPROVED'
                    ? Icons.check_circle
                    : Icons.cancel,
                color: request.status == 'APPROVED'
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFF44336),
              ),
              title: Text(
                request.status == 'APPROVED'
                    ? 'Request Approved'
                    : 'Request Rejected',
              ),
              subtitle: Text(request.timestamp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cylinderRow(String type, int count, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            type,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}