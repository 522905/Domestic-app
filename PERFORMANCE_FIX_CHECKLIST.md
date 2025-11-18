# Performance Fixes - Developer Checklist

## Phase 1: Critical Blockers (MUST FIX - 1 Hour)

### Task 1.1: Add dispose() to CreateSaleOrderScreen
- **File:** `lib/presentation/pages/orders/forms/create_sale_order_page.dart`
- **Lines:** After line 63
- **Changes:**
  - [ ] Add `@override void dispose()` method
  - [ ] Clear `_selectedItems` list
  - [ ] Clear `_warehouses` list
  - [ ] Clear `_vehicles` list
  - [ ] Call `super.dispose()`
- **Verification:** 
  - [ ] App doesn't crash when opening/closing screen 10 times
  - [ ] Memory decreases after closing screen

### Task 1.2: Implement Cache Limit in OrdersBloc
- **File:** `lib/presentation/blocs/orders/orders_bloc.dart`
- **Changes:**
  - [ ] Add `static const int _maxCacheSize = 100;` near line 9
  - [ ] In `_onLoadMoreOrders()` method (after line 79):
    ```dart
    if (_allOrders.length > _maxCacheSize) {
      _allOrders.removeRange(_maxCacheSize, _allOrders.length);
    }
    ```
  - [ ] In `addNewOrder()` method (after line 332):
    ```dart
    if (_allOrders.length > _maxCacheSize) {
      _allOrders.removeRange(_maxCacheSize, _allOrders.length);
    }
    ```
- **Verification:**
  - [ ] Memory stays < 100MB after scrolling 500+ orders
  - [ ] App doesn't lag when scrolling

### Task 1.3: Add Timeout to Stream Listener
- **File:** `lib/presentation/pages/orders/order_details_page.dart`
- **Lines:** 60-91 (method `_requestOrderAction`)
- **Changes:**
  - [ ] Import: `import 'dart:async';` at top
  - [ ] Wrap the `await` call with `.timeout(Duration(seconds: 30))`
  - [ ] Add try-catch for `TimeoutException`
  - [ ] Show error snackbar on timeout
- **Code template:**
  ```dart
  try {
    final responseState = await context.read<OrdersBloc>().stream
        .firstWhere(
          (state) => state is OrdersLoadedWithResponse || state is OrdersError,
        )
        .timeout(const Duration(seconds: 30));
    // Use responseState
  } on TimeoutException {
    if (mounted) {
      context.showErrorSnackBar('Request timed out after 30 seconds');
    }
  }
  ```
- **Verification:**
  - [ ] Navigate away mid-request - listener doesn't hang
  - [ ] Timeout works after 30 seconds
  - [ ] No crashed state if listener dies

---

## Phase 2: High Priority (Sprint 1 - 2 Hours)

### Task 2.1: Extract Const Styles in OrdersPage
- **File:** `lib/presentation/pages/orders/orders_page.dart`
- **Changes:**
  - [ ] Create `lib/presentation/constants/order_styles.dart`
  - [ ] Move repeated TextStyle definitions to file:
    - [ ] `kFilterChipLabelStyle` (line 373-377)
    - [ ] `kStatusLabelStyle` (line 806-812)
    - [ ] `kOrderCardTitleStyle` (line 793-798)
  - [ ] Import and use in orderspage.dart: `style: kFilterChipLabelStyle`
- **Expected Impact:** Reduces rebuild objects by 60%

### Task 2.2: Move Computations Out of Build
- **File:** `lib/presentation/pages/orders/orders_page.dart`
- **Changes:**
  - [ ] Move `_formatFilterKey()` computation to `build()` start
  - [ ] Cache results in local Map: `Map<String, String> _formattedKeys = {}`
  - [ ] Pre-compute ternary operations in filter dialog
- **Code example:**
  ```dart
  @override
  Widget build(BuildContext context) {
    // Cache computations at start
    final formattedKeys = state.appliedFilters.keys.map((key) {
      return MapEntry(key, _formatFilterKey(key));
    }).toMap();
    
    // Use cached values in map
    ...formattedKeys.entries.map((entry) {
      return _buildAppliedFilterChip('${entry.value}: ${state.appliedFilters[entry.key]}');
    })
  }
  ```

### Task 2.3: Add Image Caching
- **Files:** (5 files to update)
  - [ ] `lib/presentation/pages/cash/cash_transaction_detail_screen.dart`
  - [ ] `lib/presentation/pages/purchase_invoice/receive_vehicle_screen.dart`
  - [ ] `lib/presentation/pages/purchase_invoice/purchase_invoice_details_screen.dart`
  - [ ] `lib/presentation/pages/purchase_invoice/vehicle_history_screen.dart`
  - [ ] `lib/presentation/pages/purchase_invoice/vehicle_history_screen.dart` (appears twice in grep)
