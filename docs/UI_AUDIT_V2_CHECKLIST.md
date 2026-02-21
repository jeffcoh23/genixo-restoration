# UI/UX Audit V2 Checklist (Compact + Complete)

> Source: `docs/UI_AUDIT.md`
> Goal: track implementation to prime-time readiness.

---

## 1) P0 Launch Blockers (Must Complete)

### Contrast and Accessibility
- [ ] Fix status badge contrast failures (AA 4.5:1 minimum at 12px).
- [ ] Ensure `warning`, `info`, `completed`, and `neutral` status styles pass AA with chosen text color.
- [ ] Add automated contrast checks for all status variants.

### Touch Targets
- [ ] Raise critical action controls below 44px on mobile to 44px min target.
- [ ] Keep sub-44 controls only for tertiary desktop interactions.

### Keyboard and ARIA Compliance
- [ ] Replace/custom-fix `MultiFilterSelect` for full keyboard operation and ARIA semantics.
- [ ] Replace/custom-fix `Incidents/New` team checklist control for keyboard and ARIA correctness.
- [ ] Replace/custom-fix `OverviewPanel` assign dropdown for keyboard and ARIA correctness.
- [ ] Validate visible focus states across these controls.

### Primitive Consistency
- [ ] Replace raw `<select>` in `app/frontend/pages/Properties/New.tsx`.
- [ ] Replace raw `<select>` in `app/frontend/pages/Incidents/components/AttachmentForm.tsx`.
- [ ] Confirm no remaining raw `<select>` in page-level forms.

---

## 2) P1 High Priority (Pre Prime-Time)

### Form Usability and Clarity
- [ ] Refactor `Incidents/New` into clear sections:
  - [ ] Incident Basics
  - [ ] Situation Details
  - [ ] Team Assignment
  - [ ] Contacts
- [ ] Add sticky action footer on long forms (`Cancel`, `Create Request`).
- [ ] Default-collapse advanced/optional fields where appropriate.

### Form System Consistency
- [ ] Standardize label hierarchy and required/optional conventions.
- [ ] Standardize inline helper text and error presentation spacing/color.
- [ ] Standardize form action patterns (primary/secondary/tertiary emphasis).

### Action Hierarchy
- [ ] Promote critical ghost/icon-only actions to clearer primary/secondary controls.
- [ ] Keep icon-only controls for tertiary actions.

### Mobile Information Architecture
- [ ] Add mobile-friendly card/list rendering for key table-heavy views.

### Incident Detail Navigation
- [ ] Rebalance incident detail tabs to emphasize top workflows.
- [ ] Improve tab behavior for narrow widths (overflow/scroll/discoverability).

### Empty States
- [ ] Standardize all empty states to include:
  - [ ] icon
  - [ ] plain-language explanation
  - [ ] next action (if permitted)

---

## 3) P2 Medium Priority

### Semantics Beyond Color
- [ ] Add non-color cues for unread/status/metric semantics where color currently carries meaning alone.

### Confirmation Patterns
- [ ] Replace browser `confirm()` in `Properties/Show` with shared `Dialog` confirmation.
- [ ] Replace browser `confirm()` in `Users/Show` with shared `Dialog` confirmation.

### Upload Flow Robustness
- [ ] Improve `PhotoUploadDialog` upload queue UX:
  - [ ] explicit per-file status and errors
  - [ ] prevent accidental close while uploads in-flight
  - [ ] clearer completion/failure outcomes

### Typography Density
- [ ] Reduce overuse of `text-xs` for task-critical content.
- [ ] Keep `text-xs` mostly for metadata/supporting text.

### Filter UX
- [ ] Add applied-filter chips with one-click clear in list/index pages.

---

## 4) Form System Checklist (Complete Standard)

### Tiering
- [ ] Tier 1 (inline forms): compact but usable targets (40px desktop / 44px mobile where task-critical).
- [ ] Tier 2 (dialog/sheet): sectioned fields, sticky actions if scrollable.
- [ ] Tier 3 (full page): grouped cards + explicit section headers + sticky footer for long forms.

### Labels and Errors
- [ ] Required fields always explicit.
- [ ] Optional fields marked consistently.
- [ ] One shared error style (`text-destructive`, spacing consistent).
- [ ] Add top-level error summary on long forms with multiple errors.

### Priority Forms to Normalize
- [ ] `app/frontend/pages/Incidents/New.tsx`
- [ ] `app/frontend/pages/Incidents/components/AttachmentForm.tsx`
- [ ] `app/frontend/pages/Properties/New.tsx`
- [ ] `app/frontend/pages/Users/Index.tsx` (invite form)
- [ ] `app/frontend/pages/Settings/OnCall.tsx`
- [ ] `app/frontend/pages/EquipmentItems/Index.tsx` (dialogs/sheets)

---

## 5) Contrast and Visual System Checklist

