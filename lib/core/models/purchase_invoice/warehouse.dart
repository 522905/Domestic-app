class Warehouse {
  final int id;
  final String name;
  final String code;

  Warehouse({
    required this.id,
    required this.name,
    required this.code,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }
}