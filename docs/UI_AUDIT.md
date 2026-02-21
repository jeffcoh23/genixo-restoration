# UI/UX Audit V2 (Prime-Time Readiness)

> Comprehensive UI/UX audit for Genixo Restoration.
>
> Goal: if this document is implemented exactly, the app is ready for prime-time users across all six roles.

---

## 1. Scope and Method

### Scope

- Full UI/UX audit across authentication, incident workflows, properties, organizations, users, settings, and equipment inventory.
- Includes visual design quality, form usability, accessibility/contrast, and multi-step flow clarity.

### Sources reviewed

- Product/domain docs: `docs/ARCHITECTURE.md`, `docs/BUSINESS_RULES.md`, `docs/SCHEMA.md`, `docs/VIEWS.md`, `docs/DESIGN.md`, `docs/TESTING.md`, `docs/ROADMAP.md`, `docs/PROJECT_SETUP.md`, `docs/CODE_QUALITY.md`, `docs/INERTIA_RAILS.md`, `docs/DFR-reference.pdf`.
- Frontend implementation: all files under `app/frontend/`.

### Severity rubric

- `P0` Critical: blocks prime-time launch (accessibility, major trust or task-completion risk).
- `P1` High: materially degrades user efficiency or confidence.
- `P2` Medium: quality gaps that should be fixed before broad scale.
- `P3` Low: polish and consistency improvements.

---

## 2. Executive Verdict

Current state is strong functionally, but not yet prime-time for UI/UX quality.

### Readiness score

- Visual cohesion: `6/10`
- Form quality and consistency: `5/10`
- Accessibility and contrast: `4/10`
- Core flow clarity: `6/10`
- Mobile ergonomics: `5/10`
- Overall prime-time readiness: `5.2/10`

### Launch blockers

All `P0` items below must be completed before prime-time release.

---

## 3. P0 Blockers (Must Fix)

### P0-1: Status color contrast fails WCAG AA

- Affected:
  - `app/frontend/lib/statusColor.ts`
  - badge usages in `app/frontend/pages/Dashboard.tsx`, `app/frontend/pages/Incidents/Index.tsx`, `app/frontend/components/StatusBadge.tsx`
- Problem:
  - White text on several status colors is below 4.5:1 contrast.
  - Measured failures:
    - white on warning (`--color-status-warning`): `2.14:1`
    - white on info (`--color-status-info`): `2.85:1`
    - white on completed (`--color-status-completed`): `2.95:1`
    - white on neutral (`--color-status-neutral`): `3.47:1`
- Required fix:
  - Update status token values (or per-status text colors) so every badge/text combination meets WCAG AA at 12px.
  - Keep semantic meaning, but guarantee accessible contrast.
- Done when:
  - Automated contrast checks for all status badge variants pass >= `4.5:1`.

### P0-2: Controls below minimum touch target

- Affected broadly:
  - Multiple screens use `h-6`, `h-7`, `h-8` controls for interactive actions.
  - Examples in `app/frontend/pages/Incidents/Index.tsx`, `app/frontend/pages/Incidents/components/*`, `app/frontend/pages/Settings/*`, `app/frontend/pages/EquipmentItems/Index.tsx`.
- Problem:
  - Critical interactions are too small for field/mobile users.
- Required fix:
  - Set minimum touch target for interactive controls to 44px on mobile breakpoints.
  - Reserve sub-44 controls only for non-critical desktop-only inline affordances.
- Done when:
  - No primary/secondary action needed for task completion is below 44px on mobile.

### P0-3: Keyboard accessibility gaps in custom controls

- Affected:
  - `app/frontend/components/MultiFilterSelect.tsx`
  - `app/frontend/pages/Incidents/New.tsx` (`UserChecklistSection` custom checkbox rows)
  - `app/frontend/pages/Incidents/components/OverviewPanel.tsx` (`AssignDropdown`)
- Problem:
  - Custom widgets are click-oriented and do not implement full keyboard interaction patterns (`Arrow`, `Esc`, roving focus, correct ARIA roles/states).
