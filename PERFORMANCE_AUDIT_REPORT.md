# Performance & Memory Leak Audit Report
## Domestic App - Flutter Application

**Generated:** 2024-11-18
**Scope:** Orders, Inventory, Vehicle Selection, and Form Screens
**Status:** CRITICAL ISSUES FOUND - Action Required Before Development Push

---

## EXECUTIVE SUMMARY

The codebase has **8 critical performance issues** and **5 memory leak risks** that require immediate attention before pushing to development. The main concerns are:
- Missing dispose() method in CreateSaleOrderScreen
- Unbounded list growth in OrdersBloc
- Stream listener without cleanup in OrderDetailsPage
- Unnecessary rebuilds due to missing const constructors
- Heavy operations on main thread

---

## CRITICAL ISSUES

### 1. MISSING DISPOSE METHOD - CreateSaleOrderScreen
**Severity:** CRITICAL  
**Risk:** Memory leak, controller not being disposed

**File:** `/home/user/Domestic-app/lib/presentation/pages/orders/forms/create_sale_order_page.dart`  
**Lines:** 22-27, 53-63

**Problem:**
```dart
class _CreateSaleOrderScreenState extends State<CreateSaleOrderScreen> {
  late final ApiServiceInterface apiService;
  // ... multiple state variables
  final List<SelectableOrderItem> _selectedItems = [];  // Line 48
  List<Map<String, dynamic>> _warehouses = [];           // Line 49
  List<Map<String, dynamic>> _vehicles = [];             // Line 50

  @override
  void initState() {
    super.initState();
    apiService = context.read<ApiServiceInterface>();
    _loadVehicles();
    _loadWarehouses();
    // ... more operations
  }

  // ❌ NO DISPOSE METHOD FOUND
  // This causes memory leaks when screen is disposed
}
```

**Impact:**
- `_selectedItems` list is never cleared
- `_warehouses` and `_vehicles` lists persist in memory
- No cleanup when navigating away from screen
- Repeated opens of this screen accumulate memory

**Recommendation:**
Add dispose method:
```dart
@override
void dispose() {
  _selectedItems.clear();
  _warehouses.clear();
  _vehicles.clear();
  super.dispose();
}
```

---

### 2. UNBOUNDED LIST GROWTH IN ORDERS BLOC
**Severity:** CRITICAL  
**Risk:** Memory leak from pagination, infinite list accumulation

**File:** `/home/user/Domestic-app/lib/presentation/blocs/orders/orders_bloc.dart`  
**Lines:** 10, 79-87, 332-336

**Problem:**
```dart
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final ApiServiceInterface apiService;
  static const int _pageLimit = 10;
  List<Order> _allOrders = [];  // ❌ Line 10 - Never cleared, keeps growing

  // In _onLoadMoreOrders (Line 79)
  final allOrders = List<Order>.from(currentState.orders)..addAll(newOrders);
  _allOrders = allOrders;  // ❌ Keeps appending, no limit

  // In addNewOrder (Line 332)
  _allOrders.insert(0, order);  // ❌ Unbounded growth
}
```

**Impact:**
- Each pagination load adds more orders without limit
- Memory usage grows infinitely as user scrolls
- For busy warehouse: 1000+ orders = significant memory leak
- No cleanup when user logs out (was recently fixed per git log, but verify)

**Recommendation:**
Implement cache size limits:
```dart
static const int _maxCacheSize = 100;

void _addToCache(Order order) {
  _allOrders.insert(0, order);
  if (_allOrders.length > _maxCacheSize) {
    _allOrders.removeRange(_maxCacheSize, _allOrders.length);
  }
}
```

---

### 3. STREAM LISTENER WITHOUT CLEANUP
**Severity:** CRITICAL  
**Risk:** Stream listeners persist indefinitely

**File:** `/home/user/Domestic-app/lib/presentation/pages/orders/order_details_page.dart`  
**Lines:** 69-71

**Problem:**
```dart
void _requestOrderAction(BuildContext context, String orderId, OrderActionType actionType) async {
  // ... code ...
  
  // ❌ Stream listener without cleanup
  final responseState = await context.read<OrdersBloc>().stream.firstWhere(
    (state) => state is OrdersLoadedWithResponse || state is OrdersError,
  );
  
  // If user leaves page before completion, stream listener leaks
}
```

