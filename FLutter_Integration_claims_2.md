# Unified Order API — Design Document

**Version:** Draft v3
**Date:** 2026-02-12
**Status:** Pending Approval

---

## Problem Statement

The Flutter client currently uses two separate APIs:
- `GET /api/sdms-claims/orders/` — list of SDMS orders
- `GET /api/sdms-claims/transfers/` — list of claim transfers (separate screen)

This forces the user to navigate to a dedicated "Approvals" screen to approve/reject transfers. The intended UX is a **single order list** where approvals are inline — orders needing the user's action float to the top, and approve/reject/cancel happens from the **order detail page** (not the list).

Additionally, the current FSM does not support **cancelling** a transfer. If delivery boy Y receives a transfer request from delivery boy X but the order actually belongs to delivery boy Z, Y has no way to cancel — they can only approve (giving credit to X, wrong person) or reject (keeping credit for Y, also wrong). The cancel action returns the order to UNCLAIMED so the correct person can claim it.

---

## Proposed API Structure

### Endpoints (Flutter-facing)

| Method | Endpoint | Purpose | Changed? |
|--------|----------|---------|----------|
| GET | `/api/sdms-claims/orders/?tab=active` | Active orders (loaded in full) | **Modified** — two tabs, search, user-scoped |
| GET | `/api/sdms-claims/orders/?tab=history` | Historical orders (paginated) | **Modified** — two tabs, search, user-scoped |
| POST | `/api/sdms-claims/orders/` | Create order | No change |
| GET | `/api/sdms-claims/orders/{id}/` | Order detail (with transfer info) | **Modified** — new nested fields |
| POST | `/api/sdms-claims/orders/{id}/claim/` | Claim an order | No change |
| POST | `/api/sdms-claims/orders/{id}/retry/` | Retry failed RPA | No change |
| POST | `/api/sdms-claims/orders/{id}/approve-transfer/` | Approve pending transfer | **New** |
| POST | `/api/sdms-claims/orders/{id}/reject-transfer/` | Reject pending transfer | **New** |
| POST | `/api/sdms-claims/orders/{id}/cancel-transfer/` | Cancel pending transfer (back to unclaimed) | **New** |

### Endpoints (kept for admin/internal — not used by Flutter)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/sdms-claims/transfers/` | List all transfers (admin view) |
| GET | `/api/sdms-claims/transfers/{id}/` | Transfer detail |
| POST | `/api/sdms-claims/transfers/{id}/approve/` | Approve (by transfer ID) |
| POST | `/api/sdms-claims/transfers/{id}/reject/` | Reject (by transfer ID) |

---

## 1. Order List — Two Tabs with Search

The order list is **always scoped to the current user** — no `is_mine` filter needed. The backend automatically filters to orders where the user is `original_delivery_boy`, `initiated_by`, or `intended_claimant`.

### Tab Parameter

| `tab` value | What it shows | Pagination | Statuses included |
|-------------|--------------|------------|-------------------|
| `active` (default) | Orders needing attention | **No pagination — full load** | `QUEUED`, `PROCESSING`, `UNCLAIMED`, `PENDING_APPROVAL`, `PENDING_DATA`, `INCIDENT`, `PENDING_COMPLETION` |
| `history` | Resolved / terminal orders | **Paginated** (page size 20) | `CLAIMED`, `REJECTED`, `FAILED` |

> **Design rationale:** The active tab is loaded in full because it's always small (typically 5-20 orders) and the user needs to see all actionable items at once. The history tab grows over time (200-500/month) so it's paginated.

### Search

Search works **within the active tab** and filters by:
- `order_id` — exact or partial match
- `consumer_name` — partial match (case-insensitive)
- `consumer_number` — exact or partial match (relationship ID)

```
GET /api/sdms-claims/orders/?tab=active&search=MOHD
GET /api/sdms-claims/orders/?tab=history&search=REL-12345
GET /api/sdms-claims/orders/?tab=history&search=005443212575
```

### Priority Sorting (Active Tab Only)

The active tab is sorted into priority tiers:

| Priority | Condition | Meaning |
|----------|-----------|---------|
| **0** | PENDING transfer where `from_user == current user` | "I must approve/reject/cancel" |
| **1** | `data_status` is `QUEUED` or `PROCESSING` | "RPA in progress" |
| **2** | PENDING transfer exists but someone else must act | "Waiting on someone else" |
| **3** | `UNCLAIMED`, `INCIDENT`, `PENDING_COMPLETION` | "Needs attention" |

