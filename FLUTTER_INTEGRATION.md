# Ujjwala Installation & Reimbursement - Flutter Integration Guide

**Version:** 1.0
**Date:** 2026-02-26

---

## What is Ujjwala?

Ujjwala is a government scheme that provides free LPG cylinders to eligible consumers. The government reimburses the distributor for each installation. The end-to-end flow is:

1. **DCA (another system)** manages consumer eligibility, service area assignment, and proof-of-installation documents.
2. **LPG Ops Backend (this system)** proxies installation submissions to DCA, tracks each installation locally, verifies delivery in the SDMS supplier system via RPA, and creates batch reimbursement Sales Orders in ERPNext.
3. **Flutter app** is the delivery boy's interface for all of this.

The delivery boy's journey:
- Go to customer premises, complete physical installation
- Submit installation proof via Flutter (photos, signatures) — this goes to DCA through us
- Trigger SDMS verification (RPA checks the supplier system to confirm the order exists and is complete)
- Once verified, claim reimbursement by creating a Sales Order against available warehouse stock

---

## Authentication

All endpoints use the standard `CompanyJWTAuthentication`. Include the JWT token in every request:

```
Authorization: Bearer <token>
```

The same token is forwarded to DCA when proxying installation submissions, so DCA can authenticate the delivery boy.

**Base URL:** `/api/ujjwala/`

---

## Data Model Overview

### Installation Statuses

| Status | Value | Meaning |
|--------|-------|---------|
| Pending Verification | `PENDING_VERIFICATION` | Submitted to DCA, awaiting SDMS verification via RPA |
| Verified | `VERIFIED` | RPA confirmed installation exists and is complete in SDMS. Eligible for reimbursement. |
| Reimbursed | `REIMBURSED` | Included in a batch Sales Order. Done. |
| Failed | `FAILED` | RPA could not verify. May be retryable. |
| Unusual | `UNUSUAL` | RPA found the order but items could not be mapped to ERPNext item codes. Admin will resolve. |

### Error Categories (when status = FAILED)

| Category | Value | Meaning | User Action |
|----------|-------|---------|-------------|
| Not Found | `NOT_FOUND` | Order not found in SDMS | Retry (data from DCA is validated, so this is transient) |
| Pending Completion | `PENDING_COMPLETION` | Order exists but not yet marked complete in SDMS | Retry later |
| Technical | `TECHNICAL` | RPA infrastructure error | Retry |
| *(empty string)* | `""` | Unknown/legacy | Retry |

### Installation Object (API response shape)

```json
{
  "id": 42,
  "dca_application_id": "22",
  "relationship_id": "0000100001-CUST123",
  "order_id": "ORD-2026-001234",
  "doc_number": "DOC-2026-5678",
  "consumer_name": "Mohd Ashraf",
  "consumer_address": "Village Khanpur, Tehsil Rajouri",
  "status": "VERIFIED",
  "status_display": "Verified",
  "items": [
    {
      "item_code": "CYL-14.2-F",
      "sdms_item_name": "INDANE GAS 14.2 KG FILLED",
      "quantity": 1,
      "rate": "1053.50",
      "amount": "1053.50"
    }
  ],
  "partner_name": "Ashraf Gas Agency",
  "delivery_boy_name": "Imran Khan",
  "rpa_error": "",
  "error_category": "",
  "can_retry": false,
  "created_at": "2026-02-26T10:30:00",
  "updated_at": "2026-02-26T11:00:00"
}
```

**Notes:**
- `items` is populated only after RPA verification succeeds. Empty array before that.
- `items[].item_code` may be blank if item mapping failed (status will be `UNUSUAL` in that case).
- `can_retry` is `true` only when `status=FAILED` and retry count < 3.
- `delivery_boy_name` shows who performed the installation (useful in partner scope view).

### Reimbursement Batch Object

```json
{
  "id": 7,
  "partner_name": "Ashraf Gas Agency",
  "installation_count": 5,
  "sales_order_name": "SO-2026-00456",
  "erp_posting_status": "SUCCESS",
  "erp_posting_status_display": "Success",
  "erp_posting_error": "",
  "created_at": "2026-02-26T14:00:00"
}
```

---

## Workflow 1: Submit Installation

**When:** Delivery boy completes a physical installation at customer premises and needs to submit proof.

