class DacOrderEntry {
  final String id;
  final int slipNumber;
  final String? consumerId;
  final String? consumerNumber;
  final String dacCode;
  final String? remark;
  final DateTime createdAt;
  // TODO: Add synced/serverId fields when API endpoint available

  DacOrderEntry({
    required this.id,
    this.slipNumber = 0,
    this.consumerId,
    this.consumerNumber,
    required this.dacCode,
    this.remark,
    required this.createdAt,
  });

  DacOrderEntry copyWith({int? slipNumber}) => DacOrderEntry(
        id: id,
        slipNumber: slipNumber ?? this.slipNumber,
        consumerId: consumerId,
        consumerNumber: consumerNumber,
        dacCode: dacCode,
        remark: remark,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'slipNumber': slipNumber,
        'consumerId': consumerId,
        'consumerNumber': consumerNumber,
        'dacCode': dacCode,
        'remark': remark,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DacOrderEntry.fromJson(Map<String, dynamic> json) => DacOrderEntry(
        id: json['id'] as String,
        slipNumber: (json['slipNumber'] as int?) ?? 0,
        consumerId: json['consumerId'] as String?,
        consumerNumber: json['consumerNumber'] as String?,
        dacCode: json['dacCode'] as String,
        remark: json['remark'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String get displayIdentifier {
    final parts = <String>[];
    if (consumerId != null && consumerId!.isNotEmpty) {
      parts.add('Consumer ID: $consumerId');
    }
    if (consumerNumber != null && consumerNumber!.isNotEmpty) {
      parts.add('Consumer No: $consumerNumber');
    }
    return parts.isNotEmpty ? parts.join(' | ') : '-';
  }
}
