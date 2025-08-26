import 'package:lpg_distribution_app/core/models/deposit/selectable_deposit_item.dart';

abstract class DepositData {
  static const String unlinked = 'unlinked';
  static const String salesOrder = 'sales_order';
  static const String materialRequest = 'material_request';

  final String depositType;
  final Map<String, dynamic> rawData;
  final List<Map<String, dynamic>> warehouses;
  final List<Map<String, dynamic>> vehicles;

  DepositData({
    required this.depositType,
    required this.rawData,
    required this.warehouses,
    required this.vehicles,
  });

  List<SelectableDepositItem> getSelectableItems();
  int getMaxQuantityLimit();
}
