import 'package:lpg_distribution_app/core/models/deposit/selectable_deposit_item.dart';

import 'deposit_data.dart';

class MaterialRequestDepositData extends DepositData {
  final List<Map<String, dynamic>> materialRequests;

  MaterialRequestDepositData({
    required Map<String, dynamic> rawData,
    required List<Map<String, dynamic>> warehouses,
    required List<Map<String, dynamic>> vehicles,
  }) : materialRequests = List<Map<String, dynamic>>.from(rawData['material_requests'] ?? []),
        super(
        depositType: DepositData.materialRequest,
        rawData: rawData,
        warehouses: warehouses,
        vehicles: vehicles,
      );

  @override
  List<SelectableDepositItem> getSelectableItems() {
    final items = <SelectableDepositItem>[];

    for (var request in materialRequests) {
      items.add(SelectableDepositItem(
        id: 'material_request_${request['item_row_name']}',
        itemCode: request['item_code'] ?? '',
        itemName: request['item_code'] ?? '',
        description: request['item_code'] ?? '',
        type: 'material_request_item',
        maxQuantity: (request['pending_qty'] ?? 0).toInt(),
        metadata: {
          ...request,
          'material_request': request['material_request'],
          'item_row_name': request['item_row_name'],
        },
      ));
    }

    return items;
  }

  @override
  int getMaxQuantityLimit() => materialRequests.fold<int>(
    0,
    (sum, request) => sum + ((request['pending_qty'] ?? 0) as int),
); // Sum of all pending quantities
}