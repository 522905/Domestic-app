# Offline Delivery API Changes — Flutter Update Guide

This document covers API changes made **after** the initial `OFFLINE_DELIVERY_FLUTTER_GUIDE.md` was written. Apply these updates to your existing implementation.

---

## 1. Distribution Points — `warehouse` replaced with `physical_site`

Distribution points are **no longer company-specific**. The `warehouse` field has been replaced with `physical_site`.

### What changed

| Before | After |
|--------|-------|
| `warehouse` field (company-scoped warehouse) | `physical_site` field (global physical location) |
| Response included `warehouse: { id, name }` | Response includes `physical_site: { id, name }` |
| Points filtered by company on the server | All active points returned (no company filter) |

### Updated response — `GET /api/offline-delivery/distribution-points/`

```json
[
  {
    "id": "a1b2c3d4-...",
    "name": "Sherpur Godown Gate",
    "physical_site": {
      "id": 3,
      "name": "Sherpur Store"
    },
    "is_adhoc": false,
    "allow_quick_delivery": true,
    "is_active": true,
    "today_token_count": 42
  }
]
```

`physical_site` can be `null` (same as `warehouse` could be before).

### Flutter action required

- Rename model field: `warehouse` → `physicalSite`
- Update JSON parsing: read `physical_site` instead of `warehouse`
- The object shape is the same (`{ id, name }`) — only the key name changed
- Remove any company-based filtering logic for distribution points on the client side (the server no longer does it)

---

## 2. Paginated List Responses

Both **booking verifications** and **tokens** list endpoints now return paginated responses instead of plain arrays.

### What changed

**Before** — plain array:
```json
[
  { "id": "...", ... },
  { "id": "...", ... }
]
```

**After** — paginated envelope:
```json
{
  "count": 85,
  "next": "https://api.example.com/api/offline-delivery/tokens/?page=2",
  "previous": null,
  "results": [
    { "id": "...", ... },
    { "id": "...", ... }
  ]
}
```

### Pagination parameters

| Parameter | Type | Default | Max | Description |
|-----------|------|---------|-----|-------------|
| `page` | int | `1` | — | Page number |
| `page_size` | int | `20` | `100` | Items per page |

### Affected endpoints

| Endpoint | Notes |
|----------|-------|
| `GET /api/offline-delivery/booking-verifications/` | List verifications |
| `GET /api/offline-delivery/tokens/` | List tokens |

### Response fields

| Field | Type | Description |
|-------|------|-------------|
| `count` | int | Total number of matching records |
| `next` | string or null | Full URL to next page, `null` if last page |
| `previous` | string or null | Full URL to previous page, `null` if first page |
| `results` | array | Array of records for this page |

### Flutter action required

- Update the response parser for both list endpoints to unwrap the paginated envelope
- Read items from `response["results"]` instead of the top-level array
- Use `count` for total count display
- Use `next` / `previous` for infinite scroll or page navigation
- Pass `?page=N` and optionally `?page_size=N` in requests

### Example — loading with pagination

```
GET /api/offline-delivery/tokens/?distribution_point_id=abc&page=1&page_size=30
```

```json
{
  "count": 74,
  "next": ".../tokens/?distribution_point_id=abc&page=2&page_size=30",
  "previous": null,
  "results": [ ... 30 tokens ... ]
}
```

To load next page:
```
GET /api/offline-delivery/tokens/?distribution_point_id=abc&page=2&page_size=30
```

---

## 3. Search — New `search` Query Parameter

Both **booking verifications** and **tokens** list endpoints now support a `search` query parameter for free-text filtering.

### Booking verifications — `GET /api/offline-delivery/booking-verifications/`

| Parameter | Searches across |
|-----------|----------------|
| `search` | `consumer_id`, `consumer_number`, `consumer_name`, `order_number` |

### Tokens — `GET /api/offline-delivery/tokens/`

| Parameter | Searches across |
|-----------|----------------|
| `search` | `consumer_id`, `consumer_number`, `consumer_name`, `consumer_name_manual`, `order_number` |

Search is **case-insensitive** and matches **partial strings** (contains match).

### Combining with existing filters

Search works alongside all existing query parameters:

```
GET /api/offline-delivery/tokens/?distribution_point_id=abc&status=DELIVERED&search=kumar&page=1
```

This returns page 1 of delivered tokens at distribution point `abc` where any of the searchable fields contain "kumar".

### Complete query parameter reference

**Booking verifications:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | Filter by status: `QUEUED`, `PROCESSING`, `VERIFIED`, `BOOKING_CREATED`, `FAILED` |
| `distribution_point_id` | UUID | Filter by distribution point |
| `company_id` | int | **NEW** — Filter by company (distributor) |
| `date` | YYYY-MM-DD | Filter by date (defaults to today) |
| `search` | string | **NEW** — Free-text search |
| `page` | int | **NEW** — Page number (default: 1) |
| `page_size` | int | **NEW** — Items per page (default: 20, max: 100) |

