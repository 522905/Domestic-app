# Offline Delivery — Flutter Integration Guide

## 0. About This Document

This document is the complete integration guide for the Flutter mobile app to implement the Offline Delivery feature. It is a companion to `OFFLINE_DELIVERY_DESIGN.md` (the backend system design) and covers:

1. **Methodology** — what we are building, why, and the architectural approach
2. **Workflows** — every happy path and sad path, step by step
3. **API contracts** — request/response formats for every endpoint
4. **UI behavior rules** — what to show/hide based on mode, role, and state
5. **Financial display logic** — the `digital_amount` design change and its impact
6. **Silent push handling** — real-time config and record refresh
7. **Error handling** — every error code and what the app should do
8. **Local state management** — caching, cleanup, image lifecycle

Read this document end-to-end before starting implementation. Cross-reference with `OFFLINE_DELIVERY_DESIGN.md` for backend internals (Camunda processes, Django admin, reconciliation mechanics) that are transparent to the app but useful for understanding the full picture.

---

## 1. Methodology & What We Are Building

### The Problem

Indian Oil's SDMS (Supplier Delivery Management System) has three subsystems that fail independently during the current 8-10x demand crisis:

| Subsystem | Function | Failure Impact |
|-----------|----------|----------------|
| **SDMS Core** | Consumer data, booking validation, delivery recording | No digital operations possible |
| **Booking Channels** | Consumer places a cylinder refill order | Consumers can't book online/via call center |
| **OTP/DAC Channels** | SMS delivery authentication codes | No delivery verification code available |

Distribution still happens physically — trucks arrive, cylinders are handed out — but without digital capture, there is no audit trail, no queue management, and no reconciliation path.

### What We Are Building

A backend-authoritative offline delivery system that:

1. **Degrades gracefully** — three operational modes (MANUAL, ASSISTED, VERIFIED) derived from which subsystems are up. The app uses as much SDMS capability as is available.
2. **Captures first, reconciles later** — during field hours (8 AM–8 PM), priority is speed. SDMS posting happens asynchronously via RPA during off-peak windows.
3. **Lives on the server** — all data is backend-authoritative. Token numbers assigned atomically via Redis. The only thing deferred to background on the app side is image upload (via tus resumable protocol).
4. **Fits the existing ecosystem** — same JWT auth, company-scoping, notification patterns. After reconciliation, tokens link to `sdms_claims.SDMSOrder` via the `OFFLINE_DELIVERY` source.

### Architectural Approach

```
┌─────────────────────────────────────────────────────┐
│                   FLUTTER APP                       │
│                                                     │
│  Local state:                                       │
│  - Cached system status (mode, flags)               │
│  - Selected distribution point                      │
│  - Pending tus uploads (image queue)                │
│  - Photo files awaiting cleanup                     │
│                                                     │
│  All business data lives on the server.             │
│  App is a thin client — no offline-first DB,        │
│  no local token generation, no local queuing.       │
└───────────────┬─────────────────────────────────────┘
                │ REST API + Silent Push
                ▼
┌─────────────────────────────────────────────────────┐
│                   DJANGO BACKEND                    │
│                                                     │
│  /api/offline-delivery/status/                      │
│  /api/offline-delivery/distribution-points/         │
│  /api/offline-delivery/booking-verifications/       │
│  /api/offline-delivery/tokens/                      │
│                                                     │
│  Redis: system status cache, token sequences,       │
│         price cache                                 │
│  Camunda: async RPA for verification + reconcile    │
│  Novu: push notifications (user-facing + silent)    │
└─────────────────────────────────────────────────────┘
```

**The app does NOT:**
- Generate token numbers locally
- Store tokens in a local database
- Queue API calls for later (except tus image uploads)
- Make decisions about pricing (backend provides `cash_to_collect`)
- Trigger reconciliation (admin-only via Django admin panel)

**The app DOES:**
- Cache system status and distribution points for fast UI rendering
- Manage local photo capture, compression, and tus upload lifecycle
- React to silent push notifications to refresh cached data
- Display financial amounts and mode-appropriate UI
- Print thermal receipts from token data

---

## 2. System Modes & UI Behavior Matrix

### Mode Derivation

The backend returns three boolean flags. The mode is derived as follows:

```
if sdms_active == false:
    mode = MANUAL          # Everything down — pure data capture
elif booking_channels_active == false:
    mode = ASSISTED        # RPA bridges the gap — creates bookings
else:
    mode = VERIFIED        # Consumer booked via official channels — RPA verifies only
```

`otp_channels_active` is a **cross-cutting flag** independent of mode. It controls whether DAC code entry is required at delivery confirmation, regardless of which mode is active.

### UI Behavior Matrix

| UI Element | MANUAL | ASSISTED | VERIFIED |
|------------|--------|----------|----------|
| "SDMS Offline" banner | Show | Hide | Hide |
| Verification form (consumer ID/number) | **Hidden** | Show | Show |
| "My Verifications" list | **Hidden** | Show | Show |
| "Create Token" button (on verified card) | N/A | Show | Show |
| Direct token creation form | **Show** | **Hidden** | **Hidden** |
| "Issue Anyway" on failed verification | N/A | Show (GM/WM only) | Show (GM/WM only) |
| "Owner's Reference" button | Show (GM/WM only) | Show (GM/WM only) | Show (GM/WM only) |
| Quick delivery button | Show (if point allows) | Show (if point allows) | Show (if point allows) |
| DAC code field at delivery | If `otp_channels_active` | If `otp_channels_active` | If `otp_channels_active` |
| Token list | Show (all mine) | Show (all mine) | Show (all mine) |
| Correction form | Show (if CORRECTION_NEEDED) | Show (if CORRECTION_NEEDED) | Show (if CORRECTION_NEEDED) |

### Role-Gated Features

The app must detect whether the current user has a supervisor role (GeneralManagerRole or WarehouseManagerRole). This can be determined from the existing user/role APIs or cached at login.

| Feature | Regular Delivery Boy | GM/WM/Manager |
|---------|---------------------|---------------|
| Standard token creation | Yes | Yes |
| Booking verification | Yes | Yes |
| "Issue Anyway" (supervisor override) | **No** | Yes |
| "Owner's Reference" | **No** | Yes |
| Delivery confirmation | Yes | Yes |
| Correction submission | Yes | Yes |

---

## 3. API Reference

**Base URL:** `/api/offline-delivery/`
**Authentication:** Bearer JWT (same as all other APIs)
**Company Scoping:** Automatic via `active_company_id` in JWT claim

### 3.1 System Status

#### `GET /status/`

Returns current system status and derived mode. Cached on the backend with 30-second TTL.

**Response:**
```json
{
  "sdms_active": false,
  "booking_channels_active": false,
  "otp_channels_active": false,
  "mode": "MANUAL",
  "mode_label": "Manual Operations",
  "allow_booking_creation": false,
  "require_dac_code": false,
  "updated_at": "2026-03-13T14:30:00",
  "notes": "SDMS down nationwide — all systems offline"
}
```

**Fields the app uses:**

| Field | Usage |
|-------|-------|
| `mode` | Determines which UI path is active (MANUAL/ASSISTED/VERIFIED) |
| `mode_label` | Human-readable label for display (e.g., banner text) |
| `allow_booking_creation` | Informational — true only in ASSISTED mode |
| `require_dac_code` | If true, DAC code input is mandatory at delivery |
| `updated_at` | Show "Status as of {time}" in UI |
| `notes` | Optional — show as info text under status banner |

**When to call:**
- On app launch
- On receiving silent push with `action=config_refresh, resource=system_status`
- On receiving `CONFIG_OUTDATED` error from any endpoint

### 3.2 Distribution Points

#### `GET /distribution-points/`

Returns active distribution points for the user's company.