**What happens:**
1. Flutter collects installation proof (photos, signatures, form data — whatever DCA requires).
2. Flutter sends it to our backend with just the `disbursement_id` as a required field.
3. Our backend forwards the entire request body to DCA as-is (transparent proxy).
4. DCA validates and returns identifiers (relationship_id, order_id, doc_number, consumer info).
5. Our backend creates a local `UjjwalaInstallation` record (status: `PENDING_VERIFICATION`).
6. Flutter receives the DCA response directly.

**The backend does NOT validate or inspect the request body beyond `disbursement_id`.** Whatever Flutter sends in the request body gets forwarded to DCA. This means DCA's API contract defines the payload shape, not ours.

### API: Submit Installation

```
POST /api/ujjwala/installations/
```

**Request body:** Must include `disbursement_id` (integer). Everything else is DCA's contract — forward whatever DCA expects.

```json
{
  "disbursement_id": 22,
  "...any other fields DCA requires...": "..."
}
```

**Response:** DCA's response passed through. Expected shape:

```json
{
  "success": true,
  "data": {
    "disbursement_id": 22,
    "relationship_id": "0000100001-CUST123",
    "order_id": "ORD-2026-001234",
    "doc_number": "DOC-2026-5678",
    "consumer_name": "Mohd Ashraf",
    "consumer_address": "Village Khanpur, Tehsil Rajouri"
  }
}
```

**Status:** `201 Created` on success, `400 Bad Request` if DCA rejects or delivery boy has no role.

**Error response:**
```json
{
  "error": "Failed to submit to DCA: <details>"
}
```

---

## Workflow 2: List Installations

**When:** Delivery boy wants to see their installations or all installations under their partner.

### API: List Installations

```
GET /api/ujjwala/installations/
```

**Query parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `scope` | string | `partner` | `mine` = only my installations. `partner` = all installations under my partner (includes other delivery boys). |
| `status` | string | *(none)* | Filter by status. Values: `PENDING_VERIFICATION`, `VERIFIED`, `REIMBURSED`, `FAILED`, `UNUSUAL`. |
| `reimbursed` | string | *(none)* | `true` = only reimbursed. `false` = only not yet reimbursed. |

**Examples:**

```
# My verified, unreimbursed installations
GET /api/ujjwala/installations/?scope=mine&status=VERIFIED&reimbursed=false

# All partner installations that failed
GET /api/ujjwala/installations/?scope=partner&status=FAILED

# Everything under my partner
GET /api/ujjwala/installations/
```

**Response:** Paginated list of Installation objects (see shape above).

---

## Workflow 3: Trigger SDMS Verification (Bulk)

**When:** After submitting one or more installations, the delivery boy triggers RPA verification. This tells the system to check SDMS (the government supplier system) to confirm each installation actually exists and is complete.

**What happens:**
1. Flutter sends a list of installation IDs that are in `PENDING_VERIFICATION` status.
2. Backend starts a Camunda RPA process for each one.
3. RPA reads the order from SDMS, extracts item details (what was delivered, quantities, rates).
4. On success: installation moves to `VERIFIED`, items are populated.
5. On failure: installation moves to `FAILED` with error details.
6. On unusual items (unmapped to ERPNext): installation moves to `UNUSUAL` — admin resolves.

**RPA runs asynchronously.** The API returns immediately with a summary of what was queued. Flutter should poll the list endpoint to see updated statuses.

### API: Bulk Verify

```
POST /api/ujjwala/installations/bulk-verify/
```

**Request body:**

```json
{
  "installation_ids": [42, 43, 44, 45]
}
```

**Response:**

```json
{
  "queued": [42, 43, 44],
  "failed": [
    {"id": 45, "error": "Failed to start Camunda process"}
  ],
  "skipped": [],
  "summary": "3 queued, 1 failed, 0 skipped"
}
```

- `queued`: IDs where RPA was successfully started.
- `failed`: IDs where RPA could not be started (infrastructure issue).
- `skipped`: IDs that were not found or not in `PENDING_VERIFICATION` status for this user/company.

---

## Workflow 4: Retry Failed Installations

**When:** An installation verification failed (status = `FAILED`) and `can_retry` is `true`. The delivery boy wants to try again.

**What happens:**
1. The installation is reset from `FAILED` back to `PENDING_VERIFICATION`.
2. A new Camunda RPA process is started.
3. Same async flow as bulk-verify.

Each installation can be retried up to 3 times. After that, `can_retry` becomes `false`.

Since the data comes from DCA (which validates it), failures are typically transient (SDMS lag, technical errors). Retrying usually succeeds.