- **Steps:**
  - [ ] Add to `pubspec.yaml`:
    ```yaml
    cached_network_image: ^3.2.3
    ```
  - [ ] Run `flutter pub get`
  - [ ] Replace all `Image.network()` calls with `CachedNetworkImage`
  - [ ] Add error placeholders

---

## Phase 3: Medium Priority (Sprint 2 - 3 Hours)

### Task 3.1: Add Search Debounce
- **File:** `lib/presentation/pages/orders/orders_page.dart`
- **Implementation:**
  - [ ] Add `Timer? _searchDebounce;` to `_OrdersPageState`
  - [ ] In `dispose()`: `_searchDebounce?.cancel();`
  - [ ] In search `onChanged()`:
    ```dart
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      context.read<OrdersBloc>().add(SearchOrders(_searchController.text));
    });
    ```

### Task 3.2: Add RepaintBoundary to List Items
- **File:** `lib/presentation/pages/orders/orders_page.dart`
- **Lines:** 750 (in itemBuilder)
- **Change:**
  ```dart
  itemBuilder: (context, index) {
    return RepaintBoundary(
      child: _buildOrderCard(orders[index]),
    );
  }
  ```

### Task 3.3: Optimize OrderDetailsPage
- **File:** `lib/presentation/pages/orders/order_details_page.dart`
- **Changes:**
  - [ ] Move `_fetchUserRole()` out of `initState`
  - [ ] Call it separately after first bloc load
  - [ ] Prevent multiple cascading API calls

---

## Testing & Validation

### Before/After Metrics

Run these commands to measure improvements:

```bash
# Profile memory
flutter run --profile
# Open DevTools > Memory tab
# Perform actions and watch memory graph

# Measure frame rate
flutter run --profile
# Open DevTools > Performance tab
# Scroll through list, check for jank
```

### Acceptance Criteria

- [ ] **Memory Test:** After scrolling 500 orders, memory < 100MB
- [ ] **Scroll Performance:** 60 FPS when scrolling order list
- [ ] **Navigation Test:** Open/close CreateSaleOrderScreen 10x, memory returns to baseline
- [ ] **API Test:** Navigate away mid-request, no listener hangs
- [ ] **Image Loading:** Images cache on second load (no re-download)
- [ ] **Search:** Typing in search doesn't cause lag

### Memory Profiling Steps

1. Open app in profile mode:
   ```bash
   flutter run --profile
   ```

2. Open DevTools:
   - Press `d` in terminal

3. Go to Memory tab

4. Click "Start Recording"

5. Perform user actions:
   - Open Orders page
   - Scroll through 500+ orders
   - Open create order screen
   - Close it
   - Open order details
   - Navigate away mid-operation

6. Stop recording

7. Look for:
   - Memory shouldn't exceed 150MB total
   - Memory returns to 50MB baseline after navigation
   - No sawtooth memory patterns (GC thrashing)

---

## Rollout Plan

### Code Review Checklist

- [ ] All 3 critical issues fixed
- [ ] No new memory leaks introduced
- [ ] All dispose() methods present
- [ ] No API calls without timeout
- [ ] No listeners without cleanup

### Testing Before Push to Dev

```bash
# 1. Run all tests
flutter test

# 2. Static analysis
flutter analyze

# 3. Memory profiling (see above)

# 4. Manual testing on low-end device if available
# Or use Android Emulator with reduced RAM
```

### Verification Checklist

- [ ] No OOM crashes on 500+ orders
- [ ] No jank/lag when scrolling
- [ ] App stays below 150MB memory
- [ ] All dialogs close without hanging
- [ ] Images load faster on second visit
- [ ] Search doesn't cause UI lag

---

## Files to Modify Summary

```
CRITICAL (Must do):
  - lib/presentation/pages/orders/forms/create_sale_order_page.dart (Add dispose)
  - lib/presentation/blocs/orders/orders_bloc.dart (Add cache limit)
  - lib/presentation/pages/orders/order_details_page.dart (Add timeout)

HIGH (Should do):
  - lib/presentation/pages/orders/orders_page.dart (2 changes: styles + computations)
  - lib/presentation/pages/purchase_invoice/*.dart (Image caching - 4 files)

MEDIUM (Nice to have):
  - lib/presentation/pages/orders/orders_page.dart (Add search debounce)
  - lib/presentation/pages/orders/order_details_page.dart (Optimize cascading calls)
```

---

## Questions?

Refer to:
- Full audit: `/PERFORMANCE_AUDIT_REPORT.md`
- Quick summary: `/CRITICAL_FIXES_SUMMARY.md`

