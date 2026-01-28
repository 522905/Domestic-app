import 'package:equatable/equatable.dart';
import 'quota_item.dart';
import 'company_sync_info.dart';

class QuotaSnapshot extends Equatable {
  final String partnerName;
  final String partnerCode;
  final DateTime snapshotDate;
  final bool isQuotaEnabled;
  final bool isSdmsDown;
  final bool isPartnerExempt;
  final List<QuotaItem> items;
  final DateTime? lastSync;  // Oldest sync (staleness indicator)
  final List<CompanySyncInfo> syncStatus;

  const QuotaSnapshot({
    required this.partnerName,
    required this.partnerCode,
    required this.snapshotDate,
    required this.isQuotaEnabled,
    required this.isSdmsDown,
    required this.isPartnerExempt,
    required this.items,
    this.lastSync,
    required this.syncStatus,
  });

  // Computed properties
  bool get canSync => syncStatus.any((c) => c.canSync);
  bool get isStale => lastSync == null ||
      DateTime.now().difference(lastSync!).inMinutes > 60;
  bool get hasBlockedItems => items.any((item) => item.isBlocked);
  int get blockedItemsCount => items.where((item) => item.isBlocked).length;

  factory QuotaSnapshot.fromJson(Map<String, dynamic> json) {
    return QuotaSnapshot(
      partnerName: json['partner_name'] ?? '',
      partnerCode: json['partner_code'] ?? '',
      snapshotDate: DateTime.parse(json['snapshot_date']),
      isQuotaEnabled: json['is_quota_enabled'] ?? true,
      isSdmsDown: json['is_sdms_down'] ?? false,
      isPartnerExempt: json['is_partner_exempt'] ?? false,
      items: (json['items'] as List?)
          ?.map((item) => QuotaItem.fromJson(item))
          .toList() ?? [],
      lastSync: json['last_sync'] != null
          ? DateTime.parse(json['last_sync'])
          : null,
      syncStatus: (json['sync_status'] as List?)
          ?.map((status) => CompanySyncInfo.fromJson(status))
          .toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [
    partnerName, partnerCode, snapshotDate, isQuotaEnabled,
    isSdmsDown, isPartnerExempt, items, lastSync, syncStatus,
  ];
}