### API: Retry Failed

```
POST /api/ujjwala/installations/retry/
```

**Request body:** Same shape as bulk-verify.

```json
{
  "installation_ids": [45, 46]
}
```

**Response:**

```json
{
  "reset": [45],
  "failed": [
    {"id": 46, "error": "Max retries (3) exceeded"}
  ],
  "skipped": [],
  "summary": "1 retried, 1 failed, 0 skipped"
}
```

- `reset`: IDs successfully reset and re-queued for RPA.
- `failed`: IDs that could not be retried (max retries exceeded, or Camunda issue).
- `skipped`: IDs not found, not FAILED, or not belonging to this user.

---

## Workflow 5: Reimbursement Preview

**When:** Delivery boy wants to claim reimbursement. Before creating a Sales Order, they need to see what's available — how many verified installations exist under their partner, and whether the warehouse has enough stock.

**What happens:**
1. Delivery boy selects a warehouse.
2. Backend aggregates all `VERIFIED` (unreimbursed) installations across the entire partner.
3. Backend checks ERPNext stock for each item code found in those installations.
4. Returns a summary so Flutter can show availability before the delivery boy commits.

### API: Reimbursement Preview

```
GET /api/ujjwala/reimbursements/preview/?warehouse_id=5
```

**Query parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `warehouse_id` | integer | Yes | Warehouse to check stock against |

**Response:**

```json
{
  "warehouse": {
    "id": 5,
    "name": "WH-RAJOURI-01 - AIG",
    "label": "WH-RAJOURI-01 - AIG"
  },
  "claimable_count": 12,
  "items": [
    {
      "item_code": "CYL-14.2-F",
      "claimable_qty": 12,
      "available_stock": 25
    }
  ]
}
```

- `claimable_count`: Total verified, unreimbursed installations for the partner.
- `items[].claimable_qty`: How many of this item are needed across all claimable installations.
- `items[].available_stock`: How many are physically in stock at the warehouse.

**Flutter should compare `claimable_qty` vs `available_stock` per item.** If stock is insufficient for some items, the delivery boy can still create a reimbursement for a smaller qty (FIFO picking will select oldest installations first, and the system validates stock per-item for the picked set).

---

## Workflow 6: Create Reimbursement

**When:** Delivery boy has seen the preview and wants to create a batch Sales Order for reimbursement.