Within each tier, sorted by `created_at` descending (newest first).

The history tab is sorted by `created_at` descending only.

### List Response Fields

```json
{
    "id": "a1b2c3d4-...",
    "order_id": "123456789",
    "consumer_name": "MOHD ASHRAF",
    "consumer_number": "REL-12345",
    "order_date": "2025-06-15",
    "order_category": "REFILL",
    "payment_mode": "ONLINE",
    "posting_type": "NORMAL",
    "data_status": "COMPLETE",
    "claim_status": "PENDING_APPROVAL",
    "settlement_status": "N/A",
    "amount": "1053.00",
    "original_delivery_boy_name": "Farooq Ahmad",
    "claimed_by_name": null,
    "source": "FLUTTER_APP",
    "created_at": "2025-06-15T10:30:00+05:30",
    "can_claim": false,
    "can_retry": false,

    "has_pending_transfer": true,
    "pending_transfer_summary": {
        "to_user_name": "Bilal Dar",
        "auto_approve_at": "2025-06-17T09:00:00+05:30",
        "is_actionable_by_me": true
    }
}
```

**Key changes from previous design:**
- `consumer_name` and `consumer_number` are now in the list response (key anchors for delivery boys)
- `is_mine` field removed — the view is always user-scoped
- `can_approve_transfer` / `can_reject_transfer` / `can_cancel_transfer` replaced by `pending_transfer_summary.is_actionable_by_me` — actions only happen on the detail page, the list only needs to show an indicator
- `pending_transfer_summary` replaces the flat booleans — provides the info needed for the list card (who wants to claim, when will it auto-approve, and whether I need to act)

### Card Display Priority (Flutter)

**Key anchors at the top of every card:**
```
┌──────────────────────────────┐
│ MOHD ASHRAF                  │  ← Consumer Name (primary anchor)
│ REL-12345                    │  ← Relationship ID (secondary anchor)
│ #123456789  ·  15 Jun 2025   │  ← Order ID + Date
│ REFILL · ONLINE · Rs1,053   │  ← Category + Payment + Amount
│                              │
│ ⚠ Bilal Dar wants to claim   │  ← Transfer indicator (if applicable)
│   Auto-approves in 18 hours  │
└──────────────────────────────┘
```

**Card indicator logic (list view — NO action buttons, info only):**

| `pending_transfer_summary` | `is_actionable_by_me` | Display |
|---------------------------|----------------------|---------|
| present | `true` | Highlighted card — "Needs your approval. {to_user_name} wants to claim. Auto-approves in X hours." |
| present | `false` | Subtle indicator — "Pending on {original_delivery_boy_name}" |
| `null` | — | Standard status badge based on `claim_status` / `data_status` |

**No Approve/Reject/Cancel buttons on the list.** Tap the card → navigate to detail page → actions there.

---

## 2. Order Detail — Transfer Information + Actions

### `GET /api/sdms-claims/orders/{id}/`

New fields added to the detail response:

```json
{
    "id": "a1b2c3d4-...",
    "order_id": "123456789",
    "consumer_name": "MOHD ASHRAF",
    "consumer_number": "REL-12345",
    "...": "... (all existing fields unchanged) ...",

    "pending_transfer": {
        "id": "d4e5f6g7-...",
        "from_user_name": "Farooq Ahmad",
        "to_user_name": "Bilal Dar",
        "status": "PENDING",
        "auto_approve_at": "2025-06-17T09:00:00+05:30",
        "can_approve": true,
        "can_reject": true,
        "can_cancel": true,
        "created_at": "2025-06-15T14:00:00+05:30"
    },

    "transfer_history": [
        {
            "id": "x1y2z3-...",
            "from_user_name": "Farooq Ahmad",
            "to_user_name": "Ali Shah",
            "status": "CANCELLED",
            "resolved_at": "2025-06-14T16:00:00+05:30",
            "rejection_reason": ""
        }
    ]
}
```

### `pending_transfer` Object

