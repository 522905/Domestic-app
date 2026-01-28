import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../blocs/digital_credit/digital_credit_bloc.dart';
import '../../blocs/digital_credit/digital_credit_event.dart';
import '../../blocs/digital_credit/digital_credit_state.dart';
import 'widgets/status_badge_widget.dart';
import 'widgets/timeline_widget.dart';

class CreditDetailPage extends StatefulWidget {
  final String creditId;

  const CreditDetailPage({
    Key? key,
    required this.creditId,
  }) : super(key: key);

  @override
  State<CreditDetailPage> createState() => _CreditDetailPageState();
}

class _CreditDetailPageState extends State<CreditDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<DigitalCreditBloc>().add(LoadCreditDetail(widget.creditId));
  }

  void _showClaimDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('Claim Credit'),
        content: const Text('Claim this digital credit to your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<DigitalCreditBloc>().add(ClaimCredit(widget.creditId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E5CA8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Claim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Details'),
        backgroundColor: const Color(0xFF0E5CA8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DigitalCreditBloc>().add(LoadCreditDetail(widget.creditId));
            },
          ),
        ],
      ),
      body: BlocListener<DigitalCreditBloc, DigitalCreditState>(
        listener: (context, state) {
          if (state is CreditClaimSuccess) {
            final result = state.result;
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                title: Row(
                  children: [
                    Icon(
                      result.isDirectClaim ? Icons.check_circle : Icons.info_outline,
                      color: result.isDirectClaim ? Colors.green : Colors.orange,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        result.isDirectClaim ? 'Credit Claimed!' : 'Transfer Requested',
                      ),
                    ),
                  ],
                ),
                content: Text(result.message),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      // Refresh detail
                      context.read<DigitalCreditBloc>().add(LoadCreditDetail(widget.creditId));
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else if (state is DigitalCreditError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<DigitalCreditBloc, DigitalCreditState>(
          builder: (context, state) {
            if (state is CreditDetailLoading || state is CreditClaiming) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CreditDetailLoaded) {
              final credit = state.credit;

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DigitalCreditBloc>().add(LoadCreditDetail(widget.creditId));
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card with amount
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20.w),
                          child: Column(
                            children: [
                              if (credit.amount != null)
                                Text(
                                  '₹${credit.amount!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 36.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0E5CA8),
                                  ),
                                ),
                              SizedBox(height: 12.h),
                              Text(
                                'Order: ${credit.orderId}',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                DateFormat('dd MMM yyyy').format(credit.orderDate),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Status badges
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          StatusBadgeWidget(
                            status: credit.dataStatus,
                            statusDisplay: credit.dataStatusDisplay,
                            type: 'data',
                          ),
                          StatusBadgeWidget(
                            status: credit.claimStatus,
                            statusDisplay: credit.claimStatusDisplay,
                            type: 'claim',
                          ),
                          if (credit.isSettled)
                            StatusBadgeWidget(
                              status: credit.dprStatus,
                              statusDisplay: 'Settled',
                              type: 'dpr',
                            ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      // Basic information card
                      _buildInfoCard(
                        'Basic Information',
                        [
                          if (credit.consumerName != null)
                            _buildInfoRow(Icons.person, 'Consumer', credit.consumerName!),
                          if (credit.consumerNumber != null)
                            _buildInfoRow(Icons.tag, 'Consumer Number', credit.consumerNumber!),
                          if (credit.originalDeliveryBoyName != null)
                            _buildInfoRow(
                              Icons.delivery_dining,
                              'Original Delivery Boy',
                              credit.originalDeliveryBoyName!,
                            ),
                          if (credit.finalDeliveryBoyName != null &&
                              credit.finalDeliveryBoyName != credit.originalDeliveryBoyName)
                            _buildInfoRow(
                              Icons.person_pin,
                              'Claimed By',
                              credit.finalDeliveryBoyName!,
                            ),
                          if (credit.deliveryDate != null)
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Delivery Date',
                              DateFormat('dd MMM yyyy').format(credit.deliveryDate!),
                            ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      // Timeline
                      if (credit.timeline != null && credit.timeline!.isNotEmpty) ...[
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: TimelineWidget(timeline: credit.timeline!),
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                      // Action buttons
                      if (credit.canClaim && credit.isUnclaimed) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showClaimDialog,
                            icon: const Icon(Icons.check_circle),
                            label: Text(
                              credit.isMine ? 'Claim Credit' : 'Request Transfer',
                              style: TextStyle(fontSize: 16.sp),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0E5CA8),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (credit.canRetry && credit.isFailed) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.read<DigitalCreditBloc>().add(RetryCredit(widget.creditId));
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              'Retry Credit',
                              style: TextStyle(fontSize: 16.sp),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            } else if (state is CreditDetailError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
                    SizedBox(height: 16.h),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () {
                        context.read<DigitalCreditBloc>().add(LoadCreditDetail(widget.creditId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
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
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.sp, color: Colors.grey.shade600),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