**What happens:**
1. Delivery boy picks a warehouse and enters a quantity (number of installations to reimburse).
2. Backend FIFO-picks the oldest `qty` verified installations under the partner.
3. Backend aggregates items from picked installations (e.g., 5 installations x 1 cylinder each = 5 cylinders).
4. Backend validates that aggregated qty per item code <= available stock at warehouse.
5. Creates a `ReimbursementBatch` record linking the picked installations.
6. Creates a Sales Order in ERPNext with:
   - Customer = partner's ERPNext ID
   - Items = aggregated from picked installations (actual item codes and quantities from RPA)
   - Debit account = government receivable (not partner's account — government pays)
   - `custom_connection_type` = "Ujjwala"
7. On SO success: all picked installations transition to `REIMBURSED`.
8. On SO failure: installations stay `VERIFIED` (can retry).

### API: Create Reimbursement

```
POST /api/ujjwala/reimbursements/
```

**Request body:**

```json
{
  "warehouse_id": 5,
  "qty": 5
}
```

- `qty`: Number of installations to include. Must be <= `claimable_count` from preview. Backend FIFO-picks (oldest first).

**Response (success):**

```json
{
  "id": 7,
  "partner_name": "Ashraf Gas Agency",
  "installation_count": 5,
  "sales_order_name": "SO-2026-00456",
  "erp_posting_status": "SUCCESS",
  "erp_posting_status_display": "Success",
  "erp_posting_error": "",
  "created_at": "2026-02-26T14:00:00"
}
```

**Response (ERP failure — batch created but SO failed):**

```json
{
  "id": 8,
  "partner_name": "Ashraf Gas Agency",
  "installation_count": 5,
  "sales_order_name": "",
  "erp_posting_status": "FAILED",
  "erp_posting_status_display": "Failed",
  "erp_posting_error": "HTTPError: 500 ...",
  "created_at": "2026-02-26T14:05:00"
}
```

When `erp_posting_status` is `FAILED`, the installations remain `VERIFIED` and are NOT locked to this batch. The delivery boy can try again.

**Validation errors (400):**

```json
{"error": "Requested qty (10) exceeds claimable installations (5)"}
{"error": "Insufficient stock for CYL-14.2-F: need 5, available 2"}
{"error": "No items found on the selected installations"}
```

---

## Workflow 7: List Reimbursement Batches

**When:** Delivery boy wants to see history of reimbursement batches created under their partner.

### API: List Reimbursements

```
GET /api/ujjwala/reimbursements/
```

**Response:** Paginated list of ReimbursementBatch objects (see shape above). Filtered to the current user's partner and company.

---

## Status Lifecycle Diagram

```
                    submit_installation()
                           |
                           v
                 PENDING_VERIFICATION
                    |             |
           verify() |             | mark_failed()
                    v             v
               VERIFIED        FAILED -----> PENDING_VERIFICATION
                    |          (can_retry)     (reset_for_retry, max 3x)
                    |
                    |  mark_unusual()
                    |       |
                    |       v
                    |    UNUSUAL
                    |    (admin resolves item mapping,
                    |     then re-verifies)
                    |
          reimburse() (batch SO created)
                    |
                    v
               REIMBURSED
```

---

## Suggested Flutter Polling Strategy

RPA verification is asynchronous (takes 10-60 seconds typically). After calling `bulk-verify` or `retry`:

1. Show a "Verifying..." state on the affected installations.
2. Poll `GET /api/ujjwala/installations/?scope=mine&status=PENDING_VERIFICATION` every 5-10 seconds.
3. When an installation disappears from this filtered list, it has transitioned — re-fetch the full list to see the new status.
4. Stop polling when no installations are in `PENDING_VERIFICATION`.

---

## Typical Delivery Boy Session

1. **Morning:** Delivery boy gets a list of Ujjwala installations to do today (from DCA / field manager).

2. **At each customer site:**
   - Complete physical installation
   - Open Flutter app, submit proof: `POST /api/ujjwala/installations/` with `disbursement_id` + DCA payload

3. **After completing all installations for the day:**
   - Open installations list: `GET /api/ujjwala/installations/?scope=mine&status=PENDING_VERIFICATION`
   - Select all, trigger verification: `POST /api/ujjwala/installations/bulk-verify/`
   - Wait for RPA to complete (poll list)
   - Check for failures, retry if needed: `POST /api/ujjwala/installations/retry/`

4. **When ready to claim reimbursement:**
   - Check preview: `GET /api/ujjwala/reimbursements/preview/?warehouse_id=5`
   - See claimable count and stock availability
   - Create reimbursement: `POST /api/ujjwala/reimbursements/` with `warehouse_id` + `qty`
   - Confirm SO was created (check `erp_posting_status`)

5. **Review history:**
   - Past reimbursements: `GET /api/ujjwala/reimbursements/`
   - All partner installations: `GET /api/ujjwala/installations/?scope=partner`

---

## Edge Cases

| Scenario | What Happens |
|----------|-------------|
| Duplicate submission (same `disbursement_id` + company) | 400 error — unique constraint prevents duplicates |
| DCA is down | 400 error with message "Failed to submit to DCA: ..." |
| RPA finds order not complete yet | Status = `FAILED`, error_category = `PENDING_COMPLETION`, `can_retry = true` |
| RPA finds unknown item (not in item mapping) | Status = `UNUSUAL` — admin adds mapping, re-verifies |
| Insufficient warehouse stock | 400 error on create reimbursement with specific item details |
| ERPNext SO creation fails | Batch created with `erp_posting_status = FAILED`, installations stay `VERIFIED` |
| Delivery boy has no partner/role | 400 error "User does not have a delivery boy role for this company" |
| `qty` exceeds claimable | 400 error with exact counts |

---

## API Summary

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `POST` | `/api/ujjwala/installations/` | Submit installation proof (proxy to DCA) |
| `GET` | `/api/ujjwala/installations/` | List installations (scope, status, reimbursed filters) |
| `POST` | `/api/ujjwala/installations/bulk-verify/` | Trigger RPA verification for multiple installations |
| `POST` | `/api/ujjwala/installations/retry/` | Retry failed installations (reset + re-trigger RPA) |
| `GET` | `/api/ujjwala/reimbursements/preview/?warehouse_id=X` | Preview claimable count and stock availability |
| `POST` | `/api/ujjwala/reimbursements/` | Create batch reimbursement SO |
| `GET` | `/api/ujjwala/reimbursements/` | List reimbursement batches |
