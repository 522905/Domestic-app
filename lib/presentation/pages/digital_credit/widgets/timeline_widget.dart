import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/digital_credit/timeline_item.dart';

class TimelineWidget extends StatelessWidget {
  final List<TimelineItem> timeline;

  const TimelineWidget({
    Key? key,
    required this.timeline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Credit Timeline',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 16.h),
        ...timeline.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == timeline.length - 1;

          return _buildTimelineItem(item, isLast);
        }).toList(),
      ],
    );
  }

  Widget _buildTimelineItem(TimelineItem item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: item.done ? const Color(0xFF0E5CA8) : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: item.done
                    ? Icon(Icons.check, color: Colors.white, size: 14.sp)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.w,
                    color: item.done ? const Color(0xFF0E5CA8) : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.status,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: item.done ? Colors.grey.shade800 : Colors.grey.shade500,
                    ),
                  ),
                  if (item.at != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(item.at!),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ] else if (!item.done) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