The currently active (PENDING) transfer, or `null` if none exists.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Transfer ID (not needed by Flutter — use order-level endpoints) |
| `from_user_name` | string | Original delivery boy (the one who must act) |
| `to_user_name` | string | Requester (who wants to claim) |
| `status` | string | Always `"PENDING"` (by definition) |
| `auto_approve_at` | datetime | When auto-approval kicks in |
| `can_approve` | boolean | `true` if current user is `from_user` |
| `can_reject` | boolean | `true` if current user is `from_user` |
| `can_cancel` | boolean | `true` if current user is `from_user` |
| `created_at` | datetime | When the transfer request was created |

### `transfer_history` Array

All resolved transfers (APPROVED, REJECTED, AUTO_APPROVED, CANCELLED) for this order, sorted by most recent first. Empty array `[]` if no history.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Transfer ID |
| `from_user_name` | string | Original delivery boy |
| `to_user_name` | string | Requester |
| `status` | string | `APPROVED`, `REJECTED`, `AUTO_APPROVED`, or `CANCELLED` |
| `resolved_at` | datetime | When the transfer was resolved |
| `rejection_reason` | string | Reason (if rejected, else empty) |

### Detail Page — Action Buttons

| `pending_transfer` | `can_approve` | Display |
|--------------------|---------------|---------|
| `null` | — | No transfer section. Show Claim button if `can_claim == true` |
| present | `true` | Transfer card with **Approve**, **Reject**, and **Cancel** buttons |
| present | `false` | Transfer card as info-only: "You requested this order from {from_user_name}. Auto-approves at {time}" |

---

## 3. Approve Transfer (from Order)

### `POST /api/sdms-claims/orders/{id}/approve-transfer/`

Approves the pending transfer on this order. No request body needed.

**Response (200 — Success):**

```json
{
    "message": "Transfer approved successfully",
    "success": true,
    "order": {
        "id": "a1b2c3d4-...",
        "claim_status": "CLAIMED",
        "claimed_by_name": "Bilal Dar",
        "pending_transfer": null,
        "transfer_history": [
            {"status": "APPROVED", "...": "..."}
        ],
        "...": "..."
    }
}
```

**Error responses:**

| Code | Message |
|------|---------|
| 400 | "Only the original owner can approve this transfer" |
| 400 | "No pending transfer found for this order" |

---

## 4. Reject Transfer (from Order)

### `POST /api/sdms-claims/orders/{id}/reject-transfer/`

Rejects the pending transfer. The original delivery boy keeps the claim. Order becomes `CLAIMED` (terminal).

**Request Body (optional):**

```json
{
    "reason": "I delivered this order myself"
}
```

**Response (200 — Success):**

```json
{
    "message": "Transfer rejected. Credit claimed by original owner.",
    "success": true,
    "order": {
        "claim_status": "CLAIMED",
        "claimed_by_name": "Farooq Ahmad",
        "pending_transfer": null,
        "...": "..."
    }
}
```

---

## 5. Cancel Transfer (from Order)

### `POST /api/sdms-claims/orders/{id}/cancel-transfer/`

Cancels the pending transfer — neither approves nor rejects. The order returns to `UNCLAIMED` so the correct person can claim it.

**Use case:** Delivery boy Y receives a transfer request from X, but Y knows Z actually delivered it. Y cancels, then Z claims properly.

No request body needed.

**Response (200 — Success):**

```json
{
    "message": "Transfer cancelled. Order is now unclaimed.",
    "success": true,
    "order": {
        "claim_status": "UNCLAIMED",
        "claimed_by_name": null,
        "can_claim": true,
        "pending_transfer": null,
        "transfer_history": [
            {"status": "CANCELLED", "...": "..."}
        ],
        "...": "..."
    }
}
```

**Difference from Reject:**

| Action | Order Status After | Who Gets Credit | Re-claimable? |
|--------|-------------------|-----------------|---------------|
| **Approve** | `CLAIMED` | Requester (to_user) | No |
| **Reject** | `CLAIMED` | Original (from_user) | No |
| **Cancel** | `UNCLAIMED` | Nobody yet | **Yes** |
| **Auto-Approve** | `CLAIMED` | Requester (to_user) | No |

---

## 6. Flutter Screen Redesign

### Screen 1: Order Entry (Home Action)

No change from current design.

### Screen 2: My Orders — Two Tabs

