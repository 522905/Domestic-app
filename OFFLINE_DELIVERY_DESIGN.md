# Offline Delivery — System Design Document

## 0. About This Document

### What we are designing

A Django app (`offline_delivery`) that serves as the backend for LPG cylinder distribution when Indian Oil's digital systems (SDMS) are partially or fully unavailable. It provides REST APIs consumed by a Flutter mobile app used by delivery boys in the field. The system captures consumer identity, queue tokens, delivery confirmations, and reference images — all of which would normally go through SDMS — and defers the SDMS posting to off-peak hours via Camunda RPA automation.

### Why we are designing it

An ongoing geopolitical crisis has caused 8-10x normal LPG demand. Indian Oil's SDMS ecosystem — which handles bookings, OTP-based delivery authentication, and sales recording — cannot cope with the load and goes down frequently during peak hours. Distribution still happens physically (trucks arrive, cylinders are handed out), but without digital capture, there is no audit trail, no queue management, and no way to reconcile deliveries against SDMS later. The current workaround is a purely local "Service Booking" feature in the app (SharedPreferences + thermal print + CSV export) which has no backend, no verification, and no path to SDMS reconciliation.

### Design intent

1. **Graceful degradation, not all-or-nothing.** SDMS has three subsystems (booking channels, OTP/DAC channels, core SDMS) that fail independently. The system defines three operational modes (MANUAL, ASSISTED, VERIFIED) derived from which subsystems are up, so field operations use as much SDMS capability as is available at any given moment.

2. **Capture first, reconcile later.** During operating hours (8 AM–8 PM), the priority is speed — get the consumer a token, hand over the cylinder, print a receipt. SDMS posting happens asynchronously via RPA during off-peak windows. The data model is designed so that every token carries enough information to be fully reconciled later, even if it was created in full-offline MANUAL mode.

3. **Backend-authoritative, not local-first.** Unlike the current Service Booking feature, all data lives on the server. The only thing deferred to background is image upload (via tus resumable protocol) for poor-connectivity scenarios. Token numbers are assigned atomically via Redis INCR, not locally.

4. **Fit into the existing ecosystem.** After reconciliation, tokens link to `sdms_claims.SDMSOrder` (existing model) via a new `OFFLINE_DELIVERY` source choice. The system reuses existing patterns: Django-FSM for state management, django-rq for background jobs, Camunda for RPA orchestration, the same JWT auth and company-scoping used across all apps.

5. **Designed for review.** This document is the complete specification — data models, API contracts, state machines, Camunda process definitions, thermal receipt format, and mobile integration checklist. It is intended to be critiqued and refined before any code is written.

---

## 1. Context & Problem Statement

Indian Oil's SDMS (Supplier Delivery Management System) ecosystem consists of three independently-failing components:

| Component | What it does |
|-----------|-------------|
| **Booking Channels** | Consumer places an order/booking for a cylinder refill |
| **OTP/Delivery Channels** | Consumer receives a DAC (Delivery Authentication Code) via SMS after booking |
| **SDMS** | Core system — hosts consumer data, validates bookings, records deliveries. The SDMS mobile app is used by delivery boys to confirm sales |

During the current geopolitical crisis, LPG demand is 8-10x normal. These systems are frequently degraded or unavailable. Distribution points handle 800-1500 consumers per day with 8-10 delivery boys working simultaneously.

**Goal:** Digitally capture all booking, queue, and delivery data in the field during operating hours. Push accumulated data to SDMS via Camunda RPA during off-peak hours (before 8 AM / after 8 PM).

---

## 2. System Status Model

Three independent boolean flags, configured globally from Django admin:

```
sdms_active            : bool   — Is the SDMS core system reachable?
booking_channels_active : bool   — Can consumers place bookings themselves?
otp_channels_active     : bool   — Are OTP/DAC SMS channels delivering?
```

These derive the operational mode:

| SDMS | Booking | Mode | Reads as |
|------|---------|------|----------|
| ❌ | x | **MANUAL** | Manual Operations — everything is down, we're on our own. Pure data capture, collect full cash, token for queue management. |
| ✅ | ❌ | **ASSISTED** | Booking Assisted — RPA is bridging the gap. RPA verifies/creates bookings on consumer's behalf. |
| ✅ | ✅ | **VERIFIED** | Verified Only — official channels handled it. Consumer books themselves, we only verify via RPA. |

OTP channel status (`otp_channels_active`) is a **cross-cutting flag** independent of mode. It controls whether DAC code entry is required at delivery confirmation, regardless of which mode is active.

**Mode derivation logic:**
- `sdms_active = false` → **MANUAL** (regardless of other flags)
- `sdms_active = true, booking_channels_active = false` → **ASSISTED**
- `sdms_active = true, booking_channels_active = true` → **VERIFIED**

**Key rules:**
- **MANUAL**: No RPA interaction. All data accepted as-is. Reconciled later.
- **ASSISTED**: RPA is allowed to **create** bookings on the consumer's behalf (if none exists).
- **VERIFIED**: RPA only **verifies** existing bookings — never creates.
- **OTP flag**: When `otp_channels_active = true`, DAC code is required at delivery. When `false`, delivery is confirmed without DAC.

---

## 3. Distribution Points

Distribution points are **not** the same as warehouses. They are the physical locations where consumers queue and collect cylinders on a given day. They can be:

- **Permanent** — mapped to an existing warehouse (e.g., "Sherpur Godown")
- **Ad hoc** — a truck dispatched to a high-demand area (e.g., "Lal Chowk Truck — 13 Mar 2026")

A delivery boy selects their active distribution point when they begin operating. Token queue numbers are scoped to **distribution point + date** and reset daily.

### Model: `DistributionPoint`

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `company` | FK → Company | Company scope |
| `name` | CharField(100) | Display name (e.g., "Sherpur Godown", "Lal Chowk Truck") |
| `warehouse` | FK → Warehouse, nullable | Linked warehouse (null for ad hoc points) |
| `is_adhoc` | BooleanField | Whether this is a temporary/ad hoc location |
| `allow_quick_delivery` | BooleanField | Whether one-shot delivery (skip queue) is enabled at this point |
| `is_active` | BooleanField | Active/inactive toggle |
| `created_at` | DateTimeField | Auto |
| `updated_at` | DateTimeField | Auto |

---

## 4. Core Workflow

The workflow has three entry points into a single `OfflineDeliveryToken` model:

### Entry Point 1: Full Workflow (Crowd Management)

