import 'package:lpg_distribution_app/core/models/deposit/selectable_deposit_item.dart';

import 'deposit_data.dart';

class UnlinkedDepositData extends DepositData {
  final Map<String, List<Map<String, dynamic>>> buckets;
  final Map<String, List<Map<String, dynamic>>> facets;

  UnlinkedDepositData({
    required Map<String, dynamic> rawData,
    required List<Map<String, dynamic>> warehouses,
    required List<Map<String, dynamic>> vehicles,
  }) : buckets = _extractBuckets(rawData),
        facets = _extractFacets(rawData),
        super(
        depositType: DepositData.unlinked,
        rawData: rawData,
        warehouses: warehouses,
        vehicles: vehicles,
      );

  static Map<String, List<Map<String, dynamic>>> _extractBuckets(Map<String, dynamic> data) {
    final buckets = data['buckets'] as Map<String, dynamic>? ?? {};
    return buckets.map((key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value ?? [])));
  }

  static Map<String, List<Map<String, dynamic>>> _extractFacets(Map<String, dynamic> data) {
    final facets = data['facets'] as Map<String, dynamic>? ?? {};
    return facets.map((key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value ?? [])));
  }

  @override
  List<SelectableDepositItem> getSelectableItems() {
    final items = <SelectableDepositItem>[];

    // Process Empty items
    if (buckets['Empty'] != null) {
      for (var item in buckets['Empty']!) {
        items.add(SelectableDepositItem(
          id: 'unlinked_empty_${item['item_code']}',
          itemCode: item['item_code'] ?? '',
          itemName: item['item_name'] ?? item['item_code'] ?? '',
          description: item['description'] ?? '',
          type: 'unlinked_empty',
          maxQuantity: 500, // Static limit as requested
          metadata: {
            ...item,
            'bucket_type': 'Empty',
          },
        ));
      }
    }

    // Process Defective items
    if (buckets['Defective'] != null) {
      for (var item in buckets['Defective']!) {
        items.add(SelectableDepositItem(
          id: 'unlinked_defective_${item['item_code']}',
          itemCode: item['item_code'] ?? '',
          itemName: item['item_name'] ?? item['item_code'] ?? '',
          description: item['description'] ?? '',
          type: 'unlinked_defective',
          maxQuantity: 500, // Static limit as requested
          metadata: {
            ...item,
            'bucket_type': 'Defective',
          },
        ));
      }
    }

    return items;
  }

  @override
  int getMaxQuantityLimit() => 500; // Static limit for unlinked deposits

  List<Map<String, dynamic>> getItemGroupFilters() {
    return facets['item_group'] ?? [];
  }
}