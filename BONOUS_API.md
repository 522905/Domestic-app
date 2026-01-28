# Bonus APIs for Flutter App

## Overview

These APIs allow the Flutter app to display bonus quota information to delivery partners. Bonuses are earned when partners maintain high posting ratios (SDMS sales vs pickups) and can be used as additional quota for future pickups.

## Use Cases

### 1. View Bonus Schemes
**User Story**: As a delivery partner, I want to understand how bonuses are calculated so I can maximize my earnings.

The `/bonus-schemes/` endpoint returns the active bonus calculation rules, including:
- Target posting ratio required to earn bonus (e.g., 90%)
- Bonus percentage earned (e.g., 10% of net pickups)
- Validity period (e.g., 2 days)

### 2. View My Bonuses
**User Story**: As a delivery partner, I want to see all my bonuses grouped by status so I can track what I've earned, used, and lost.

The `/bonuses/` endpoint returns:
- Summary statistics (counts and quantities by status)
- Paginated list of bonuses with filtering and sorting
- Urgency indicators for bonuses expiring soon

### 3. View Bonus Details
**User Story**: As a delivery partner, I want to see the details of a specific bonus including how it was calculated.

The `/bonuses/<id>/` endpoint returns:
- Full bonus details with consumption tracking
- Source metrics showing the calculation inputs (pickups, returns, sales, posting ratio)

---

## Authentication

All endpoints require JWT authentication with company context.

```
Authorization: Bearer <jwt_token>
```

The JWT token must include `active_company_id` claim. User must have a `DeliveryBoyRole` associated with a partner.

**Error Response (403 Forbidden)**:
```json
{
  "error": "User is not a delivery boy"
}
```

---

## API Endpoints

### 1. GET `/api/quotas/bonus-schemes/`

Returns all active bonus schemes with their configuration and any partner-specific overrides.

#### Query Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `include_inactive` | boolean | `false` | Include inactive schemes |

#### Response

```json
{
  "schemes": [
    {
      "id": 1,
      "name": "default",
      "description": "Standard 10% bonus for maintaining 90% posting ratio",
      "is_active": true,
      "config": {
        "target_posting_ratio": 0.90,
        "bonus_percentage": 0.10,
        "validity_days": 2
      },
      "partner_overrides": {
        "target_posting_ratio": 0.85,
        "bonus_percentage": 0.12
      }
    }
  ]
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `schemes` | array | List of bonus schemes |
| `schemes[].id` | integer | Unique scheme identifier |
| `schemes[].name` | string | Scheme name (e.g., "default", "festive_bonus") |
| `schemes[].description` | string | Human-readable description |
| `schemes[].is_active` | boolean | Whether scheme is currently active |
| `schemes[].config` | object | Global configuration values |
| `schemes[].config.target_posting_ratio` | decimal | Required posting ratio (0.0-1.0) |
| `schemes[].config.bonus_percentage` | decimal | Bonus rate (0.0-1.0) |
| `schemes[].config.validity_days` | integer | Days until bonus expires |
| `schemes[].partner_overrides` | object | Partner-specific overrides (optional, only present if partner has custom config) |

#### Example Usage

```dart
// Fetch bonus schemes
final response = await dio.get('/api/quotas/bonus-schemes/');
final schemes = response.data['schemes'] as List;