```
┌─────────────────────────────────────────────────────────┐
│ Step 1: BOOKING VERIFICATION (ASSISTED & VERIFIED only) │
│                                                         │
│ Delivery boy enters consumer ID/number + order # (opt)  │
│ → Backend queues Camunda RPA job (async)                │
│ → Delivery boy moves to next consumer                   │
│ → RPA result arrives: verified / created / error        │
│ → Push notification + list update on mobile             │
│                                                         │
│ If SDMS down (MANUAL mode): skip this step entirely     │
│ If RPA returns error: BLOCKED for regular delivery boys │
│   (delivery boy sees error reason, e.g. "quota          │
│    exhausted", "25-day rule", "consumer not found")     │
│                                                         │
│ SUPERVISOR OVERRIDE: Manager/WM/GM role can still       │
│   "Issue Anyway" — creates unverified token with        │
│   mandatory photo + reason, flagged for priority        │
│   reconciliation review                                 │
└───────────────┬─────────────────────────────────────────┘
                │ Success / MANUAL mode
                ▼
┌─────────────────────────────────────────────────────────┐
│ Step 2: TOKEN CREATION                                  │
│                                                         │
│ From verified booking → "Create Token" action           │
│ From MANUAL mode → direct token creation (unverified)   │
│                                                         │
│ Assigns queue number (per distribution point, per day)  │
│ Captures 1-2 reference photos (deferred upload)         │
│ Prints thermal receipt:                                 │
│   Queue #, distribution point, consumer ID/number,      │
│   order #, amount to pay, date/time                     │
│                                                         │
│ Consumer receives receipt and waits for their turn       │
└───────────────┬─────────────────────────────────────────┘
                │ Consumer's turn (could be 1-2 hours later)
                ▼
┌─────────────────────────────────────────────────────────┐
│ Step 3: DELIVERY CONFIRMATION                           │
│                                                         │
│ If OTP channels active: delivery boy enters DAC code    │
│ If OTP channels down: just mark as delivered            │
│                                                         │
│ Record cash_collected amount                            │
│ Token → DELIVERED                                       │
└───────────────┬─────────────────────────────────────────┘
                │ Off-hours (admin triggers)
                ▼
┌─────────────────────────────────────────────────────────┐
│ Step 4: RECONCILIATION                                  │
│                                                         │
│ Admin triggers push to Camunda RPA                      │
│ RPA posts bookings + delivery confirmations to SDMS     │
│ If data error → reconciliation_status = CORRECTION_NEEDED│
│ → Push notification to delivery boy                     │
│ → Delivery boy reviews reference photo, corrects data   │
│ → OR admin corrects from photo if deadline approaching  │
│ Corrected token re-queued for posting                   │
│ On success → reconciliation_status = POSTED             │
│ → device cleanup signal                                 │
└─────────────────────────────────────────────────────────┘
```

### Entry Point 2: MANUAL Mode Direct Token (SDMS Down)

Same as Step 2 above, but with no prior booking verification. Consumer-provided data is accepted as-is. Cash collection defaults to the cached price list amount (marked as "estimated").

### Entry Point 3: Quick Delivery (One-Shot)

For low-volume distribution points where crowd management isn't needed. Enabled per-distribution-point via `allow_quick_delivery`.

Consolidates token creation + delivery confirmation + image attachment into a single API call. No queue number assigned. Status jumps directly to `DELIVERED`.

**Important:** Quick delivery does NOT skip booking verification. In ASSISTED/VERIFIED modes, the booking must be verified first (Step 1 still applies). Quick delivery only skips the queue/crowd management stages — it is not a shortcut past verification.

### Entry Point 4: Owner's Reference (GM/Manager Desk)

For people who are **not registered consumers** at this agency. The manager/GM desk can issue a token directly — no consumer ID, no consumer number, no booking verification required.

- Requires manager/WM/GM role
- `override_reason` is mandatory (must explain what and why)
- `consumer_name_manual` is mandatory — provides a human-readable identity anchor for audit
- Sets `creation_type = OWNERS_REFERENCE`, `booking_origin = OWNERS_REFERENCE`
- Gets a regular queue number and follows normal delivery confirmation flow (evidence required before delivery)
- `reconciliation_status` set to `NOT_APPLICABLE` at creation — excluded from SDMS posting
- Can be voided from Django admin like any other TOKEN_ISSUED token

### Entry Point 5: Supervisor Override (GM/Manager Desk)

When RPA verification fails for a known consumer but the manager/GM desk decides to issue anyway (e.g., consumer has a physical receipt, RPA timed out, etc.).

- Requires manager/WM/GM role
- Links to the failed `BookingVerification`
- `override_reason` is mandatory
- Sets `creation_type = SUPERVISOR_OVERRIDE`, `booking_origin = UNVERIFIED_EXCEPTION`
- Reference photo is mandatory before delivery confirmation (not at token creation time)
- Flagged for priority reconciliation review

### Token Voiding (Admin Only)

Tokens where the consumer didn't show up to collect are voided from the Django admin list view (admin action). Not available from the mobile app. Sets `status = VOIDED` — a terminal state with no delivery and no reconciliation.

---

## 5. Data Models

### 5.1 `OfflineSystemStatus` (Singleton)

Global system status. One row, managed via Django admin.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `id` | AutoField | — | Single row (pk=1) |
| `sdms_active` | BooleanField | True | Is SDMS core system reachable? |
| `booking_channels_active` | BooleanField | True | Can consumers place bookings? |
| `otp_channels_active` | BooleanField | True | Are OTP/DAC SMS channels working? |
| `updated_at` | DateTimeField | Auto | Last toggle timestamp |
| `updated_by` | FK → User, nullable | — | Who last changed status |
| `notes` | TextField, blank | — | Reason for status change (audit trail) |

**Derived properties:**
- `mode` → returns `'MANUAL'`, `'ASSISTED'`, or `'VERIFIED'`
- `allow_booking_creation` → `sdms_active and not booking_channels_active` (i.e., ASSISTED mode only)
- `require_dac_code` → `otp_channels_active`

**Caching:** Status is read on every API call. Cache in Redis with 30-second TTL, invalidated on save.

### 5.2 `BookingVerification`

Tracks async RPA booking verification/creation requests. Linked to the token via nullable OneToOneField on the token side. A verification may exist without a token (e.g., failed verification that was never overridden). Tokens created via MANUAL mode or OWNERS_REFERENCE have no linked verification.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `company` | FK → Company | Company scope |
| `distribution_point` | FK → DistributionPoint | Where this was initiated |
| `consumer_id` | CharField(20), nullable | Consumer ID (format: `X-XXXXXXXXXXXX`) |
| `consumer_number` | CharField(15), nullable | Consumer number (10+ digits) |
| `consumer_name` | CharField(255), blank | Consumer name (populated from RPA response if available) |
| `order_number` | CharField(50), nullable | Order/booking number if consumer provided one |
| `created_by` | FK → User | Delivery boy who initiated |
| `status` | FSMField | `QUEUED` → `PROCESSING` → `VERIFIED` / `BOOKING_CREATED` / `FAILED` |
| `camunda_process_id` | CharField(100), nullable | Camunda process instance ID |
| `allow_booking_creation` | BooleanField | Snapshot of system setting at time of request |
| `rpa_response` | JSONField, nullable | Full RPA response data |
| `order_number_from_rpa` | CharField(50), nullable | Order # returned by RPA (if booking was created) |
| `cash_to_collect` | DecimalField, nullable | Amount to collect, from RPA |
| `digital_amount` | DecimalField(10,2), nullable | Amount already paid digitally (from RPA) |
| `is_digitally_paid` | BooleanField, default False | RPA detected digital payment |
| `error_message` | TextField, blank | Error reason from RPA |
| `error_code` | CharField(50), blank | Machine-readable error code (e.g., `QUOTA_EXHAUSTED`, `MIN_DAYS_RULE`, `CONSUMER_NOT_FOUND`) |
| `retry_count` | IntegerField, default 0 | Number of retries |
| `idempotency_key` | UUIDField, nullable, unique | Client-generated key to prevent duplicate creation on retry |
| `created_at` | DateTimeField | Auto |
| `updated_at` | DateTimeField | Auto |

**FSM Transitions:**
```
QUEUED → PROCESSING         (Camunda process started)
PROCESSING → VERIFIED       (existing booking found and valid)
PROCESSING → BOOKING_CREATED (new booking created by RPA)
PROCESSING → FAILED         (error — quota, rules, not found, etc.)
FAILED → QUEUED             (retry)
```

**Validation:** At least one of `consumer_id` or `consumer_number` is required.

### 5.3 `OfflineDeliveryToken`

The central model. Tracks the complete lifecycle from token issuance through delivery to reconciliation.

