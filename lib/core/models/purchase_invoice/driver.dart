class Driver {
  final int? id;
  final String name;
  final String phoneNumber;
  final String? photoUrl;
  final int visitCount;
  final String? lastVisitDate;

  Driver({
    this.id,
    required this.name,
    required this.phoneNumber,
    this.photoUrl,
    this.visitCount = 0,
    this.lastVisitDate,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      photoUrl: json['photo_url'],
      visitCount: json['visit_count'] ?? 0,
      lastVisitDate: json['last_visit_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'photo_url': photoUrl,
    };
  }
}