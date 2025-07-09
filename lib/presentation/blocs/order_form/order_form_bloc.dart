import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/inventory_item.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/warehouse.dart';
import '../../../domain/entities/vehicle.dart';
import '../../pages/orders/create_order_page.dart';

// Events
abstract class OrderFormEvent extends Equatable {
  const OrderFormEvent();

  @override
  List<Object?> get props => [];
}

class OrderTypeChanged extends OrderFormEvent {
  final String orderType;

  const OrderTypeChanged(this.orderType);

  @override
  List<Object> get props => [orderType];
}

class VehicleSelected extends OrderFormEvent {
  final Vehicle vehicle;

  const VehicleSelected(this.vehicle);

  @override
  List<Object> get props => [vehicle];
}

class WarehouseSelected extends OrderFormEvent {
  final Warehouse warehouse;

  const WarehouseSelected(this.warehouse);

  @override
  List<Object> get props => [warehouse];
}

class ItemAdded extends OrderFormEvent {
  final InventoryItem item;
  final int quantity;

  const ItemAdded(this.item, this.quantity);

  @override
  List<Object> get props => [item, quantity];
}

class ItemRemoved extends OrderFormEvent {
  final String itemId;

  const ItemRemoved(this.itemId);

  @override
  List<Object> get props => [itemId];
}

class ItemQuantityChanged extends OrderFormEvent {
  final String itemId;
  final int quantity;

  const ItemQuantityChanged(this.itemId, this.quantity);

  @override
  List<Object> get props => [itemId, quantity];
}

class DeliveryDateChanged extends OrderFormEvent {
  final DateTime deliveryDate;

  const DeliveryDateChanged(this.deliveryDate);

  @override
  List<Object> get props => [deliveryDate];
}

class SubmitOrder extends OrderFormEvent {}

class LoadVehicles extends OrderFormEvent {}

class LoadWarehouses extends OrderFormEvent {}

class LoadInventoryItems extends OrderFormEvent {
  final String? warehouseId;
  final String? itemType;
  final String? searchQuery;

