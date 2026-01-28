import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../domain/entities/bonus/bonus_scheme.dart';

/// Card widget to display a bonus scheme
class BonusSchemeCard extends StatefulWidget {
  final BonusScheme scheme;

  const BonusSchemeCard({
    Key? key,
    required this.scheme,
  }) : super(key: key);

  @override
  State<BonusSchemeCard> createState() => _BonusSchemeCardState();
}

class _BonusSchemeCardState extends State<BonusSchemeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            contentPadding: EdgeInsets.all(16.w),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.scheme.name,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.scheme.hasPartnerOverrides)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      'Custom',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(width: 8.w),
                if (!widget.scheme.isActive)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Text(
                      'Inactive',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.h),
                Text(
                  widget.scheme.description,
                  style: TextStyle(fontSize: 12.sp),
                ),
                SizedBox(height: 16.h),

                // Requirements
                _buildRequirementRow(
                  Icons.trending_up,
                  'Maintain ${widget.scheme.targetPostingRatio.toStringAsFixed(1)}% posting ratio',
                ),
                SizedBox(height: 8.h),

                // Reward
                _buildRequirementRow(
                  Icons.card_giftcard,
                  'Earn ${widget.scheme.bonusPercentage.toStringAsFixed(1)}% bonus on net pickups',
                  color: Colors.green,
                ),
                SizedBox(height: 8.h),

                // Validity
                _buildRequirementRow(
                  Icons.calendar_today,
                  'Valid for ${widget.scheme.validityDays} days',
                  color: Colors.blue,
                ),
              ],
            ),
          ),

          // Expandable explanation section
          if (_isExpanded)
            Container(
              padding: EdgeInsets.all(16.w),
              color: Colors.grey.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How is posting ratio calculated?',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Posting Ratio = (Confirmed Sales / Net Pickups) × 100',
                    style: TextStyle(fontSize: 12.sp, fontFamily: 'monospace'),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Where:',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '• Net Pickups = Pickups - Returns',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  Text(
                    '• Confirmed Sales = OTP Sales + Override Sales',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ],
              ),
            ),

          // Expand/Collapse button
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isExpanded ? 'Show Less' : 'How it works',
                    style: TextStyle(fontSize: 12.sp, color: Colors.blue),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16.sp,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: color ?? Colors.grey),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: color ?? Colors.black87,
              fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