**Response:**
```json
[
  {
    "id": "a1b2c3d4-...",
    "name": "Sherpur Godown",
    "warehouse": {"id": 1, "name": "Sherpur - IOC"},
    "is_adhoc": false,
    "allow_quick_delivery": false,
    "is_active": true,
    "today_token_count": 142
  },
  {
    "id": "e5f6g7h8-...",
    "name": "Lal Chowk Truck — 14 Mar 2026",
    "warehouse": null,
    "is_adhoc": true,
    "allow_quick_delivery": true,
    "is_active": true,
    "today_token_count": 23
  }
]
```

**Fields the app uses:**

| Field | Usage |
|-------|-------|
| `id` | Sent in all token/verification creation requests |
| `name` | Display in picker and on receipts |
| `warehouse` | Informational — show warehouse name if linked |
| `is_adhoc` | Visual indicator (e.g., truck icon vs building icon) |
| `allow_quick_delivery` | If true, show quick delivery option at this point |
| `today_token_count` | Show on point card (e.g., "142 tokens today") |

**When to call:**
- On app launch (after status)
- On receiving silent push with `action=config_refresh, resource=distribution_point`

### 3.3 Booking Verifications

#### `POST /booking-verifications/`

Submit a consumer for async RPA booking verification.

**Request:**
```json
{
  "distribution_point_id": "a1b2c3d4-...",
  "consumer_id": "2-123456789012",
  "consumer_number": "9876543210",
  "order_number": "ORD-2026-001234",
  "idempotency_key": "550e8400-e29b-41d4-a716-446655440000"
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `distribution_point_id` | Yes | Selected distribution point UUID |
| `consumer_id` | At least one of consumer_id/consumer_number | Format: `X-XXXXXXXXXXXX` |
| `consumer_number` | At least one of consumer_id/consumer_number | 10+ digit number |
| `order_number` | No | Booking/order number if consumer provides one |
| `idempotency_key` | Recommended | Client-generated UUID v4 — prevents duplicate on network retry |

**Success Response (201 Created):**
```json
{
  "id": "b2c3d4e5-...",
  "consumer_id": "2-123456789012",
  "consumer_number": "9876543210",
  "consumer_name": "",
  "order_number": "ORD-2026-001234",
  "status": "QUEUED",
  "cash_to_collect": null,
  "digital_amount": null,
  "is_digitally_paid": false,
  "order_number_from_rpa": null,
  "error_message": "",
  "error_code": "",
  "has_token": false,
  "created_at": "2026-03-13T10:30:00",
  "updated_at": "2026-03-13T10:30:00"
}
```

**Idempotent Return (200 OK):**
Same shape as 201. Returned when `idempotency_key` matches an existing verification.

**Error Responses:**

| Status | Condition | App Action |
|--------|-----------|------------|
| 400 `CONFIG_OUTDATED` | Mode is MANUAL — verification not available | Re-fetch `/status/`, switch to MANUAL UI |
| 400 | Neither consumer_id nor consumer_number provided | Show validation error |
| 400 | Distribution point invalid or inactive | Show error, re-fetch points |

**`CONFIG_OUTDATED` error shape:**
```json
{
  "error": "This action is not available in the current system mode.",
  "code": "CONFIG_OUTDATED",
  "current_mode": "MANUAL"
}
```

#### `GET /booking-verifications/`

List verifications created by the current user.

**Query Parameters:**

| Param | Type | Default | Notes |
|-------|------|---------|-------|
| `status` | string | — | Filter: `QUEUED`, `PROCESSING`, `VERIFIED`, `BOOKING_CREATED`, `FAILED` |
| `distribution_point_id` | UUID | — | Filter by point |
| `date` | date (YYYY-MM-DD) | today | Filter by creation date |

**Response:**
```json
[
  {
    "id": "b2c3d4e5-...",
    "consumer_id": "2-123456789012",
    "consumer_number": "9876543210",
    "consumer_name": "Mohd Rafiq",
    "order_number": "ORD-2026-001234",
    "status": "VERIFIED",
    "cash_to_collect": "1050.00",
    "digital_amount": null,
    "is_digitally_paid": false,
    "order_number_from_rpa": "ORD-2026-001234",
    "error_message": "",
    "error_code": "",
    "has_token": false,
    "created_at": "2026-03-13T10:30:00",
    "updated_at": "2026-03-13T10:30:45"
  },
  {
    "id": "f6g7h8i9-...",
    "consumer_id": "2-111222333444",
    "consumer_number": null,
    "consumer_name": "",
    "order_number": null,
    "status": "FAILED",
    "cash_to_collect": null,
    "digital_amount": null,
    "is_digitally_paid": false,
    "order_number_from_rpa": null,
    "error_message": "Consumer quota exhausted. Next eligible date: 2026-03-28",
    "error_code": "QUOTA_EXHAUSTED",
    "has_token": false,
    "created_at": "2026-03-13T10:31:00",
    "updated_at": "2026-03-13T10:31:30"
  }
]
```

#### `GET /booking-verifications/{id}/`

Single verification detail. Same shape as list item.

#### `POST /booking-verifications/{id}/retry/`

Retry a failed verification. Transitions `FAILED → QUEUED`, increments `retry_count`, re-queues Camunda.

**Request:** Empty body.

**Response (200):**
```json
{
  "message": "Verification queued for retry (attempt 1)"
}
```

**Error (400):** Verification not in FAILED status.

### 3.4 Tokens

#### `POST /tokens/`

Create a delivery token. The request shape varies by `creation_type`.

**Variant A — STANDARD from verification (ASSISTED/VERIFIED):**
```json
{
  "creation_type": "STANDARD",
  "distribution_point_id": "a1b2c3d4-...",
  "booking_verification_id": "b2c3d4e5-...",
  "idempotency_key": "660e8400-..."
}
```

**Variant B — STANDARD direct (MANUAL mode):**
```json
{
  "creation_type": "STANDARD",
  "distribution_point_id": "a1b2c3d4-...",
  "consumer_id": "2-123456789012",
  "consumer_number": "9876543210",
  "order_number": "ORD-2026-001234",
  "idempotency_key": "770e8400-..."
}
```

**Variant C — SUPERVISOR_OVERRIDE (GM/WM role, after failed verification):**
```json
{
  "creation_type": "SUPERVISOR_OVERRIDE",
  
  "distribution_point_id": "a1b2c3d4-...",
  "booking_verification_id": "f6g7h8i9-...",
  "override_reason": "Consumer has physical receipt, RPA timed out",
  "idempotency_key": "880e8400-..."
}
```

**Variant D — OWNERS_REFERENCE (GM/WM role, non-consumer):**
```json
{
  "creation_type": "OWNERS_REFERENCE",
  "distribution_point_id": "a1b2c3d4-...",
  "consumer_name_manual": "Bilal Ahmad",
  "override_reason": "Family of army personnel, referred by depot owner",
  "idempotency_key": "990e8400-..."
}
```

**All Variants — Common Optional Fields:**

| Field | Type | Notes |
|-------|------|-------|
| `token_date` | date | Defaults to today. Do not override unless the backend instructs. |
| `is_quick_delivery` | boolean | Used internally by quick-deliver endpoint. Do not set directly. |

**Success Response (201 Created):**

The response uses the `TokenDetailSerializer` — the full token representation:

```json
{
  "id": "c3d4e5f6-...",
  "token_number": 143,
  "token_date": "2026-03-13",
  "consumer_id": "2-123456789012",
  "consumer_number": "9876543210",
  "consumer_name": "Mohd Rafiq",
  "consumer_name_manual": "",
  "order_number": "ORD-2026-001234",
  "booking_origin": "PRE_EXISTING",
  "booking_verification": {
    "id": "b2c3d4e5-...",
    "status": "VERIFIED",
    "cash_to_collect": "1050.00",
    "digital_amount": null,
    "is_digitally_paid": false,
    "..."
  },
  "dac_code": null,
  "delivered_at": null,
  "cash_to_collect": "1050.00",
  "cash_to_collect_is_estimated": false,
  "price_cached_at": null,
  "digital_amount": null,
  "cash_collected": null,
  "reference_image_1": null,
  "reference_image_2": null,
  "images_uploaded": false,
  "evidence_required": false,
  "remark": "",
  "status": "TOKEN_ISSUED",
  "mode_snapshot": "VERIFIED",
  "creation_type": "STANDARD",
  "is_quick_delivery": false,
  "override_reason": "",
  "reconciliation_status": "NOT_STARTED",
  "reconciliation_error": "",
  "reconciliation_attempts": 0,
  "reconciled_at": null,
  "distribution_point": "a1b2c3d4-...",
  "distribution_point_name": "Sherpur Godown",
  "created_by_name": "Ravi Kumar",
  "created_at": "2026-03-13T10:35:00",
  "updated_at": "2026-03-13T10:35:00"
}
```

**Idempotent Return (200 OK):** Same shape. Returned when `idempotency_key` matches existing token.

**Error Responses:**

| Status | Code/Condition | App Action |
|--------|---------------|------------|
| 400 | Missing consumer_id and consumer_number | Show validation error |
| 400 | override_reason required (SUPERVISOR_OVERRIDE/OWNERS_REFERENCE) | Show validation error |
| 400 | consumer_name_manual required (OWNERS_REFERENCE) | Show validation error |
| 400 | Verification not in VERIFIED/BOOKING_CREATED status | Show error, re-fetch verification |
| 400 | Quick delivery not enabled at this distribution point | Show error |
| 400 | Supervisor role required | Show error (should not happen if role-gated in UI) |
| 400 | Duplicate consumer at this point today | Show error with message |
| 400 | Duplicate order number at this point today | Show error with message |
| 400 | Distribution point invalid or inactive | Show error, re-fetch points |

#### `GET /tokens/`

List tokens for the user's company.

**Query Parameters:**

| Param | Type | Default | Notes |
|-------|------|---------|-------|
| `distribution_point_id` | UUID | — | Filter by point |
| `date` | date | today | Filter by token_date |
| `status` | string | — | `TOKEN_ISSUED`, `DELIVERED`, `VOIDED` |
| `is_delivered` | string | — | `true` or `false` (convenience filter, does not include VOIDED) |
| `reconciliation_status` | string | — | `NOT_STARTED`, `CORRECTION_NEEDED`, `POSTED`, etc. |
| `created_by` | integer | — | User PK (admin use) |

**Response:** Array of token list items:
```json
[
  {
    "id": "c3d4e5f6-...",
    "token_number": 143,
    "token_date": "2026-03-13",
    "consumer_id": "2-123456789012",
    "consumer_number": "9876543210",
    "consumer_name": "Mohd Rafiq",
    "consumer_name_manual": "",
    "order_number": "ORD-2026-001234",
    "status": "TOKEN_ISSUED",
    "reconciliation_status": "NOT_STARTED",
    "mode_snapshot": "MANUAL",
    "creation_type": "STANDARD",
    "booking_origin": "UNKNOWN",
    "is_quick_delivery": false,
    "cash_to_collect": "1050.00",
    "cash_to_collect_is_estimated": true,
    "digital_amount": null,
    "cash_collected": null,
    "distribution_point": "a1b2c3d4-...",
    "distribution_point_name": "Sherpur Godown",
    "created_by_name": "Ravi Kumar",
    "evidence_required": false,
    "images_uploaded": false,
    "created_at": "2026-03-13T10:35:00",
    "delivered_at": null
  }
]
```

#### `GET /tokens/{id}/`

Full token detail. Same shape as the 201 response from `POST /tokens/` (includes nested `booking_verification`).

#### `POST /tokens/{id}/deliver/`

Confirm delivery on a token.

**Request:**
```json
{
  "dac_code": "847291",
  "cash_collected": "1050.00"
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `dac_code` | Only when `require_dac_code = true` | DAC/OTP code from consumer |
| `cash_collected` | Always | Actual cash amount collected |

**Success Response (200):** Full token detail (TokenDetailSerializer).

**Error Responses:**

| Status | Condition | App Action |
|--------|-----------|------------|
| 400 | Token not in TOKEN_ISSUED state | Show error (may already be delivered — refresh) |
| 400 | Evidence required but images not uploaded | Show "Upload photo first" — block delivery |
| 400 | DAC code required but missing | Show validation error on DAC field |

**Idempotency:** First successful delivery wins. If token is already DELIVERED, the existing state is returned (200) regardless of payload. A retry with different `cash_collected` does NOT overwrite.

#### `POST /tokens/{id}/correct/`

Submit corrected data for a token needing correction.

**Request:**
```json
{
  "consumer_id": "2-123456789012",
  "consumer_number": "9876543211",
  "order_number": "ORD-2026-001235",
  "dac_code": "847292"
}
```

All fields are optional — include only the ones that need correction.

**Success Response (200):** Full token detail with `reconciliation_status = "CORRECTED"`.

**Idempotency:** If `reconciliation_status` is already `CORRECTED`, returns existing state.

#### `POST /tokens/{id}/attach-images/`

Attach tus-uploaded image URLs to a token.

**Request:**
```json
{
  "reference_image_1": "https://tus.example.com/files/abc123def456",
  "reference_image_2": "https://tus.example.com/files/789ghi012jkl"
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `reference_image_1` | At least one | tus file URL |
| `reference_image_2` | No | Second reference photo |

**Success Response (200):** Full token detail with `images_uploaded = true`.

**Idempotency:** Last write wins. Re-upload replaces URLs.

#### `POST /tokens/quick-deliver/`

One-shot delivery — creates token + marks delivered in a single call.

**Request (ASSISTED/VERIFIED):**
```json
{
  "distribution_point_id": "a1b2c3d4-...",
  "booking_verification_id": "b2c3d4e5-...",
  "dac_code": "847291",
  "cash_collected": "1050.00",
  "reference_image_1": "https://tus.example.com/files/abc123",
  "idempotency_key": "aa0e8400-..."
}
```

**Request (MANUAL):**
```json
{
  "distribution_point_id": "a1b2c3d4-...",
  "consumer_id": "2-123456789012",
  "consumer_number": "9876543210",
  "order_number": "ORD-2026-001234",
  "dac_code": "847291",
  "cash_collected": "1050.00",
  "reference_image_1": "https://tus.example.com/files/abc123",
  "idempotency_key": "bb0e8400-..."
}
```

**Success Response (201):** Full token detail with `status = "DELIVERED"`, `is_quick_delivery = true`, `token_number = null`.

**Validation:** All token creation validations apply, plus:
- Quick delivery must be enabled at the distribution point (`allow_quick_delivery = true`)
- `cash_collected` is required (delivery is inline)

---

## 4. Complete Workflows

### 4.1 App Initialization

```
App Launch / Resume
    │
    ├─ GET /api/offline-delivery/status/
    │  Store in local state:
    │    mode, require_dac_code, allow_booking_creation, notes, updated_at
    │
    ├─ GET /api/offline-delivery/distribution-points/
    │  Store in local state:
    │    List of points with allow_quick_delivery, today_token_count
    │
    ├─ Prompt user to select active distribution point
    │  (if not already selected or if point is no longer active)
    │
    └─ Set up silent push listener (see Section 6)
```

**On mode change (via silent push or manual re-fetch):**
- If mode changed from what the app had cached → show a brief toast/snackbar: "System mode changed to {mode_label}"
- Rebuild the main screen UI according to the new mode
- If the user was in the middle of a verification form and mode changed to MANUAL → show dialog: "SDMS is now offline. Verification is no longer available. You can create tokens directly."

### 4.2 Booking Verification (ASSISTED/VERIFIED Only)

``**Precondition:** `mode` is `ASSISTED` or `VERIFIED`.``

#### Happy Path

```
1. User opens verification form
   Fields: consumer_id, consumer_number (at least one), order_number (optional)

2. User submits
   App generates idempotency_key (UUID v4), stores locally
   POST /booking-verifications/
     → 201 Created, status = QUEUED

3. Verification appears in "My Verifications" list with QUEUED badge
   User can move on to the next consumer immediately

4. RPA processes in background (typically 5-30 seconds)

5. App receives update via:
   - Silent push: action=record_updated, resource=booking_verification
   - OR periodic poll of GET /booking-verifications/ (every 10-15 seconds while list is visible)

6. Verification status updates:

   ┌─ VERIFIED
   │  consumer_name populated, cash_to_collect populated
   │  digital_amount populated (may be null or 0 if no digital payment)
   │  order_number_from_rpa confirmed
   │  has_token = false
   │  → Show green badge, "Create Token" button enabled
   │
   ├─ BOOKING_CREATED (ASSISTED mode only)
   │  Same fields populated as VERIFIED
   │  → Show green badge with "Booking Created" label
   │  → "Create Token" button enabled
   │
   └─ FAILED
      error_message and error_code populated
      → Show red badge, error message text
      → "Retry" button always visible
      → "Issue Anyway" button visible only for GM/WM role (→ Workflow 4.5)
```

#### Sad Paths

| Scenario | Error | App Action |
|----------|-------|------------|
| Mode is MANUAL | 400 `CONFIG_OUTDATED` | Re-fetch `/status/`. Show dialog: "SDMS is now offline." Switch to MANUAL UI. |
| Neither consumer_id nor consumer_number provided | 400 validation | Show inline validation error |
| Distribution point invalid | 400 validation | Show error, re-fetch distribution points |
| Network error on POST | HTTP timeout/error | Retry with same idempotency_key. The backend will return the existing verification if it was created. |
| Idempotency_key matches existing | 200 OK | Show the existing verification (not an error) |
| RPA never responds | Verification stays in QUEUED/PROCESSING | After 2 minutes, show "Verification is taking longer than expected. You can retry or wait." |

### 4.3 Token Creation — Standard from Verification

**Precondition:** Verification status is `VERIFIED` or `BOOKING_CREATED`, and `has_token = false`.

#### Happy Path

```
1. User taps "Create Token" on a verified verification card

2. App sends:
   POST /tokens/
   {
     "creation_type": "STANDARD",
     "distribution_point_id": "{selected_point}",
     "booking_verification_id": "{verification_id}",
     "idempotency_key": "{new UUID v4}"
   }
   → 201 Created

3. Response contains:
   token_number (queue number, e.g., 143)
   cash_to_collect (from RPA — exact amount, not estimated)
   digital_amount (from RPA — may be null/0)
   cash_to_collect_is_estimated = false
   booking_origin = PRE_EXISTING or SYSTEM_CREATED
   status = TOKEN_ISSUED
   evidence_required = false

4. Verification card updates: has_token = true, "Create Token" button hidden

5. Token appears in token list

6. Print thermal receipt (see Section 8)

7. Optionally capture photos → tus upload → attach-images
```

#### Sad Paths

| Scenario | Error | App Action |
|----------|-------|------------|
| Duplicate consumer at this point today | 400 | Show "This consumer already has a token today at this point" |
| Duplicate order number | 400 | Show "An active token with this order number already exists" |
| Verification already has a token | 400 | Refresh verification list — another user may have created it |
| Network error | HTTP error | Retry with same idempotency_key |

### 4.4 Token Creation — Standard Direct (MANUAL Mode)

**Precondition:** `mode` is `MANUAL`.

#### Happy Path

```
1. User opens direct token creation form
   Fields: consumer_id, consumer_number (at least one), order_number (optional)

2. User submits
   POST /tokens/
   {
     "creation_type": "STANDARD",
     "distribution_point_id": "{selected_point}",
     "consumer_id": "2-123456789012",
     "consumer_number": "9876543210",
     "order_number": "ORD-2026-001234",
     "idempotency_key": "{UUID v4}"
   }
   → 201 Created

3. Response contains:
   token_number (queue number)
   cash_to_collect (from price cache — may be null)
   digital_amount = null (unknown in MANUAL mode)
   cash_to_collect_is_estimated = true (if price came from cache)
   booking_origin = UNKNOWN
   mode_snapshot = MANUAL
   status = TOKEN_ISSUED

4. Token appears in list

5. Print thermal receipt
   - Amount row shows "(est.)" suffix if cash_to_collect_is_estimated = true
   - Amount row omitted entirely if cash_to_collect = null

6. Optionally capture photos → tus upload → attach-images
```

#### Sad Paths

Same duplicate and validation errors as Workflow 4.3. Additionally:

| Scenario | Error | App Action |
|----------|-------|------------|
| Mode is not MANUAL but no verification provided | 400 | Should not happen if UI is mode-gated. Re-fetch `/status/`. |
| Price cache empty on backend | Not an error | `cash_to_collect` will be null. Show "Amount unavailable" on receipt. |

### 4.5 Supervisor Override (GM/WM Role)

**Precondition:** User has GM/WM role. Verification is in `FAILED` status.

#### Happy Path

```
1. On a FAILED verification card, GM/WM user sees "Issue Anyway" button

2. User taps "Issue Anyway"
   App shows override form: override_reason (mandatory text area)

3. User submits
   POST /tokens/
   {
     "creation_type": "SUPERVISOR_OVERRIDE",
     "distribution_point_id": "{selected_point}",
     "booking_verification_id": "{failed_verification_id}",
     "override_reason": "Consumer has physical receipt, RPA timed out",
     "idempotency_key": "{UUID v4}"
   }
   → 201 Created

4. Response contains:
   booking_origin = UNVERIFIED_EXCEPTION
   evidence_required = true  ← IMPORTANT
   cash_to_collect (from price cache or null — verification failed, no RPA data)
   digital_amount = null
   status = TOKEN_ISSUED

5. Token appears in list with "Evidence Required" badge

6. Print thermal receipt

7. BEFORE delivery: user MUST upload at least one photo
   tus upload → POST /tokens/{id}/attach-images/
   → images_uploaded = true
   → delivery unblocked
```

#### Sad Paths

| Scenario | Error | App Action |
|----------|-------|------------|
| User lacks GM/WM role | 400 | Should not happen if button is role-gated in UI |
| override_reason blank | 400 | Show validation error |
| Attempt to deliver without image | 400 "Evidence required" | Show "Upload photo first", disable deliver button |

### 4.6 Owner's Reference (GM/WM Role)

**Precondition:** User has GM/WM role. Available in all modes.

#### Happy Path

```
1. User taps "Owner's Reference" button

2. Form shows:
   - consumer_name_manual (mandatory) — recipient's name
   - override_reason (mandatory) — why this person is being served
   - order_number (optional)

   NO consumer_id, NO consumer_number fields

3. User submits
   POST /tokens/
   {
     "creation_type": "OWNERS_REFERENCE",
     "distribution_point_id": "{selected_point}",
     "consumer_name_manual": "Bilal Ahmad",
     "override_reason": "Family of army personnel, referred by depot owner",
     "idempotency_key": "{UUID v4}"
   }
   → 201 Created

4. Response contains:
   booking_origin = OWNERS_REFERENCE
   evidence_required = true
   reconciliation_status = NOT_APPLICABLE  ← will never be posted to SDMS
   cash_to_collect (from price cache or null)
   digital_amount = null
   token_number (gets a regular queue number)
   status = TOKEN_ISSUED

5. Token appears in list with "Owner's Reference" and "Evidence Required" badges

6. Print thermal receipt
   - Consumer line shows consumer_name_manual instead of consumer ID
   - No consumer ID / consumer number lines

7. BEFORE delivery: MUST upload at least one photo
```

#### Sad Paths

| Scenario | Error | App Action |
|----------|-------|------------|
| consumer_name_manual blank | 400 | Show validation error |
| override_reason blank | 400 | Show validation error |
| User lacks GM/WM role | 400 | Should not happen if button is role-gated |

### 4.7 Delivery Confirmation

**Precondition:** Token in `TOKEN_ISSUED` status.

#### Pre-Delivery Checks (App-Side)

Before showing the delivery form, check these conditions in order:

```
1. evidence_required == true AND images_uploaded == false?
   → YES: Show "Reference photo required before delivery"
          Deliver button disabled
          Show "Upload Photo" button instead
          → After upload completes → re-check

2. All checks pass → show delivery form
```

#### Happy Path

```
1. User taps "Deliver" on a token card

2. Delivery form shows:
   - DAC code field (visible only if require_dac_code == true, mandatory)
   - Cash collected field (always visible, mandatory)
     Pre-filled with cash_to_collect if available
   - If digital_amount > 0: info line "Digitally paid: Rs. {digital_amount}"

3. User fills and submits
   POST /tokens/{id}/deliver/
   {
     "dac_code": "847291",
     "cash_collected": "1050.00"
   }
   → 200 OK

4. Token updates:
   status = DELIVERED
   delivered_at populated
   cash_collected populated

5. Token moves to "Delivered" section in list
```

#### Sad Paths

| Scenario | Error | App Action |
|----------|-------|------------|
| Evidence required, images not uploaded | 400 | Show "Upload photo first" |
| DAC code required but missing | 400 | Show validation error on DAC field |
| Token already delivered (by another device) | 200 | Show existing delivered state — not an error |
| Token has been voided (by admin) | 400 "Not in TOKEN_ISSUED state" | Refresh token list — token was voided |

### 4.8 Image Upload

**When to trigger:**
- After token creation (optional for STANDARD, mandatory for SUPERVISOR_OVERRIDE/OWNERS_REFERENCE)
- Can be deferred — upload in background, attach URLs when complete

#### Happy Path

```
1. User captures photo via camera
   Compress: ~800px wide, 70% JPEG quality

2. Start tus resumable upload
   - Endpoint: tus server URL (configured in app)
   - Chunked, resumable, background-capable
   - On poor connectivity: tus handles retry/resume automatically

3. On tus upload complete → receive file URL

4. Submit URL to backend:
   POST /tokens/{id}/attach-images/
   {
     "reference_image_1": "https://tus.example.com/files/abc123"
   }
   → 200 OK, images_uploaded = true

5. If evidence_required was true → delivery is now unblocked
```

#### Two Photos

Repeat capture for second photo. Submit both URLs:
```json
{
  "reference_image_1": "https://tus.example.com/files/abc123",
  "reference_image_2": "https://tus.example.com/files/def456"
}
```

#### Sad Paths

| Scenario | Recovery |
|----------|----------|
| tus upload fails mid-way | tus protocol handles resume — retry automatically |
| tus upload succeeds but attach-images API fails | Retry attach-images with the same URL — last write wins |
| User captures new photo after already attaching | Submit again — overwrites previous URLs |

### 4.9 Quick Delivery

**Precondition:** Distribution point has `allow_quick_delivery = true`.

#### Happy Path (MANUAL Mode)

```
1. User taps "Quick Delivery" at a quick-delivery-enabled point

2. Single form shows:
   - consumer_id / consumer_number (at least one)
   - order_number (optional)
   - DAC code (if require_dac_code)
   - cash_collected (mandatory)
   - Photo capture (optional)

3. If photos captured → tus upload first, get URLs

4. Submit:
   POST /tokens/quick-deliver/
   {
     "distribution_point_id": "...",
     "consumer_id": "2-123456789012",
     "consumer_number": "9876543210",
     "cash_collected": "1050.00",
     "reference_image_1": "https://tus.example.com/...",
     "idempotency_key": "..."
   }
   → 201 Created

5. Token created with:
   status = DELIVERED
   token_number = null (no queue position)
   is_quick_delivery = true

6. No receipt printed (no queue to manage)
7. Done
```

#### Happy Path (ASSISTED/VERIFIED Mode)

```
1. User FIRST completes Workflow 4.2 (booking verification)
2. Once verification is VERIFIED/BOOKING_CREATED:

   POST /tokens/quick-deliver/
   {
     "distribution_point_id": "...",
     "booking_verification_id": "...",
     "dac_code": "847291",
     "cash_collected": "1050.00",
     "idempotency_key": "..."
   }
   → 201 Created
```

#### Sad Paths

| Scenario | Error | App Action |
|----------|-------|------------|
| Quick delivery not enabled at point | 400 | Should not happen if button visibility is gated on `allow_quick_delivery` |
| All token creation validations | Same as Workflow 4.3/4.4 | Same actions |
| Missing cash_collected | 400 | Show validation error |

### 4.10 Correction (After Reconciliation Failure)

**Trigger:** Token has `reconciliation_status = CORRECTION_NEEDED`.

#### Detection

The app detects tokens needing correction via:
1. Silent push: `action=record_updated, resource=delivery_token`
2. Periodic poll: `GET /tokens/?reconciliation_status=CORRECTION_NEEDED`
3. On the main token list: filter/badge for `CORRECTION_NEEDED` status

#### Happy Path

```
1. App shows correction-needed tokens prominently
   Each card shows:
   - reconciliation_error (why it failed)
   - reference_image_1/reference_image_2 (for visual review)
   - Editable fields: consumer_id, consumer_number, order_number, dac_code

2. User reviews the reference photo, identifies the error

3. User corrects the relevant field(s)
   POST /tokens/{id}/correct/
   {
     "consumer_number": "9876543211"
   }
   → 200 OK

4. Token updates:
   reconciliation_status = CORRECTED
   corrected_by populated

5. Admin will re-queue corrected tokens for reconciliation
   (transparent to the app — no action needed)
```

#### Sad Paths

| Scenario | Behavior |
|----------|----------|
| Already CORRECTED | Returns existing state (200) — idempotent per cycle |
| Wrong correction → reconciliation fails again | New `CORRECTION_NEEDED` cycle opens — user can correct again |
| Admin corrects from Django panel instead | Token goes to CORRECTED without app involvement — app sees updated status |

### 4.11 Local Cleanup

**Purpose:** Clean up local photo files for tokens that have reached terminal reconciliation states.

```
Periodically (on app resume, or every 30 minutes):

  GET /tokens/?date={each locally cached date with images}

  For each token with local images:
  ├─ reconciliation_status == POSTED       → delete local images
  ├─ reconciliation_status == NOT_APPLICABLE → delete local images
  ├─ status == VOIDED                      → delete local images, hide from active list
  └─ Otherwise                             → keep
```

**Important:** Only delete local images (the compressed files on disk). The tus URLs in the backend are the authoritative copies.

---

## 5. Design Change: `digital_amount` Field

### What Changed from the Original Design

The original design stored financial data as:
- `cash_to_collect` — total amount from RPA (the complete order value)
- `is_digitally_paid` — boolean flag indicating digital payment exists

During implementation, we added **`digital_amount`** (DecimalField, nullable) to both `BookingVerification` and `OfflineDeliveryToken`. This changes the semantics of `cash_to_collect`:

| Field | Original Meaning | New Meaning |
|-------|-----------------|-------------|
| `cash_to_collect` | Total order value | **Cash portion only** — what the delivery boy should collect in cash |
| `digital_amount` | _(did not exist)_ | Amount already settled digitally (UPI, loyalty points, etc.) |
| `is_digitally_paid` | Whether any digital payment exists | Unchanged — boolean convenience flag |

**The total order value = `cash_to_collect` + `digital_amount`** (when both are known).

### Impact by Mode

| Mode | `cash_to_collect` | `digital_amount` | Source |
|------|-------------------|-------------------|--------|
| ASSISTED/VERIFIED (from RPA) | Cash portion from RPA | Digital portion from RPA | Both populated by RPA via verification |
| MANUAL (no RPA) | Full estimated price from cache | `null` | Price cache knows total price, not payment split |
| SUPERVISOR_OVERRIDE | From price cache or null | `null` | Verification failed — no RPA data available |
| OWNERS_REFERENCE | From price cache or null | `null` | No verification at all |

### Display Rules for the App

**On the token card (list view):**
```
if digital_amount != null && digital_amount > 0:
    Show "Cash: Rs. {cash_to_collect}" (main amount)
    Show "Digital: Rs. {digital_amount}" (secondary, smaller text, different color)
else if cash_to_collect != null:
    Show "Amount: Rs. {cash_to_collect}"
    if cash_to_collect_is_estimated:
        Append "(est.)" suffix
else:
    Show "Amount: —" or "Amount unavailable"
```

**On the delivery confirmation form:**
```
if digital_amount != null && digital_amount > 0:
    Show info line: "Already paid digitally: Rs. {digital_amount}"
    Pre-fill cash_collected with cash_to_collect
    Label: "Cash to collect"
else:
    Pre-fill cash_collected with cash_to_collect
    Label: "Amount to collect"
```

**On the thermal receipt:**
```
if digital_amount != null && digital_amount > 0:
    Print "Digital Paid : Rs. {digital_amount}"
    Print "Cash Amount  : Rs. {cash_to_collect}"
else if cash_to_collect != null:
    Print "Amount       : Rs. {cash_to_collect}"
    if cash_to_collect_is_estimated:
        Append " (est.)"
else:
    Omit amount line entirely
```

### Why This Matters

In the field, a delivery boy needs to know **how much cash to collect**, not the total order value. If a consumer has already paid Rs. 500 digitally on a Rs. 1050 order, the delivery boy collects Rs. 550 in cash. The original design would have shown "Rs. 1050" and relied on the delivery boy to figure out the split. The new design shows "Cash: Rs. 550" and "Digital: Rs. 500" explicitly.

In MANUAL mode, `digital_amount` is null because there's no RPA to determine the payment split. The full estimated price is shown and the delivery boy collects based on whatever information the consumer provides (printed receipt, previous payment record, etc.). During reconciliation, the RPA will determine the actual split.

---

## 6. Silent Push Notifications

### Payload Format

Silent push notifications are data-only pushes (no user-visible alert) that tell the app to refresh specific data.

```json
{
  "silent": true,
  "scope": "offline_delivery",
  "action": "config_refresh",
  "resource": "system_status",
  "resource_id": null,
  "timestamp": "2026-03-14T20:15:00"
}
```

### Handling Matrix

| `action` | `resource` | App Action |
|----------|-----------|------------|
| `config_refresh` | `system_status` | Re-fetch `GET /status/`. If mode changed, rebuild UI. |
| `config_refresh` | `distribution_point` | Re-fetch `GET /distribution-points/`. Update picker, counts. |
| `record_updated` | `booking_verification` | Re-fetch `GET /booking-verifications/` (or just the single record if `resource_id` is provided). Update verification list. |
| `record_updated` | `delivery_token` | Re-fetch affected token. Check if `reconciliation_status` changed to `CORRECTION_NEEDED`. |

### Implementation Notes

1. **FCM data message** — these are FCM data-only messages (not notification messages). On Android, they are delivered to the app even in the background via `onMessageReceived`. On iOS, they require `content-available: 1` and background modes enabled.

2. **Deduplication** — use `timestamp` to ignore stale pushes (e.g., if two pushes arrive for the same `resource` and the first one already triggered a fetch).

3. **Batching** — if multiple pushes arrive in quick succession (e.g., admin toggles system status twice in 5 seconds), debounce the API calls (e.g., wait 2 seconds after last push before fetching).

4. **Fallback** — silent push is best-effort. The app should also poll periodically (every 30-60 seconds when on the main screen) as a fallback if push delivery is unreliable.

---

## 7. Verification Status Indicators

### Verification Card States

| Status | Badge Color | Badge Text | Actions Available |
|--------|-------------|------------|-------------------|
| `QUEUED` | Blue | "Queued" | None (waiting) |
| `PROCESSING` | Light Blue | "Verifying..." | None (RPA running) |
| `VERIFIED` | Green | "Verified" | "Create Token" (if `has_token = false`) |
| `BOOKING_CREATED` | Green | "Booking Created" | "Create Token" (if `has_token = false`) |
| `FAILED` | Red | "Failed" | "Retry" (all users), "Issue Anyway" (GM/WM only) |

### Token Card States

| `status` | Badge Color | Badge Text |
|----------|-------------|------------|
| `TOKEN_ISSUED` | Blue | "Issued" or "#{token_number}" |
| `DELIVERED` | Green | "Delivered" |
| `VOIDED` | Grey | "Voided" |

### Reconciliation Status Indicators (on Delivered Tokens)

| `reconciliation_status` | Badge Color | Badge Text | User Action |
|------------------------|-------------|------------|-------------|
| `NOT_STARTED` | Grey | — (don't show) | None |
| `NOT_APPLICABLE` | Grey | "N/A" (subtle) | None |
| `QUEUED` | Blue | "Reconciling..." | None |
| `POSTED` | Green | "Posted" | Cleanup local images |
| `FAILED` | Red | "Recon. Failed" | None (admin handles) |
| `CORRECTION_NEEDED` | Orange | "Correction Needed" | Show correction form |
| `CORRECTED` | Purple | "Corrected" | None (waiting for re-queue) |

### Booking Origin Indicators (on Token Cards)

| `booking_origin` | Label | Visibility |
|-----------------|-------|------------|
| `PRE_EXISTING` | "Pre-existing Booking" | Subtle/small text |
| `SYSTEM_CREATED` | "System Booking" | Subtle/small text |
| `UNKNOWN` | "Unverified" | Subtle/small text, MANUAL mode indicator |
| `UNVERIFIED_EXCEPTION` | "Supervisor Override" | Prominent, orange/yellow badge |
| `OWNERS_REFERENCE` | "Owner's Reference" | Prominent, distinct badge |

### Creation Type Indicators

| `creation_type` | Where to Show | Visual Treatment |
|----------------|---------------|------------------|
| `STANDARD` | Don't show (default) | — |
| `SUPERVISOR_OVERRIDE` | Token card, detail view | Orange badge |
| `OWNERS_REFERENCE` | Token card, detail view | Distinct badge (e.g., purple/teal) |

### Evidence Required Indicator

When `evidence_required = true` and `images_uploaded = false`:
- Show camera icon with exclamation mark on token card
- Show "Photo required before delivery" text
- Delivery button disabled/greyed out

When `evidence_required = true` and `images_uploaded = true`:
- Show camera icon with checkmark (green)
- Delivery button enabled

---

## 8. Thermal Receipt Printing

### Token Receipt (printed after token creation, NOT for quick delivery)

```
================================
       DELIVERY TOKEN
================================

Token No    : #143
Location    : Sherpur Godown
Date        : 13/03/2026
Time        : 10:35 AM

Consumer    : Mohd Rafiq           ← from consumer_name (or consumer_name_manual)
Consumer ID : 2-123456789012       ← omit row if null
Consumer No : 9876543210           ← omit row if null
Order No    : ORD-2026-001234      ← omit row if null

Digital Paid: Rs. 500.00           ← only if digital_amount > 0
Cash Amount : Rs. 550.00           ← use this label if digital_amount > 0
Amount      : Rs. 1050.00 (est.)   ← use this label if no digital split; add (est.) if estimated
--------------------------------

        ┌─────────────┐
        │   QR CODE   │            ← QR encodes order_number; omit block if no order_number
        │ (Order No)  │
        └─────────────┘

Please wait for your turn.
================================



```

**Rules:**
- `consumer_name` or `consumer_name_manual` for Consumer line — omit if both empty
- Consumer ID row: omit if `consumer_id` is null
- Consumer No row: omit if `consumer_number` is null
- Order No row: omit if `order_number` is null
- Financial section: see `digital_amount` display rules in Section 5
- QR code: only when `order_number` is available
- 3 line feeds at end for thermal paper tear
- **Quick delivery does NOT print a receipt**

---

## 9. Idempotency Guide

### Why Idempotency Keys Matter

Field conditions (poor connectivity, impatient users, network retries) mean the app will frequently need to retry requests. Without idempotency, retries create duplicates.

### Rules by Endpoint

| Endpoint | Idempotency Mechanism | App Behavior |
|----------|----------------------|--------------|
| `POST /booking-verifications/` | `idempotency_key` (client UUID) | Generate once, retry with same key. 200 = already exists. |
| `POST /tokens/` | `idempotency_key` (client UUID) | Generate once, retry with same key. 200 = already exists. |
| `POST /tokens/{id}/deliver/` | First-write-wins on token status | Retry safe. If already DELIVERED, returns existing state. |
| `POST /tokens/{id}/correct/` | Per-cycle: CORRECTION_NEEDED → CORRECTED | Retry safe within same cycle. |
| `POST /tokens/{id}/attach-images/` | Last-write-wins | Retry replaces URLs. No idempotency key needed. |
| `POST /tokens/quick-deliver/` | `idempotency_key` (client UUID) | Generate once, retry with same key. |
| `POST /booking-verifications/{id}/retry/` | FSM guard (must be FAILED) | Retry safe — if already QUEUED, returns success. |

### Implementation Pattern

```dart
// Generate key once when user initiates action
final idempotencyKey = Uuid().v4();

// Store key locally (e.g., in form state)
// On retry (network error, timeout), reuse SAME key
// On NEW action (user fills form again), generate NEW key

try {
  final response = await api.createToken(
    distributionPointId: selectedPoint.id,
    creationType: 'STANDARD',
    // ... other fields
    idempotencyKey: idempotencyKey,
  );

  if (response.statusCode == 201) {
    // New token created
  } else if (response.statusCode == 200) {
    // Existing token returned (idempotent retry)
    // Treat the same as 201 — show the token
  }
} catch (e) {
  // Network error — retry with SAME idempotencyKey
}
```

---

## 10. Error Code Reference

### Standard Error Format

All 400-level errors follow this shape:

```json
{
  "error": "Human-readable error message",
  "code": "MACHINE_READABLE_CODE"
}
```

Or for field-level validation errors:

```json
{
  "field_name": ["Error message for this field"]
}
```

### Error Codes

| Code | Endpoint | Meaning | App Action |
|------|----------|---------|------------|
| `CONFIG_OUTDATED` | Any | System mode has changed since app last fetched status | Re-fetch `GET /status/`, rebuild UI, show mode change toast |
| `QUOTA_EXHAUSTED` | Verification callback | Consumer's refill quota used up | Show error on verification card. No retry will help — consumer must wait. |
| `MIN_DAYS_RULE` | Verification callback | Not enough days since last refill | Show error with next eligible date from `error_message` |
| `CONSUMER_NOT_FOUND` | Verification callback | Consumer ID/number not found in SDMS | Show error. User should check ID and retry, or supervisor can override. |

### HTTP Status Codes

| Status | Meaning | General App Action |
|--------|---------|-------------------|
| 200 | Success (or idempotent return) | Process response |
| 201 | Created | Process response |
| 400 | Validation error | Show error message(s) |
| 401 | JWT expired | Refresh token, retry |
| 403 | Permission denied (role check) | Should not happen if UI is role-gated |
| 404 | Resource not found | Refresh list, resource may have been deleted |
| 428 | Missing company claim in JWT | Re-authenticate with company selection |
| 500 | Server error | Show generic error, retry after delay |

---

## 11. Recommended App State Architecture

### Local State to Cache

| State | Storage | Refresh Trigger |
|-------|---------|-----------------|
| System status (mode, flags) | In-memory + SharedPreferences | Silent push, app resume, CONFIG_OUTDATED error |
| Distribution points list | In-memory + SharedPreferences | Silent push, app resume |
| Selected distribution point | SharedPreferences | User action |
| User role (has GM/WM) | SharedPreferences | Login, token refresh |
| Pending tus uploads | SQLite or Hive | tus completion callback |
| Local photo file paths | SQLite or Hive (keyed by token ID) | Capture, cleanup |

### What NOT to Cache Locally

- Token data (always fetch from server — it's the source of truth)
- Verification data (always fetch from server)
- Prices (backend handles this internally)
- Reconciliation state (server-managed)

### Polling Strategy

When silent push is unreliable (app foregrounded but push not received):

| Screen | What to Poll | Interval |
|--------|-------------|----------|
| Verification list visible | `GET /booking-verifications/` | Every 10-15 seconds |
| Token list visible | `GET /tokens/` | Every 30 seconds |
| Main screen (idle) | `GET /status/` | Every 60 seconds |
| Background | Nothing | Rely on silent push |

---

## 12. Token List Sorting & Grouping

### Default Sort Order

Tokens should be displayed most-recent-first (`created_at` descending), but the primary view should be **grouped by status** for operational clarity:

**Section 1: Pending Delivery** (`status = TOKEN_ISSUED`)
- Sort by `token_number` ascending (queue order)
- Show evidence_required badge where applicable
- "Deliver" action button

**Section 2: Delivered Today** (`status = DELIVERED`, today)
- Sort by `delivered_at` descending
- Show reconciliation_status badge

**Section 3: Needs Correction** (`reconciliation_status = CORRECTION_NEEDED`)
- Prominent — orange/yellow section header
- "Correct" action button

**Section 4: Quick Deliveries** (`is_quick_delivery = true`, today)
- Sort by `created_at` descending
- No token number shown

### Filtering

Provide filter chips for:
- All / Pending / Delivered / Voided
- Distribution point (if user operates at multiple)
- Date picker (default: today)

---

## 13. End-to-End Scenario Examples

### Scenario A: Normal Day, SDMS Down (MANUAL Mode)

```
08:00  Admin sets sdms_active=false, booking_channels_active=false, otp_channels_active=false
       → Silent push → app switches to MANUAL mode, shows "SDMS Offline" banner

08:15  Delivery boy Ravi selects "Sherpur Godown" as distribution point

08:20  Consumer #1 arrives with consumer ID card
       Ravi enters consumer_id → POST /tokens/ (STANDARD, MANUAL)
       → Token #1 created, cash_to_collect = 1050.00 (est.), digital_amount = null
       Ravi prints receipt, hands to consumer

08:25  Consumer #2 arrives
       Same flow → Token #2

09:30  Consumer #1's turn
       Ravi taps "Deliver" on Token #1
       DAC code field hidden (otp_channels_active = false)
       Enters cash_collected = 1050.00
       → Token #1 status = DELIVERED

12:00  GM at desk — person without consumer ID arrives, referred by depot owner
       GM taps "Owner's Reference"
       Enters name "Bilal Ahmad", reason "Army family, depot owner reference"
       → Token #87 created, booking_origin = OWNERS_REFERENCE
       GM captures photo of person's Aadhaar card → tus upload → attach-images
       Later, delivers Token #87 with cash_collected = 1050.00

20:00  Admin triggers reconciliation from Django admin
       Tokens queued for Camunda RPA → posts to SDMS overnight

Next morning:
       Ravi opens app → tokens show reconciliation_status = POSTED
       App deletes local images for posted tokens
```

### Scenario B: Partial SDMS, Booking Channels Down (ASSISTED Mode)

```
08:00  Admin sets sdms_active=true, booking_channels_active=false, otp_channels_active=true
       → ASSISTED mode, DAC required

08:20  Consumer arrives — "I couldn't book online, the website is down"
       Delivery boy enters consumer_id → POST /booking-verifications/
       → Status QUEUED, card shows "Verifying..."

08:21  RPA checks SDMS:
       - No existing booking found
       - allow_booking_creation = true (ASSISTED mode)
       - RPA creates booking
       → Verification status = BOOKING_CREATED
       → cash_to_collect = 1050.00, digital_amount = null
       → Push notification: "Booking created for Consumer 2-123456789012"

08:22  Delivery boy taps "Create Token" on the verified card
       → Token created, booking_origin = SYSTEM_CREATED

09:30  Delivery time
       DAC code field shown (otp_channels_active = true)
       Consumer provides DAC from SMS → "847291"
       Delivery boy enters DAC + cash_collected
       → Delivered
```

### Scenario C: Verification Fails, Supervisor Override

```
10:00  Delivery boy submits verification for consumer
       → RPA returns FAILED, error_code = QUOTA_EXHAUSTED
       → "Consumer quota exhausted. Next eligible: 2026-03-28"

10:01  Delivery boy shows error to consumer
       Consumer insists they haven't received a cylinder this month
       Consumer shows physical receipt from the booking office

10:02  Delivery boy calls GM desk
       GM opens the same verification on their device
       GM taps "Issue Anyway"
       Enters reason: "Consumer has booking office receipt dated 2026-03-12"
       → Token created, creation_type = SUPERVISOR_OVERRIDE
       → evidence_required = true

10:03  GM captures photo of the physical receipt
       tus upload → attach-images → images_uploaded = true

10:15  Consumer's turn → normal delivery (with DAC if OTP active)

20:00  Reconciliation flags this token for priority review
       Admin verifies the receipt photo and approves posting
```

### Scenario D: Quick Delivery at Mobile Truck

```
11:00  Small truck at remote location, low volume
       Distribution point "Lal Chowk Truck" has allow_quick_delivery = true

11:05  Consumer arrives
       Mode is ASSISTED → delivery boy submits verification first
       → VERIFIED, cash_to_collect = 1050.00, digital_amount = 200.00

11:06  Delivery boy taps "Quick Deliver"
       Form pre-filled from verification:
         "Already paid digitally: Rs. 200.00"
         Cash to collect: Rs. 1050.00 (pre-filled)
       Enters DAC code, captures photo
       → POST /tokens/quick-deliver/
       → Token created + delivered in one call
       → No receipt printed
```

### Scenario E: Correction After Reconciliation Failure

```
Day 1, 20:00  Admin triggers reconciliation
              Token #42 fails: "Order number ORD-2026-001234 not found in SDMS"
              → reconciliation_status = CORRECTION_NEEDED
              → Silent push to delivery boy

Day 2, 08:00  Delivery boy opens app
              Sees orange "Correction Needed" badge on Token #42
              Opens correction form:
                Shows: reconciliation_error message
                Shows: reference photo of consumer's receipt
                Editable: consumer_id, consumer_number, order_number, dac_code

              Delivery boy checks photo → order number was misread
              Actual number: ORD-2026-001243 (last two digits swapped)
              POST /tokens/{id}/correct/
              { "order_number": "ORD-2026-001243" }
              → reconciliation_status = CORRECTED

Day 2, 20:00  Admin re-queues corrected tokens
              Token #42 posts successfully
              → reconciliation_status = POSTED
              → Silent push → app cleans up local images
```

---

## 14. Cross-Reference: Design Document Sections

This guide corresponds to the following sections in `OFFLINE_DELIVERY_DESIGN.md`:

| This Guide Section | Design Doc Section |
|--------------------|-------------------|
| 2. System Modes | Section 2. System Status Model |
| 3.1 System Status API | Section 6.1 |
| 3.2 Distribution Points API | Section 6.2 |
| 3.3 Booking Verifications API | Section 6.3 |
| 3.4 Tokens API | Section 6.4, 6.5, 6.6 |
| 4.1-4.11 Workflows | Section 4. Core Workflow |
| 5. digital_amount Change | NEW — not in original design, added during implementation |
| 6. Silent Push | Section 9. Notification Events |
| 7. Status Indicators | Section 5. Data Models (status enums) |
| 8. Thermal Receipt | Section 8. Thermal Receipt Format |
| 9. Idempotency | Scattered across Section 6 API specs |
| N/A (backend-only) | Section 7. Camunda Process Definitions |
| N/A (backend-only) | Section 10. Django App Structure |
| N/A (backend-only) | Section 12. Relationship to Existing Systems |

---

## 15. Implementation Checklist

### Phase 1: Foundation
- [ ] Add `/api/offline-delivery/` base URL to API client
- [ ] Create data models (DTOs) for: SystemStatus, DistributionPoint, BookingVerification, OfflineDeliveryToken
- [ ] Implement `GET /status/` and cache result
- [ ] Implement `GET /distribution-points/` and distribution point picker
- [ ] Add mode-switching logic (rebuild UI on mode change)
- [ ] Set up silent push listener with `scope=offline_delivery` filter

### Phase 2: Token Creation (MANUAL Mode)
- [ ] Direct token creation form (consumer_id, consumer_number, order_number)
- [ ] `POST /tokens/` with `creation_type=STANDARD`
- [ ] Idempotency key generation and retry handling
- [ ] Token list (`GET /tokens/`) with status badges
- [ ] Thermal receipt printing
- [ ] `cash_to_collect` display with `(est.)` suffix logic
- [ ] Duplicate error handling

### Phase 3: Verification + Token Creation (ASSISTED/VERIFIED)
- [ ] Booking verification form
- [ ] `POST /booking-verifications/` with idempotency
- [ ] Verification list with status polling / silent push refresh
- [ ] `CONFIG_OUTDATED` error handling → re-fetch status
- [ ] "Create Token" from verified verification
- [ ] `digital_amount` display on verification cards and token cards
- [ ] Error code display for failed verifications (QUOTA_EXHAUSTED, etc.)
- [ ] Retry button (`POST /booking-verifications/{id}/retry/`)

### Phase 4: Delivery Confirmation
- [ ] Delivery form with conditional DAC code field
- [ ] Evidence-required gate (check images_uploaded before allowing delivery)
- [ ] `POST /tokens/{id}/deliver/`
- [ ] Pre-fill `cash_collected` from `cash_to_collect`
- [ ] `digital_amount` info line on delivery form
- [ ] First-write-wins handling (already-delivered = success)

### Phase 5: Image Upload
- [ ] Camera capture + compression
- [ ] tus resumable upload client integration
- [ ] `POST /tokens/{id}/attach-images/` after tus completion
- [ ] Pending upload queue (retry failed tus uploads)
- [ ] Visual indicator: camera icon with checkmark/exclamation

### Phase 6: Supervisor Flows (GM/WM Role)
- [ ] Role detection (has GM/WM role → show supervisor buttons)
- [ ] "Issue Anyway" button on failed verifications
- [ ] Override reason form
- [ ] `SUPERVISOR_OVERRIDE` token creation
- [ ] "Owner's Reference" button and form
- [ ] `consumer_name_manual` and `override_reason` mandatory fields
- [ ] `OWNERS_REFERENCE` token creation
- [ ] Evidence-required enforcement for both types

### Phase 7: Quick Delivery
- [ ] Quick delivery button (visible only if point allows)
- [ ] Combined form (verification reference + delivery fields)
- [ ] `POST /tokens/quick-deliver/`
- [ ] No receipt printing for quick delivery

### Phase 8: Corrections
- [ ] Detect `CORRECTION_NEEDED` tokens (push + poll)
- [ ] Correction form with reference image display
- [ ] `POST /tokens/{id}/correct/`
- [ ] Per-cycle idempotency handling

### Phase 9: Cleanup & Polish
- [ ] Local image cleanup based on reconciliation_status
- [ ] Voided token handling (hidden from active list)
- [ ] Token list sorting and grouping (Section 12)
- [ ] Date picker for historical token viewing
- [ ] Error states: network offline, server unreachable
- [ ] Loading states: verification pending, delivery submitting