  const LoadInventoryItems({
    this.warehouseId,
    this.itemType,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [warehouseId, itemType, searchQuery];
}

// States
abstract class OrderFormState extends Equatable {
  const OrderFormState();

  @override
  List<Object?> get props => [];
}

class OrderFormInitial extends OrderFormState {}

class OrderFormLoading extends OrderFormState {}

class OrderFormLoaded extends OrderFormState {
  final String orderType;
  final Vehicle? selectedVehicle;
  final Warehouse? selectedWarehouse;
  final Map<String, OrderItemQuantity> selectedItems;
  final DateTime deliveryDate;
  final List<Vehicle> availableVehicles;
  final List<Warehouse> availableWarehouses;
  final List<InventoryItem> availableItems;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isValid;
  final DateTime stateTimestamp; // Add this field

  OrderFormLoaded({
    this.orderType = 'Refill',
    this.selectedVehicle,
    this.selectedWarehouse,
    this.selectedItems = const {},
    DateTime? deliveryDate,
    this.availableVehicles = const [],
    this.availableWarehouses = const [],
    this.availableItems = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.isValid = false,
    DateTime? stateTimestamp,
  }) : deliveryDate = deliveryDate ?? DateTime.now(),
        stateTimestamp = stateTimestamp ?? DateTime.now();

  @override
  List<Object?> get props => [
    orderType,
    selectedVehicle,
    selectedWarehouse,
    selectedItems,
    deliveryDate,
    availableVehicles,
    availableWarehouses,
    availableItems,
    isSubmitting,
    errorMessage,
    isValid,
    stateTimestamp
  ];

  OrderFormLoaded copyWith({
    String? orderType,
    Vehicle? selectedVehicle,
    bool clearVehicle = false,
    Warehouse? selectedWarehouse,
    bool clearWarehouse = false,
    Map<String, OrderItemQuantity>? selectedItems,
    DateTime? deliveryDate,
    List<Vehicle>? availableVehicles,
    List<Warehouse>? availableWarehouses,
    List<InventoryItem>? availableItems,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool? isValid,
    DateTime? stateTimestamp,
  }) {
    return OrderFormLoaded(
      orderType: orderType ?? this.orderType,
      selectedVehicle: clearVehicle ? null : selectedVehicle ?? this.selectedVehicle,
      selectedWarehouse: clearWarehouse ? null : selectedWarehouse ?? this.selectedWarehouse,
      selectedItems: selectedItems ?? this.selectedItems,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      availableVehicles: availableVehicles ?? this.availableVehicles,
      availableWarehouses: availableWarehouses ?? this.availableWarehouses,
      availableItems: availableItems ?? this.availableItems,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isValid: isValid ?? this.isValid,
      stateTimestamp: DateTime.now(), // Always create a new timestamp
    );
  }
}

class OrderFormSubmitted extends OrderFormState {
  final String orderNumber;
  final Order order;

  const OrderFormSubmitted(this.orderNumber, this.order);

  @override
  List<Object> get props => [orderNumber, order];
}

class OrderFormError extends OrderFormState {
  final String message;

  const OrderFormError(this.message);

  @override
  List<Object> get props => [message];
}

// Helper class
class OrderItemQuantity {
  final InventoryItem item;
  final int quantity;

  const OrderItemQuantity({
    required this.item,
    required this.quantity,
  });
}

// BLoC
class OrderFormBloc extends Bloc<OrderFormEvent, OrderFormState> {
  final ApiServiceInterface apiService;

  OrderFormBloc({required this.apiService}) : super(OrderFormInitial()) {
    on<OrderTypeChanged>(_onOrderTypeChanged);
    on<VehicleSelected>(_onVehicleSelected);
    on<WarehouseSelected>(_onWarehouseSelected);
    on<ItemAdded>(_onItemAdded);
    on<ItemRemoved>(_onItemRemoved);
    on<ItemQuantityChanged>(_onItemQuantityChanged);
    on<DeliveryDateChanged>(_onDeliveryDateChanged);
    on<SubmitOrder>(_onSubmitOrder);
    on<LoadVehicles>(_onLoadVehicles);
    on<LoadWarehouses>(_onLoadWarehouses);
    on<LoadInventoryItems>(_onLoadInventoryItems);
    on<UpdateItems>(_onUpdateItems);

    // Initialize
    add(LoadVehicles());
  }

  void _onUpdateItems(
      UpdateItems event,
      Emitter<OrderFormState> emit,
      ) {
    if (state is OrderFormLoaded) {
      final currentState = state as OrderFormLoaded;
      final updatedItems = Map<String, OrderItemQuantity>.from(currentState.selectedItems);
      updatedItems.addAll(event.items);

      emit(currentState.copyWith(
        selectedItems: updatedItems,
        isValid: _validateForm(
          vehicle: currentState.selectedVehicle,
          warehouse: currentState.selectedWarehouse,
          items: updatedItems,
        ),
      ));
    }
  }

  void _onOrderTypeChanged(
      OrderTypeChanged event,
      Emitter<OrderFormState> emit,
      ) {
    if (state is OrderFormLoaded) {
      final currentState = state as OrderFormLoaded;

      emit(currentState.copyWith(
        orderType: event.orderType,
        selectedItems: {},
        isValid: _validateForm(
          orderType: event.orderType,
          vehicle: currentState.selectedVehicle,
          warehouse: currentState.selectedWarehouse,
          items: {},
        ),
      ));

      // Load filtered items based on new order type
      if (currentState.selectedWarehouse != null) {
        add(LoadInventoryItems(
          warehouseId: currentState.selectedWarehouse?.warehouseName,
          itemType: event.orderType,
        ));
      }
    }
  }

  void _onVehicleSelected(VehicleSelected event, Emitter<OrderFormState> emit) {
    print("BLoC: Vehicle selection event for ${event.vehicle.id}");

    if (state is OrderFormLoaded) {
      final currentState = state as OrderFormLoaded;

      // Load warehouses for this vehicle
      add(LoadWarehouses());

      // Create a new state with the selected vehicle
      emit(OrderFormLoaded(
        orderType: currentState.orderType,
        selectedVehicle: event.vehicle,
        selectedWarehouse: null,
        selectedItems: {},
        deliveryDate: currentState.deliveryDate,
        availableVehicles: currentState.availableVehicles,
        availableWarehouses: currentState.availableWarehouses,
        availableItems: currentState.availableItems,
        isSubmitting: false,
        errorMessage: null,
        isValid: false,
        stateTimestamp: DateTime.now(),
      ));
    }
  }

  void _onWarehouseSelected(
      WarehouseSelected event,
      Emitter<OrderFormState> emit,
      ) {
    if (state is OrderFormLoaded) {
      final currentState = state as OrderFormLoaded;

      emit(currentState.copyWith(
        selectedWarehouse: event.warehouse,
        isValid: _validateForm(
          vehicle: currentState.selectedVehicle,
          warehouse: event.warehouse,
          items: currentState.selectedItems,
        ),
      ));

      // Load inventory items for the selected warehouse
      add(LoadInventoryItems(
        warehouseId: event.warehouse.warehouseName,
        itemType: currentState.orderType,
      ));
    }
  }

  void _onItemAdded(
      ItemAdded event,
      Emitter<OrderFormState> emit,
      ) {
    if (state is OrderFormLoaded) {
      final currentState = state as OrderFormLoaded;
      final updatedItems = Map<String, OrderItemQuantity>.from(currentState.selectedItems);

      updatedItems[event.item.id] = OrderItemQuantity(
        item: event.item,
        quantity: event.quantity,
      );

      emit(OrderFormLoaded(
        orderType: currentState.orderType,
        selectedVehicle: currentState.selectedVehicle,
        selectedWarehouse: currentState.selectedWarehouse,
        selectedItems: updatedItems,
        deliveryDate: currentState.deliveryDate,
        availableVehicles: currentState.availableVehicles,
        availableWarehouses: currentState.availableWarehouses,
        availableItems: currentState.availableItems,
        isSubmitting: currentState.isSubmitting,
        errorMessage: currentState.errorMessage,
        isValid: _validateForm(
          vehicle: currentState.selectedVehicle,
          warehouse: currentState.selectedWarehouse,
          items: updatedItems,
        ),
      ));
    }
  }

  void _onItemRemoved(
      ItemRemoved event,
      Emitter<OrderFormState> emit,
      ) {
    if (state is OrderFormLoaded) {
      final currentState = state as OrderFormLoaded;
      final updatedItems = Map<String, OrderItemQuantity>.from(currentState.selectedItems);

      updatedItems.remove(event.itemId);

      emit(currentState.copyWith(
        selectedItems: updatedItems,
        isValid: _validateForm(
          vehicle: currentState.selectedVehicle,
          warehouse: currentState.selectedWarehouse,
          items: updatedItems,
        ),
      ));
    }
  }

  void _onItemQuantityChanged(
      ItemQuantityChanged event,
      Emitter<OrderFormState> emit,
      ) {
    if (state is OrderFormLoaded) {
      final currentState = state as OrderFormLoaded;
      final updatedItems = Map<String, OrderItemQuantity>.from(currentState.selectedItems);

      if (updatedItems.containsKey(event.itemId)) {
        final currentItem = updatedItems[event.itemId]!;

        if (event.quantity <= 0) {
          updatedItems.remove(event.itemId);
        } else {
          updatedItems[event.itemId] = OrderItemQuantity(
            item: currentItem.item,
            quantity: event.quantity,
          );
        }

        emit(currentState.copyWith(
          selectedItems: updatedItems,
          isValid: _validateForm(
            vehicle: currentState.selectedVehicle,
            warehouse: currentState.selectedWarehouse,
            items: updatedItems,
          ),
        ));
      }
    }
  }

  void _onDeliveryDateChanged(
      DeliveryDateChanged event,
      Emitter<OrderFormState> emit,
      ) {
    if (state is OrderFormLoaded) {
      final currentState = state as OrderFormLoaded;
      emit(currentState.copyWith(
        deliveryDate: event.deliveryDate,
      ));
    }
  }

Future<void> _onSubmitOrder(
    SubmitOrder event,
    Emitter<OrderFormState> emit,
) async {
  if (state is OrderFormLoaded) {
    final currentState = state as OrderFormLoaded;

    if (!currentState.isValid) {
      emit(currentState.copyWith(
        errorMessage: 'Please complete all required fields',
      ));
      return;
    }

    emit(currentState.copyWith(isSubmitting: true));

    try {
      // Prepare items for the API
      final List<Map<String, dynamic>> orderItems = currentState.selectedItems.values.map((itemQuantity) {
        return {
          'item_code': itemQuantity.item.id, // Use 'item_code' as required by the API
          'qty': itemQuantity.quantity,      // Use 'qty' as required by the API
        };
      }).toList();

      final formattedDeliveryDate = DateFormat('yyyy-MM-dd').format(currentState.deliveryDate);

      final Map<String, dynamic> orderData = {
        "delivery_date": formattedDeliveryDate,
        "items": orderItems, // Include all items
        "order_type": currentState.orderType,
        "vehicle_number": currentState.selectedVehicle!.registrationNumber,
        "warehouse": currentState.selectedWarehouse!.warehouseName,
      };

      final response = await apiService.createOrder(orderData);

      final orderItems2 = currentState.selectedItems.values.map((itemQuantity) {
        return OrderItem(
          id: itemQuantity.item.id,
          name: itemQuantity.item.name,
          quantity: itemQuantity.quantity,
          unit: itemQuantity.item.type == 'Cylinder' ? 'Cylinder' : 'Unit',
        );
      }).toList();
      final newOrder = Order(
        id: response['id']?.toString() ?? '',
        orderNumber: response['order_number'] ?? '',
        orderType: currentState.orderType,
        status: 'Pending',
        createdAt: DateTime.now(),
        items: orderItems2,
        warehouseId: currentState.selectedWarehouse!.warehouseName,
        vehicleId: currentState.selectedVehicle!.id,
        grandTotal: response['virtual_code'] ?? '',
      );

      emit(OrderFormSubmitted(response['order_number'] ?? '', newOrder));
    } catch (e) {
      print("Error submitting order: $e");
      emit(currentState.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to submit order: $e',
      ));
    }
  }
}

  Future<void> _onLoadVehicles(
      LoadVehicles event,
      Emitter<OrderFormState> emit,
      ) async {
    if (state is OrderFormInitial) {
      emit(OrderFormLoaded(availableVehicles: []));
    }

    if (state is OrderFormLoaded) {
      final currentState = state as OrderFormLoaded;

      try {
        // Fetch vehicles from API
        final vehiclesData = await apiService.getVehicles();

        final List<Vehicle> vehicles = vehiclesData.map<Vehicle>((data) {
          return Vehicle(
            id: data['id']?.toString() ?? '',
            registrationNumber: data['registration'] ?? '',
            cooldownUntil: null,
            isAvailable: data['available'] ?? false,
          );
        }).toList();

        emit(currentState.copyWith(
          availableVehicles: vehicles,
        ));
      } catch (e) {
        print("Error loading vehicles: $e");
        emit(currentState.copyWith(
          errorMessage: 'Failed to load vehicles: $e',
        ));
      }
    }
  }

    Future<void> _onLoadWarehouses(
    LoadWarehouses event,
    Emitter<OrderFormState> emit,
  ) async {
    if (state is OrderFormLoaded) {
      final currentState = state as OrderFormLoaded;

      try {
        // Fetch warehouses from API
        final warehousesData = await apiService.getWarehouses();

        // Parse the response into Warehouse objects
        final List<Warehouse> warehouses = warehousesData.map<Warehouse>((data) {
          return Warehouse(
            name: data.name ?? '',
            warehouseName: data.warehouseName ?? '',
            company: data.company ?? '',
          );
        }).toList();

        // Update the state with the fetched warehouses
        emit(currentState.copyWith(
          availableWarehouses: warehouses,
        ));
      } catch (e) {
        emit(currentState.copyWith(
          errorMessage: 'Failed to load warehouses: $e',
        ));
      }
    }
  }

  Future<void> _onLoadInventoryItems(
      LoadInventoryItems event,
      Emitter<OrderFormState> emit,
      ) async {
    if (state is OrderFormLoaded) {
      final currentState = state as OrderFormLoaded;

      try {
        final warehouseId = event.warehouseId ?? currentState.selectedWarehouse?.warehouseName;

        // If no warehouse selected, return empty list but don't show error
        if (warehouseId == null) {
          emit(currentState.copyWith(
            availableItems: [],
          ));
          return;
        }

        // For testing: add some fixed items so we can see them
        final List<InventoryItem> items = [
          const InventoryItem(
            id: '1',
            name: '14.2kg Domestic Cylinder',
            type: 'Cylinder',
            available: 120,
            reserved: 10,
            nfrType: '',
            item: '',
          ),
          const InventoryItem(
            id: '2',
            name: '5kg Domestic Cylinder',
            type: 'Cylinder',
            available: 45,
            reserved: 5,
            nfrType: '',
            item: '',
          ),
          const InventoryItem(
            id: '3',
            name: 'Standard Regulator',
            type: 'NFR',
            nfrType: 'Regulator',
            available: 75,
            reserved: 0,
            item: '',
          ),
        ];

        print("DEBUG: Loaded ${items.length} items");

        emit(currentState.copyWith(
          availableItems: items,
        ));
      } catch (e) {
        print("Error loading inventory: $e");
      }
    }
  }

  bool _validateForm({
    String? orderType,
    Vehicle? vehicle,
    Warehouse? warehouse,
    Map<String, OrderItemQuantity>? items,
  }) {
    final effectiveOrderType = orderType ?? (state is OrderFormLoaded ? (state as OrderFormLoaded).orderType : null);
    final effectiveVehicle = vehicle ?? (state is OrderFormLoaded ? (state as OrderFormLoaded).selectedVehicle : null);
    final effectiveWarehouse = warehouse ?? (state is OrderFormLoaded ? (state as OrderFormLoaded).selectedWarehouse : null);
    final effectiveItems = items ?? (state is OrderFormLoaded ? (state as OrderFormLoaded).selectedItems : {});

    return effectiveOrderType != null &&
        effectiveVehicle != null &&
        effectiveWarehouse != null &&
        effectiveItems.isNotEmpty;
  }
}

class LoadWarehousesForVehicle extends OrderFormEvent {
  final String vehicleId;

  const LoadWarehousesForVehicle(this.vehicleId);

  @override
  List<Object> get props => [vehicleId];
}
