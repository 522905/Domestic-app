import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/vehicle.dart';
import '../../blocs/order_form/order_form_bloc.dart';
import '../../../domain/entities/inventory_item.dart';
import '../../../domain/entities/warehouse.dart';
import '../../blocs/orders/orders_bloc.dart';
import '../../widgets/selectors/item_selector_dialog.dart';
import 'dialogs/select_warehouse_dialog.dart';

class CreateOrderPage extends StatelessWidget {
  const CreateOrderPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderFormBloc(
        apiService: context.read<ApiServiceInterface>(),
      ),
      child: const _CreateOrderView(),
    );
  }
}

class _CreateOrderView extends StatefulWidget {
  const _CreateOrderView();

  @override
  State<_CreateOrderView> createState() => _CreateOrderViewState();
}

class _CreateOrderViewState extends State<_CreateOrderView> {
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _warehouseController = TextEditingController();
  final TextEditingController _searchItemsController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  late OrderFormBloc _orderFormBloc;

  List<Map<String, dynamic>> availableItems = [];

  @override
  void initState() {
    super.initState();
    _dateController.text =
        DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _warehouseController.dispose();
    _searchItemsController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orderFormBloc =
        BlocProvider.of<OrderFormBloc>(context); // Get the BLoC here
  }

  @override
  Widget build(BuildContext context) {
    print("========= BUILD CALLED =========");

    return BlocListener<OrderFormBloc, OrderFormState>(
      listenWhen: (previous, current) => current is OrderFormSubmitted,
      listener: (context, state) {
        if (state is OrderFormSubmitted) {
          // Add the new order to OrdersBloc
          BlocProvider.of<OrdersBloc>(context).add(AddOrder(state.order));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order ${state.orderNumber} created successfully'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'New Order Request',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF0E5CA8),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: BlocConsumer<OrderFormBloc, OrderFormState>(
            listenWhen: (previous, current) {
              print(
                  "LISTEN CHECK: ${previous.runtimeType} -> ${current.runtimeType}");
              return true; // Always listen to ensure we see all state changes
            },
            listener: (context, state) {
              print("LISTENER TRIGGERED: State is ${state.runtimeType}");
              if (state is OrderFormLoaded) {
                print(
                    "Vehicle: ${state.selectedVehicle?.id}, WH: ${state.selectedWarehouse?.warehouseName}");
                print("WH Count: ${state.availableWarehouses.length}");
              }
            },
            buildWhen: (previous, current) {
              print(
                  "BUILD CHECK: ${previous.runtimeType} -> ${current.runtimeType}");
              return true; // Always rebuild to debug
            },
            builder: (context, state) {
              if (state is OrderFormInitial || state is OrderFormLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is OrderFormLoaded) {
                // Print selected items for debugging
                print(
                    'Builder called with ${state.selectedItems.length} items');
                print(
                    "MAIN BUILD: Vehicle: ${state.selectedVehicle?.id}, WH count: ${state.availableWarehouses.length}");

                // Auto-fill controllers if values are selected
                if (state.selectedVehicle != null &&
                    _vehicleController.text.isEmpty) {
                  _vehicleController.text =
                      state.selectedVehicle!.registrationNumber;
                }

                if (state.selectedWarehouse != null &&
                    _warehouseController.text.isEmpty) {
                  _warehouseController.text = state.selectedWarehouse!.name;
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Type
                      _buildSectionTitle('Order Type'),
                      _buildOrderTypeSelector(context, state),
                      SizedBox(height: 16.h),

                      // Vehicle
                      _buildSectionTitle('Vehicle'),
                      _buildVehicleSelector(context, state),
                      SizedBox(height: 16.h),

                      // Warehouse
                      _buildSectionTitle('Warehouse'),
                      _buildWarehouseSelector(context, state),
                      if (state.selectedWarehouse != null)
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            'Available stock across multiple items',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      SizedBox(height: 16.h),

                      // Selected Items
                      if (state.selectedItems.isNotEmpty)
                        Column(
                          children:
                              state.selectedItems.values.map((itemQuantity) {
                            return _buildSelectedItemCardWithCustomWidget(
                                context, itemQuantity, state);
                          }).toList(),
                        ),

                      // Add Another Item button
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: OutlinedButton(
                          onPressed: () {
                            _showSelectItemsDialog(context, state);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48.h),
                            foregroundColor: const Color(0xFF0E5CA8),
                            side: const BorderSide(color: Color(0xFF0E5CA8)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add),
                              SizedBox(width: 8.w),
                              const Text('ADD ANOTHER ITEM'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Delivery Date
                      _buildSectionTitle('Delivery Date'),
                      _buildDatePicker(context, state),
                      SizedBox(height: 24.h),

                      ElevatedButton(
                        onPressed: () {
                          print('Submit button tapped');

                          final currentState = state as OrderFormLoaded;

                          if (!currentState.isValid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please complete all required fields')),
                            );
                            return;
                          }

                          if (currentState.selectedItems.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please add at least one item')),
                            );
                            return;
                          }
                          context.read<OrderFormBloc>().add(SubmitOrder());
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 56.h),
                          backgroundColor: const Color(0xFF0E5CA8),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: state.isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'SUBMIT ORDER',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const Center(child: Text('Something went wrong'));
            },
          ),
          bottomSheet: BlocBuilder<OrderFormBloc, OrderFormState>(
            buildWhen: (previous, current) {
              // Always rebuild when the vehicle selection changes
              if (previous is OrderFormLoaded && current is OrderFormLoaded) {
                return previous.selectedVehicle != current.selectedVehicle;
              }
              return true;
            },
            builder: (context, state) {
              if (state is OrderFormLoaded) {
                if (state.selectedVehicle != null &&
                    state.selectedVehicle!.cooldownUntil != null) {
                  return Container(
                    padding: EdgeInsets.all(16.w),
                    color: Colors.orange.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 24.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'This vehicle will not be available for new orders for 2.5 hours after submission.',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          )),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildOrderTypeSelector(BuildContext context, OrderFormLoaded state) {
    return Row(
      children: [
        Expanded(
          child: _buildOrderTypeRadio(
            context,
            title: 'Refill',
            value: 'Refill',
            groupValue: state.orderType,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildOrderTypeRadio(
            context,
            title: 'NFR',
            value: 'NFR',
            groupValue: state.orderType,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTypeRadio(
    BuildContext context, {
    required String title,
    required String value,
    required String groupValue,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color:
              groupValue == value ? const Color(0xFF0E5CA8) : Colors.grey[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: groupValue == value
                ? const Color(0xFF0E5CA8)
                : Colors.grey[700],
          ),
        ),
        value: value,
        groupValue: groupValue,
        onChanged: (value) {
          if (value != null) {
            context.read<OrderFormBloc>().add(OrderTypeChanged(value));
          }
        },
        activeColor: const Color(0xFF0E5CA8),
        contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
      ),
    );
  }

  Widget _buildVehicleSelector(BuildContext context, OrderFormLoaded state) {
    return GestureDetector(
      onTap: () {
        _showVehicleSelectionSheet(context, state.availableVehicles);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _vehicleController,
                readOnly: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Select a vehicle',
                ),
                onTap: () {
                  _showVehicleSelectionSheet(context, state.availableVehicles);
                },
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseSelector(BuildContext context, OrderFormLoaded state) {
    return BlocBuilder<OrderFormBloc, OrderFormState>(
        // This buildWhen ensures the widget rebuilds when warehouse list changes
        buildWhen: (previous, current) {
      if (previous is OrderFormLoaded && current is OrderFormLoaded) {
        print('>> Rebuilding warehouse selector: '
            'vehicle=${current.selectedVehicle?.id} '
            'warehouses=[${current.availableWarehouses.map((w) => w.warehouseName).join(',')}]');
        // Rebuild if vehicle changes or if warehouse list changes
        return previous.selectedVehicle != current.selectedVehicle ||
            previous.availableWarehouses != current.availableWarehouses;
      }
      return true; // Always build on other state changes
    }, builder: (context, builderState) {
      if (builderState is! OrderFormLoaded) {
        return Container(); // Return empty container if not loaded state
      }

      final state = builderState;
      final isVehicleSelected = state.selectedVehicle != null;
      final availableWarehouses = state.availableWarehouses;

      print('Warehouse selector rebuilding:');
      print('- Vehicle selected: ${isVehicleSelected}');
      print('- Available warehouses: ${availableWarehouses.length}');

      return GestureDetector(
        onTap: isVehicleSelected
            ? () {
                _showSelectWarehouseDialog(context, availableWarehouses);
              }
            : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            border: Border.all(
                color:
                    isVehicleSelected ? Colors.grey[300]! : Colors.grey[200]!),
            borderRadius: BorderRadius.circular(4),
            color: isVehicleSelected ? Colors.white : Colors.grey[100],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _warehouseController,
                  readOnly: true,
                  enabled: isVehicleSelected,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: isVehicleSelected
                        ? 'Select a warehouse'
                        : 'Select a vehicle first',
                  ),
                  onTap: isVehicleSelected
                      ? () {
                          _showSelectWarehouseDialog(
                              context, availableWarehouses);
                        }
                      : null,
                ),
              ),
              Icon(Icons.arrow_drop_down,
                  color: isVehicleSelected ? Colors.grey : Colors.grey[400]),
            ],
          ),
        ),
      );
    });
  }

  void _showVehicleSelectionSheet(
      BuildContext context, List<Vehicle> vehicles) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Vehicle'),
              SizedBox(height: 16.h),
              Expanded(
                child: ListView.builder(
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    return ListTile(
                      title: Text(vehicle.registrationNumber),
                      onTap: () {
                        // Close the bottom sheet first
                        Navigator.pop(bottomSheetContext);

                        // Update the text controller
                        _vehicleController.text = vehicle.registrationNumber;

                        // Directly add event to the bloc we captured in didChangeDependencies
                        _orderFormBloc.add(VehicleSelected(vehicle));

                        // Force a rebuild
                        setState(() {});

                        print("Vehicle selected and setState called");
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildSelectedItemCardWithCustomWidget(
    BuildContext context,
    OrderItemQuantity itemQuantity,
    OrderFormLoaded state,
  ) {
    final item = itemQuantity.item;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                // Stock level indicator
                _buildStockLevelIndicator(item),
                const Spacer(),
                // Quantity field widget
                ItemQuantityField(
                  itemId: item.id,
                  quantity: itemQuantity.quantity,
                  maxQuantity: item.available,
                  onQuantityChanged: (newQuantity) {
                    context.read<OrderFormBloc>().add(
                          ItemQuantityChanged(
                            item.id,
                            newQuantity,
                          ),
                        );
                  },
                  onRemoveItem: () {
                    context.read<OrderFormBloc>().add(ItemRemoved(item.id));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockLevelIndicator(InventoryItem item) {
    // Determine stock level color
    Color indicatorColor;
    double level = item.available / (item.available + item.reserved);

    if (level > 0.7) {
      indicatorColor = Colors.green;
    } else if (level > 0.3) {
      indicatorColor = Colors.orange;
    } else {
      indicatorColor = Colors.red;
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 8.h,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: level.clamp(0.0, 1.0),
                child: Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Available: ${item.available} | Reserved: ${item.reserved}',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, OrderFormLoaded state) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: state.deliveryDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );

        if (date != null) {
          _dateController.text = DateFormat('EEEE, MMMM d, yyyy').format(date);
          context.read<OrderFormBloc>().add(DeliveryDateChanged(date));
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: state.deliveryDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );

                  if (date != null) {
                    _dateController.text =
                        DateFormat('EEEE, MMMM d, yyyy').format(date);
                    context
                        .read<OrderFormBloc>()
                        .add(DeliveryDateChanged(date));
                  }
                },
              ),
            ),
            const Icon(Icons.calendar_today, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showSelectWarehouseDialog(
      BuildContext context, List<Warehouse> warehouses) {
    showDialog(
      context: context,
      builder: (context) => SelectWarehouseDialog(
        warehouses: warehouses,
        onWarehouseSelected: (warehouse) {
          Navigator.pop(context);
          context.read<OrderFormBloc>().add(WarehouseSelected(warehouse));
          _warehouseController.text = warehouse.name;
          _orderFormBloc.add(WarehouseSelected(warehouse));
          setState(() {});
        },
      ),
    );
  }
}

void _showSelectItemsDialog(BuildContext context, OrderFormLoaded state) {
  if (state.selectedWarehouse == null) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a warehouse first')));
    return;
  }

  if (state.availableItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items available for this warehouse')));
    return;
  }

  // Use the actual selectedItem data directly without trying to match
  ItemSelectorDialog.show(
    context,
    ['Cylinder', 'NFR'],
    ['Regulator', 'Pipe'],
        (selectedItem) {
      try {
        // Create an InventoryItem directly from the dialog selection
        final inventoryItem = InventoryItem(
          id: selectedItem['itemId'],
          name: selectedItem['name'],
          type: selectedItem['type'],
          nfrType: selectedItem['nfrType'],
          available: selectedItem['available'],
          reserved: 0,
          item: '',
        );

        // Create OrderItemQuantity
        final orderItemQuantity = OrderItemQuantity(
          item: inventoryItem,
          quantity: selectedItem['quantity'],
        );

        // Update items
        final updatedItems = Map<String, OrderItemQuantity>.from(state.selectedItems);
        updatedItems[inventoryItem.id] = orderItemQuantity;

        // Add to bloc
        context.read<OrderFormBloc>().add(UpdateItems(updatedItems));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e')),
        );
      }
    },
  );
}

class SimpleSelectItemsDialog extends StatefulWidget {
  final List<InventoryItem> availableItems;
  final Function(Map<InventoryItem, int>) onItemsSelected;

  const SimpleSelectItemsDialog({
    Key? key,
    required this.availableItems,
    required this.onItemsSelected,
  }) : super(key: key);

  @override
  State<SimpleSelectItemsDialog> createState() =>
      _SimpleSelectItemsDialogState();
}

class _SimpleSelectItemsDialogState extends State<SimpleSelectItemsDialog> {
  final Map<InventoryItem, int> _selectedItems = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Items'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400.h,
        child: ListView.builder(
          itemCount: widget.availableItems.length,
          itemBuilder: (context, index) {
            final item = widget.availableItems[index];
            final isSelected = _selectedItems.containsKey(item);

            return ListTile(
              title: Text(item.name),
              subtitle: Text('Available: ${item.available}'),
              trailing: isSelected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (_selectedItems[item]! > 1) {
                                _selectedItems[item] =
                                    _selectedItems[item]! - 1;
                              } else {
                                _selectedItems.remove(item);
                              }
                            });
                          },
                        ),
                        Text('${_selectedItems[item]}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              if (_selectedItems[item]! < item.available) {
                                _selectedItems[item] =
                                    _selectedItems[item]! + 1;
                              }
                            });
                          },
                        ),
                      ],
                    )
                  : ElevatedButton(
                      child: const Text('Add'),
                      onPressed: () {
                        setState(() {
                          _selectedItems[item] = 1;
                        });
                      },
                    ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedItems.isEmpty
              ? null
              : () => widget.onItemsSelected(_selectedItems),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class UpdateItems extends OrderFormEvent {
  final Map<String, OrderItemQuantity> items;

  const UpdateItems(this.items);

  @override
  List<Object> get props => [items];
}

class ItemQuantityField extends StatefulWidget {
  final String itemId;
  final int quantity;
  final int maxQuantity;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemoveItem;

  const ItemQuantityField({
    Key? key,
    required this.itemId,
    required this.quantity,
    required this.maxQuantity,
    required this.onQuantityChanged,
    required this.onRemoveItem,
  }) : super(key: key);

  @override
  State<ItemQuantityField> createState() => _ItemQuantityFieldState();
}

class _ItemQuantityFieldState extends State<ItemQuantityField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quantity.toString());
  }

  @override
  void didUpdateWidget(ItemQuantityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      _controller.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Decrement button
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: IconButton(
            icon: const Icon(Icons.remove),
            onPressed: widget.quantity > 1
                ? () => widget.onQuantityChanged(widget.quantity - 1)
                : widget.onRemoveItem,
            padding: EdgeInsets.all(4.w),
            constraints: const BoxConstraints(),
            iconSize: 20.sp,
          ),
        ),
        SizedBox(width: 8.w),

        // Text input
        Container(
          width: 48.w,
          height: 36.h,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (value) {
              int? newQuantity = int.tryParse(value);
              if (newQuantity != null &&
                  newQuantity > 0 &&
                  newQuantity <= widget.maxQuantity) {
                widget.onQuantityChanged(newQuantity);
              } else if (newQuantity != null && newQuantity <= 0) {
                widget.onRemoveItem();
              } else {
                // Invalid input, reset to previous value
                _controller.text = widget.quantity.toString();
              }
            },
          ),
        ),

        SizedBox(width: 8.w),

        // Increment button
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.quantity < widget.maxQuantity
                  ? Colors.grey[300]!
                  : Colors.grey[200]!,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: IconButton(
            icon: const Icon(Icons.add),
            onPressed: widget.quantity < widget.maxQuantity
                ? () => widget.onQuantityChanged(widget.quantity + 1)
                : null,
            padding: EdgeInsets.all(4.w),
            constraints: const BoxConstraints(),
            iconSize: 20.sp,
            color: widget.quantity < widget.maxQuantity
                ? Colors.black87
                : Colors.grey[400],
          ),
        ),
      ],
    );
  }

}