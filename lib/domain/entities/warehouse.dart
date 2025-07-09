class Warehouse {
  final String name;
  final String warehouseName;
  final String company;

  Warehouse({required this.name, required this.warehouseName, required this.company});

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      name: json['name'] ?? '',
      warehouseName: json['warehouse_name'] ?? '',
      company: json['company'] ?? '',
    );
  }
}