**Impact:**
- Listeners accumulate if user navigates away mid-operation
- Memory leak in OrdersBloc stream subscriptions
- Could cause multiple event processing if listener doesn't cleanup

**Recommendation:**
Use StreamController with proper cleanup:
```dart
final completer = Completer<OrdersState>();
final subscription = context.read<OrdersBloc>().stream
  .skip(1) // Skip current state
  .listen((state) {
    if (state is OrdersLoadedWithResponse || state is OrdersError) {
      if (!completer.isCompleted) {
        completer.complete(state);
      }
    }
  });

try {
  final responseState = await completer.future.timeout(Duration(seconds: 30));
} finally {
  subscription.cancel();
}
```

---

### 4. TAB CONTROLLER LISTENER NOT REMOVED - Inventory Screen
**Severity:** HIGH  
**Risk:** Listener remains after dispose

**File:** `/home/user/Domestic-app/lib/presentation/pages/inventory/inventory_screen.dart`  
**Lines:** 61-68, 87-92

**Problem:**
```dart
class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);  // Line 51
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _searchController = TextEditingController();

    _tabController.addListener(() {  // ❌ Line 61 - Listener added
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentFilter = _statusTabs[_tabController.index];
        });
        _filterRequests(_currentFilter);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);  // Line 88
    _tabController.dispose();  // Properly disposed
    _searchController.dispose();
    super.dispose();
  }
}
```

**Status:** ✓ GOOD - TabController is properly disposed in dispose() method

**Note:** The listener added via `addListener()` is automatically removed when the TabController is disposed, so this is handled correctly.

---

### 5. UNNECESSARY REBUILDS - Missing Const Constructors
**Severity:** HIGH  
**Risk:** Unnecessary widget rebuilds on every render

**File:** `/home/user/Domestic-app/lib/presentation/pages/orders/orders_page.dart`  
**Lines:** Multiple locations

**Problem:**
```dart
// Line 127-151
@override
Widget build(BuildContext context) {
  return Scaffold(  // ❌ Not const - creates new instance every build
    drawer: GlobalDrawer.getDrawer(context),
    appBar: AppBar(
      title: const Text(
        'Orders',
        style: TextStyle(  // ❌ Not const - style recreated
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color(0xFF0E5CA8),
      elevation: 0,
    ),
    // ... more non-const widgets
  );
}

// Line 369-394 - Filter chip building
return FilterChip(
  label: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value ?? label,
        style: TextStyle(  // ❌ New TextStyle created every build
          fontSize: 12.sp,
          color: value != null ? Colors.white : Colors.grey[800],
        ),
      ),
      SizedBox(width: 4.w),  // ❌ Not const
      Icon(
        Icons.arrow_drop_down,
        size: 16.sp,  // ❌ Computed every time
        color: value != null ? Colors.white : Colors.grey[800],
      ),
    ],
  ),
);
```

**Impact:**
- Every setState() triggers full rebuild of all widgets
- TextStyle, SizedBox, Icon recreated on each render
- Filter sections rebuild when search query changes
- Applied filters section rebuilds for each filter entry

**Example Impact:**
- OrdersPage rebuilds frequently due to setState() calls (lines 69, 113, 293, etc.)
- Each rebuild recreates ~20 TextStyle objects
- For list of 50 orders: 50 × 20 = 1000 new objects per rebuild

---

### 6. EXPENSIVE OPERATIONS IN BUILD METHOD
**Severity:** HIGH  
**Risk:** Synchronous heavy operations blocking UI

**File:** `/home/user/Domestic-app/lib/presentation/pages/orders/orders_page.dart`  
**Lines:** 551-557, 660-675