- Required fix:
  - Replace custom dropdown/checkbox list behavior with accessible primitives (`Select`, `Popover` + command list, or checkbox groups).
  - Ensure full keyboard operation and visible focus styles.
- Done when:
  - Full flow can be completed keyboard-only with predictable tab order and visible focus ring.

### P0-4: Raw native selects still present in core forms

- Affected:
  - `app/frontend/pages/Properties/New.tsx`
  - `app/frontend/pages/Incidents/components/AttachmentForm.tsx`
- Problem:
  - Inconsistent visual language and behavior versus the rest of the app.
- Required fix:
  - Replace remaining raw `<select>` with shared `Select` component.
- Done when:
  - No raw `<select>` remains in page-level forms.

---

## 4. P1 Findings (High Priority)

### P1-1: Incident creation form is cognitively heavy

- Affected: `app/frontend/pages/Incidents/New.tsx`
- Problem:
  - Single long form mixes intake, workflow, team assignment, and contacts without progressive disclosure.
- Required fix:
  - Split into clear sections/cards:
    - Incident Basics
    - Situation Details
    - Team Assignment
    - Contacts
  - Add sticky footer actions (`Cancel`, `Create Request`) on long pages.
  - Collapse advanced/optional fields by default.

### P1-2: Inconsistent form label hierarchy and error presentation

- Affected broadly: most forms under `app/frontend/pages/**`
- Problem:
  - Mixed use of `Label`, raw `label`, `text-xs` labels, and inconsistent error copy placement.
- Required fix:
  - Standardize on one form field recipe:
    - Label (14px minimum on desktop, 13px min mobile)
    - Control
    - Helper text (optional)
    - Error text (consistent spacing and color)

### P1-3: Too many low-emphasis ghost actions for important tasks

- Affected:
  - Incident screens (`Show`, `DailyLogPanel`, `EquipmentPanel`, `LaborPanel`, `OverviewPanel`)
  - Equipment management and on-call pages
- Problem:
  - Important actions are visually underweighted (tiny ghost buttons/icons).
- Required fix:
  - Promote primary actions to explicit buttons in action bars.
  - Keep icon-only controls for tertiary actions only.

### P1-4: Mobile table usability is weak

- Affected:
  - `app/frontend/pages/Incidents/Index.tsx`
  - `app/frontend/pages/Properties/Index.tsx`
  - `app/frontend/pages/Users/Index.tsx`
  - `app/frontend/pages/EquipmentItems/Index.tsx`
  - several incident panel tables
- Problem:
  - Horizontal tables dominate critical flows on small screens.
- Required fix:
  - Add responsive card/list rendering for mobile for key operational tables.

### P1-5: Tab density and discoverability in incident detail

- Affected: `app/frontend/pages/Incidents/components/RightPanelShell.tsx`
- Problem:
  - Six tabs with equal weight create scan friction; on smaller widths tab discoverability drops.
- Required fix:
  - Prioritize top tasks (`Daily Log`, `Messages`, `Documents`) and move lower-frequency admin tasks under `Manage` sub-actions.
  - Ensure horizontal scroll/overflow behavior for tabs on narrow screens.

### P1-6: Inconsistent empty-state quality

- Affected:
  - Good patterns exist (`MessagePanel`, some list pages), but others are plain text-only or visually sparse (`Invitations/Expired`, some admin tables).
- Required fix:
  - Standardize empty states to include icon, plain-language explanation, and next action where permitted.

---

## 5. P2 Findings (Medium Priority)

### P2-1: Status and metric semantics rely too much on color

- Affected:
  - Dashboard unread counters, status chips, equipment status pills.
- Required fix:
  - Add non-color cues consistently (labels/icons/tooltips), especially for unread/activity distinctions.

### P2-2: Legacy destructive browser confirms

- Affected:
  - `app/frontend/pages/Properties/Show.tsx`
  - `app/frontend/pages/Users/Show.tsx`
- Required fix:
  - Replace `confirm()` dialogs with consistent `Dialog` confirmation pattern.

### P2-3: Form behavior consistency in media upload flows

- Affected:
  - `app/frontend/pages/Incidents/components/PhotoUploadDialog.tsx`
