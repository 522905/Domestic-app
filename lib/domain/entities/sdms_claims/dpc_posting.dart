import '../../../core/constants/app_colors_enhanced.dart';
import 'package:flutter/material.dart';

/// Digital Payment Settlement posting status (3-track ERP integration)
/// Tracks Accrual -> Allocation -> Settlement workflow
class DpcPosting {
  final String settlementName;
  final String accrualStatus;
  final String allocationStatus;
  final String settlementStatus;
  final String? allocatedToErp;
  final bool isOverridden;
  final String? overrideReason;
  final String? error;

  DpcPosting({
    required this.settlementName,
    required this.accrualStatus,
    required this.allocationStatus,
    required this.settlementStatus,
    this.allocatedToErp,
    required this.isOverridden,
    this.overrideReason,
    this.error,
  });

  // Computed properties for display
  bool get hasError =>
      error != null && error!.isNotEmpty ||
      accrualStatus == 'FAILED' ||
      allocationStatus == 'FAILED' ||
      settlementStatus == 'FAILED';

  bool get isFullySettled =>
      accrualStatus == 'CREATED' &&
      allocationStatus == 'ALLOCATED' &&
      settlementStatus == 'SETTLED';

  bool get isAllocated => allocationStatus == 'ALLOCATED';
  bool get isPendingApproval => allocationStatus == 'PENDING_APPROVAL';
  bool get isUnallocated => allocationStatus == 'UNALLOCATED';

  /// Get user-friendly display status for the overall DPC posting
  String getDisplayStatus() {
    if (hasError) return 'Failed';
    if (accrualStatus == 'PENDING') return 'Pending';
    if (isFullySettled) return 'Settled';
    if (isAllocated) return 'Allocated';
    if (isPendingApproval) return 'Awaiting Approval';
    if (isUnallocated) return 'Unallocated';
    return 'In Progress';
  }

  /// Get color for the overall DPC posting status
  Color getStatusColor() {
    if (hasError) return AppColorsEnhanced.errorRed;
    if (accrualStatus == 'PENDING') return AppColorsEnhanced.secondaryText;
    if (isFullySettled) return AppColorsEnhanced.successGreen;
    if (isAllocated) return AppColorsEnhanced.successGreen;
    if (isPendingApproval) return AppColorsEnhanced.warningYellow;
    if (isUnallocated) return AppColorsEnhanced.infoBlue;
    return AppColorsEnhanced.infoBlue;
  }

  /// Get color for a specific track
  Color getTrackColor(String status) {
    switch (status) {
      case 'PENDING':
      case 'UNSETTLED':
      case 'UNALLOCATED':
        return AppColorsEnhanced.secondaryText;
      case 'CREATED':
      case 'ALLOCATED':
      case 'SETTLED':
        return AppColorsEnhanced.successGreen;
      case 'PENDING_APPROVAL':
        return AppColorsEnhanced.warningYellow;
      case 'FAILED':
        return AppColorsEnhanced.errorRed;
      default:
        return AppColorsEnhanced.secondaryText;
    }
  }

  factory DpcPosting.fromJson(Map<String, dynamic> json) {
    return DpcPosting(
      settlementName: json['settlement_name'] as String? ?? '',
      accrualStatus: json['accrual_status'] as String? ?? 'PENDING',
      allocationStatus: json['allocation_status'] as String? ?? 'UNALLOCATED',
      settlementStatus: json['settlement_status'] as String? ?? 'UNSETTLED',
      allocatedToErp: json['allocated_to_erp'] as String?,
      isOverridden: json['is_overridden'] as bool? ?? false,
      overrideReason: json['override_reason'] as String?,
      error: json['error'] as String?,
    );
  }

  DpcPosting copyWith({
    String? settlementName,
    String? accrualStatus,
    String? allocationStatus,
    String? settlementStatus,
    String? allocatedToErp,
    bool? isOverridden,
    String? overrideReason,
    String? error,
  }) {
    return DpcPosting(
      settlementName: settlementName ?? this.settlementName,
      accrualStatus: accrualStatus ?? this.accrualStatus,
      allocationStatus: allocationStatus ?? this.allocationStatus,
      settlementStatus: settlementStatus ?? this.settlementStatus,
      allocatedToErp: allocatedToErp ?? this.allocatedToErp,
      isOverridden: isOverridden ?? this.isOverridden,
      overrideReason: overrideReason ?? this.overrideReason,
      error: error ?? this.error,
    );
  }
}