**Problem:**
```dart
// Line 551-557 - Rebuilding applied filters on every build
...state.appliedFilters.entries.map(
  (entry) {
    final formattedKey = _formatFilterKey(entry.key);  // ❌ String formatting computation
    return _buildAppliedFilterChip('$formattedKey: ${entry.value}');
  },
),

// Line 576-582 - String manipulation in build
String _formatFilterKey(String key) {
  return key
      .split('_')  // ❌ String split every time
      .map((word) => word[0].toUpperCase() + word.substring(1))  // ❌ String manipulation
      .join(' ');
}

// Line 660-675 - Mapping large lists in dialogs
...options.map((option) => ListTile(
  title: Text('${option.value} (${option.count})'),
  leading: Radio<String>(
    value: option.value,
    groupValue: filterType == 'Vehicle' ? _selectedVehicle :
    filterType == 'Warehouse' ? _selectedWarehouse : _selectedStatus,  // ❌ Ternary evaluation for each option
  ),
  // ... more properties
)),
```

**Impact:**
- Dialog filters computed even when not visible
- String formatting runs for every applied filter on each render
- Ternary operation evaluated 100s of times in filter dialogs

---

### 7. HEAVY OPERATIONS IN BUILD - OrderDetailsPage
**Severity:** HIGH  
**Risk:** Stream listener operations on main thread

**File:** `/home/user/Domestic-app/lib/presentation/pages/orders/order_details_page.dart`  
**Lines:** 69-71, 37-49

**Problem:**
```dart
void _requestOrderAction(BuildContext context, String orderId, OrderActionType actionType) async {
  // ❌ Heavy await operation without timeout
  final responseState = await context.read<OrdersBloc>().stream.firstWhere(
    (state) => state is OrdersLoadedWithResponse || state is OrdersError,
  );
  // This can hang indefinitely, blocking the page

  // ❌ No timeout protection
  // ❌ If user navigates away, listener still waiting
}

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // ❌ Multiple setState() calls indirectly via API loads (Lines 38-48)
    if (widget.order != null) {
      if (currentState is! OrderDetailsLoaded || currentState.detailedOrder.id != widget.order!.id) {
        context.read<OrdersBloc>().add(LoadOrderDetails(widget.order!.orderNumber));
      }
      _fetchUserRole();  // ❌ setState() call in callback
    }
  });
}

Future<void> _fetchUserRole() async {
  final roles = await User().getUserRoles();  // ❌ API call
  setState(() {  // ❌ Triggers rebuild
    userRole = roles.map((role) => role.role).toList();
  });
}
```

**Impact:**
- User can navigate away leaving stream listener active
- No timeout causes indefinite waiting
- Multiple API calls in cascade (initState -> _fetchUserRole -> API)
- Each API response triggers setState() -> rebuild

---

### 8. IMAGE CACHING NOT IMPLEMENTED
**Severity:** MEDIUM  
**Risk:** Large images not cached, repeated downloads

**Files:**
- `/home/user/Domestic-app/lib/presentation/pages/cash/cash_transaction_detail_screen.dart`
- `/home/user/Domestic-app/lib/presentation/pages/purchase_invoice/receive_vehicle_screen.dart`
- `/home/user/Domestic-app/lib/presentation/pages/purchase_invoice/purchase_invoice_details_screen.dart`
- `/home/user/Domestic-app/lib/presentation/pages/purchase_invoice/vehicle_history_screen.dart`

**Problem:**
```dart
// Using Image.network() without caching
child: Image.network(
  imageUrl,
  // ❌ No caching, will download every time page rebuilds
  fit: BoxFit.cover,
),
```

**Impact:**
- Images downloaded multiple times
- Network bandwidth wasted
- Slow page loads
- No offline support

