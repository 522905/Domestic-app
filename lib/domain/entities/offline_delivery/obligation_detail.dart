import 'package:equatable/equatable.dart';
import 'obligation_director.dart';

class ObligationDetail extends Equatable {
  final String id;
  final ObligationDirector? directedBy;
  final String? consumerNameManual;

  // What we're delivering
  final String? deliveryType; // REFILL / NEW_CONNECTION
  final String? itemCode; // M00087, M00104
  final int quantity;

  // Director display name (when API returns just FK id)
  final String? directedByName;

  // Assignment
  final String? assignedToName;

  // SDMS posting
  final String? poolConsumerId;

  // Empty collection tracking
  final String? emptyArrangement; // SAME_DAY / DEFERRED / NOT_APPLICABLE
  final int emptiesExpected;
  final int emptiesCollected;
  final DateTime? emptiesDueDate;
  final bool emptiesCompleted;
  final DateTime? emptiesCompletedAt;
  final String? emptiesCompletedByName;

  // Deferred cash tracking
  final String? cashArrangement; // ALREADY_PAID / COLLECT_AT_DELIVERY / DEFERRED / NOT_APPLICABLE
  final DateTime? cashDueDate;
  final bool cashCollectedLater;
  final DateTime? cashCollectedLaterAt;
  final String? cashCollectedLaterByName;

  const ObligationDetail({
    required this.id,
    this.directedBy,
    this.consumerNameManual,
    this.deliveryType,
    this.itemCode,
    this.quantity = 1,
    this.directedByName,
    this.assignedToName,
    this.poolConsumerId,
    this.emptyArrangement,
    this.emptiesExpected = 0,
    this.emptiesCollected = 0,
    this.emptiesDueDate,
    this.emptiesCompleted = false,
    this.emptiesCompletedAt,
    this.emptiesCompletedByName,
    this.cashArrangement,
    this.cashDueDate,
    this.cashCollectedLater = false,
    this.cashCollectedLaterAt,
    this.cashCollectedLaterByName,
  });

  /// Display name for cylinder type
  String get itemDisplayName {
    switch (itemCode) {
      case 'M00087':
        return '14.2 Kg';
      case 'M00104':
        return '5 Kg';
      default:
        return itemCode ?? 'Unknown';
    }
  }

  /// Display name for delivery type
  String get deliveryTypeDisplay {
    switch (deliveryType) {
      case 'REFILL':
        return 'Refill';
      case 'NEW_CONNECTION':
        return 'New Connection';
      default:
        return deliveryType ?? 'Unknown';
    }
  }

  /// Best available director display name
  String? get directorDisplayName {
    if (directedBy != null && directedBy!.name.isNotEmpty) return directedBy!.name;
    if (directedByName != null && directedByName!.isNotEmpty) return directedByName;
    return null;
  }

  int get emptiesRemaining => emptiesExpected - emptiesCollected;
  bool get hasPendingEmpties => !emptiesCompleted && emptiesExpected > 0;
  bool get hasPendingCash =>
      cashArrangement == 'DEFERRED' && !cashCollectedLater;

  bool get isOverdueEmpties {
    if (!hasPendingEmpties || emptiesDueDate == null) return false;
    return DateTime.now().isAfter(emptiesDueDate!);
  }

  bool get isOverdueCash {
    if (!hasPendingCash || cashDueDate == null) return false;
    return DateTime.now().isAfter(cashDueDate!);
  }

  factory ObligationDetail.fromJson(Map<String, dynamic> json) {
    // directed_by can be a nested object or just an int (FK ID)
    ObligationDirector? director;
    final directedByRaw = json['directed_by'];
    if (directedByRaw is Map<String, dynamic>) {
      director = ObligationDirector.fromJson(directedByRaw);
    } else if (directedByRaw is int) {
      director = ObligationDirector(id: directedByRaw, name: '', role: '');
    }

    return ObligationDetail(
      id: json['id']?.toString() ?? '',
      directedBy: director,
      consumerNameManual: json['consumer_name_manual']?.toString(),
      deliveryType: json['delivery_type']?.toString(),
      itemCode: json['item_code']?.toString(),
      quantity: json['quantity'] != null ? int.tryParse(json['quantity'].toString()) ?? 1 : 1,
      directedByName: json['directed_by_name']?.toString(),
      assignedToName: json['assigned_to_name']?.toString(),
      poolConsumerId: json['pool_consumer_id']?.toString(),
      emptyArrangement: json['empty_arrangement']?.toString(),
      emptiesExpected: json['empties_expected'] != null ? int.tryParse(json['empties_expected'].toString()) ?? 0 : 0,
      emptiesCollected: json['empties_collected'] != null ? int.tryParse(json['empties_collected'].toString()) ?? 0 : 0,
      emptiesDueDate: json['empties_due_date'] != null
          ? DateTime.tryParse(json['empties_due_date'].toString())
          : null,
      emptiesCompleted: json['empties_completed'] ?? false,
      emptiesCompletedAt: json['empties_completed_at'] != null
          ? DateTime.tryParse(json['empties_completed_at'].toString())
          : null,
      emptiesCompletedByName: json['empties_completed_by_name']?.toString(),
      cashArrangement: json['cash_arrangement']?.toString(),
      cashDueDate: json['cash_due_date'] != null
          ? DateTime.tryParse(json['cash_due_date'].toString())
          : null,
      cashCollectedLater: json['cash_collected_later'] ?? false,
      cashCollectedLaterAt: json['cash_collected_later_at'] != null
          ? DateTime.tryParse(json['cash_collected_later_at'].toString())
          : null,
      cashCollectedLaterByName: json['cash_collected_later_by_name']?.toString(),
    );
  }

  ObligationDetail copyWith({
    int? emptiesCollected,
    bool? emptiesCompleted,
    DateTime? emptiesCompletedAt,
    bool? cashCollectedLater,
    DateTime? cashCollectedLaterAt,
  }) {
    return ObligationDetail(
      id: id,
      directedBy: directedBy,
      consumerNameManual: consumerNameManual,
      deliveryType: deliveryType,
      itemCode: itemCode,
      quantity: quantity,
      directedByName: directedByName,
      assignedToName: assignedToName,
      poolConsumerId: poolConsumerId,
      emptyArrangement: emptyArrangement,
      emptiesExpected: emptiesExpected,
      emptiesCollected: emptiesCollected ?? this.emptiesCollected,
      emptiesDueDate: emptiesDueDate,
      emptiesCompleted: emptiesCompleted ?? this.emptiesCompleted,
      emptiesCompletedAt: emptiesCompletedAt ?? this.emptiesCompletedAt,
      emptiesCompletedByName: emptiesCompletedByName,
      cashArrangement: cashArrangement,
      cashDueDate: cashDueDate,
      cashCollectedLater: cashCollectedLater ?? this.cashCollectedLater,
      cashCollectedLaterAt: cashCollectedLaterAt ?? this.cashCollectedLaterAt,
      cashCollectedLaterByName: cashCollectedLaterByName,
    );
  }

  @override
  List<Object?> get props => [
        id, directedBy, consumerNameManual, deliveryType, itemCode, quantity,
        directedByName, assignedToName, poolConsumerId, emptyArrangement, emptiesExpected,
        emptiesCollected, emptiesDueDate, emptiesCompleted, emptiesCompletedAt,
        emptiesCompletedByName, cashArrangement, cashDueDate,
        cashCollectedLater, cashCollectedLaterAt, cashCollectedLaterByName,
      ];
}