| Field | Type | Description |
|-------|------|-------------|
| **Identity** | | |
| `id` | UUID | Primary key |
| `company` | FK → Company | Company scope |
| `distribution_point` | FK → DistributionPoint | Where this token was issued |
| `token_number` | PositiveIntegerField, nullable | Queue number (null for quick delivery) |
| `token_date` | DateField | Date of issuance (for daily reset scoping) |
| **Consumer** | | |
| `consumer_id` | CharField(20), nullable | Consumer ID (format: `X-XXXXXXXXXXXX`) |
| `consumer_number` | CharField(15), nullable | Consumer number (10+ digits) |
| `consumer_name` | CharField(255), blank | Consumer name (populated from RPA or reconciliation — not user-editable) |
| `consumer_name_manual` | CharField(255), blank | Free-text recipient name — mandatory for OWNERS_REFERENCE tokens, blank for all others (not validated against any system) |
| **Booking** | | |
| `booking_verification` | OneToOneField → BookingVerification, nullable | Linked verification (null for MANUAL mode and OWNERS_REFERENCE tokens) |
| `order_number` | CharField(50), nullable | Final order number (from consumer, RPA, or correction) |
| `booking_origin` | CharField(25) | `PRE_EXISTING` / `SYSTEM_CREATED` / `UNKNOWN` / `UNVERIFIED_EXCEPTION` / `OWNERS_REFERENCE` — see below |
| **Delivery** | | |
| `dac_code` | CharField(20), nullable | Delivery Authentication Code |
| `delivered_at` | DateTimeField, nullable | When delivery was confirmed |
| **Financial** | | |
| `cash_to_collect` | DecimalField(10,2), nullable | Expected amount (from RPA or price cache). Null if price cache is empty. |
| `cash_to_collect_is_estimated` | BooleanField, default False | True when amount is from price cache, not RPA |
| `price_cached_at` | DateTimeField, nullable | When the price was cached (for staleness tracking). Null if amount came from RPA. |
| `digital_amount` | DecimalField(10,2), nullable | Amount already paid digitally. Copied from verification, null in MANUAL mode (filled during reconciliation). |
| `cash_collected` | DecimalField(10,2), nullable | Actual cash collected at delivery |
| **Reference** | | |
| `reference_image_1` | URLField, nullable | tus upload URL of consumer document/receipt photo |
| `reference_image_2` | URLField, nullable | tus upload URL of second reference photo (optional) |
| `images_uploaded` | BooleanField, default False | Whether image URLs have been submitted to server |
| `evidence_required` | BooleanField, default False | If true, delivery is blocked until `images_uploaded = true`. Auto-set when `creation_type` is `SUPERVISOR_OVERRIDE` or `OWNERS_REFERENCE`. |
| `remark` | TextField, blank | Free text notes |
| **Workflow** | | |
| `status` | FSMField | See status machine below |
| `mode_snapshot` | CharField(10) | System mode at time of creation (`MANUAL` / `ASSISTED` / `VERIFIED`) |
| `creation_type` | CharField(25) | Explicit variant: `STANDARD`, `SUPERVISOR_OVERRIDE`, or `OWNERS_REFERENCE` |
| `is_quick_delivery` | BooleanField, default False | Created via one-shot API |
| `override_reason` | TextField, blank | Why the supervisor/manager authorized the exception (mandatory for `SUPERVISOR_OVERRIDE` and `OWNERS_REFERENCE`) |
| **Reconciliation** | | |
| `reconciliation_status` | CharField(20) | `NOT_STARTED` / `NOT_APPLICABLE` / `QUEUED` / `POSTED` / `FAILED` / `CORRECTION_NEEDED` / `CORRECTED` |
| `reconciliation_camunda_id` | CharField(100), nullable | Camunda process for SDMS posting |
| `reconciliation_error` | TextField, blank | Error from SDMS posting |
| `reconciliation_attempts` | IntegerField, default 0 | |
| `reconciled_at` | DateTimeField, nullable | When successfully posted to SDMS |
| `sdms_order` | FK → sdms_claims.SDMSOrder, nullable | Link to SDMSOrder once created in SDMS |
| **People** | | |
| `created_by` | FK → User | Delivery boy who created the token |
| `delivered_by` | FK → User, nullable | Delivery boy who confirmed delivery (may differ) |
| `corrected_by` | FK → User, nullable | Who corrected data (if correction needed) |
| `voided_by` | FK → User, nullable | Who voided the token |
| `voided_at` | DateTimeField, nullable | When the token was voided |
| **Idempotency** | | |
| `idempotency_key` | UUIDField, nullable, unique | Client-generated key to prevent duplicate creation on retry |
| **Timestamps** | | |
| `created_at` | DateTimeField | Auto |
| `updated_at` | DateTimeField | Auto |

**Status FSM:**

The token `status` tracks the **delivery lifecycle** only — was the cylinder handed over? Reconciliation progress is tracked separately via `reconciliation_status`.

Verification states live on `BookingVerification`, not on the token. The token is only created after verification succeeds (ASSISTED/VERIFIED) or directly without verification (MANUAL).

```
TOKEN_ISSUED → DELIVERED                   (delivery confirmed)
TOKEN_ISSUED → VOIDED                      (consumer didn't collect — end-of-day cleanup)

# Quick delivery:
→ DELIVERED                                (initial state, no TOKEN_ISSUED step)
```

`VOIDED` is a terminal state — no delivery, no reconciliation needed. Voided tokens are excluded from duplicate checks and reconciliation batches.

**Initial state by entry point:**
- Full workflow (ASSISTED/VERIFIED): `TOKEN_ISSUED` (created from verified BookingVerification)
- Full workflow (MANUAL): `TOKEN_ISSUED` (created directly, no verification)
- Quick delivery: `DELIVERED` (all steps consolidated)

**Reconciliation status** (separate field, tracks SDMS posting lifecycle):
```
NOT_STARTED → QUEUED → POSTED             (success)
                     → FAILED             (retry-able)
                     → CORRECTION_NEEDED  (data error, needs human fix)
CORRECTION_NEEDED → CORRECTED → QUEUED    (re-queued after correction)

NOT_APPLICABLE                             (OWNERS_REFERENCE tokens — skipped from SDMS posting)
```

Only tokens with `status = DELIVERED` and `reconciliation_status != NOT_APPLICABLE` are eligible for reconciliation. `OWNERS_REFERENCE` tokens get `reconciliation_status = NOT_APPLICABLE` at creation time.

**Booking Origin — tracks how the booking was obtained:**

| Value | When set | Meaning |
|-------|----------|---------|
| `PRE_EXISTING` | ASSISTED/VERIFIED mode, RPA found existing booking | Consumer or booking channel already created the booking |
| `SYSTEM_CREATED` | ASSISTED mode, RPA created a new booking | We booked on the consumer's behalf via RPA |
| `UNKNOWN` | MANUAL mode (no verification possible) | Booking status unknown — will be determined during reconciliation |
| `UNVERIFIED_EXCEPTION` | Supervisor override after verification failure | Verification failed, but supervisor (manager/WM/GM role) issued token anyway — flagged for priority reconciliation |
| `OWNERS_REFERENCE` | GM/manager desk issues token for a non-consumer | Person is not a registered consumer at this agency. Manager/GM authorizes service on owner's reference. Mandatory reason. Flagged for priority reconciliation. |

Derived from `BookingVerification.status` when token is created from a verification (`VERIFIED` → `PRE_EXISTING`, `BOOKING_CREATED` → `SYSTEM_CREATED`). Defaults to `UNKNOWN` for MANUAL mode tokens (no verification possible). Quick deliveries in ASSISTED/VERIFIED mode still require verification, so they get `PRE_EXISTING` or `SYSTEM_CREATED`. Supervisor overrides get `UNVERIFIED_EXCEPTION`. Owner's reference tokens get `OWNERS_REFERENCE`.