for (final scheme in schemes) {
  final config = scheme['config'];
  final overrides = scheme['partner_overrides'];

  // Use override if exists, otherwise use global config
  final targetRatio = overrides?['target_posting_ratio'] ?? config['target_posting_ratio'];
  final bonusPct = overrides?['bonus_percentage'] ?? config['bonus_percentage'];

  print('To earn bonus: Maintain ${(targetRatio * 100).toStringAsFixed(0)}% posting ratio');
  print('Bonus earned: ${(bonusPct * 100).toStringAsFixed(0)}% of net pickups');
}
```

---

### 2. GET `/api/quotas/bonuses/`

Returns partner's bonuses with summary statistics. Supports filtering, sorting, and pagination.

#### Query Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `status` | string | `all` | Filter by status (see Status Filter Values) |
| `item_code` | string | - | Filter by product (e.g., `M0087`) |
| `scheme` | string | - | Filter by bonus scheme name (e.g., `default`) |
| `sort` | string | `-earned_date` | Sort field with optional `-` prefix for descending |
| `page` | integer | `1` | Page number |
| `page_size` | integer | `20` | Items per page (max: 100) |

#### Status Filter Values

| Value | Description | Query Logic |
|-------|-------------|-------------|
| `active` | Unused bonuses | `status=ACTIVE AND quantity_consumed=0 AND expiry_date >= today` |
| `partially_consumed` | Partially used | `status=ACTIVE AND quantity_consumed > 0 AND expiry_date >= today` |
| `consumed` | Fully used | `status=FULLY_CONSUMED` |
| `expired` | Expired (used or unused) | `status=EXPIRED OR (status=ACTIVE AND expiry_date < today)` |
| `all` | All bonuses | No filter |

#### Sort Fields

| Field | Description |
|-------|-------------|
| `earned_date` | Date bonus was earned |
| `expiry_date` | Date bonus expires |
| `quantity_remaining` | Remaining quantity |
| `quantity_earned` | Original quantity |

Prefix with `-` for descending order (e.g., `-earned_date`).

#### Response

```json
{
  "summary": {
    "total_active": 5,
    "total_active_quantity": 120,
    "total_consumed": 15,
    "total_consumed_quantity": 380,
    "total_expired": 8,
    "total_expired_quantity": 95,
    "expiring_soon": 2,
    "expiring_soon_quantity": 30
  },
  "count": 28,
  "page": 1,
  "page_size": 20,
  "total_pages": 2,
  "next": "http://api.example.com/api/quotas/bonuses/?page=2",
  "previous": null,
  "results": [
    {
      "id": 123,
      "item_code": "M0087",
      "item_name": "14 KG Cylinder",
      "earned_date": "2026-01-22",
      "expiry_date": "2026-01-24",
      "quantity_earned": 10,
      "quantity_consumed": 3,
      "quantity_remaining": 7,
      "status": "ACTIVE",
      "status_display": "Active",
      "consumption_percentage": 30.0,
      "days_until_expiry": 0,
      "expiry_urgency": "expiring_today",
      "strategy_name": "default"
    },
    {
      "id": 122,
      "item_code": "M0087",
      "item_name": "14 KG Cylinder",
      "earned_date": "2026-01-21",
      "expiry_date": "2026-01-23",
      "quantity_earned": 8,
      "quantity_consumed": 8,
      "quantity_remaining": 0,
      "status": "FULLY_CONSUMED",
      "status_display": "Fully Consumed",
      "consumption_percentage": 100.0,
      "days_until_expiry": null,
      "expiry_urgency": null,
      "strategy_name": "default"
    }
  ]
}
```

#### Response Fields

**Summary Object**

| Field | Type | Description |
|-------|------|-------------|
| `total_active` | integer | Count of active bonuses (unused + partially consumed, not expired) |
| `total_active_quantity` | integer | Total remaining quantity in active bonuses |
| `total_consumed` | integer | Count of fully consumed bonuses |
| `total_consumed_quantity` | integer | Total quantity that was consumed |
| `total_expired` | integer | Count of expired bonuses |
| `total_expired_quantity` | integer | Total quantity that expired unused |
| `expiring_soon` | integer | Count of bonuses expiring within 3 days |
| `expiring_soon_quantity` | integer | Total remaining quantity expiring within 3 days |

**Pagination Fields**

| Field | Type | Description |
|-------|------|-------------|
| `count` | integer | Total number of bonuses matching filter |
| `page` | integer | Current page number |
| `page_size` | integer | Items per page |
| `total_pages` | integer | Total number of pages |
| `next` | string/null | URL for next page |
| `previous` | string/null | URL for previous page |

**Result Item Fields**

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique bonus identifier |
| `item_code` | string | Product code (e.g., "M0087") |
| `item_name` | string | Product name (e.g., "14 KG Cylinder") |
| `earned_date` | date | Date bonus was earned (YYYY-MM-DD) |
| `expiry_date` | date | Date bonus expires (YYYY-MM-DD) |
| `quantity_earned` | integer | Original bonus quantity |
| `quantity_consumed` | integer | Quantity used so far |
| `quantity_remaining` | integer | Quantity still available |
| `status` | string | Status code: `ACTIVE`, `FULLY_CONSUMED`, `EXPIRED`, `VOIDED` |
| `status_display` | string | Human-readable status |
| `consumption_percentage` | float | Percentage consumed (0.0-100.0) |
| `days_until_expiry` | integer/null | Days until expiry (null if expired/consumed) |
| `expiry_urgency` | string/null | Urgency level (see Expiry Urgency Values) |
| `strategy_name` | string | Name of bonus scheme that created this bonus |

**Expiry Urgency Values**

| Value | Condition |
|-------|-----------|
| `expiring_today` | `days_until_expiry == 0` |
| `expiring_tomorrow` | `days_until_expiry == 1` |
| `expiring_soon` | `days_until_expiry <= 3` |
| `null` | `days_until_expiry > 3` or bonus is expired/consumed |

#### Example Usage

```dart
// Fetch active bonuses expiring soon
final response = await dio.get('/api/quotas/bonuses/', queryParameters: {
  'status': 'active',
  'sort': 'expiry_date',  // Soonest expiring first
  'page_size': 10,
});

