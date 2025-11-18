# CRITICAL FIXES REQUIRED BEFORE DEVELOPMENT PUSH

## 3 IMMEDIATE BLOCKERS

### 1. Missing dispose() - CreateSaleOrderScreen
**File:** `/home/user/Domestic-app/lib/presentation/pages/orders/forms/create_sale_order_page.dart`  
**Lines:** Add after line 63

```dart
@override
void dispose() {
  _selectedItems.clear();
  _warehouses.clear();
  _vehicles.clear();
  super.dispose();
}
```

**Why:** Memory leak when screen is dismissed. Lists persist in memory causing OOM on repeated opens.

---

### 2. Unbounded List Growth - OrdersBloc
**File:** `/home/user/Domestic-app/lib/presentation/blocs/orders/orders_bloc.dart`  
**Issue:** Line 10 - `List<Order> _allOrders = []` grows infinitely

**Quick Fix:** Add cache size management in `_onLoadMoreOrders` (line 79):
```dart
static const int _maxCacheSize = 100;

// After line 79:
final allOrders = List<Order>.from(currentState.orders)..addAll(newOrders);
_allOrders = allOrders;

// Add size limit:
if (_allOrders.length > _maxCacheSize) {
  _allOrders.removeRange(_maxCacheSize, _allOrders.length);
}
```

**Why:** Infinite scrolling leads to memory bloat. 1000+ orders = 20-30MB of wasted memory per session.

---

### 3. Stream Listener Leak - OrderDetailsPage
**File:** `/home/user/Domestic-app/lib/presentation/pages/orders/order_details_page.dart`  
**Lines:** 69-71

**Problem:**
```dart
final responseState = await context.read<OrdersBloc>().stream.firstWhere(
  (state) => state is OrdersLoadedWithResponse || state is OrdersError,
);
```

**Fix:** Add timeout and cleanup:
```dart
try {
  final responseState = await context.read<OrdersBloc>().stream.firstWhere(
    (state) => state is OrdersLoadedWithResponse || state is OrdersError,
  ).timeout(const Duration(seconds: 30));
  
  // Use responseState
} on TimeoutException {
  if (mounted) {
    context.showErrorSnackBar('Operation timed out');
  }
}
```

**Why:** If user navigates away, listener stays active. Multiple rapid actions accumulate listeners = memory leak.

---

## SUMMARY OF ALL ISSUES

| # | Issue | File | Severity | Est. Time |
|---|-------|------|----------|-----------|
| 1 | Missing dispose() | create_sale_order_page.dart | CRITICAL | 5 min |
| 2 | Unbounded list | orders_bloc.dart | CRITICAL | 15 min |
| 3 | Stream listener leak | order_details_page.dart | CRITICAL | 20 min |
| 4 | Unnecessary rebuilds | orders_page.dart | HIGH | 30 min |
| 5 | Build method computations | orders_page.dart | HIGH | 20 min |
| 6 | Image caching | Multiple files | MEDIUM | 45 min |
| 7 | Heavy stream ops | order_details_page.dart | HIGH | 25 min |

**Total Time to Fix Critical Issues:** ~1 hour

---

## TESTING CHECKLIST

After fixes, run these tests:

- [ ] Scroll through 500+ orders - check memory in DevTools
- [ ] Repeatedly open/close CreateSaleOrderScreen - check memory
- [ ] Navigate away during approval request - check for hung listeners
- [ ] Open order details 10 times - verify no listener accumulation

**Memory targets:**
- Initial load: < 50MB
- After scrolling 500 orders: < 100MB
- After 10 detail views: < 120MB

---

## DO NOT PUSH WITHOUT FIXING

This report identifies issues that will cause:
- **OOM crashes** on devices with < 2GB RAM
- **Jank/lag** when scrolling large lists
- **Data leaks** if sensitive info stays in memory after logout
- **Battery drain** from continuous garbage collection

All three critical issues MUST be fixed before code review.