**Indexes:**
- `(distribution_point, token_date)` — for queue number queries
- `(distribution_point, token_date, token_number)` — unique together (excluding nulls)
- `(created_by, token_date)` — delivery boy's daily list
- `(status)` — filtering by workflow stage
- `(reconciliation_status)` — batch reconciliation queries
- `(company, created_at)` — company-scoped listing

**Token Number Assignment (Redis atomic counter):**
- Key: `offline_delivery:token_seq:{distribution_point_id}:{YYYY-MM-DD}`
- Assigned via `INCR` — atomic, no DB locking, handles 10 concurrent users safely
- TTL: 48 hours (auto-cleans after the day passes)
- Quick delivery tokens get `token_number = null` (no queue position)

**Constraints:**
- `UniqueConstraint(fields=['distribution_point', 'token_date', 'token_number'], condition=Q(token_number__isnull=False))` — no duplicate queue numbers per point per day (DB-level safety net behind Redis counter)
- At least one of `consumer_id` or `consumer_number` required (enforced at serializer level — except for `OWNERS_REFERENCE` tokens)
- `UniqueConstraint(fields=['idempotency_key'], condition=Q(idempotency_key__isnull=False))` — prevents duplicate token creation on mobile retry

**Duplicate Prevention (server-side, enforced at service layer):**

Duplicate checks are **point-scoped by design** — each distribution point operates autonomously during field hours. Cross-point duplicates (same consumer at two trucks on the same day) are caught during reconciliation, not at creation time. This is intentional: in a crisis queue, a delivery boy at Truck A should not be blocked by unsynced state from Truck B.

**Cross-point duplicates at reconciliation:** When reconciliation detects the same consumer or order number served at multiple distribution points on the same day, both tokens are flagged `CORRECTION_NEEDED` for admin manual review. Admin decides which to post and which to void.

- Same `order_number` already has an active (non-voided) token today at this distribution point → **block** (order numbers are unique in practice — duplicates indicate a retry or mistake)
- Same `consumer_id` or `consumer_number` already has an active (non-voided) token today at this distribution point → **block** (consumer served once per day per point)
- Voided tokens are excluded from all duplicate checks
- `OWNERS_REFERENCE` tokens are excluded from consumer-based duplicate checks (no consumer_id/consumer_number to check against). If an `order_number` is provided on an owner's reference token, the order-number duplicate check still applies.

**Evidence Requirements (reference images):**

| `creation_type` | `evidence_required` | Enforcement |
|-----------------|---------------------|-------------|
| `SUPERVISOR_OVERRIDE` | `true` (auto-set) | Delivery blocked until image attached |
| `OWNERS_REFERENCE` | `true` (auto-set) | Delivery blocked until image attached |
| `STANDARD` (MANUAL mode) | `false` | Recommended, not enforced |
| `STANDARD` (ASSISTED/VERIFIED mode) | `false` | Optional |

