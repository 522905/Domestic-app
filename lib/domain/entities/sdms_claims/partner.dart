/// Partner entity for claim-on-behalf functionality
/// IMPORTANT: Use the 'id' field (DB primary key) when passing intended_partner to Create Order API
class Partner {
  final int id; // DB primary key - USE THIS for intended_partner
  final String partnerId; // ERPNext Customer ID (e.g., CUST-00123)
  final String partnerName;
  final bool isActive;

  Partner({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    required this.isActive,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] as int,
      partnerId: json['partner_id'] as String,
      partnerName: json['partner_name'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Partner copyWith({
    int? id,
    String? partnerId,
    String? partnerName,
    bool? isActive,
  }) {
    return Partner(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      isActive: isActive ?? this.isActive,
    );
  }
}