**API Calls:**
- Active tab: `GET /api/sdms-claims/orders/?tab=active`
- History tab: `GET /api/sdms-claims/orders/?tab=history&page=1`

```
+----------------------------------+
|  My Orders          🔍 Search    |
|  [Active]  [History]             |
|                                  |
|  ┌──────────────────────────────┐|
|  │ MOHD ASHRAF                  ││  ← Key anchors
|  │ REL-12345                    ││
|  │ #123456789 · 15 Jun 2025    ││
|  │ REFILL · ONLINE · Rs1,053   ││
|  │                              ││
|  │ ⚠ Bilal Dar wants to claim   ││  ← Transfer indicator
|  │   Auto-approves in 18 hours  ││
|  └──────────────────────────────┘|
|                                  |
|  ┌──────────────────────────────┐|
|  │ GHULAM NABI                  ││
|  │ REL-67890                    ││
|  │ #987654321 · 15 Jun 2025    ││
|  │ REFILL · CASH · Rs850       ││
|  │                              ││
|  │ ⏳ Fetching data...           ││
|  └──────────────────────────────┘|
|                                  |
|  ┌──────────────────────────────┐|
|  │ ALI MOHAMMAD                 ││
|  │ REL-11223                    ││
|  │ #555666777 · 14 Jun 2025    ││
|  │ SV · CASH · Rs4,500         ││
|  │                              ││
|  │ ⏳ Pending on Farooq Ahmad   ││
|  └──────────────────────────────┘|
+----------------------------------+
```

**Active tab sorting (all loaded at once):**

| Priority | Orders |
|----------|--------|
| 0 | Transfers pending MY approval |
| 1 | RPA in progress (QUEUED, PROCESSING) |
| 2 | Transfers pending on someone else |
| 3 | UNCLAIMED, INCIDENT, PENDING_COMPLETION |

**History tab (paginated, page_size=20):**
- CLAIMED, REJECTED, FAILED
- Sorted by `created_at` descending

**Search bar:**
- Searches within the currently active tab
- Matches: `order_id`, `consumer_name`, `consumer_number`
- Typing triggers filter (debounced)

**Card structure — key anchors first:**

Every card shows these fields in this order:
1. **Consumer Name** (bold, primary)
2. **Relationship ID** (`consumer_number`)
3. **Order ID** + **Date**
4. **Category** + **Payment Mode** + **Amount**
5. **Status indicator** (transfer pending, fetching, claimed, etc.)

### Screen 3: Order Detail — With Inline Actions

```
+----------------------------------+
|  <- MOHD ASHRAF                  |
|     REL-12345                    |
|     Order #123456789             |
|                                  |
|  Status: Pending Approval        |
|  Category: Refill                |
|  Payment: Online · Rs1,053       |
|  Date: 15 Jun 2025              |
|                                  |
|  ┌──────────────────────────────┐|
|  │ ⚠ Transfer Request           ││
|  │                              ││
|  │ Bilal Dar wants to claim     ││
|  │ this order from you.         ││
|  │                              ││
|  │ Auto-approves in 18 hours    ││
|  │ (17 Jun 2025, 9:00 AM)      ││
|  │                              ││
|  │ [Approve] [Reject] [Cancel]  ││
|  └──────────────────────────────┘|
|                                  |
|  Consumer: 9876543210            |
|  Address: Srinagar, Kashmir      |
|                                  |
|  Original Delivery Boy           |
|  Farooq Ahmad                    |
|                                  |
|  ERP Status (online orders)      |
|  Accrual: Pending                |
|  Allocation: Unallocated         |
|  Settlement: Unsettled           |
|                                  |
|  Transfer History                |
|  ┌──────────────────────────────┐|
|  │ Farooq Ahmad → Ali Shah      ││
|  │ Cancelled · 14 Jun 2025     ││
|  └──────────────────────────────┘|
+----------------------------------+
```

**Detail header uses key anchors:** Consumer Name, Relationship ID, Order ID at the top.

**Action buttons appear ONLY on the detail page:**
- **Approve / Reject / Cancel** — when `pending_transfer.can_approve == true`
- **Claim** — when `can_claim == true`
- **Retry** — when `can_retry == true`

### Screen 4: Dedicated Approvals Screen

**Removed.** Approvals are inline in the order detail.

---