- Problem:
  - Native `fetch` flow gives minimal per-file failure feedback and closes/reloads regardless of pending uploads.
- Required fix:
  - Add explicit upload queue states, failure messaging, and guard against closing while uploads are active.

### P2-4: Typography density skews small in operations views

- Affected broadly in incident management views.
- Required fix:
  - Reduce overuse of `text-xs` for task-critical labels and values.
  - Keep `text-xs` for metadata only.

### P2-5: Filter UX lacks quick “applied filters” visibility

- Affected:
  - `Incidents/Index`, `Properties/Index`, `EquipmentItems/Index`
- Required fix:
  - Add applied filter chips with one-click clear per filter.

---

## 6. Forms Deep Audit

### 6.1 Current issues

- Control inconsistency:
  - Raw selects mixed with shadcn selects.
- Layout inconsistency:
  - Some forms are card-based; others are plain stacked fields with no grouping.
- Label inconsistency:
  - Mixed casing, size, and required marker treatment.
- Action inconsistency:
  - Some forms use clear primary/secondary actions; others hide critical actions in small ghost buttons.
- Validation inconsistency:
  - Inline errors are not uniformly styled/presented.

### 6.2 Required standard (single form system)

Apply this to all Tier 1/2/3 forms:

- Tier 1 (inline): compact but minimum 40px desktop / 44px mobile targets.
- Tier 2 (dialog/sheet): sectioned layout, sticky action row if content scrolls.
- Tier 3 (full page): grouped cards with explicit section headings and sticky footer actions on long forms.
- Labels:
  - Required fields always explicit.
  - Optional fields marked consistently.
- Errors:
  - 1 pattern only (`text-destructive`, consistent spacing).
  - Add optional top-level summary for long forms with many errors.

### 6.3 Priority form targets

- `app/frontend/pages/Incidents/New.tsx`
- `app/frontend/pages/Incidents/components/AttachmentForm.tsx`
- `app/frontend/pages/Properties/New.tsx`
- `app/frontend/pages/Users/Index.tsx` (invite form)
- `app/frontend/pages/Settings/OnCall.tsx`
- `app/frontend/pages/EquipmentItems/Index.tsx` dialogs/sheets

---

## 7. Contrast and Visual System Audit

### 7.1 Token-level issues

- `status` palette currently optimized for vibrancy, not accessibility.
- `muted-foreground` on `muted` backgrounds is borderline (`4.40:1`) and frequently used at `text-xs`.

### 7.2 Required token adjustments

- Adjust status color values (or text colors) to guarantee 4.5:1 for badge text.
- Slightly increase contrast for metadata text on muted surfaces.
- Keep semantic intent but prioritize readability under daylight/mobile use.

### 7.3 Component-level visual cleanup

- Normalize card paddings and section headers across pages.
- Ensure interactive rows have distinct hover + focus states.
- Keep one visual language for tables/lists; avoid mixed density patterns on adjacent pages.

---

## 8. Core Flow Audit

### 8.1 Incident intake flow

- Strengths:
  - Complete data model support and team assignment capability.
- Friction:
  - Long monolithic form, optional fields presented too early, contact entry dense.
- Required changes:
  - Progressive disclosure and sectioning.
  - Stronger microcopy for emergency path consequences.
  - Better contact entry UX (repeatable card rows with cleaner spacing and error state).

### 8.2 Incident execution flow (`Show`)

- Strengths:
  - Rich operational surfaces in one workspace.
- Friction:
  - Tab overload; dense controls; discoverability of manage/team actions is weak.
  - Fixed viewport-height shell may reduce usable area on shorter screens.
- Required changes:
  - Rebalance tab priorities.
  - Increase action prominence.
  - Improve responsive behavior for constrained heights.

### 8.3 Messaging and docs flow

- Strengths:
  - Strong visual thread grouping and clean upload entry points.
- Friction:
  - Attachment-only send is blocked by body validation in `MessagePanel`.
- Required changes:
  - Allow send when `body` is empty if files are attached.

### 8.4 Admin setup flows (users/properties/orgs/on-call/equipment)

- Strengths:
  - End-to-end functionality exists.