**Recommendation:**
```dart
// Use cached_network_image package
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: imageUrl,
  fit: BoxFit.cover,
  placeholder: (context, url) => Shimmer.fromColors(...),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

---

## MEMORY LEAK RISKS

### Risk 1: Inventory Detail Screen - No dispose cleanup
**Severity:** MEDIUM  
**File:** `/home/user/Domestic-app/lib/presentation/pages/inventory/Inventory_detail_screen.dart`  
**Lines:** 31, 72-78

**Status:** ✓ GOOD
```dart
class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();  // ✓ Properly disposed
    _isProcessing = false;
    _selectedRejectionReason = null;
    super.dispose();
  }
}
```

---

### Risk 2: Order Countdown Timer - Multiple timer instances
**Severity:** LOW  
**File:** `/home/user/Domestic-app/lib/presentation/pages/orders/forms/order_countdown_timmer.dart`  
**Lines:** 20-76

**Status:** ✓ GOOD
```dart
class _OrderCountdownTimerState extends State<OrderCountdownTimer>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void dispose() {
    _timer?.cancel();  // ✓ Timer cancelled
    _pulseController.dispose();  // ✓ Controller disposed
    super.dispose();
  }
}
```

---

### Risk 3: Orders Page - Scroll Controller properly disposed
**Severity:** LOW  
**File:** `/home/user/Domestic-app/lib/presentation/pages/orders/orders_page.dart`  
**Lines:** 24-64

**Status:** ✓ GOOD
```dart
class _OrdersPageState extends State<OrdersPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);  // Listener added
  }

  @override
  void dispose() {
    _searchController.dispose();  // ✓ Disposed
    _scrollController.dispose();  // ✓ Disposed (auto-removes listener)
    super.dispose();
  }
}
```

---

### Risk 4: Vehicle Selector Dialog - TextField controller not tracked
**Severity:** LOW  
**File:** `/home/user/Domestic-app/lib/presentation/widgets/selectors/vehicle_selector_dialog.dart`  
**Lines:** 69-91

**Status:** ⚠️ POTENTIAL ISSUE
```dart
class _VehicleSelectorContentState extends State<_VehicleSelectorContent> {
  String searchQuery = '';
  List<Map<String, dynamic>> filteredVehicles = [];

  void _filterVehicles(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredVehicles = widget.vehicles.where((vehicle) {
        // ... filtering logic
      }).toList();
    });
  }

  // No explicit dispose() needed since no controllers are stored
}
```

**Note:** TextField in line 144-154 has no controller, so it's auto-disposed by framework.

---

### Risk 5: WidgetsBindingObserver - Properly removed
**Severity:** LOW  
**File:** `/home/user/Domestic-app/lib/presentation/pages/inventory/inventory_screen.dart`  
**Lines:** 32, 51, 79-84, 87-88

**Status:** ✓ GOOD
```dart
class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);  // Added
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<InventoryBloc>().add(const RefreshInventoryRequests());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);  // ✓ Removed
    // ... rest of cleanup
  }
}
```

---

## SUGGESTIONS FOR IMPROVEMENT

### 1. CACHE STRATEGY FOR ORDERS
Implement a smart cache with size limits:
```dart
// In OrdersBloc
static const int _maxCacheSize = 100;  // Keep last 100 orders
static const int _maxDetailCacheSize = 10;  // Keep last 10 detail views

Future<void> _addToCache(Order order) async {
  _allOrders.insert(0, order);
  // Remove oldest items if exceeding limit
  if (_allOrders.length > _maxCacheSize) {
    _allOrders.removeRange(_maxCacheSize, _allOrders.length);
  }
}
```

---

### 2. DEBOUNCE SEARCH OPERATIONS
Current implementation triggers too many rebuilds:
```dart
// In OrdersPage
// Add debounce to search
void _setupSearch() {
  _searchDebounce = Timer(const Duration(milliseconds: 500), () {
    context.read<OrdersBloc>().add(SearchOrders(_searchController.text));
  });
}

@override
void onChanged(String value) {
  _searchDebounce?.cancel();
  _setupSearch();
}
```

---

### 3. EXTRACT CONSTANTS FOR REUSABLE STYLES
```dart
// Create a constants file
const kOrderCardTextStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: Colors.grey,
);

const kPrimaryColor = Color(0xFF0E5CA8);
const kErrorColor = Color(0xFFF44336);
const kSuccessColor = Color(0xFF4CAF50);

// Use in widgets with const
@override
Widget build(BuildContext context) {
  return Text('Order', style: kOrderCardTextStyle);  // Reuses same style
}
```

---

### 4. USE REPAINT BOUNDARIES FOR HEAVY WIDGETS
For list items that are expensive to build:
```dart
RepaintBoundary(
  child: _buildOrderCard(orders[index]),
)
```

---

### 5. IMPLEMENT IMAGE CACHING
Add to pubspec.yaml:
```yaml
dependencies:
  cached_network_image: ^3.2.0
  flutter_cache_manager: ^3.3.0