- [ ] Update status tokens or per-status text treatment to AA.
- [ ] Increase metadata contrast on muted surfaces where borderline.
- [ ] Normalize card paddings and section header treatment.
- [ ] Ensure interactive rows have both hover and focus-visible clarity.
- [ ] Unify list/table density patterns across adjacent screens.

---

## 6) Core Flow Checklist

### Incident Intake
- [ ] Reduce cognitive load via progressive disclosure.
- [ ] Add stronger emergency microcopy (consequence clarity).
- [ ] Improve repeatable contact row UX and spacing.

### Incident Execution (`Show`)
- [ ] Rebalance tabs for highest-frequency workflows.
- [ ] Increase action prominence in dense operational areas.
- [ ] Improve constrained-height behavior (short viewport handling).

### Messaging and Documents
- [ ] Allow message submit with attachments even when body is empty.

### Admin Setup Flows
- [ ] Standardize filter patterns.
- [ ] Standardize table/list patterns.
- [ ] Standardize dialog and confirmation behaviors.

---

## 7) Page-by-Page Action Checklist

### Auth and Invitations
- [ ] `app/frontend/pages/Login.tsx` — unify flash handling with shared alert/toast pattern.
- [ ] `app/frontend/pages/Auth/ForgotPassword.tsx` — same flash consistency update.
- [ ] `app/frontend/pages/Auth/ResetPassword.tsx` — add password requirements helper text.
- [ ] `app/frontend/pages/Invitations/Accept.tsx` — wrap in card and align with auth shell.
- [ ] `app/frontend/pages/Invitations/Expired.tsx` — upgrade to structured empty/error state.

### Incidents
- [ ] `app/frontend/pages/Incidents/New.tsx` — sectioned layout + sticky submit + larger contact controls.
- [ ] `app/frontend/pages/Incidents/Show.tsx` — improve adaptive height/mobile spacing.
- [ ] `app/frontend/pages/Incidents/components/RightPanelShell.tsx` — mobile-safe tabs + priority order.
- [ ] `app/frontend/pages/Incidents/components/AttachmentForm.tsx` — remove raw select + apply field standard.
- [ ] `app/frontend/pages/Incidents/components/MessagePanel.tsx` — support attachment-only send.

### Lists/Admin
- [ ] `app/frontend/pages/Incidents/Index.tsx` — improve small-screen filters/search UX.
- [ ] `app/frontend/pages/Properties/New.tsx` — remove raw select.
- [ ] `app/frontend/pages/Users/Index.tsx` — improve invite role/org dependency UX.
- [ ] `app/frontend/pages/Settings/OnCall.tsx` — increase control size + reorder/remove clarity.
- [ ] `app/frontend/pages/EquipmentItems/Index.tsx` — reduce visual complexity, clarify edit/view transitions.

---

## 8) Rollout Sequence Checklist

### Phase 1: Accessibility Baseline
- [ ] Contrast fixes
- [ ] Touch targets
- [ ] Keyboard/ARIA fixes
- [ ] Remove raw selects

### Phase 2: Form System Unification
- [ ] Standard recipe adopted
- [ ] Incident create form rework
- [ ] Validation/helper text consistency

### Phase 3: Core Flow Refinements
- [ ] Incident detail IA/action hierarchy
- [ ] Messaging/docs flow improvements
- [ ] Admin flow consistency + mobile support

### Phase 4: Final Polish
- [ ] Empty states and microcopy pass
- [ ] Spacing consistency pass
- [ ] Icon-only/visual hierarchy cleanup

---

## 9) Prime-Time Definition of Done Checklist

- [ ] All `P0` and `P1` items completed.
- [ ] Status + critical text contrast pass WCAG AA.
- [ ] Critical workflows are keyboard-completable.
- [ ] Critical workflows are mobile-usable.
- [ ] No unapproved raw form primitives remain.
- [ ] Key pages share consistent form/list/empty-state patterns.
- [ ] No dead-end flow for any role (manager, technician, office/sales, property manager, area manager, PM manager).

---

## 10) Release Gate QA Checklist

- [ ] Contrast audit pass (tokens + badges + alerts).
- [ ] 44px touch target pass (mobile critical interactions).
- [ ] Keyboard-only pass:
  - [ ] login / reset / invitation accept
  - [ ] incident creation
  - [ ] incident tab navigation + assignments/contacts
  - [ ] equipment and on-call admin tasks
- [ ] Mobile viewport pass:
  - [ ] incidents index
  - [ ] incident detail
  - [ ] new incident form
  - [ ] messages/documents interactions
- [ ] Cross-role UX pass (all six roles).

---

## 11) Suggested Tracking Fields (Optional)

- [ ] Add owner per checklist item.
- [ ] Add target sprint/phase per item.
- [ ] Add PR link per completed item.
- [ ] Add QA evidence link (video/screenshot/test run) per release-gate item.
