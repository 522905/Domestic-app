
// lib/domain/entities/inventory_item.dart
class InventoryItem {
  final String id;
  final String name;
  final String type; // Cylinder, Accessory, etc.
  final int available;
  final int reserved;
  final int? total;
  final int? defective;
  final int? inTransit;
  final DateTime? lastUpdated;
   final String? nfrType;
   final String item;
  const InventoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.available,
    required this.reserved,
    this.total,
    this.defective,
    this.inTransit,
    this.lastUpdated,
    required this.nfrType,
    required this.item,
 });

}

