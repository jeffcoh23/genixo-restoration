# Loading and Error State Audit

Date: 2026-02-24
Branch: loading-error-state-audit
Scope: UI loading feedback and user-facing error handling for interactive flows (Inertia + React)

## Goal
Create a reusable loading/error handling pattern for action-driven UI (panels, dialogs, inline actions) before patching individual pages.

## Summary
The app is generally good on form submit loading/error states where `useForm` is used directly (e.g. create/edit forms).

The main gaps are action-oriented components that call `router.post/patch/delete` or `fetch` directly and do not render:
- a local pending state
- a visible inline error message
- field-level validation errors (for custom local-state modals)

This leads to "dead click" UX when requests fail.

## Current Strengths (already okay)
- `app/frontend/pages/Incidents/New.tsx`
  - submit loading (`processing`)
  - field errors + summary banner
- `app/frontend/pages/Properties/New.tsx`
- `app/frontend/pages/Properties/Edit.tsx`
- `app/frontend/pages/Organizations/New.tsx`
- `app/frontend/pages/Organizations/Edit.tsx`
- `app/frontend/pages/Incidents/components/LaborForm.tsx`
- `app/frontend/pages/Incidents/components/EquipmentForm.tsx`
- `app/frontend/pages/Incidents/components/AttachmentForm.tsx`
- `app/frontend/pages/Incidents/components/IncidentEditForm.tsx`

## High Priority Gaps (P1)
These can produce silent failures in core workflows.

### Incidents
- `app/frontend/pages/Incidents/components/MessagePanel.tsx`
  - Uses `router.post` directly for send.
  - Has pending state (`sending`) but no visible error on failure.
  - Impact: users think message sent when it failed.

- `app/frontend/pages/Incidents/Show.tsx`
  - Status transition dropdown uses `router.patch` directly.
  - Has pending state (`transitioning`) but no visible error.
  - Impact: status appears stuck with no reason.

- `app/frontend/pages/Incidents/components/OverviewPanel.tsx` (Manage tab)
  - Team assign/remove actions use `router.post/delete` directly.
  - Contact add/edit modal uses local state + `router.post/patch` (not `useForm`).
  - No field-level validation rendering for contact modal.
  - No inline error banner for assign/remove/contact actions.
  - Impact: high confusion in a core management panel.

### Properties
- `app/frontend/pages/Properties/Show.tsx`
  - Assignment add/remove actions use `router.post/delete` directly.
  - No visible pending/error feedback.
  - Same pattern as incident manage panel.

## Medium Priority Gaps (P2)

### Incidents / Daily Operations
- `app/frontend/pages/Incidents/components/EquipmentPanel.tsx`
  - Remove action has no pending/error feedback.

- `app/frontend/pages/Incidents/components/PhotoUploadDialog.tsx`
  - Tracks per-file state and aggregate counts (good), but error copy is generic and no retry affordance.

- `app/frontend/pages/Incidents/components/PhotosPanel.tsx`
  - Bulk upload has aggregate message but limited detail/actionability.
  - Could standardize error/success summary and preserve filters (already mostly good).

### Users
- `app/frontend/pages/Users/Index.tsx`
  - Resend invitation action uses inline `router.patch` without pending/error state.

- `app/frontend/pages/Users/Show.tsx`
  - Activate/deactivate actions lack consistent pending/error feedback.

### Settings / Equipment Admin (shared pattern candidates)
- `app/frontend/pages/Settings/OnCall.tsx`
  - Save/add/remove/reorder actions mostly have pending flags on some paths, but no visible error banners.

- `app/frontend/pages/Settings/EquipmentTypes.tsx`
  - Create/activate/deactivate actions likely same pattern (needs shared action feedback).

- `app/frontend/pages/EquipmentItems/Index.tsx`
  - Add/update/deactivate/create-type have partial pending state, weak/no visible inline errors.

## Low Priority Gaps (P3)
- Silent background actions where failure impact is low and retry path is obvious.
- Cosmetic loading consistency (button labels/spinners) on secondary admin pages.

## Reusable System Proposal (before fixes)

### 1. `useInertiaAction` hook (shared)
Location: `app/frontend/lib/useInertiaAction.ts` (or `app/frontend/hooks/useInertiaAction.ts`)

Responsibilities:
- Wrap `router.post/patch/delete`
- Expose:
  - `pending` (boolean)
  - `error` (string | null)
  - `clearError()`
  - `runPost/runPatch/runDelete(...)` or generic `run(method, url, data, options)`
- Normalize Inertia validation/error payloads:
  - first error string extraction from `errors` object
  - fallback generic message
- Support common defaults:
  - `preserveScroll: true`
  - optional `preserveState`
- Keep `onSuccess/onError/onFinish` passthrough support

Why:
- Eliminates repeated ad hoc `setSubmitting/setError` logic
- Makes panel actions consistent across Incidents, Properties, Settings, Users

### 2. `InlineActionFeedback` component (shared)
Location: `app/frontend/components/InlineActionFeedback.tsx`

Responsibilities:
- Compact inline message block for panel/dialog actions
- Variants:
  - `error`
  - `success` (optional, phase 2)
  - `info` (optional)
- Supports dismiss + compact spacing
- Built on existing `Alert` component so styling is consistent

Why:
- Action panels need smaller feedback than global flash
- Keeps error messaging local to the control that failed

### 3. Contact modal should use `useForm` (not local state)
Target: `app/frontend/pages/Incidents/components/OverviewPanel.tsx` contact modal (and similar modals later)

Why:
- Field-level validation rendering comes for free
- Less custom error plumbing
- Consistent with the rest of the app

### 4. Optional phase-2 helpers
- `useAsyncUploadStatus` for `fetch` uploads (photos/messages if needed)
- Shared "pending destructive action" button pattern for row removals

## Recommended Implementation Order
1. Build shared `useInertiaAction` + `InlineActionFeedback`
2. Apply to P1:
   - `MessagePanel.tsx`
   - `Incidents/Show.tsx` (status transition)
   - `OverviewPanel.tsx` (assign/remove/contact modal)
   - `Properties/Show.tsx`
3. Apply to P2:
   - `Users/Index.tsx`, `Users/Show.tsx`
   - `EquipmentPanel.tsx`
   - `Settings/OnCall.tsx`
   - `EquipmentItems/Index.tsx` / `Settings/EquipmentTypes.tsx`
4. Upload UX pass:
   - `PhotosPanel.tsx`
   - `PhotoUploadDialog.tsx`

## Testing Plan (targeted)
- System tests for visible error feedback on key failed actions (where feasible)
- Component-level smoke via existing system flows (no artificial timeouts)
- Full `bundle exec rails test test/system` after P1/P2 changes