## 7. What Happens After Approve/Reject/Cancel

### On Approve

1. Transfer status → `APPROVED`
2. Order `claim_status` → `CLAIMED`, `claimed_by` = requester
3. ERP posting jobs queued
4. Order moves from Active tab to History tab

### On Reject

1. Transfer status → `REJECTED`
2. Order `claim_status` → `CLAIMED`, `claimed_by` = original
3. ERP posting jobs queued
4. Order moves from Active tab to History tab

### On Cancel

1. Transfer status → `CANCELLED`
2. Order `claim_status` → `UNCLAIMED` (stays in Active tab)
3. No ERP posting
4. Order is re-claimable — anyone can claim it

### On Auto-Approve (background cron)

1. Transfer status → `AUTO_APPROVED`
2. Same outcome as manual approve
3. Push notification sent to both parties

### Multi-Transfer Scenario (enabled by Cancel)

```
1. Delivery boy X enters order #123 (posted by Y in SDMS)
2. Transfer created: X → Y (pending Y's approval)
3. Y sees the request but knows Z actually delivered it
4. Y cancels the transfer → order returns to UNCLAIMED
5. Z claims order #123 → new transfer created: Z → Y
6. Y approves → order CLAIMED by Z, ERP posting starts
```

Transfer history will show the full audit trail:
```json
[
    {"from_user_name": "Y", "to_user_name": "X", "status": "CANCELLED"},
    // pending_transfer shows: Z → Y (PENDING)
]
```

---

## 8. Backend Implementation Summary

### Files Modified

| File | Change |
|------|--------|
| `sdms_claims/models/choices.py` | Add `CANCELLED` to `ClaimTransferStatus` enum |
| `sdms_claims/models/sdms_order.py` | Add `cancel_claim_transfer()` FSM transition: `PENDING_APPROVAL → UNCLAIMED` |
| `sdms_claims/services/claim_transfer_service.py` | Add `cancel_transfer()` method |
| `sdms_claims/views/sdms_order_views.py` | Two-tab queryset with priority sorting, search, user-scoping, prefetch transfers, new approve/reject/cancel actions |
| `sdms_claims/serializers/sdms_order.py` | Add `consumer_number` to list. Add `pending_transfer_summary` to list. Add `pending_transfer`, `transfer_history` to detail. Remove `is_mine` |
| `sdms_claims/docs/FLUTTER_INTEGRATION_claims.md` | Update to v1.4 with new design |

### Model Changes (requires migration)

**`ClaimTransferStatus`** — add `CANCELLED = 'CANCELLED'`

**`SDMSOrder`** — new FSM transition:
```python
@fsm_log_by
@transition(field='claim_status', source='PENDING_APPROVAL', target='UNCLAIMED')
def cancel_claim_transfer(self, by=None):
    """Cancel a pending transfer, returning order to unclaimed."""
    self.claimed_by = None
    self.claimed_partner = None
    self.claimed_at = None
```

**`ClaimTransferService`** — new method:
```python
@transaction.atomic
def cancel_transfer(self, transfer_id, cancelled_by):
    transfer = ClaimTransfer.objects.select_for_update().get(pk=transfer_id)
    if transfer.from_user_id != cancelled_by.id:
        return False, "Only the original owner can cancel this transfer"
    if transfer.status != 'PENDING':
        return False, "Transfer is not pending"

    transfer.status = 'CANCELLED'
    transfer.resolved_by = cancelled_by
    transfer.resolved_at = timezone.now()
    transfer.save()

    order = transfer.order
    order.cancel_claim_transfer(by=cancelled_by)
    order.save()
    return True, "Transfer cancelled. Order is now unclaimed."
```

### Queryset Logic (Pseudocode)

