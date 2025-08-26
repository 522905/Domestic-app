// lib/core/models/order/order_data.dart
import 'selectable_order_item.dart';

class OrderData {
  final Map<String, dynamic> rawData;
  final List<Map<String, dynamic>> warehouses;
  final List<Map<String, dynamic>> vehicles;
  final String orderType;

  OrderData({
    required this.rawData,
    required this.warehouses,
    required this.vehicles,
    required this.orderType,
  });

  List<SelectableOrderItem> getSelectableItems() {
    final buckets = rawData['buckets'] as Map<String, dynamic>? ?? {};
    final List<SelectableOrderItem> allItems = [];

    // Extract items from all buckets
    buckets.forEach((bucketType, items) {
      if (items is List) {
        for (var item in items) {
          allItems.add(SelectableOrderItem.fromJson(item, bucketType));
        }
      }
    });

    return allItems;
  }

  List<Map<String, dynamic>> getItemGroupFilters() {
    final facets = rawData['facets'] as Map<String, dynamic>? ?? {};
    final itemGroups = facets['item_group'] as List<dynamic>? ?? [];

    return itemGroups.map<Map<String, dynamic>>((group) {
      return {
        'value': group['value'] ?? '',
        'count': group['count'] ?? 0,
      };
    }).toList();
  }

  List<Map<String, dynamic>> getAvailabilityFilters() {
    final facets = rawData['facets'] as Map<String, dynamic>? ?? {};
    final availability = facets['availability'] as List<dynamic>? ?? [];

    return availability.map<Map<String, dynamic>>((avail) {
      return {
        'value': avail['value'] ?? '',
        'count': avail['count'] ?? 0,
      };
    }).toList();
  }

  List<Map<String, dynamic>> getBucketFilters() {
    final buckets = rawData['buckets'] as Map<String, dynamic>? ?? {};

    return buckets.keys.map<Map<String, dynamic>>((bucketType) {
      final items = buckets[bucketType] as List? ?? [];
      return {
        'value': bucketType,
        'count': items.length,
      };
    }).toList();
  }
}