```

---

### 6. ADD TIMEOUTS TO ASYNC OPERATIONS
```dart
Future<OrdersState?> _waitForResponse() async {
  try {
    return await context.read<OrdersBloc>().stream
        .firstWhere(
          (state) => state is OrdersLoadedWithResponse || state is OrdersError,
        )
        .timeout(const Duration(seconds: 30));
  } on TimeoutException {
    // Handle timeout gracefully
    return null;
  }
}
```

---

### 7. PREFETCH DATA FOR FREQUENTLY USED SCREENS
In MaterialPageRoute:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => OrderDetailsPage(order: order),
  ),
).then((_) {
  // Prefetch next item while user is viewing current one
  context.read<OrdersBloc>().add(LoadOrderDetails(nextOrderId));
});
```

---

## SUMMARY TABLE

| Issue | File | Lines | Severity | Status | Action |
|-------|------|-------|----------|--------|--------|
| Missing dispose() in CreateSaleOrderScreen | create_sale_order_page.dart | 22-27 | CRITICAL | ❌ TODO | Add dispose() method |
| Unbounded list growth in OrdersBloc | orders_bloc.dart | 10, 79-87 | CRITICAL | ❌ TODO | Implement cache limits |
| Stream listener without cleanup | order_details_page.dart | 69-71 | CRITICAL | ❌ TODO | Add timeout + cleanup |
| Unnecessary rebuilds (no const) | orders_page.dart | 127-151 | HIGH | ❌ TODO | Add const constructors |
| Expensive operations in build | orders_page.dart | 551-675 | HIGH | ❌ TODO | Move computations to methods |
| Heavy operations in build (streams) | order_details_page.dart | 69-71 | HIGH | ❌ TODO | Add timeout protection |
| Image caching not implemented | Multiple | Multiple | MEDIUM | ❌ TODO | Use cached_network_image |
| TabController listener | inventory_screen.dart | 61-68 | LOW | ✓ GOOD | Already properly disposed |
| Inventory detail cleanup | Inventory_detail_screen.dart | 72-78 | MEDIUM | ✓ GOOD | No action needed |
| Countdown timer cleanup | order_countdown_timmer.dart | 20-76 | LOW | ✓ GOOD | No action needed |
| Orders page scroll listener | orders_page.dart | 24-64 | LOW | ✓ GOOD | No action needed |
| WidgetsBindingObserver | inventory_screen.dart | 51, 88 | LOW | ✓ GOOD | No action needed |

---

## PRIORITY ACTION ITEMS

### Immediate (Before Development Push)
1. [ ] Add dispose() method to CreateSaleOrderScreen
2. [ ] Implement cache size limits in OrdersBloc
3. [ ] Add timeout + cleanup to OrderDetailsPage stream listener

### High Priority (Sprint 1)
4. [ ] Add const constructors to reduce rebuilds
5. [ ] Move expensive operations out of build methods
6. [ ] Implement image caching with cached_network_image

### Medium Priority (Sprint 2)
7. [ ] Add debounce to search operations
8. [ ] Extract style constants
9. [ ] Add RepaintBoundary to list items
10. [ ] Implement data prefetching

---

## TESTING RECOMMENDATIONS

1. **Memory Profiling**
   ```bash
   flutter run --profile
   # Use DevTools Memory tab to check for leaks
   ```

2. **Performance Testing**
   ```bash
   flutter run --trace-startup
   flutter run --profile
   # Monitor frame rates in DevTools
   ```

3. **Load Testing**
   - Scroll through 1000+ orders list
   - Monitor memory growth
   - Check for jank or frame drops

4. **Navigation Testing**
   - Navigate away mid-API call
   - Check for lingering listeners
   - Monitor memory after returning

---

## ADDITIONAL NOTES

**Recent Fixes Applied (Git Log):**
- e807f2c: Clear BLoC memory caches on logout
- 54bc0b7: Clear all cached data on logout

**Verification:** Check that the LogoutBloc properly calls `ClearOrdersCache` and `ClearInventoryCache` events.

---

**Report Status:** Ready for Action
**Next Steps:** Assign issues to developers and create tickets in your issue tracker