**Sequence Gaps:**
Token numbers may have gaps (e.g., 1, 2, 4 if token 3's creation failed after Redis INCR). Gaps are normal and do not indicate lost data.

### 5.4 Price List Cache (Redis)

No database model. Cylinder prices are cached in Redis for internal use only (not exposed via API).

**Scope:** Domestic 14.2 KG LPG refill only. This is the only product distributed during offline/crisis operations. Commercial, addon, and other categories are not handled by this system.

**Redis key pattern:** `offline_delivery:price:{company_id}:{item_code}`
**Value:** JSON `{"price": "1050.00", "item_name": "Indane Gas 14.2 KG Refill", "fetched_at": "2026-03-13T06:00:00"}`
**TTL:** 24 hours (auto-expires, re-fetched on next access or manual refresh)

**Usage:** When a token is created in MANUAL mode, the backend reads the cached price and populates `cash_to_collect` + sets `cash_to_collect_is_estimated = true` + sets `price_cached_at` from the cache's `fetched_at`. The mobile app never sees or fetches the price list directly.

**Missing/stale cache:** If the Redis cache is empty or expired, `cash_to_collect` is set to `null` (not a guess). The delivery boy collects based on whatever information the consumer has (printed receipt, previous payment, etc.). No fake certainty.

**Refresh:** Admin can trigger a manual cache refresh from Django admin. Prices are fetched from ERPNext using the existing `requests`-based ERP service.

---

## 6. API Specification

Base URL: `/api/offline-delivery/`

### 6.1 System Status

#### `GET /status/`
Returns current system status and derived mode.

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

### 6.2 Distribution Points

#### `GET /distribution-points/`
List active distribution points for user's company. Read-only — distribution points are created and configured exclusively from Django admin.

**Response:**
```json
[
  {
    "id": "uuid",
    "name": "Sherpur Godown",
    "warehouse": {"id": 1, "name": "Sherpur - IOC"},
    "is_adhoc": false,
    "allow_quick_delivery": false,
    "is_active": true,
    "today_token_count": 142
  }
]
```

### 6.3 Booking Verification

#### `POST /booking-verifications/`
Submit a consumer for async booking verification (ASSISTED & VERIFIED modes only).

**Request:**
```json
{
  "distribution_point_id": "uuid",
  "consumer_id": "2-123456789012",
  "consumer_number": "9876543210",
  "order_number": "ORD-2026-001234",
  "idempotency_key": "550e8400-e29b-41d4-a716-446655440000"
}
```

`idempotency_key` is optional but recommended. If a request with the same key arrives again, the existing verification is returned instead of creating a duplicate.

**Response (201):**
```json
{
  "id": "uuid",
  "status": "QUEUED",
  "consumer_id": "2-123456789012",
  "consumer_number": "9876543210",
  "consumer_name": "",
  "order_number": "ORD-2026-001234",
  "created_at": "2026-03-13T10:30:00"
}
```

**Error (409 — config mismatch):**
```json
{
  "error": "This action is not available in the current system mode.",
  "code": "CONFIG_OUTDATED",
  "current_mode": "MANUAL"
}
```
The `CONFIG_OUTDATED` code tells the app to re-fetch `GET /status/`, refresh its local config, and adjust the UI accordingly. This pattern applies to any endpoint called outside its valid mode.

#### `GET /booking-verifications/`
List verifications created by the current user, ordered by most recent. Used for the delivery boy's "my verifications" list.

**Query params:**
- `status` — filter by status (e.g., `VERIFIED`, `FAILED`)
- `distribution_point_id` — filter by point
- `date` — filter by date (default: today)

**Response:**
```json
[
  {
    "id": "uuid",
    "consumer_id": "2-123456789012",
    "consumer_number": "9876543210",
    "consumer_name": "Mohd Rafiq",
    "order_number": "ORD-2026-001234",
    "status": "VERIFIED",
    "cash_to_collect": "1050.00",
    "is_digitally_paid": false,
    "order_number_from_rpa": "ORD-2026-001234",
    "error_message": "",
    "error_code": "",
    "has_token": false,
    "created_at": "2026-03-13T10:30:00",
    "updated_at": "2026-03-13T10:30:45"
  },
  {
    "id": "uuid2",
    "consumer_id": "3-987654321098",
    "consumer_number": null,
    "consumer_name": "",
    "order_number": null,
    "status": "FAILED",
    "cash_to_collect": null,
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
Get single verification detail.

#### `POST /booking-verifications/{id}/retry/`
Retry a failed verification. Transitions `FAILED → QUEUED` and re-queues the Camunda booking verification process. Any authenticated user can retry — the original `created_by` remains unchanged.

**Response (200):**
```json
{
  "id": "uuid",
  "status": "QUEUED",
  "retry_count": 1
}
```

### 6.4 Tokens

#### `POST /tokens/`
Create a token (queue entry). Two modes:

**STANDARD — From verified booking (ASSISTED/VERIFIED):**
```json
{
  "creation_type": "STANDARD",
  "distribution_point_id": "uuid",
  "booking_verification_id": "uuid",
  "remark": "Consumer has physical receipt",
  "idempotency_key": "550e8400-e29b-41d4-a716-446655440000"
}
```
Consumer data, consumer name, and order number are pulled from the linked booking verification. Requires verification status to be `VERIFIED` or `BOOKING_CREATED`. Images are attached later via `POST /tokens/{id}/attach-images/`.

**STANDARD — Direct creation (MANUAL mode, SDMS down):**
```json
{
  "creation_type": "STANDARD",
  "distribution_point_id": "uuid",
  "consumer_id": "2-123456789012",
  "consumer_number": "9876543210",
  "order_number": "ORD-2026-001234",
  "remark": "No SDMS verification available",
  "idempotency_key": "660e8400-e29b-41d4-a716-446655440001"
}
```
Only allowed when `sdms_active = false`. Images are attached later via `POST /tokens/{id}/attach-images/`.

**SUPERVISOR_OVERRIDE — After verification failure (manager/WM/GM role only):**
```json
{
  "creation_type": "SUPERVISOR_OVERRIDE",
  "distribution_point_id": "uuid",
  "booking_verification_id": "uuid",
  "override_reason": "Consumer has physical receipt from booking channel, RPA verification timed out",
  "remark": "Override by GM desk",
  "idempotency_key": "770e8400-e29b-41d4-a716-446655440002"
}
```
Requires the requesting user to have `GeneralManagerRole`, `WarehouseManagerRole`, or manager-level permissions. The linked verification can be in `FAILED` status. Sets `creation_type = SUPERVISOR_OVERRIDE`, `booking_origin = UNVERIFIED_EXCEPTION`, and flags the token for priority reconciliation review. Reference photo is mandatory before delivery confirmation — token creation succeeds without it, but `evidence_required = true` blocks delivery until at least one image is attached via `POST /tokens/{id}/attach-images/`.

**OWNERS_REFERENCE — Non-consumer service (manager/WM/GM role only):**
```json
{
  "creation_type": "OWNERS_REFERENCE",
  "distribution_point_id": "uuid",
  "override_reason": "Family of army personnel, referred by depot owner. Not registered at this agency.",
  "remark": "Owner's reference — serve from available stock",
  "consumer_name_manual": "Bilal Ahmad",
  "idempotency_key": "aa0e8400-e29b-41d4-a716-446655440005"
}
```
For people who are **not registered consumers** at this agency. No `consumer_id`, `consumer_number`, or `booking_verification_id` required. The manager/GM desk creates the token directly. Sets `creation_type = OWNERS_REFERENCE`, `booking_origin = OWNERS_REFERENCE`. `override_reason` and `consumer_name_manual` are both **mandatory** (reason explains what and why; name provides a human-readable identity anchor for audit). These tokens get `reconciliation_status = NOT_APPLICABLE` at creation (excluded from SDMS posting).

Duplicate prevention rules are relaxed for `OWNERS_REFERENCE` tokens (no consumer_id/consumer_number to check against).

`idempotency_key` is optional but recommended on all creation requests. If a request with the same key arrives again, the existing token is returned.

**Response (201):**
```json
{
  "id": "uuid",
  "token_number": 143,
  "token_date": "2026-03-13",
  "distribution_point": {
    "id": "uuid",
    "name": "Sherpur Godown"
  },
  "consumer_id": "2-123456789012",
  "consumer_number": "9876543210",
  "consumer_name": "",
  "order_number": "ORD-2026-001234",
  "status": "TOKEN_ISSUED",
  "mode_snapshot": "MANUAL",
  "booking_origin": "UNKNOWN",
  "cash_to_collect": "1050.00",
  "cash_to_collect_is_estimated": true,
  "created_by": {"id": 5, "username": "delivery_boy_1", "full_name": "Ravi Kumar"},
  "created_at": "2026-03-13T10:35:00"
}
```

**Validation errors:**
- `400` — Missing consumer ID and consumer number (at least one required — except for OWNERS_REFERENCE)
- `400` — Booking verification not in VERIFIED/BOOKING_CREATED status (or FAILED for non-override requests)
- `400` — Booking verification already has a token
- `400` — Owner's reference: missing `override_reason` or `consumer_name_manual`
- `400` — Invalid `creation_type` value
- `403` — `creation_type` is `SUPERVISOR_OVERRIDE` or `OWNERS_REFERENCE` but user lacks manager/WM/GM role
- `409 CONFIG_OUTDATED` — SDMS is active (not in MANUAL mode), cannot create unverified token — app should re-fetch `/status/`
- `409` — Duplicate: active token already exists for this consumer today at this distribution point
- `409` — Duplicate: active token already exists for this order number today at this distribution point
- `404` — Distribution point not found or inactive

**Duplicate error response format:**
```json
{
  "error": "Active token already exists for this consumer today at this distribution point.",
  "code": "DUPLICATE_CONSUMER",
  "existing_token_id": "uuid",
  "existing_token_number": 42
}
```
`code` is `DUPLICATE_CONSUMER` or `DUPLICATE_ORDER_NUMBER`. The `existing_token_id` and `existing_token_number` let the mobile app show which token conflicts.

#### `GET /tokens/`
List tokens. For delivery boys: shows their own tokens. For admins: shows all.

**Query params:**
- `distribution_point_id` — filter by point
- `date` — filter by date (default: today)
- `status` — filter by status
- `is_delivered` — convenience filter: `true` = `status=DELIVERED`, `false` = `status=TOKEN_ISSUED`. Does not include VOIDED tokens — use `status=VOIDED` explicitly to find those.
- `reconciliation_status` — filter by reconciliation state
- `created_by` — filter by delivery boy (admin only)

**Response:**
```json
{
  "count": 143,
  "results": [
    {
      "id": "uuid",
      "token_number": 143,
      "token_date": "2026-03-13",
      "distribution_point": {"id": "uuid", "name": "Sherpur Godown"},
      "consumer_id": "2-123456789012",
      "consumer_number": "9876543210",
      "consumer_name": "Mohd Rafiq",
      "order_number": "ORD-2026-001234",
      "dac_code": null,
      "status": "TOKEN_ISSUED",
      "mode_snapshot": "MANUAL",
      "booking_origin": "UNKNOWN",
      "is_quick_delivery": false,
      "cash_to_collect": "1050.00",
      "cash_to_collect_is_estimated": true,
      "cash_collected": null,
      "reconciliation_status": "NOT_STARTED",
      "remark": "",
      "images_uploaded": false,
      "created_by": {"id": 5, "username": "ravi", "full_name": "Ravi Kumar"},
      "created_at": "2026-03-13T10:35:00",
      "delivered_at": null
    }
  ]
}
```

#### `GET /tokens/{id}/`
Get full token detail (includes booking verification data if linked).

#### `POST /tokens/{id}/deliver/`
Confirm delivery on a token.

**Request:**
```json
{
  "dac_code": "847291",
  "cash_collected": "1050.00"
}
```

`dac_code` is required only when `otp_channels_active = true`. `cash_collected` is always required.

**Idempotency:** First successful delivery wins. If the token is already DELIVERED, the existing state is returned unchanged regardless of payload. A retry with different `cash_collected` or `dac_code` does **not** overwrite — if the delivery boy entered wrong values, that's a correction (via reconciliation), not a re-delivery. Two devices attempting to deliver the same token: first one wins, second gets the existing result.

**Evidence requirement:** For tokens with `creation_type` = `SUPERVISOR_OVERRIDE` or `OWNERS_REFERENCE`, delivery is blocked until at least one reference image is attached (`images_uploaded = true`). Returns `400` with message "Reference image required before delivery confirmation."

**Response (200):**
```json
{
  "id": "uuid",
  "status": "DELIVERED",
  "dac_code": "847291",
  "cash_collected": "1050.00",
  "delivered_at": "2026-03-13T12:45:00",
  "delivered_by": {"id": 5, "username": "ravi", "full_name": "Ravi Kumar"}
}
```

**Voiding:** No REST API. Voiding is done from the Django admin list view (admin action on TOKEN_ISSUED tokens). Sets `status = VOIDED`, `voided_at`, `voided_by`.

#### `POST /tokens/{id}/correct/`
Submit corrected data for a token in `CORRECTION_NEEDED` state. Any authenticated user can submit corrections — `corrected_by` tracks who did it, but the original `created_by` carries the liability. Only `consumer_id`, `consumer_number`, `order_number`, and `dac_code` are correctable from this endpoint. `consumer_name` is not user-editable — it is populated by the verification service or during reconciliation. Other fields (booking_origin, cash_collected, distribution point, etc.) can only be corrected from Django admin.

**Request:**
```json
{
  "consumer_id": "2-123456789012",
  "consumer_number": "9876543211",
  "order_number": "ORD-2026-001235",
  "dac_code": "847292"
}
```

Only fields that need correction are included. Unchanged fields are omitted.

**Idempotency:** First successful correction per cycle wins. If `reconciliation_status` is already `CORRECTED`, the existing state is returned unchanged. If the corrected data is still wrong, reconciliation will fail again and open a new `CORRECTION_NEEDED` cycle — anyone can then submit a fresh correction. Multiple corrections are possible, but only one per `CORRECTION_NEEDED` → `CORRECTED` cycle.

**Response (200):**
```json
{
  "id": "uuid",
  "status": "DELIVERED",
  "reconciliation_status": "CORRECTED",
  "corrected_by": {"id": 5, "username": "ravi", "full_name": "Ravi Kumar"}
}
```

### 6.5 Quick Delivery

#### `POST /tokens/quick-deliver/`
One-shot delivery — consolidates token creation, image attachment, and delivery confirmation into a single call. Skips queue/token number assignment but does **not** skip booking verification.

- In **ASSISTED/VERIFIED** mode: requires a `booking_verification_id` (verification must be completed first)
- In **MANUAL** mode: consumer data provided directly (same as regular token creation)
- Only available at distribution points with `allow_quick_delivery = true`

**Implementation note:** Quick delivery is a thin orchestration wrapper over the same service-layer primitives as regular token creation + delivery confirmation. It does not have its own business rules — same duplicate checks, mode gates, idempotency behavior, and validation logic as the separate endpoints.

**Request (ASSISTED/VERIFIED):**
```json
{
  "distribution_point_id": "uuid",
  "booking_verification_id": "uuid",
  "dac_code": "847291",
  "cash_collected": "1050.00",
  "remark": "Direct delivery, no queue",
  "reference_image_1": "https://tus.example.com/files/abc123",
  "reference_image_2": "https://tus.example.com/files/def456",
  "idempotency_key": "880e8400-e29b-41d4-a716-446655440003"
}
```

**Request (MANUAL):**
```json
{
  "distribution_point_id": "uuid",
  "consumer_id": "2-123456789012",
  "consumer_number": "9876543210",
  "order_number": "ORD-2026-001234",
  "dac_code": "847291",
  "cash_collected": "1050.00",
  "remark": "Direct delivery, no queue",
  "reference_image_1": "https://tus.example.com/files/abc123",
  "idempotency_key": "990e8400-e29b-41d4-a716-446655440004"
}
```

`reference_image_1` and `reference_image_2` are optional tus URLs (can also be attached later). `dac_code` required only when `otp_channels_active = true`. Quick delivery respects `evidence_required` the same as regular flow — if `creation_type` is `SUPERVISOR_OVERRIDE` or `OWNERS_REFERENCE`, image URLs must be provided inline since there is no separate attach step before delivery.

**Response (201):**
```json
{
  "id": "uuid",
  "token_number": null,
  "status": "DELIVERED",
  "is_quick_delivery": true,
  "delivered_at": "2026-03-13T10:40:00",
  "cash_collected": "1050.00",
  "booking_origin": "PRE_EXISTING"
}
```

**Validation:**
All token creation validations from `POST /tokens/` apply (duplicate checks, `creation_type` validation, evidence enforcement, `CONFIG_OUTDATED`), plus:
- `403` — Quick delivery not enabled at this distribution point
- `400` — Missing required fields (including `cash_collected`, which is required since delivery is inline)
- `400` — Booking verification not completed (ASSISTED/VERIFIED mode)
- `400` — Evidence-required token (`SUPERVISOR_OVERRIDE` / `OWNERS_REFERENCE`) but no image URLs provided

### 6.6 Image Upload (tus Resumable Upload)

Images are uploaded via the **tus resumable upload protocol**, not through Django APIs. This gives us resumable uploads, chunking, parallel uploads, and robustness on spotty field connectivity.

**Flow:**
1. Mobile app captures and compresses photo locally
2. App uploads to tus server endpoint (resumable, background, chunked)
3. tus server returns a file URL on completion
4. App submits the URL(s) to Django via the attach-images API

**tus server:** A `tusd` instance (to be added to `docker-compose.yml`) with file storage on the same server or S3-compatible storage.

#### `POST /tokens/{id}/attach-images/`
Attach tus-uploaded image URLs to a token. Can be called any time after token creation (deferred).

**Request:**
```json
{
  "reference_image_1": "https://tus.example.com/files/abc123def456",
  "reference_image_2": "https://tus.example.com/files/789ghi012jkl"
}
```

`reference_image_2` is optional.

**Response (200):**
```json
{
  "id": "uuid",
  "images_uploaded": true,
  "reference_image_1": "https://tus.example.com/files/abc123def456",
  "reference_image_2": "https://tus.example.com/files/789ghi012jkl"
}
```

**Idempotency:** Overwrites. This is the one mutation where retry with a different payload is legitimate (failed upload → re-upload with new URL). Last write wins, no idempotency key needed.

**Notes:**
- Django validates that the URLs point to the expected tus server domain
- Images are never uploaded through Django — no multipart handling, no memory pressure
- tus server handles chunking, resume, and storage independently

### 6.7 Reconciliation & Cleanup

Reconciliation is managed entirely from the **Django admin panel**:
- View/filter tokens by `reconciliation_status`
- Trigger batch push to Camunda via admin actions
- Review reference images and correction details inline
- Correct data on behalf of delivery boys when deadlines approach
- **Filter by `booking_origin`** — admin views and any reporting should clearly separate standard tokens, supervisor overrides (`UNVERIFIED_EXCEPTION`), and owner's reference (`OWNERS_REFERENCE`) tokens. Metrics like posted rate and failure rate should be computed on standard tokens only to avoid pollution from exception paths.

No dedicated REST APIs for reconciliation. The mobile app detects reconciled tokens via the `reconciliation_status` field in `GET /tokens/` responses and can clean up local images when status is `POSTED` or `NOT_APPLICABLE`.

---

## 7. Camunda Process Definitions

### 7.1 Booking Verification Process

**Process Key:** `process_offline_delivery_booking_verify`

**Variables sent:**
| Variable | Type | Description |
|----------|------|-------------|
| `verification_id` | String (UUID) | BookingVerification PK |
| `consumer_id` | String | Consumer ID |
| `consumer_number` | String | Consumer number |
| `order_number` | String | Order number (if provided) |
| `distributor_code` | String | 10-digit padded SDMS distributor code |
| `company_id` | Integer | Company PK |
| `allow_booking_creation` | Boolean | Whether RPA may create a booking |

**Expected callback/completion:**
RPA worker updates `BookingVerification` via API or direct DB update:
- Sets `status` → `VERIFIED` / `BOOKING_CREATED` / `FAILED`
- Populates `rpa_response`, `order_number_from_rpa`, `cash_to_collect`, `digital_amount`, `is_digitally_paid`, `consumer_name`
- On failure: sets `error_message` and `error_code`

### 7.2 Reconciliation Process

**Process Key:** `process_offline_delivery_reconcile`

**Variables sent:**
| Variable | Type | Description |
|----------|------|-------------|
| `token_id` | String (UUID) | OfflineDeliveryToken PK |
| `consumer_id` | String | Consumer ID |
| `consumer_number` | String | Consumer number |
| `consumer_name` | String | Consumer name (if available) |
| `order_number` | String | Order number |
| `cash_collected` | String | Actual cash collected |
| `digital_amount` | String | Amount already paid digitally |
| `dac_code` | String | DAC code (if captured) |
| `distributor_code` | String | 10-digit padded SDMS distributor code |
| `company_id` | Integer | Company PK |
| `mode_snapshot` | String | What mode the token was created in (MANUAL/ASSISTED/VERIFIED) |
| `booking_origin` | String | `PRE_EXISTING`, `SYSTEM_CREATED`, `UNKNOWN`, `UNVERIFIED_EXCEPTION`, or `OWNERS_REFERENCE` |
| `needs_booking` | Boolean | Whether this token needs a booking created in SDMS (MANUAL mode tokens) |
| `needs_delivery_confirmation` | Boolean | Whether delivery needs to be posted |

**Reconciliation eligibility:**
- Only tokens with `status = DELIVERED` and `reconciliation_status != NOT_APPLICABLE` are eligible (matches the FSM section rule exactly)
- `OWNERS_REFERENCE` tokens get `reconciliation_status = NOT_APPLICABLE` at creation — they have no consumer in our agency's SDMS and are excluded from SDMS posting. For v1, these tokens remain in `DELIVERED` + `NOT_APPLICABLE` as terminal state. No further back-office processing is defined yet — this is a known business-process gap deferred to v2.
- `UNVERIFIED_EXCEPTION` tokens are included in reconciliation but flagged for priority review

**Expected callback/completion:**
- On success: update `reconciliation_status` → `POSTED`, set `reconciled_at`, link `sdms_order`. Also populates `consumer_name` on the token if returned by SDMS (direct update, not via verification signal).
- On failure: update `reconciliation_status` → `FAILED` with error details
- On data error: update `reconciliation_status` → `CORRECTION_NEEDED` with specifics

---

## 8. Thermal Receipt Format

### Token Receipt (printed at Step 2)

```
================================
       DELIVERY TOKEN
================================

Token No    : #143
Location    : Sherpur Godown
Date        : 13/03/2026
Time        : 10:35 AM

Consumer    : Mohd Rafiq
Consumer ID : 2-123456789012
Consumer No : 9876543210
Order No    : ORD-2026-001234

Amount      : Rs. 1050.00 (est.)
--------------------------------

        ┌─────────┐
        │ QR CODE │
        │(Order #)│
        └─────────┘

Please wait for your turn.
================================


```

**Notes:**
- Consumer name row shown if available, omitted otherwise
- "est." suffix on amount when `cash_to_collect_is_estimated = true`
- Amount row omitted if `cash_to_collect` is null
- Order No row omitted if not available
- **QR code** encodes the order number. Printed only when order number is available. Enables SDMS mobile app to scan and post the sale directly when systems come back up.
- QR code generated via ESC/POS native QR command (GS '(' k) or as a bitmap if printer doesn't support native QR
- 3 line feeds at end for thermal paper tear
- **Quick delivery does not print a receipt** — no queue, no token to hand over

---

## 9. Notification Events

### 9.1 User-Facing Notifications

| Event | Recipient | Channel | Message |
|-------|-----------|---------|---------|
| Booking verified | Delivery boy (creator) | Push + in-app | "Booking verified for Consumer {id}. Order #{order_number}" |
| Booking created | Delivery boy (creator) | Push + in-app | "New booking created for Consumer {id}. Order #{order_number}" |
| Booking failed | Delivery boy (creator) | Push + in-app | "Booking failed for Consumer {id}: {error_message}" |
| Correction needed | Delivery boy (creator) | Push + in-app | "Token #{number} needs correction: {error_detail}" |
| Reconciliation complete | Delivery boy (creator) | In-app only | "Token #{number} successfully posted to SDMS" |

### 9.2 Silent Push Notifications (Config Refresh)

Silent push notifications are **data-only pushes** (no user-visible alert) that tell the app to refresh specific data. They follow a standardized payload format designed to be reusable across all Django apps, not just `offline_delivery`.

**Standard Silent Push Payload:**
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

**Payload fields:**

| Field | Type | Description |
|-------|------|-------------|
| `silent` | bool | Always `true` — tells the app this is not a user-visible notification |
| `scope` | string | Django app name that owns this notification (e.g., `offline_delivery`, `quotas`, `stocks`) |
| `action` | string | What happened: `config_refresh`, `record_updated`, `record_created`, `record_deleted` |
| `resource` | string | What changed: `system_status`, `distribution_point`, `price_cache`, or any model/config name |
| `resource_id` | string/null | Specific record ID if applicable (null for global config changes) |
| `timestamp` | datetime | When the change occurred (for deduplication / ordering) |

**Triggers for `offline_delivery`:**

| Django Signal | scope | action | resource | resource_id | Recipients |
|---------------|-------|--------|----------|-------------|------------|
| `OfflineSystemStatus.post_save` | `offline_delivery` | `config_refresh` | `system_status` | null | All active users |
| `DistributionPoint.post_save` | `offline_delivery` | `config_refresh` | `distribution_point` | `{point_id}` | Users at that point |
| `BookingVerification.post_save` (status change) | `offline_delivery` | `record_updated` | `booking_verification` | `{verification_id}` | Creator (delivery boy) |
| `OfflineDeliveryToken.post_save` (reconciliation_status change) | `offline_delivery` | `record_updated` | `delivery_token` | `{token_id}` | Creator (delivery boy) |

**App-side handling:**
1. App receives silent push
2. Reads `scope` → routes to the correct module handler
3. Reads `action` + `resource` → knows which API to call (e.g., `GET /api/offline-delivery/status/`)
4. Pulls fresh data, updates local state, adjusts UI

**Future usage by other apps (examples):**
```json
{"silent": true, "scope": "quotas", "action": "record_updated", "resource": "quota_config", ...}
{"silent": true, "scope": "stocks", "action": "config_refresh", "resource": "warehouse_status", ...}
{"silent": true, "scope": "orders", "action": "record_updated", "resource": "sale_order", "resource_id": "uuid", ...}
```

**Novu workflow:** A single reusable workflow (`silent_config_push`) — push-only, no in-app, no email. All Django apps share this one workflow, differentiated by payload.

**Implementation:**
- `post_save` signal on relevant models → queues Novu push via django-rq
- Uses existing `NovuClient` wrapper from `notifications/services.py`
- Recipient targeting: broadcast to all company users, or scoped to specific users depending on `resource`

---

## 10. Django App Structure

```
python_src/offline_delivery/
├── __init__.py
├── apps.py
├── models/
│   ├── __init__.py
│   ├── choices.py                    # All enums/TextChoices
│   ├── system_status.py              # OfflineSystemStatus singleton
│   ├── distribution_point.py         # DistributionPoint
│   ├── booking_verification.py       # BookingVerification
│   ├── delivery_token.py             # OfflineDeliveryToken
│   └── (no price list model — cached in Redis)
├── serializers.py
├── views.py
├── urls.py
├── services/
│   ├── __init__.py
│   ├── token_service.py              # Token creation, delivery, correction
│   ├── booking_verification_service.py  # Verification + Camunda integration
│   ├── reconciliation_service.py     # Batch reconciliation
│   └── price_cache_service.py        # Redis-based price cache (fetch from ERPNext, read for token creation)
├── admin.py
├── signals.py                          # post_save handlers (e.g. propagate consumer_name from verification to token)
└── migrations/
```

---

## 11. Mobile App Integration Checklist

The mobile app team should implement the following against these APIs:

### Startup
- [ ] Call `GET /status/` — cache mode, derive UI behavior
- [ ] Call `GET /distribution-points/` — let user select active point
- [ ] No need to fetch prices — backend populates `cash_to_collect` internally from cached price list
- [ ] Register for silent push notifications (scope: `offline_delivery`)
- [ ] On receiving silent push: inspect `action` + `resource` fields:
  - `config_refresh` + `system_status` → re-fetch `GET /status/`
  - `config_refresh` + `distribution_point` → re-fetch `GET /distribution-points/`
  - `record_updated` + `booking_verification` → refresh verification list
  - `record_updated` + `delivery_token` → refresh token list

### MANUAL Mode (Full Offline)
- [ ] Show "SDMS Offline" banner
- [ ] Token creation form: consumer ID/number, order number (optional), remark
- [ ] Display `cash_to_collect` from API response with "(estimated)" label when `cash_to_collect_is_estimated = true`
- [ ] Capture 1-2 photos, compress locally
- [ ] Upload to tus server in background (resumable, chunked)
- [ ] On tus upload complete, call `POST /tokens/{id}/attach-images/` with URLs
- [ ] Print token receipt

### ASSISTED / VERIFIED Mode (Verification Available)
- [ ] Booking verification form: consumer ID/number, order number (optional)
- [ ] Submit → show "Verifying..." in list
- [ ] Poll `GET /booking-verifications/` or listen for silent push (`record_updated` + `booking_verification`)
- [ ] On success: show "Create Token" button on the verification card
- [ ] On failure: show error reason, offer retry
- [ ] On failure (manager/WM/GM role): also show "Issue Anyway" button → requires override reason
- [ ] On token creation: print receipt with verified data
- [ ] Show `booking_origin` indicator (PRE_EXISTING / SYSTEM_CREATED / UNVERIFIED_EXCEPTION)

### Delivery Confirmation
- [ ] "Deliver" action on token card
- [ ] If `evidence_required = true` and `images_uploaded = false`: show "Upload photo first" — delivery button disabled (applies to `SUPERVISOR_OVERRIDE` and `OWNERS_REFERENCE` tokens)
- [ ] If `require_dac_code`: show DAC code input field
- [ ] Cash collected input (pre-filled with `cash_to_collect`)
- [ ] Submit → token moves to DELIVERED

### Owner's Reference (Manager/WM/GM Role Only)
- [ ] Only visible to users with manager/WM/GM role
- [ ] Separate "Owner's Reference" button/flow — creates token for non-consumers
- [ ] Form: distribution point, recipient name (`consumer_name_manual`), reason (mandatory), remark
- [ ] No consumer ID/number required
- [ ] Shows `booking_origin = OWNERS_REFERENCE` badge on the token card
- [ ] Same delivery confirmation flow as regular tokens

### Quick Delivery
- [ ] Only show at distribution points with `allow_quick_delivery = true`
- [ ] Single form: all fields at once
- [ ] Submit → done

### Corrections
- [ ] Check for `CORRECTION_NEEDED` tokens periodically (or listen for silent push `record_updated` + `delivery_token`)
- [ ] Show reference image alongside editable fields
- [ ] Submit correction → re-queued for reconciliation

### Cleanup
- [ ] Periodically check `reconciliation_status` in `GET /tokens/` responses
- [ ] Delete local images for tokens with `reconciliation_status = POSTED` or `NOT_APPLICABLE`
- [ ] Voided tokens (voided by admin) will appear with `status = VOIDED` — hide from active list

---

## 12. Relationship to Existing Systems

### `sdms_claims.SDMSOrder`
- `OfflineDeliveryToken.sdms_order` links to `SDMSOrder` after reconciliation
- When reconciliation creates a booking/delivery in SDMS, the resulting order flows into the normal `sdms_claims` pipeline for claim processing
- The `SDMSOrder.source` field will gain a new choice: `OFFLINE_DELIVERY`
- Consumer fields (`consumer_number`, `order_id`) use the same formats

### Camunda
- Uses the same `CamundaIntegrationService._format_variables()` pattern
- New process definitions needed: `process_offline_delivery_booking_verify` and `process_offline_delivery_reconcile`
- Same Camunda REST API endpoint

### ERPNext Price List
- Cylinder prices cached in Redis (no DB model), fetched from ERPNext Item Price
- Used internally by token creation service in MANUAL mode to populate `cash_to_collect`
- Fetched using the existing `requests`-based ERP service pattern

---

## 13. Open Items / Future Considerations

1. **Degraded mode** — Currently using Active/Unavailable. If "Degraded" is needed later (e.g., SDMS is slow but reachable), it can be added as a third state per system component.
2. **Variable quantity** — Current design assumes 1 cylinder per token. A future round will add quantity support.
3. **Per-warehouse mode** — Currently global. If different regions need different modes, `OfflineSystemStatus` can be extended with regional overrides.
4. **Image upload is the only deferred operation** — All API calls (token creation, booking verification, delivery confirmation) are real-time and require network connectivity. Only reference image uploads are handled in the background via tus resumable protocol (compress → chunked upload → attach URL).
5. **tusd infrastructure** — A `tusd` instance needs to be added to `docker-compose.yml` for production. Storage backend can be local filesystem or S3-compatible (MinIO).
6. **Audit trail** — All FSM transitions are logged via `django_fsm_log`. Additional audit events can be added via Django signals.
7. **Booking origin analytics** — The `booking_origin` field enables reporting on how many bookings were pre-existing vs system-created vs unknown vs supervisor-overridden, which is valuable for understanding the impact of this system.
8. **Stock linkage** — Delivery confirmation should decrement available stock at the distribution point. The `stocks` app already has the models. Integration deferred to a future phase, but the token model is designed to support it (distribution point + delivery confirmation = sufficient to track stock movement).
9. **Admin reconciliation at scale** — Reconciliation is managed via Django admin (bulk actions + filters) for v1. If volume exceeds what Django admin handles comfortably (thousands of tokens needing triage), a dedicated reconciliation dashboard may be needed in v2.
10. **Image replacement audit trail** — `POST /tokens/{id}/attach-images/` is last-write-wins for field retry convenience. In v2, consider logging previous URLs, who replaced them, and when — especially for evidence-required tokens where images matter most.
11. **Owner's reference post-delivery lifecycle** — `OWNERS_REFERENCE` tokens reach `DELIVERED` + `NOT_APPLICABLE` as terminal state. No back-office settlement or ledger treatment is defined for v1. If these tokens need any formal closure (manual ledger entry, separate review queue, etc.), that process will be defined in v2 based on observed volume and business needs.
