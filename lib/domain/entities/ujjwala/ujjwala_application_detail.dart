class UjjwalaApplicationDetail {
  // Applicant
  final String applicantName;
  final String applicantMobile;
  final String aadhaarNumber;
  final String dateOfBirth;
  final String gender;
  final String caste;

  // Bank
  final String bankAccountName;
  final String bankAccountNumber;
  final String ifscCode;
  final String branchName;
  final String bankName;

  // Consumer
  final String consumerId;
  final String lgpConnectionType;
  final String applicationStatus;

  // Address & GPS
  final String fullAddress;
  final String latitude;
  final String longitude;
  final String googleMapsUrl;

  // Pre-Suraksha documents
  final List<Map<String, String>> documents;

  // Latest installation (if submitted)
  final String? installationStatus;
  final String? kitchenPhotoUrl;
  final String? gatePhotoUrl;
  final String? stovePhotoUrl;
  final String? rejectionReason;

  const UjjwalaApplicationDetail({
    required this.applicantName,
    required this.applicantMobile,
    required this.aadhaarNumber,
    required this.dateOfBirth,
    required this.gender,
    required this.caste,
    required this.bankAccountName,
    required this.bankAccountNumber,
    required this.ifscCode,
    required this.branchName,
    required this.bankName,
    required this.consumerId,
    required this.lgpConnectionType,
    required this.applicationStatus,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    required this.googleMapsUrl,
    required this.documents,
    this.installationStatus,
    this.kitchenPhotoUrl,
    this.gatePhotoUrl,
    this.stovePhotoUrl,
    this.rejectionReason,
  });

  factory UjjwalaApplicationDetail.fromJson(Map<String, dynamic> json) {
    final rawDocs = json['pre_suraksha_documents'] as List<dynamic>? ?? [];
    final docs = rawDocs.map((d) {
      final map = d as Map<String, dynamic>;
      return <String, String>{
        'doc_type': map['doc_type']?.toString() ?? '',
        'url': map['url']?.toString() ?? '',
      };
    }).toList();

    final installation = json['latest_installation'] as Map<String, dynamic>?;

    return UjjwalaApplicationDetail(
      applicantName: json['applicant_name']?.toString() ?? '',
      applicantMobile: json['applicant_mobile']?.toString() ?? '',
      aadhaarNumber: json['aadhaar_number']?.toString() ?? '',
      dateOfBirth: json['date_of_birth']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      caste: json['caste']?.toString() ?? '',
      bankAccountName: json['bank_account_name']?.toString() ?? '',
      bankAccountNumber: json['bank_account_number']?.toString() ?? '',
      ifscCode: json['ifsc_code']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? '',
      bankName: json['bank_name']?.toString() ?? '',
      consumerId: json['consumer_id']?.toString() ?? '',
      lgpConnectionType: json['lgp_connection_type']?.toString() ?? '',
      applicationStatus: json['application_status']?.toString() ?? '',
      fullAddress: json['full_address']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      googleMapsUrl: json['google_maps_url']?.toString() ?? '',
      documents: docs,
      installationStatus: installation?['status']?.toString(),
      kitchenPhotoUrl: installation?['kitchen_photo_url']?.toString(),
      gatePhotoUrl: installation?['gate_photo_url']?.toString(),
      stovePhotoUrl: installation?['stove_photo_url']?.toString(),
      rejectionReason: installation?['rejection_reason']?.toString(),
    );
  }
}
