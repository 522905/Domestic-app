class Warehouse {
  final String name;
  final String warehouseName;
  final String customer;

  Warehouse(
      {
        required this.name,
        required this.warehouseName,
        required this.customer
      }
  );

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      name: json['name'] ?? '',
      warehouseName: json['warehouse_name'] ?? '',
      customer: json['company'] ?? '',
    );
  }
}