```python
def get_queryset(self):
    user = self.request.user
    company = self.request.active_company

    # Always scoped to current user (no is_mine filter needed)
    qs = SDMSOrder.objects.filter(
        company=company,
    ).filter(
        Q(original_delivery_boy=user)
        | Q(initiated_by=user)
        | Q(intended_claimant=user)
    )

    # Search (within active tab)
    search = self.request.query_params.get('search')
    if search:
        qs = qs.filter(
            Q(order_id__icontains=search)
            | Q(consumer_name__icontains=search)
            | Q(consumer_number__icontains=search)
        )

    # Tab split
    tab = self.request.query_params.get('tab', 'active')
    if tab == 'active':
        qs = qs.exclude(
            data_status__in=['COMPLETE'],
            claim_status__in=['CLAIMED', 'REJECTED'],
        ).exclude(
            data_status='FAILED',
        )
        # Priority sorting
        pending_i_must_approve = ClaimTransfer.objects.filter(
            order=OuterRef('pk'), status='PENDING', from_user=user
        )
        pending_any = ClaimTransfer.objects.filter(
            order=OuterRef('pk'), status='PENDING'
        )
        qs = qs.annotate(
            approval_priority=Case(
                When(Exists(pending_i_must_approve), then=Value(0)),
                When(data_status__in=['QUEUED', 'PROCESSING'], then=Value(1)),
                When(Exists(pending_any), then=Value(2)),
                default=Value(3),
                output_field=IntegerField(),
            ),
        ).order_by('approval_priority', '-created_at')
    else:  # history
        qs = qs.filter(
            Q(claim_status__in=['CLAIMED', 'REJECTED'])
            | Q(data_status='FAILED')
        ).order_by('-created_at')

    return qs
```

### Files NOT Modified

| File | Reason |
|------|--------|
| `ClaimTransferService.approve_transfer()` | Reused as-is |
| `ClaimTransferService.reject_transfer()` | Reused as-is |
| `ClaimTransferViewSet` | Kept for admin/internal use |

---

## 9. Migration Path (Flutter Client)

### From v1.3 to v1.4

**1. Replace order list + transfers screen with two-tab order list.**

```dart
// Active tab (full load, no pagination)
final active = await api.get('/api/sdms-claims/orders/?tab=active');

// History tab (paginated)
final history = await api.get('/api/sdms-claims/orders/?tab=history&page=1');

// Search within active tab
final results = await api.get('/api/sdms-claims/orders/?tab=active&search=MOHD');
```

**2. Update card layout — key anchors first:**

```dart
// Card layout priority:
// 1. consumer_name (bold)
// 2. consumer_number (relationship ID)
// 3. order_id + order_date
// 4. order_category + payment_mode + amount
// 5. status indicator
```

**3. Transfer indicator on list (info only, no buttons):**

```dart
final summary = order['pending_transfer_summary']; // nullable
if (summary != null) {
  final isActionable = summary['is_actionable_by_me'] as bool;
  final toUserName = summary['to_user_name'] as String;
  final autoApproveAt = summary['auto_approve_at'] as String;

  if (isActionable) {
    // Highlight: "⚠ {toUserName} wants to claim. Auto-approves in X hours"
  } else {
    // Subtle: "Pending on {original_delivery_boy_name}"
  }
}
```

**4. Detail page — action buttons:**

```dart
final pendingTransfer = order['pending_transfer']; // nullable
if (pendingTransfer != null && pendingTransfer['can_approve'] == true) {
  // Show Approve, Reject, Cancel buttons
}
```

**5. Use order-level endpoints for actions:**

```dart
await api.post('/api/sdms-claims/orders/$orderId/approve-transfer/');
await api.post('/api/sdms-claims/orders/$orderId/reject-transfer/',
    body: {"reason": "I delivered this myself"});
await api.post('/api/sdms-claims/orders/$orderId/cancel-transfer/');
```

**6. Stop using `/transfers/` API entirely.**

**7. Remove `is_mine` parameter** — the view is always user-scoped now.

---

## 10. Verification

1. `python manage.py makemigrations sdms_claims` — migration for CANCELLED + new FSM transition
2. `python manage.py migrate`
3. `python manage.py check`
4. `GET /api/sdms-claims/orders/?tab=active` — verify priority sorting, user-scoped
5. `GET /api/sdms-claims/orders/?tab=history&page=1` — verify pagination
6. `GET /api/sdms-claims/orders/?tab=active&search=MOHD` — verify search
7. `GET /api/sdms-claims/orders/{id}/` — verify `pending_transfer` + `transfer_history`
8. `POST /orders/{id}/approve-transfer/` — verify claim_status → CLAIMED
9. `POST /orders/{id}/cancel-transfer/` — verify claim_status → UNCLAIMED, re-claimable
10. Claim cancelled order with different user — verify new transfer created
11. Run worker end-to-end