final summary = response.data['summary'];
final bonuses = response.data['results'] as List;

// Show warning if bonuses expiring soon
if (summary['expiring_soon'] > 0) {
  showWarning('${summary['expiring_soon']} bonuses (${summary['expiring_soon_quantity']} qty) expiring within 3 days!');
}

// Display bonus list with urgency indicators
for (final bonus in bonuses) {
  final urgency = bonus['expiry_urgency'];
  final icon = urgency == 'expiring_today' ? '🔴'
             : urgency == 'expiring_tomorrow' ? '🟠'
             : urgency == 'expiring_soon' ? '🟡'
             : '🟢';

  print('$icon ${bonus['item_name']}: ${bonus['quantity_remaining']} remaining');
}
```

---

### 3. GET `/api/quotas/bonuses/<id>/`

Returns detailed information for a single bonus including the source metrics used to calculate it.

#### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | integer | Bonus ID |

#### Response

```json
{
  "id": 123,
  "item_code": "M0087",
  "item_name": "14 KG Cylinder",
  "earned_date": "2026-01-22",
  "expiry_date": "2026-01-24",
  "quantity_earned": 10,
  "quantity_consumed": 3,
  "quantity_remaining": 7,
  "status": "ACTIVE",
  "status_display": "Active",
  "consumption_percentage": 30.0,
  "days_until_expiry": 0,
  "strategy": {
    "id": 1,
    "name": "default",
    "description": "Standard 10% bonus for maintaining 90% posting ratio"
  },
  "source_metrics": {
    "pickups": 100,
    "returns": 5,
    "net_pickups": 95,
    "otp_sales": 20,
    "override_sales": 70,
    "confirmed_sales": 90,
    "posting_ratio": 94.7,
    "bonus_calculated": 10
  },
  "created_at": "2026-01-22T18:30:00Z"
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique bonus identifier |
| `item_code` | string | Product code |
| `item_name` | string | Product name |
| `earned_date` | date | Date bonus was earned |
| `expiry_date` | date | Date bonus expires |
| `quantity_earned` | integer | Original bonus quantity |
| `quantity_consumed` | integer | Quantity used so far |
| `quantity_remaining` | integer | Quantity still available |
| `status` | string | Status code |
| `status_display` | string | Human-readable status |
| `consumption_percentage` | float | Percentage consumed |
| `days_until_expiry` | integer/null | Days until expiry |
| `strategy` | object | Bonus scheme info |
| `strategy.id` | integer | Scheme ID |
| `strategy.name` | string | Scheme name |
| `strategy.description` | string | Scheme description |
| `source_metrics` | object | Metrics used to calculate this bonus |
| `created_at` | datetime | When bonus was created (ISO 8601) |

**Source Metrics Fields**

| Field | Type | Description |
|-------|------|-------------|
| `pickups` | integer | Total cylinders picked up that day |
| `returns` | integer | Cylinders returned |
| `net_pickups` | integer | Pickups minus returns |
| `otp_sales` | integer | Sales with OTP verification |
| `override_sales` | integer | Sales with manager override |
| `confirmed_sales` | integer | Total confirmed sales (OTP + override) |
| `posting_ratio` | float | Percentage of net pickups posted to SDMS |
| `bonus_calculated` | integer | Bonus quantity calculated |

#### Error Responses

**404 Not Found** - Bonus doesn't exist or belongs to another partner:
```json
{
  "error": "Bonus not found"
}
```

#### Example Usage

```dart
// Fetch bonus details
final response = await dio.get('/api/quotas/bonuses/123/');
final bonus = response.data;

// Display bonus calculation breakdown
final metrics = bonus['source_metrics'];
print('Bonus Calculation for ${bonus['earned_date']}:');
print('  Pickups: ${metrics['pickups']}');
print('  Returns: ${metrics['returns']}');
print('  Net Pickups: ${metrics['net_pickups']}');
print('  Confirmed Sales: ${metrics['confirmed_sales']}');
print('  Posting Ratio: ${metrics['posting_ratio']}%');
print('  Bonus Earned: ${bonus['quantity_earned']}');
```

---

## Error Handling

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 400 | Bad request (invalid parameters) |
| 401 | Unauthorized (missing/invalid token) |
| 403 | Forbidden (user is not a delivery boy) |
| 404 | Not found (bonus doesn't exist or unauthorized) |
| 428 | Precondition required (missing company claim in JWT) |

### Error Response Format

```json
{
  "error": "Error message here"
}
```

---

## Flutter Implementation Notes

### Data Models

```dart
class BonusScheme {
  final int id;
  final String name;
  final String description;
  final bool isActive;
  final Map<String, dynamic> config;
  final Map<String, dynamic>? partnerOverrides;

  // Computed getters
  double get targetPostingRatio =>
    (partnerOverrides?['target_posting_ratio'] ?? config['target_posting_ratio']) as double;
  double get bonusPercentage =>
    (partnerOverrides?['bonus_percentage'] ?? config['bonus_percentage']) as double;
  int get validityDays =>
    (partnerOverrides?['validity_days'] ?? config['validity_days']) as int;
}

class BonusSummary {
  final int totalActive;
  final int totalActiveQuantity;
  final int totalConsumed;
  final int totalConsumedQuantity;
  final int totalExpired;
  final int totalExpiredQuantity;
  final int expiringSoon;
  final int expiringSoonQuantity;
}

class Bonus {
  final int id;
  final String itemCode;
  final String itemName;
  final DateTime earnedDate;
  final DateTime expiryDate;
  final int quantityEarned;
  final int quantityConsumed;
  final int quantityRemaining;
  final String status;
  final String statusDisplay;
  final double consumptionPercentage;
  final int? daysUntilExpiry;
  final String? expiryUrgency;
  final String strategyName;

  // For detail view
  final BonusScheme? strategy;
  final Map<String, dynamic>? sourceMetrics;
  final DateTime? createdAt;

  bool get isExpiringSoon => expiryUrgency != null;
  bool get isActive => status == 'ACTIVE';
  bool get isFullyConsumed => status == 'FULLY_CONSUMED';
}
```

### UI Recommendations

1. **Dashboard Card**: Show `expiring_soon` count and quantity prominently with warning color
2. **List View**: Use tabs for status filters (Active, Consumed, Expired, All)
3. **Urgency Indicators**: Use color-coded badges:
    - Red: `expiring_today`
    - Orange: `expiring_tomorrow`
    - Yellow: `expiring_soon`
4. **Progress Bar**: Show `consumption_percentage` visually
5. **Detail View**: Show source metrics in a collapsible section for transparency

### Caching Strategy

- **Bonus schemes**: Cache for 24 hours (rarely changes)
- **Bonus list**: Cache for 5 minutes, invalidate on pickup/return actions
- **Bonus detail**: Cache for 5 minutes

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-24 | Initial release |
