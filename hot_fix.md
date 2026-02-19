# Hotfix Notes — 2026-02-12

## 1. Order Detail 404 After Transfer Approval

**Intent:** After a transfer was approved, neither party could access the order detail (`404 Not Found`).

**Root Cause:** Two issues in `SDMSOrderViewSet.get_queryset()`:

1. **User-scoping filter missing `claimed_by`** — The queryset filtered by `original_delivery_boy`, `initiated_by`, and `intended_claimant` but not `claimed_by`. After a transfer approval, the new claimant's only link to the order is `claimed_by`, so they lost access.

2. **Tab filtering applied to all actions** — The active tab excludes `CLAIMED` orders. When accessing `/orders/{id}/` (retrieve), the `tab=active` default kicked in and excluded the now-CLAIMED order. Tab/search filtering now only applies to the `list` action.

**Changed:** `sdms_claims/views/sdms_order_views.py`

---

## 2. Beneficiary Partner Indicator + Filter

**Intent:** The client needs to know whether the current user's partner account is the one that received the claim credit, and filter orders by that.

**New fields added to list and detail responses:**

| Field | Type | Description |
|-------|------|-------------|
| `original_partner_name` | string/null | Partner name of the original SDMS poster |
| `claimed_partner_name` | string/null | Partner name of whoever got the credit |
| `is_beneficiary` | bool/null | `true` if current user's partner = `claimed_partner`, `false` if different partner got credit, `null` if unclaimed or no partner role |

**New query parameter:**

| Parameter | Example | Description |
|-----------|---------|-------------|
| `is_beneficiary` | `true` / `false` | Filter orders by whether my partner got the credit. Works on both `tab=active` and `tab=history`. |

**How it works:** The user's partner is resolved from their `DeliveryBoyRole` in the current company — same mechanism used by the claim action. Comparison is partner-level, not user-level.

**Changed:** `sdms_claims/views/sdms_order_views.py`, `sdms_claims/serializers/sdms_order.py`

**No model changes, no migrations.**
