# SDMS Claims - Flutter App Integration Guide

**Version:** 1.3
**Last Updated:** 2026-02-11

---

## Changelog

### v1.3 (2026-02-11)

**Transfer List — Sorted by Actionability:**
- The `GET /transfers/` endpoint now returns results **sorted by `can_approve` descending**, then by `created_at` descending. Transfers that need the current user's action appear first, followed by all other transfers in reverse chronological order. The Flutter client should render the list in the order returned by the API — no client-side sorting needed.

**New field: `can_reject`:**
- Transfer list and detail responses now include a `can_reject` boolean alongside `can_approve`. Both follow the same permission rule (only the original delivery boy on a PENDING transfer). Use `can_approve` and `can_reject` to conditionally show/hide the Approve and Reject buttons.

**UX Clarification — Transfer List is the Approval Screen:**
- The Transfers list (`GET /transfers/`) is intended to be the **primary approvals screen**, not a sub-screen nested inside an order. Do not navigate to transfers through order drill-down. Instead, the Flutter app should have a dedicated "Approvals" or "Tasks" screen that directly calls `GET /transfers/`. Items with `can_approve: true` / `can_reject: true` will naturally appear at the top. The client should show Approve/Reject buttons only on those items, and display all other transfers (resolved or belonging to others) below as read-only history.
- Internal statuses like unclaimed orders from the delivery register are backend-only concerns and **should not be surfaced** on the Flutter client.

### v1.2 (2026-02-11)