**Tokens:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `distribution_point_id` | UUID | Filter by distribution point |
| `company_id` | int | **NEW** — Filter by company (distributor) |
| `status` | string | Filter by status: `TOKEN_ISSUED`, `DELIVERED`, `VOIDED` |
| `reconciliation_status` | string | Filter by reconciliation status |
| `created_by` | int | Filter by user ID |
| `is_delivered` | `true`/`false` | Shorthand for delivered/not-delivered |
| `date` | YYYY-MM-DD | Filter by token date (defaults to today) |
| `search` | string | **NEW** — Free-text search |
| `page` | int | **NEW** — Page number (default: 1) |
| `page_size` | int | **NEW** — Items per page (default: 20, max: 100) |

### Flutter action required

- Add a search text field in the token list and verification list UIs
- Debounce search input (300-500ms recommended) before making API calls
- Pass `?search=<text>` with list requests
- Reset to `page=1` whenever the search text changes

---

## 4. Company-Agnostic Design — Delivery Boy Selects the Distributor

The entire offline delivery system is now **company-agnostic**. The delivery boy's JWT active company is **not used** for any offline delivery operation. Instead, the delivery boy explicitly selects which company (distributor) each verification or token belongs to.

The RPA booking verification and reconciliation processes will correct any company mistakes later — the priority at the distribution point is getting consumers served.

### New endpoint — available companies

```
GET /api/offline-delivery/companies/
```

Returns all companies configured for SDMS (i.e., have a distributor code):

```json
[
  {
    "id": 1,
    "name": "ABC Gas Agency",
    "short_code": "ABC",
    "sdms_dist_code": "1234567890"
  },
  {
    "id": 2,
    "name": "XYZ LPG Distributors",
    "short_code": "XYZ",
    "sdms_dist_code": "0987654321"
  }
]
```

### `company_id` is now required in all create requests

The following create endpoints now require a `company_id` field in the request body:

| Endpoint | New required field |
|----------|-------------------|
| `POST /api/offline-delivery/booking-verifications/` | `company_id` (int) |
| `POST /api/offline-delivery/tokens/` | `company_id` (int) |
| `POST /api/offline-delivery/tokens/quick-deliver/` | `company_id` (int) |

The `company_id` must be a valid company with a non-empty `sdms_dist_code`. The server validates this and returns an error if invalid.

### Example — create booking verification

```json
POST /api/offline-delivery/booking-verifications/

{
  "company_id": 1,
  "distribution_point_id": "a1b2c3d4-...",
  "consumer_id": "12345678"
}
```

### Example — create token

```json
POST /api/offline-delivery/tokens/

{
  "company_id": 1,
  "distribution_point_id": "a1b2c3d4-...",
  "consumer_id": "12345678",
  "creation_type": "STANDARD"
}
```

### Example — quick deliver

```json
POST /api/offline-delivery/tokens/quick-deliver/

{
  "company_id": 1,
  "distribution_point_id": "a1b2c3d4-...",
  "consumer_id": "12345678",
  "cash_collected": 1103.50
}
```

### Company in responses

All verification and token responses now include a `company` object:

```json
{
  "company": {
    "id": 1,
    "name": "ABC Gas Agency",
    "sdms_dist_code": "1234567890"
  }
}
```

This appears in: booking verification list, token list, and token detail responses.

### List filtering by company

Both list endpoints now support `?company_id=` as an optional filter:

```
GET /api/offline-delivery/tokens/?distribution_point_id=abc&company_id=1
GET /api/offline-delivery/booking-verifications/?company_id=1
```

Tokens list shows **all tokens at the distribution point** (across all companies) by default. Use `?company_id=` to narrow down.

Booking verifications list shows **all verifications created by the authenticated user** (across all companies) by default.

### Flutter action required

1. **Fetch companies on app start**: Call `GET /api/offline-delivery/companies/` and cache the list
2. **Company selector UI**: Add a company/distributor picker to the verification and token creation flows. This can be a dropdown or radio button — typically the delivery boy works with 1-2 distributors
3. **Send `company_id`**: Include `company_id` in all create request bodies (verifications, tokens, quick deliver)
4. **Parse company in responses**: Read the `company` object from verification and token responses
5. **Remove JWT company dependency**: The offline delivery module does not use the JWT's active company at all

---

## Summary of All Breaking Changes

| # | Change | Breaking? | Action |
|---|--------|-----------|--------|
| 1 | `warehouse` → `physical_site` in distribution point response | **Yes** | Rename field in model + JSON parsing |
| 2 | List responses wrapped in pagination envelope | **Yes** | Read from `results` array, handle `count`/`next`/`previous` |
| 3 | `company_id` now required in create requests (was auto-set from JWT) | **Yes** | Add company selector UI, send `company_id` in request body |
| 4 | New `GET /api/offline-delivery/companies/` endpoint | No (new) | Fetch and cache company list for picker UI |
| 5 | `company` object added to verification and token responses | No (additive) | Parse and display distributor info |
| 6 | `search` query parameter added to list endpoints | No (additive) | Implement search UI and pass parameter |
| 7 | `company_id` filter added to list endpoints | No (additive) | Optionally filter lists by company |
| 8 | Distribution points no longer company-filtered | No (server returns superset) | Remove any client-side company filtering |
| 9 | Token list no longer company-scoped | **Behavior change** | Shows all tokens at point, not just one company's. Use `?company_id=` to filter |