- Friction:
  - Visual quality and interaction consistency vary heavily between pages.
- Required changes:
  - Standardize filters, tables, dialogs, and confirmation patterns.

---

## 9. Page-by-Page Priority Actions

### Authentication and invitation

- `app/frontend/pages/Login.tsx`
  - Replace flash boxes with shared alert/toast pattern used elsewhere.
- `app/frontend/pages/Auth/ForgotPassword.tsx`
  - Same flash consistency update as login.
- `app/frontend/pages/Auth/ResetPassword.tsx`
  - Add password requirements helper text.
- `app/frontend/pages/Invitations/Accept.tsx`
  - Wrap form in card and align with auth page shell.
- `app/frontend/pages/Invitations/Expired.tsx`
  - Replace plain layout with structured empty/error state card.

### Incident surfaces

- `app/frontend/pages/Incidents/New.tsx`
  - Sectioned layout and sticky submit bar.
  - Replace tiny inline contact controls with larger target controls.
  - Keep accessible team assignment controls.
- `app/frontend/pages/Incidents/Show.tsx`
  - Improve adaptive height strategy and mobile spacing.
- `app/frontend/pages/Incidents/components/RightPanelShell.tsx`
  - Mobile-safe tab overflow and clearer priority ordering.
- `app/frontend/pages/Incidents/components/AttachmentForm.tsx`
  - Replace raw `<select>` and apply standard field recipe.
- `app/frontend/pages/Incidents/components/MessagePanel.tsx`
  - Support attachment-only sends.

### Lists and admin pages

- `app/frontend/pages/Incidents/Index.tsx`
  - Improve small-screen filter/search ergonomics.
- `app/frontend/pages/Properties/New.tsx`
  - Replace raw `<select>`.
- `app/frontend/pages/Users/Index.tsx`
  - Improve invite form grouping and role/org dependencies UX.
- `app/frontend/pages/Settings/OnCall.tsx`
  - Increase control sizes and improve reorder/remove clarity.
- `app/frontend/pages/EquipmentItems/Index.tsx`
  - Reduce visual complexity in one screen: tighter hierarchy and clearer edit/view state transitions.

---

## 10. Implementation Plan (Required Sequence)

### Phase 1: Accessibility baseline (`P0`)

- Contrast fixes for status system.
- Minimum touch targets.
- Keyboard accessibility on custom controls.
- Remove raw selects.

### Phase 2: Form system unification (`P1`)

- Apply shared form recipe across all pages.
- Rework incident creation layout.
- Standardize validation and helper text.

### Phase 3: Core flow refinements (`P1/P2`)

- Incident detail tab/action hierarchy.
- Messaging/doc flow improvements.
- Admin flow consistency and mobile support.

### Phase 4: Final polish (`P2/P3`)

- Empty states, microcopy, spacing consistency.
- Icon-only actions and visual hierarchy cleanup.

---

## 11. Prime-Time Definition of Done

App is considered prime-time ready only when all are true:

- `P0` and `P1` issues in this doc are complete.
- Status and critical text contrast pass WCAG AA.
- Critical workflows (create incident, triage/update incident, assign users, upload docs/photos, manage on-call) are keyboard-completable and mobile-usable.
- No raw form primitives remain outside approved shared components.
- All key pages have consistent form/list/empty-state patterns.
- QA verifies no dead-end flow for any of the six user roles.

---

## 12. QA Checklist (Release Gate)

- Contrast audit pass for tokens + badges + alert states.
- 44px minimum tap target pass on mobile critical actions.
- Keyboard-only pass for:
  - login/reset/invitation accept
  - new incident creation
  - incident detail tabs + assignment/contact actions
  - equipment and on-call admin tasks
- Mobile viewport pass for:
  - Incident index and detail
  - New incident
  - Message and document interactions
- Cross-role UX pass (manager, technician, office/sales, property manager, area manager, PM manager).

---

## 13. Summary

This app is operationally strong but currently misses prime-time UX quality mainly in accessibility, form consistency, and high-density operational ergonomics. Implementing this Audit V2 closes those gaps and produces a reliable, readable, and low-friction interface for field and office users.