**Breaking Changes:**
- **`intended_claimant` renamed to `intended_partner`.** The Create Order API now accepts a **Partner ID** (DB primary key from the Partner API) instead of a User ID. The backend resolves the associated user via `DeliveryBoyRole`. See [Create Order](#2-create-order-submit-order-id).

**New: Partner Lookup API:**
- **`GET /api/users/api/masters/partners/`** — Use this endpoint to populate the delivery boy picker when `claim_for_self=false`. Returns `{id, partner_id, partner_name, is_active}`. The `id` field is what you pass as `intended_partner`. See [Partner Lookup API](#10-partner-lookup-for-claim-on-behalf).

### v1.1 (2026-02-11)

**Breaking Changes:**
- **Order Detail `dpc_posting` response changed.** The old flat fields (`erp_dpc_name`, `erp_dpc_created`, `erp_dpc_claimed`) are removed. Replaced with a nested `dpc_posting` object containing `settlement_name`, `accrual_status`, `allocation_status`, `settlement_status`, `allocated_to_erp`, `is_overridden`, `override_reason`, `error`. See [Order Detail](#3-get-order-detail) and [DPC Posting Object](#dpc-posting-object-new-in-v11).
- **Create Order request body updated.** `order_date` removed (populated by RPA). New `claim_for_self` boolean field added (default `true`).

**New Features:**
- **Dual-track ERP status display.** Digital payment postings now have 3 independent status tracks: Accrual (doc created), Allocation (credit assigned), Settlement (IOCL paid). The old single-status DPC flow is replaced.
- **`claim_for_self` parameter.** Explicitly indicate whether the delivery boy is claiming for themselves or on behalf of another. Defaults to `true`.

**Deprecations:**
- `erp_dpc_name`, `erp_dpc_created`, `erp_dpc_claimed` fields removed from Order Detail response. Use `dpc_posting.settlement_name`, `dpc_posting.accrual_status`, `dpc_posting.allocation_status` instead.

### v1.0 (2025-06-15)

- Initial release.

---

## Overview

The SDMS Claims system tracks SDMS (government LPG portal) orders that need to be "claimed" by delivery boys. When a delivery boy makes a delivery, the corresponding SDMS order needs to be fetched from the portal, verified, and assigned to the correct person for accounting purposes.

**Base URL:** `/api/sdms-claims/`

**Authentication:** All endpoints require JWT authentication. Include `Authorization: Bearer <token>` header. The JWT must contain an `active_company_id` claim (set during login/switch-company).

---

## Core Concepts

### What is an SDMS Order?

An SDMS Order represents a single delivery transaction in the government LPG portal. It can be a:
- **Refill** (most common) - Regular cylinder refill delivery
- **Service Order** (SV, TV_IN, TV_OUT, Conversion, Addon) - New connection, termination, etc.

Each order goes through two independent workflows:
1. **Data Fetch** (`data_status`) - RPA bot fetches order details from the SDMS portal
2. **Claim** (`claim_status`) - A delivery boy claims the order as theirs

For online payment orders, there is a third workflow:
3. **ERP Posting** (`dpc_posting`) - Three independent tracks: Accrual, Allocation, Settlement

### The Claim Flow (Flutter App Perspective)

```
Delivery boy enters order_id
        |
        v
  POST /orders/  (creates order, triggers RPA)
        |
        v
  data_status: QUEUED -> PROCESSING -> COMPLETE
  claim_status: PENDING_DATA -> UNCLAIMED
        |
        v
  [Auto-claim logic runs]
        |
        +-- Same person? -> CLAIMED (done!)
        +-- System post? -> CLAIMED (done!)
        +-- Different person? -> PENDING_APPROVAL (transfer created)
                |
                +-- Original approves -> CLAIMED
                +-- Original rejects -> CLAIMED (for original)
                +-- No response 24h+ -> CLAIMED (auto-approved for requester)
```

### ERP Digital Payment Posting (Online Orders Only)

When an online payment order is claimed, the backend creates an IOCL Digital Payment Settlement in ERPNext. This has three independent status tracks:

```
Accrual:     PENDING -> CREATED  (settlement doc created in ERP)
                   \-> FAILED

Allocation:  UNALLOCATED -> ALLOCATED          (credit assigned directly)
                        \-> PENDING_APPROVAL -> ALLOCATED  (needs admin approval)
                                           \-> UNALLOCATED (rejected, retry)
                        \-> FAILED

Settlement:  UNSETTLED -> SETTLED  (IOCL has paid, via DPR batch)
                     \-> FAILED
```

The Flutter app should display these as informational status indicators. No user action is needed - allocation and settlement are handled by admins and batch processes.

### Who Can Claim?

| Scenario | What Happens |
|----------|-------------|
| Delivery boy enters their own order | Auto-claimed immediately after RPA completes |
| Delivery boy enters someone else's order | Transfer request created, original must approve |
| System-posted order (Siebel) | Auto-claimed for whoever entered it |
| Order from Delivery Register | Not auto-claimed, waits for explicit claim |

---

## Enums Reference

Use these string values in filters and when interpreting responses.

### `order_category`
| Value | Display | Description |
|-------|---------|-------------|
| `REFILL` | Refill | Regular cylinder refill |
| `SV` | Subscription Voucher | New connection |
| `TV_IN` | Termination Voucher In | Connection termination (incoming) |
| `TV_OUT` | Termination Voucher Out | Connection termination (outgoing) |
| `CONVERSION` | Conversion | Cylinder type conversion |
| `ADDON` | Addon | Additional cylinder |
| `UNKNOWN` | Unknown | Not yet classified (RPA pending) |

### `payment_mode`
| Value | Display | Description |
|-------|---------|-------------|
| `CASH` | Cash | Cash payment |
| `ONLINE` | Online | Digital/online payment (creates settlement in ERP) |
| `UNKNOWN` | Unknown | Not yet determined |

### `posting_type`
| Value | Display | Description |
|-------|---------|-------------|
| `NORMAL` | Normal | Delivery boy posted in SDMS |
| `SYSTEM` | System | Auto-posted by SDMS (Siebel channel) |
| `UNKNOWN` | Unknown | Not yet determined |

### `data_status` (RPA data fetch)
| Value | Display | Description | User Action |
|-------|---------|-------------|-------------|
| `QUEUED` | Queued | Waiting for RPA to start | Show spinner |
| `PROCESSING` | Processing | RPA is fetching data | Show spinner |
| `COMPLETE` | Complete | Data fetched successfully | Show order details |
| `FAILED` | Failed | RPA error (retryable) | Show retry button |
| `INCIDENT` | Incident | Delivery boy lookup failed | Show "contact admin" |
| `PENDING_COMPLETION` | Pending Completion | Order not yet completed in SDMS | Show "try again later" |

### `claim_status`
| Value | Display | Description | User Action |
|-------|---------|-------------|-------------|
| `PENDING_DATA` | Pending Data | Waiting for RPA | Show spinner |
| `UNCLAIMED` | Unclaimed | Ready to claim | Show "Claim" button |
| `PENDING_APPROVAL` | Pending Approval | Transfer awaiting approval | Show transfer status |
| `CLAIMED` | Claimed | Successfully claimed | Show claimed badge |
| `REJECTED` | Rejected | Claim rejected by system | Show reason |

### `settlement_status`
| Value | Display |
|-------|---------|
| `N/A` | Not Applicable (cash order) |
| `UNSETTLED` | Unsettled (online payment, awaiting DPR) |
| `SETTLED` | Settled (DPR received) |

### `accrual_status` (new in v1.1)
| Value | Display | Description |
|-------|---------|-------------|
| `PENDING` | Pending | Settlement doc not yet created |
| `CREATED` | Created | Settlement doc created in ERP |
| `FAILED` | Failed | Creation failed |

### `allocation_status` (new in v1.1)
| Value | Display | Description |
|-------|---------|-------------|
| `UNALLOCATED` | Unallocated | Credit not yet assigned |
| `PENDING_APPROVAL` | Pending Approval | Needs admin approval |
| `ALLOCATED` | Allocated | Credit assigned to delivery boy |
| `FAILED` | Failed | Allocation failed |

### `dpc_settlement_status` (new in v1.1)
| Value | Display | Description |
|-------|---------|-------------|
| `UNSETTLED` | Unsettled | IOCL has not paid yet |
| `SETTLED` | Settled | IOCL payment received |
| `FAILED` | Failed | Settlement failed |

### `source`
| Value | Display |
|-------|---------|
| `FLUTTER_APP` | Flutter App |
| `DELIVERY_REGISTER` | Delivery Register |
| `DPR_IMPORT` | DPR Import |

### `claim_transfer_status`
| Value | Display |
|-------|---------|
| `PENDING` | Pending |
| `APPROVED` | Approved |
| `REJECTED` | Rejected |
| `AUTO_APPROVED` | Auto Approved |

---

## API Endpoints

### 1. List Orders

```
GET /api/sdms-claims/orders/
```

Returns a paginated list of SDMS orders for the current company.

**Query Parameters (all optional):**

| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `order_category` | string | `REFILL` | Filter by category |
| `data_status` | string | `COMPLETE` | Filter by RPA status |
| `claim_status` | string | `UNCLAIMED` | Filter by claim status |
| `settlement_status` | string | `UNSETTLED` | Filter by settlement |
| `source` | string | `FLUTTER_APP` | Filter by source |
| `from_date` | date | `2025-01-01` | Order date >= |
| `to_date` | date | `2025-01-31` | Order date <= |
| `is_mine` | string | `true` | Only orders related to current user |

**Response (200):**

```json
[
    {
        "id": "a1b2c3d4-...",
        "order_id": "123456789",
        "order_date": "2025-06-15",
        "order_category": "REFILL",
        "payment_mode": "ONLINE",
        "posting_type": "NORMAL",
        "data_status": "COMPLETE",
        "claim_status": "UNCLAIMED",
        "settlement_status": "UNSETTLED",
        "amount": "1053.00",
        "consumer_name": "MOHD ASHRAF",
        "original_delivery_boy_name": "Farooq Ahmad",
        "claimed_by_name": null,
        "source": "FLUTTER_APP",
        "created_at": "2025-06-15T10:30:00+05:30",
        "is_mine": true,
        "can_claim": true,
        "can_retry": false
    }
]
```

**Key fields for UI:**
- `is_mine` — Highlight orders that belong to the current user
- `can_claim` — Enable/disable the "Claim" button
- `can_retry` — Enable/disable the "Retry" button

---

### 2. Create Order (Submit Order ID)

```
POST /api/sdms-claims/orders/
```

This is the primary entry point from the Flutter app. The delivery boy enters an SDMS order ID, and the backend starts the RPA process to fetch order details.

**Request Body:**

```json
{
    "order_id": "123456789",
    "claim_for_self": true
}
```

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `order_id` | string | Yes | - | SDMS order ID (from the delivery slip) |

| `claim_for_self` | boolean | No | `true` | Whether the current user is claiming for themselves |
| `intended_partner` | integer | Conditional | - | Partner ID (DB primary key, i.e. the `id` field from the Partner API). **Required when `claim_for_self` is `false`**. Ignored when `claim_for_self` is `true`. |

**`claim_for_self` behavior:**
- `true` (default): The current user is the intended claimant. No need to pass `intended_partner`. The backend resolves the partner from the current user's `DeliveryBoyRole`.
- `false`: Claiming on behalf of another delivery boy. Must provide `intended_partner` (partner DB ID from [Partner API](#10-partner-lookup-for-claim-on-behalf)). The partner must have a `DeliveryBoyRole` in the current company.

**Example: Claiming on behalf of someone else:**

```json
{
    "order_id": "123456789",
    "claim_for_self": false,
    "intended_partner": 7
}
```

**Response (201 Created) — New order:**

```json
{
    "message": "Order created successfully",
    "created": true,
    "order": {
        "id": "a1b2c3d4-...",
        "order_id": "123456789",
        "order_date": null,
        "data_status": "QUEUED",
        "claim_status": "PENDING_DATA",
        ...
    }
}
```

> **Note:** `order_date` is `null` at creation. It is populated automatically by the RPA process when it fetches order details from the SDMS portal.

**Response (200 OK) — Duplicate (already exists):**

```json
{
    "message": "Order 123456789 already exists",
    "created": false,
    "order": {
        "id": "a1b2c3d4-...",
        "order_id": "123456789",
        "data_status": "COMPLETE",
        "claim_status": "CLAIMED",
        ...
    }
}
```

**Response (400) — Validation errors:**

```json
{
    "order_id": ["This field may not be blank."],
    "claim_for_self": ["You have no delivery boy role in this company"],
    "intended_partner": ["Required when claim_for_self is false"]
}
```

**Flutter UX Flow:**

1. Show text input for `order_id`
2. Optionally show a toggle/switch for "Claim for self" (default on). If off, show a delivery boy picker for `intended_claimant`.
3. On submit, call `POST /orders/`
4. If `created: true` -> navigate to order detail, show loading state
5. If `created: false` -> navigate to the existing order detail
6. If duplicate with `claim_status: CLAIMED` -> show "Already claimed by {name}"
7. If 400 -> show validation errors inline

---

### 3. Get Order Detail

```
GET /api/sdms-claims/orders/{id}/
```

Returns full order details including items (for service orders) and ERP posting status.

**Response (200):**

```json
{
    "id": "a1b2c3d4-...",
    "order_id": "123456789",
    "order_date": "2025-06-15",
    "order_category": "REFILL",
    "payment_mode": "ONLINE",
    "posting_type": "NORMAL",
    "data_status": "COMPLETE",
    "claim_status": "CLAIMED",
    "settlement_status": "UNSETTLED",
    "amount": "1053.00",
    "consumer_name": "MOHD ASHRAF",
    "original_delivery_boy_name": "Farooq Ahmad",
    "claimed_by_name": "Farooq Ahmad",
    "source": "FLUTTER_APP",
    "created_at": "2025-06-15T10:30:00+05:30",
    "is_mine": true,
    "can_claim": false,
    "can_retry": false,

    "delivery_date": "2025-06-15",
    "order_subtype_raw": "Refill",
    "consumer_number": "REL-12345",
    "consumer_address": "Srinagar, Kashmir",
    "consumer_phone": "9876543210",
    "sdms_user_code": "DB001",
    "sdms_delivery_boy_name": "Farooq Ahmad",
    "intended_claimant": null,
    "auto_claimed": true,
    "rejection_reason": "",

    "dpc_posting": {
        "settlement_name": "IOCL-DPS-2025-00001",
        "accrual_status": "CREATED",
        "allocation_status": "ALLOCATED",
        "settlement_status": "UNSETTLED",
        "allocated_to_erp": "PARTNER-001",
        "is_overridden": false,
        "override_reason": "",
        "error": ""
    },
    "so_posting": null,

    "quota_adjusted": false,
    "camunda_process_id": "proc-123",
    "retry_count": 0,
    "rpa_error": "",
    "items": [],
    "updated_at": "2025-06-15T10:35:00+05:30"
}
```

#### DPC Posting Object (new in v1.1)

The `dpc_posting` field is `null` if no digital payment posting exists (cash orders, or RPA not yet complete). For online payment orders, it contains:

| Field | Type | Description |
|-------|------|-------------|
| `settlement_name` | string | ERPNext document name (e.g. `IOCL-DPS-2025-00001`) |
| `accrual_status` | enum | `PENDING`, `CREATED`, `FAILED` |
| `allocation_status` | enum | `UNALLOCATED`, `PENDING_APPROVAL`, `ALLOCATED`, `FAILED` |
| `settlement_status` | enum | `UNSETTLED`, `SETTLED`, `FAILED` |
| `allocated_to_erp` | string | ERPNext Customer ID who got credit |
| `is_overridden` | boolean | Whether allocation was overridden by admin |
| `override_reason` | string | Reason for override (if any) |
| `error` | string | Last error message (if any track failed) |

**How to display DPC status in the UI:**

| Condition | Display | Color |
|-----------|---------|-------|
| `dpc_posting` is `null` | Don't show DPC section | - |
| `accrual_status == "PENDING"` | "ERP: Pending" | Grey |
| `accrual_status == "CREATED"` and `allocation_status == "ALLOCATED"` | "ERP: Allocated" | Green |
| `accrual_status == "CREATED"` and `allocation_status == "PENDING_APPROVAL"` | "ERP: Awaiting Approval" | Orange |
| `accrual_status == "CREATED"` and `allocation_status == "UNALLOCATED"` | "ERP: Unallocated" | Blue |
| `settlement_status == "SETTLED"` | "ERP: Settled" | Green |
| Any status is `"FAILED"` | "ERP: Failed" | Red |

#### SO Posting Object

The `so_posting` field is `null` if no service order posting exists. For service orders, it contains:

| Field | Type | Description |
|-------|------|-------------|
| `status` | enum | `PENDING`, `SUCCESS`, `FAILED` |
| `service_order_name` | string | ERPNext Service Order document name |
| `error` | string | Error message if failed |

**Items (`items` array):**
- Only present for service orders (SV, TV_IN, TV_OUT, etc.)
- Empty array `[]` for refill orders
- `direction: "ISSUE"` = items delivered TO customer
- `direction: "COLLECT"` = items collected FROM customer

---

### 4. Claim Order

```
POST /api/sdms-claims/orders/{id}/claim/
```

Claim an order for the current user. No request body needed — the backend resolves the user's delivery boy role and partner automatically.

**Request Body:** Empty `{}` or omitted.

**Response (200) — Direct claim (you are the original):**

```json
{
    "message": "Order claimed successfully",
    "success": true,
    "order": {
        "claim_status": "CLAIMED",
        "claimed_by_name": "Farooq Ahmad",
        ...
    }
}
```

**Response (200) — Transfer created (you are NOT the original):**

```json
{
    "message": "Transfer request created. Will auto-approve on June 17 at 09:00 AM",
    "success": true,
    "order": {
        "claim_status": "PENDING_APPROVAL",
        ...
    }
}
```

**Response (400) — Not claimable:**

```json
{
    "message": "Order is not claimable (status=CLAIMED)",
    "success": false,
    "order": { "..." : "..." }
}
```

**Response (400) — No delivery boy role:**

```json
{
    "message": "No delivery boy role found for current user"
}
```

**Flutter UX Flow:**

1. Show "Claim" button only when `can_claim == true`
2. On tap, call `POST /orders/{id}/claim/`
3. If `success: true`:
   - If `order.claim_status == "CLAIMED"` -> show success with green checkmark
   - If `order.claim_status == "PENDING_APPROVAL"` -> show info banner: "Transfer request sent to {original_delivery_boy_name}. Will auto-approve on {date}."
4. If `success: false` -> show error toast with `message`

---

### 5. Retry Failed Order

```
POST /api/sdms-claims/orders/{id}/retry/
```

Retry an order whose RPA data fetch failed. No request body needed.

**Response (200):**

```json
{
    "message": "Order queued for retry (attempt 2)",
    "order": {
        "data_status": "QUEUED",
        "retry_count": 2,
        "..."  : "..."
    }
}
```

**Response (400):**

```json
{
    "message": "Order cannot be retried (status=COMPLETE, retries=3)"
}
```

**Flutter UX Flow:**

1. Show "Retry" button only when `can_retry == true`
2. On tap, call `POST /orders/{id}/retry/`
3. If success -> transition to loading state, poll for updates
4. If failed -> show error toast

---

### 6. List Claim Transfers (Approvals Screen)

```
GET /api/sdms-claims/transfers/
```

Returns all claim transfers for the current company, **sorted by actionability**: transfers that need the current user's approval appear first (`can_approve: true`), followed by all others in reverse chronological order.

> **Important:** This endpoint is intended to power a dedicated **"Approvals" or "Tasks" screen** in the Flutter app. Do not nest this inside order detail navigation. The list is pre-sorted — render it in the order returned.

**Response (200):**

```json
[
    {
        "id": "d4e5f6g7-...",
        "order_id": "123456789",
        "order_date": "2025-06-15",
        "order_amount": "1053.00",
        "from_user_name": "Farooq Ahmad",
        "to_user_name": "Bilal Dar",
        "status": "PENDING",
        "auto_approve_at": "2025-06-17T09:00:00+05:30",
        "resolved_at": null,
        "rejection_reason": "",
        "can_approve": true,
        "can_reject": true,
        "created_at": "2025-06-15T14:00:00+05:30"
    },
    {
        "id": "e5f6g7h8-...",
        "order_id": "987654321",
        "order_date": "2025-06-14",
        "order_amount": "850.00",
        "from_user_name": "Ali Shah",
        "to_user_name": "Farooq Ahmad",
        "status": "APPROVED",
        "auto_approve_at": "2025-06-16T09:00:00+05:30",
        "resolved_at": "2025-06-15T11:00:00+05:30",
        "rejection_reason": "",
        "can_approve": false,
        "can_reject": false,
        "created_at": "2025-06-14T16:00:00+05:30"
    }
]
```

**Key fields:**
- `can_approve` — `true` only if current user is `from_user` (original) and status is `PENDING`. Show the **Approve** button only when `true`.
- `can_reject` — `true` under the same conditions as `can_approve`. Show the **Reject** button only when `true`.
- `auto_approve_at` — Show as countdown: "Auto-approves in X hours"

**Flutter UX:**
- Items with `can_approve: true` appear at the top — show Approve/Reject action buttons on these cards.
- Items with `can_approve: false` appear below — render as read-only history (show status badge: Approved, Rejected, Auto-Approved, or Pending on someone else).

---

### 7. Get Transfer Detail

```
GET /api/sdms-claims/transfers/{id}/
```

Returns full transfer details including nested order detail.

**Response (200):**

```json
{
    "id": "d4e5f6g7-...",
    "order_id": "123456789",
    "order_date": "2025-06-15",
    "order_amount": "1053.00",
    "from_user_name": "Farooq Ahmad",
    "to_user_name": "Bilal Dar",
    "status": "PENDING",
    "auto_approve_at": "2025-06-17T09:00:00+05:30",
    "resolved_at": null,
    "rejection_reason": "",
    "can_approve": true,
    "can_reject": true,
    "created_at": "2025-06-15T14:00:00+05:30",
    "order_detail": {
        "id": "a1b2c3d4-...",
        "order_id": "123456789",
        "order_category": "REFILL",
        "payment_mode": "ONLINE",
        "amount": "1053.00",
        "consumer_name": "MOHD ASHRAF",
        "dpc_posting": {
            "settlement_name": "",
            "accrual_status": "PENDING",
            "allocation_status": "UNALLOCATED",
            "settlement_status": "UNSETTLED",
            "..."  : "..."
        },
        "..."  : "..."
    },
    "notification_sent_at": "2025-06-15T14:00:05+05:30",
    "updated_at": "2025-06-15T14:00:05+05:30"
}
```

---

### 8. Approve Transfer

```
POST /api/sdms-claims/transfers/{id}/approve/
```

Only the original delivery boy (`from_user`) can approve. No request body needed.

**Response (200):**

```json
{
    "message": "Transfer approved successfully",
    "success": true
}
```

**Response (400):**

```json
{
    "message": "Only the original owner can approve this transfer",
    "success": false
}
```

---

### 9. Reject Transfer

```
POST /api/sdms-claims/transfers/{id}/reject/
```

Only the original delivery boy (`from_user`) can reject.

**Request Body (optional):**

```json
{
    "reason": "I delivered this order myself"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `reason` | string | No | Optional rejection reason |

**Response (200):**

```json
{
    "message": "Transfer rejected. Credit claimed by original owner.",
    "success": true
}
```

---

### 10. Partner Lookup (for Claim on Behalf)

```
GET /api/users/api/masters/partners/
```

> **Note:** This endpoint is outside the `/api/sdms-claims/` namespace. It is part of the Users/Masters API.

Use this to populate the delivery boy picker when `claim_for_self=false`. Returns all active partners.

**Query Parameters (all optional):**

| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `search` | string | `Farooq` | Search by `partner_id` or `partner_name` |
| `ordering` | string | `partner_name` | Order by field (`partner_name`, `partner_id`, `is_active`) |
| `show_inactive` | string | `true` | Include inactive partners (default `false`) |

**Response (200):**

```json
[
    {
        "id": 7,
        "partner_id": "CUST-00123",
        "partner_name": "Farooq Ahmad",
        "is_active": true
    },
    {
        "id": 12,
        "partner_id": "CUST-00456",
        "partner_name": "Bilal Dar",
        "is_active": true
    }
]
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | **This is what you pass as `intended_partner` in Create Order** |
| `partner_id` | string | ERPNext Customer ID (for display, e.g. `CUST-00123`) |
| `partner_name` | string | Delivery boy / partner name |
| `is_active` | boolean | Whether the partner is active |

**Flutter UX Flow:**
1. When user unchecks "Claiming for myself", show a searchable dropdown
2. Fetch partners: `GET /api/users/api/masters/partners/?search={query}`
3. Display `partner_name` in the dropdown
4. On selection, store the `id` value
5. Pass as `intended_partner` in the Create Order request

**Validation note:** If the selected partner does not have a `DeliveryBoyRole` in the current company, the Create Order API will return a `400` error:
```json
{
    "intended_partner": ["Partner Farooq Ahmad has no delivery boy role in this company"]
}
```

---

## Flutter Screen Designs

### Screen 1: Order Entry (Home Action)

**Purpose:** Delivery boy enters an SDMS order ID to start the claim process.

```
+----------------------------------+
|  Enter SDMS Order                |
|                                  |
|  Order ID                        |
|  +----------------------------+  |
|  | 123456789                  |  |
|  +----------------------------+  |
|                                  |
|  [x] Claiming for myself         |
|                                  |
|  (If unchecked, show picker:)    |
|  Delivery Boy                    |
|  +----------------------------+  |
|  | Select delivery boy...     |  |
|  +----------------------------+  |
|                                  |
|  +----------------------------+  |
|  |        Submit Order        |  |
|  +----------------------------+  |
+----------------------------------+
```

**Behavior:**
- "Claiming for myself" checkbox defaults to checked (`claim_for_self: true`)
- When unchecked, show a delivery boy picker that resolves to a `user_id` for `intended_claimant`
- On submit -> `POST /orders/`
- If `created: true` -> navigate to Order Detail screen (loading state)
- If `created: false` -> navigate to existing Order Detail screen
- If duplicate with `claim_status: CLAIMED` -> show "Already claimed by {name}"

---

### Screen 2: My Orders (List)

**Purpose:** Shows orders related to the current delivery boy.

**API Call:** `GET /orders/?is_mine=true`

```
+----------------------------------+
|  My Orders                       |
|  +------------------------------+|
|  | * 123456789    15 Jun 2025  ||
|  |   REFILL . ONLINE . Rs1,053 ||
|  |   Fetching data...           ||
|  +------------------------------+|
|  +------------------------------+|
|  | * 987654321    15 Jun 2025  ||
|  |   SV . CASH . Rs4,500       ||
|  |   Claimed                    ||
|  +------------------------------+|
|  +------------------------------+|
|  | * 555666777    14 Jun 2025  ||
|  |   REFILL . ONLINE . Rs1,053 ||
|  |   Transfer pending           ||
|  +------------------------------+|
+----------------------------------+
```

**Status badge logic:**

| `data_status` | `claim_status` | Badge | Color |
|---------------|----------------|-------|-------|
| `QUEUED` or `PROCESSING` | `PENDING_DATA` | "Fetching data..." | Grey |
| `FAILED` | any | "Failed - Tap to retry" | Red |
| `INCIDENT` | any | "Needs attention" | Orange |
| `PENDING_COMPLETION` | any | "Pending in SDMS" | Yellow |
| `COMPLETE` | `UNCLAIMED` | "Ready to claim" | Blue |
| `COMPLETE` | `PENDING_APPROVAL` | "Transfer pending" | Orange |
| `COMPLETE` | `CLAIMED` | "Claimed" | Green |
| `COMPLETE` | `REJECTED` | "Rejected" | Red |

---

### Screen 3: Order Detail

**Purpose:** Full details of an SDMS order with action buttons.

```
+----------------------------------+
|  <- Order #123456789             |
|                                  |
|  +------------------------------+|
|  | Status: Claimed              ||
|  | Category: Refill             ||
|  | Payment: Online . Rs1,053   ||
|  | Date: 15 Jun 2025           ||
|  +------------------------------+|
|                                  |
|  Consumer                        |
|  MOHD ASHRAF                     |
|  REL-12345                       |
|  9876543210                      |
|                                  |
|  Original Delivery Boy           |
|  Farooq Ahmad                    |
|                                  |
|  ERP Status (online orders only) |
|  +------------------------------+|
|  | Accrual: Created             ||
|  | Allocation: Allocated        ||
|  | Settlement: Unsettled        ||
|  +------------------------------+|
|                                  |
|  Items (service orders only)     |
|  +------------------------------+|
|  | CYL-14.2-FILLED  x1  ISSUE  ||
|  | Rs1,053.00                   ||
|  |                              ||
|  | CYL-14.2-EMPTY   x1 COLLECT ||
|  +------------------------------+|
|                                  |
|  +----------------------------+  |
|  |       Claim This Order     |  |
|  +----------------------------+  |
+----------------------------------+
```

**ERP Status section:**
- Only show for online payment orders (`payment_mode == "ONLINE"`)
- Display the three tracks from `dpc_posting` with color-coded status
- If any track is `FAILED`, show the `error` field below

**Action buttons (mutually exclusive):**

| Condition | Button | Action |
|-----------|--------|--------|
| `can_claim == true` | "Claim This Order" (primary) | `POST /orders/{id}/claim/` |
| `can_retry == true` | "Retry" (secondary) | `POST /orders/{id}/retry/` |
| `data_status == QUEUED/PROCESSING` | None (show loading) | Poll every 5s |
| `claim_status == PENDING_APPROVAL` | "View Transfer" (link) | Navigate to transfer |
| `claim_status == CLAIMED` | None (show success) | - |

**Polling strategy:**
- When `data_status` is `QUEUED` or `PROCESSING`, poll `GET /orders/{id}/` every 5 seconds
- Stop polling when `data_status` changes to `COMPLETE`, `FAILED`, `INCIDENT`, or `PENDING_COMPLETION`
- Show elapsed time: "Fetching data... (15s)"

---

### Screen 4: Approvals / Tasks (Dedicated Screen)

**Purpose:** A top-level screen showing all claim transfers. Items requiring the current user's action appear at the top. This is the **primary approval interface** — do not nest it inside order navigation.

**API Call:** `GET /transfers/`

The API returns results pre-sorted: actionable items first (`can_approve: true`), then the rest by most recent. Render in the order returned — no client-side sorting needed.

**Actionable items (can_approve == true) — show at top with action buttons:**
```
+----------------------------------+
|  ⚠ Needs Your Approval           |
|  #123456789 . Rs1,053            |
|  Bilal Dar wants to claim this   |
|  Auto-approves in 18 hours       |
|                                  |
|  [Approve]          [Reject]     |
+----------------------------------+
```

**Non-actionable items (can_approve == false) — show below as read-only:**
```
+----------------------------------+
|  #987654321 . Rs850              |
|  You → Ali Shah                  |
|  ✓ Approved . 15 Jun 2025       |
+----------------------------------+
+----------------------------------+
|  #555666777 . Rs1,200            |
|  Farooq Ahmad → You              |
|  ⏳ Pending (on Farooq)           |
+----------------------------------+
```

**Key rules:**
- Show **Approve** button only when `can_approve == true`
- Show **Reject** button only when `can_reject == true`
- For non-actionable items, show a status badge (Approved / Rejected / Auto-Approved / Pending)
- If `status == PENDING` and `can_approve == false`, it means someone else needs to act — show "Pending (on {from_user_name})"

**Auto-approve countdown:**
- Calculate from `auto_approve_at` field
- Display as: "Auto-approves in X hours" or "Auto-approves tomorrow at 9:00 AM"
- After auto-approve time passes: "Auto-approved"

---

### Screen 5: Unclaimed Orders (Optional Browse)

**Purpose:** Browse all unclaimed orders in the company (for claiming others' orders).

**API Call:** `GET /orders/?claim_status=UNCLAIMED&data_status=COMPLETE`

Show list of claimable orders with "Claim" button on each card.

---

## Polling & Real-Time Updates

The system does NOT use WebSockets. Use polling for live updates.

### When to Poll

| Screen | Condition | Interval | API Call |
|--------|-----------|----------|----------|
| Order Detail | `data_status` is `QUEUED` or `PROCESSING` | 5 seconds | `GET /orders/{id}/` |
| My Orders list | Any order with `data_status` in `QUEUED`, `PROCESSING` | 10 seconds | `GET /orders/?is_mine=true` |
| Transfer Requests | Any pending transfer | 30 seconds | `GET /transfers/` |

### When to Stop Polling

- Order detail: `data_status` reaches a terminal state (`COMPLETE`, `FAILED`, `INCIDENT`, `PENDING_COMPLETION`)
- After claiming: `claim_status` changes from `UNCLAIMED`
- Screen is not visible (dispose timer)

---

## Push Notifications

The backend sends push notifications via Novu for claim transfers. The Flutter app should handle these notification types:

| Notification | Recipient | When | Deep Link |
|--------------|-----------|------|-----------|
| `claim-transfer-request` | Original delivery boy | Someone requests their order | Transfer detail screen |
| `claim-transfer-approved` | Requester | Original approves transfer | Order detail screen |
| `claim-transfer-rejected` | Requester | Original rejects transfer | Order detail screen |
| `claim-transfer-auto-approved` | Both parties | Transfer auto-approved after timeout | Order detail screen |

---

## Error Handling

### HTTP Status Codes

| Code | Meaning | Flutter Action |
|------|---------|----------------|
| 200 | Success | Process response |
| 201 | Created | Process response (new order) |
| 400 | Validation error or business logic error | Show `message` field |
| 401 | Token expired | Redirect to login |
| 404 | Order not found | Show "Order not found" |
| 428 | Missing company context | Redirect to company selection |

### Error Response Format

All error responses include a `message` field:

```json
{
    "message": "Human-readable error message",
    "success": false
}
```

Or for validation errors (DRF standard):

```json
{
    "order_id": ["This field may not be blank."]
}
```

---

## Common Scenarios

### Scenario 1: Happy Path (Same-Day Refill, Own Order)

1. Delivery boy opens app, enters order `123456789`
2. `POST /orders/` with `{"order_id": "123456789", "claim_for_self": true}` -> `201`, `data_status: QUEUED`
3. App polls `GET /orders/{id}/` every 5s
4. After ~10s, RPA completes -> `data_status: COMPLETE`, `claim_status: CLAIMED` (auto-claimed)
5. App shows green checkmark "Claimed!"
6. `dpc_posting` shows `accrual_status: CREATED`, `allocation_status: ALLOCATED`

### Scenario 2: Claiming Someone Else's Order

1. Delivery boy enters order `987654321`
2. `POST /orders/` -> `201`, `data_status: QUEUED`
3. RPA completes -> `data_status: COMPLETE`, `claim_status: UNCLAIMED`
4. Backend detects mismatch, auto-creates transfer -> `claim_status: PENDING_APPROVAL`
5. App shows: "Transfer request sent to Farooq Ahmad. Will auto-approve on Jun 17 at 9:00 AM"
6. Original delivery boy (Farooq) gets push notification
7. Farooq opens app, sees transfer request, taps "Approve"
8. `POST /transfers/{id}/approve/` -> `200`
9. Both users see updated status

### Scenario 3: Claiming on Behalf of Another

1. User searches partners via `GET /api/users/api/masters/partners/?search=Farooq` -> gets `{id: 7, partner_name: "Farooq Ahmad", ...}`
2. User enters order `111222333` with `claim_for_self: false`, `intended_partner: 7`
3. `POST /orders/` -> `201`, `data_status: QUEUED`
4. RPA completes -> if Farooq is the original poster, auto-claimed for Farooq
5. If Farooq is NOT the original -> transfer request created

### Scenario 4: RPA Failure

1. Delivery boy enters order `111222333`
2. `POST /orders/` -> `201`
3. RPA fails -> `data_status: FAILED`, `rpa_error: "Login timeout"`
4. App shows error with "Retry" button
5. User taps retry -> `POST /orders/{id}/retry/` -> `data_status: QUEUED`
6. Polling resumes

### Scenario 5: Duplicate Entry

1. Delivery boy enters order `123456789` (already exists)
2. `POST /orders/` -> `200`, `created: false`
3. App navigates to existing order detail

### Scenario 6: Delivery Register Detection (Next Day)

1. Night: Daily rollup processes delivery register
2. System creates orders for digital payments and service orders with `source: DELIVERY_REGISTER`
3. Next morning: Delivery boy opens "My Orders" list
4. Sees new unclaimed orders detected from register
5. Taps order, taps "Claim" -> direct claim

---

## Data Model Reference (Read-Only)

### Order List Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique order ID (for API calls) |
| `order_id` | string | SDMS order number (display to user) |
| `order_date` | date/null | SDMS order date (null until RPA completes) |
| `order_category` | enum | REFILL, SV, TV_IN, TV_OUT, CONVERSION, ADDON, UNKNOWN |
| `payment_mode` | enum | CASH, ONLINE, UNKNOWN |
| `posting_type` | enum | NORMAL, SYSTEM, UNKNOWN |
| `data_status` | enum | QUEUED, PROCESSING, COMPLETE, FAILED, INCIDENT, PENDING_COMPLETION |
| `claim_status` | enum | PENDING_DATA, UNCLAIMED, PENDING_APPROVAL, CLAIMED, REJECTED |
| `settlement_status` | enum | N/A, UNSETTLED, SETTLED |
| `amount` | decimal | Order amount (null if RPA pending) |
| `consumer_name` | string | Consumer name (blank if RPA pending) |
| `original_delivery_boy_name` | string | Name of original poster (null if RPA pending) |
| `claimed_by_name` | string | Name of final claimant (null if unclaimed) |
| `source` | enum | FLUTTER_APP, DELIVERY_REGISTER, DPR_IMPORT |
| `created_at` | datetime | When order was created in system |
| `is_mine` | boolean | Whether current user is involved |
| `can_claim` | boolean | Whether current user can claim this order |
| `can_retry` | boolean | Whether order can be retried |

### Order Detail Additional Fields

| Field | Type | Description |
|-------|------|-------------|
| `delivery_date` | date | Actual delivery date from SDMS |
| `order_subtype_raw` | string | Raw subtype string from SDMS |
| `consumer_number` | string | Consumer relationship ID |
| `consumer_address` | string | Consumer address |
| `consumer_phone` | string | Consumer phone number |
| `sdms_user_code` | string | SDMS login code of original poster |
| `sdms_delivery_boy_name` | string | Name from SDMS portal |
| `intended_claimant` | integer/null | User ID of intended claimant (null if self) |
| `auto_claimed` | boolean | Whether claim was automatic |
| `rejection_reason` | string | Reason if claim was rejected |
| `dpc_posting` | object/null | Digital payment posting status (see [DPC Posting Object](#dpc-posting-object-new-in-v11)) |
| `so_posting` | object/null | Service order posting status |
| `quota_adjusted` | boolean | Whether quota was adjusted |
| `camunda_process_id` | string | RPA process tracking ID |
| `retry_count` | integer | Number of RPA retry attempts |
| `rpa_error` | string | Last RPA error message |
| `items` | array | Line items (service orders only) |
| `updated_at` | datetime | Last update timestamp |

### Transfer List Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Transfer ID (for approve/reject calls) |
| `order_id` | string | SDMS order number |
| `order_date` | date | Order date |
| `order_amount` | decimal | Order amount |
| `from_user_name` | string | Original delivery boy name |
| `to_user_name` | string | Requester name |
| `status` | enum | PENDING, APPROVED, REJECTED, AUTO_APPROVED |
| `auto_approve_at` | datetime | When transfer will auto-approve |
| `resolved_at` | datetime | When transfer was resolved (null if pending) |
| `rejection_reason` | string | Reason if rejected |
| `can_approve` | boolean | Whether current user can approve this transfer |
| `can_reject` | boolean | Whether current user can reject this transfer |
| `created_at` | datetime | When transfer was created |

---

## Migration Guide

### v1.2 to v1.3

**1. Transfer list is now pre-sorted — remove client-side sorting if any:**

The `GET /transfers/` response is now ordered by the API: actionable items (`can_approve: true`) first, then by most recent. Render the list in the order returned.

**2. Add `can_reject` field to your transfer model:**

```dart
// Before (v1.2)
final canApprove = transfer['can_approve'] as bool;
// Show both Approve and Reject based on canApprove

// After (v1.3)
final canApprove = transfer['can_approve'] as bool;
final canReject = transfer['can_reject'] as bool;
// Show Approve button when canApprove == true
// Show Reject button when canReject == true
```

> Note: Currently `can_approve` and `can_reject` are always equal, but they are separate fields to allow for future divergence (e.g., if admins can reject but not approve).

**3. Make Transfers a top-level screen (UX change):**

The transfers list should be a dedicated "Approvals" / "Tasks" screen accessible from the main navigation — not nested inside order detail. The pre-sorted API ensures that actionable items are always visible at the top without the user having to drill into individual orders.

---

### v1.1 to v1.2

**1. Rename `intended_claimant` to `intended_partner` in Create Order:**

The field now accepts a **Partner ID** (DB primary key) instead of a User ID. Get the partner ID from the [Partner API](#10-partner-lookup-for-claim-on-behalf).

**Before (v1.1):**
```json
{
    "order_id": "123456789",
    "claim_for_self": false,
    "intended_claimant": 42
}
```

**After (v1.2):**
```json
{
    "order_id": "123456789",
    "claim_for_self": false,
    "intended_partner": 7
}
```

**Dart code change:**
```dart
// Before (v1.1)
body: {"order_id": orderId, "claim_for_self": false, "intended_claimant": userId}

// After (v1.2)
body: {"order_id": orderId, "claim_for_self": false, "intended_partner": partnerId}
```

**2. Add Partner search for the picker:**
```dart
// Fetch partners for the "claim on behalf" picker
final response = await api.get('/api/users/api/masters/partners/?search=$query');
final partners = response.data as List;
// Each partner: {id: 7, partner_id: "CUST-00123", partner_name: "Farooq Ahmad", is_active: true}
// Use partner['id'] as the intended_partner value
```

---

### v1.0 to v1.1

**1. Update Create Order request:**
- Remove `order_date` from the request body (it's now auto-populated by RPA)
- Add `claim_for_self: true` (or omit it, defaults to `true`)

**Before (v1.0):**
```json
{
    "order_id": "123456789",
    "order_date": "2025-06-15",
    "intended_claimant": 42
}
```

**After (v1.1):**
```json
{
    "order_id": "123456789",
    "claim_for_self": true
}
```

**2. Update Order Detail response parsing:**

**Before (v1.0):**
```dart
final erpDpcName = order['erp_dpc_name'];
final erpDpcCreated = order['erp_dpc_created'];
final erpDpcClaimed = order['erp_dpc_claimed'];
```

**After (v1.1):**
```dart
final dpcPosting = order['dpc_posting']; // nullable
if (dpcPosting != null) {
  final settlementName = dpcPosting['settlement_name'];
  final accrualStatus = dpcPosting['accrual_status'];     // PENDING, CREATED, FAILED
  final allocationStatus = dpcPosting['allocation_status']; // UNALLOCATED, PENDING_APPROVAL, ALLOCATED, FAILED
  final settlementStatus = dpcPosting['settlement_status']; // UNSETTLED, SETTLED, FAILED
  final allocatedTo = dpcPosting['allocated_to_erp'];
  final isOverridden = dpcPosting['is_overridden'];
  final error = dpcPosting['error'];
}

final soPosting = order['so_posting']; // nullable
if (soPosting != null) {
  final soStatus = soPosting['status'];           // PENDING, SUCCESS, FAILED
  final soName = soPosting['service_order_name'];
  final soError = soPosting['error'];
}
```
