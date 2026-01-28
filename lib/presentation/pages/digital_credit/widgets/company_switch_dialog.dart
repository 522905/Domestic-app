import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CompanySwitchDialog extends StatelessWidget {
  final String currentCompanyName;
  final List<Map<String, dynamic>> suggestedCompanies;
  final Function(int companyId) onSwitch;

  const CompanySwitchDialog({
    Key? key,
    required this.currentCompanyName,
    required this.suggestedCompanies,
    required this.onSwitch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.orange.shade700, size: 28.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Order Not Found',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The order was not found in $currentCompanyName.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 16.h),
            if (suggestedCompanies.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'We found this order in another company:',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              ...suggestedCompanies.map((company) {
                final companyName = company['company_name'] as String;
                final companyId = company['company_id'] as int;
                final canSwitch = company['can_switch'] as bool? ?? true;

                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E5CA8).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.business,
                        color: const Color(0xFF0E5CA8),
                        size: 24.sp,
                      ),
                    ),
                    title: Text(
                      companyName,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: canSwitch
                        ? Text(
                            'Tap to switch and create credit',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          )
                        : Text(
                            'Cannot switch to this company',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.red.shade600,
                            ),
                          ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16.sp,
                      color: canSwitch ? const Color(0xFF0E5CA8) : Colors.grey,
                    ),
                    onTap: canSwitch
                        ? () {
                            Navigator.pop(context);
                            onSwitch(companyId);
                          }
                        : null,
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Try Different Order',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }
}
