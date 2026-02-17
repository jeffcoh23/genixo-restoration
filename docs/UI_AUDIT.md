# UI Audit: Ugliness and Composable Design

Date: February 16, 2026

## Scope

This audit covers:

- `app/frontend/layout`
- `app/frontend/components`
- `app/frontend/components/ui`
- `app/frontend/pages` (30 TSX surfaces, including Incident sub-panels)

## Executive Summary

The app has a solid token foundation but a weak applied design system. The result is a UI that feels plain, inconsistent, and hand-assembled page by page.

Key facts from the audit:

- 30 TSX page surfaces audited.
- 17 surfaces use `AppLayout`.
- 15 surfaces use `PageHeader`.
- Only Login uses the `Card` primitive directly.
- 33 raw control tags are still used in pages/layout (`<button>`, `<select>`, `<input>`, `<textarea>`).
- `statusColor()` and `timeAgo()` logic are duplicated across multiple pages.
- `components/ui` currently has only 6 primitives (`alert`, `badge`, `button`, `card`, `input`, `label`).

## Root Causes

1. Design recipes exist but are not encoded as composable building blocks.
2. Missing primitives (`Select`, `Textarea`, `Tabs`, `Dialog`, etc.) force one-off styling.
3. Shared abstractions (`DataTable`, `DetailList`, `StatusBadge`) are functionally useful but visually minimal.
4. Visual semantics (status color, empty states, section chrome, headers) are duplicated and drift.
5. Layout shell gives limited hierarchy and page personality outside Login.

## Global Findings

### 1) Surface Hierarchy Is Too Flat

- `DataTable` and `DetailList` rely on thin borders without consistent card depth.
- Many sections are plain text + dividers instead of card surfaces with clear headers/footers.
- Empty states often render as simple text, not intentional card-based guidance.

### 2) Composability Gaps in Form Controls

- Pages frequently use raw `<select>` and `<textarea>` with repeated class strings.
- Forms and modal-style panels in Incident pages each define local control styling.
- Inconsistent control heights, backgrounds, and focus ring behavior create visual noise.

### 3) Duplicated Visual Logic

- Status colors are hardcoded in page-level helper functions.
- Relative time formatting is duplicated.
- Table and list presentation patterns are duplicated in page files and components.

### 4) Incomplete Primitive Layer

Missing primitives currently block clean composition:

- `Select`
- `Textarea`
- `Tabs`
- `Dialog`/`Sheet`
- Structured `EmptyState`
- Reusable `SectionCard` and `CardTable`

## Area-by-Area Audit

### Layout and Navigation

- Files: `app/frontend/layout/AppLayout.tsx`, `app/frontend/layout/RoleSidebar.tsx`
**Issues:**
- Main content is constrained to one generic max-width for most routes.
- Header and content scaffold are serviceable but visually generic.
- Sidebar spacing/hierarchy is functional but not reinforced by stronger sectioning.

### Auth and Invitation

- Files: `app/frontend/pages/Login.tsx`, `app/frontend/pages/Invitations/*`
**State:**
- Login is the most polished page due direct `Card` primitive usage.
- Invitation pages are simpler and comparatively sparse.

### Dashboard

- File: `app/frontend/pages/Dashboard.tsx`
**Issues:**
- Page-level status color helper duplicates Incident Index logic.
- Group containers are close to design goals but still largely hand-rolled.
- Limited use of richer stat cards and section framing.

### Incident List

- File: `app/frontend/pages/Incidents/Index.tsx`
**Issues:**
- Page-level status color + time helper duplication.
- Raw `select` control for filters.
- Custom table structure diverges from shared table abstraction.

### Incident Creation

- File: `app/frontend/pages/Incidents/New.tsx`
**Issues:**
- Large amount of inline form class composition.
- Limited extraction into composable field groups.

### Incident Detail Workspace

- Files: `app/frontend/pages/Incidents/Show.tsx`, `app/frontend/pages/Incidents/components/*`
**Issues:**
- Right panel tabs are hand-rolled button tabs.
- Forms (attachment/labor/equipment/note) are all separate styling implementations.
- Message, daily log, and document views are rich but style consistency varies component to component.

### Organizations and Properties

- Files: `app/frontend/pages/Organizations/*`, `app/frontend/pages/Properties/*`
**Issues:**
- Index pages rely on minimal shared table styling.
- Show pages mix `DetailList` with one-off local action controls and select styling.

### Users

- Files: `app/frontend/pages/Users/*`
**Issues:**
- Invite form uses repeated raw select styles.
- Sections rely on minimal borders, with limited card hierarchy.

### Settings

- Files: `app/frontend/pages/Settings/*`
**Issues:**
- Profile has raw select styling.
- Equipment types has some card treatment but not yet unified with other pages.
- On-call placeholder has no polished empty-state shell yet.

## Target Composable Design System

Add and standardize on:

- `ui/select.tsx`
- `ui/textarea.tsx`
- `ui/tabs.tsx`
- `ui/dialog.tsx` or `ui/sheet.tsx`
- `components/SectionCard.tsx` (header/body/footer slots)
- `components/CardTable.tsx` (header actions + table + empty state)
- `components/EmptyStateCard.tsx`
- `components/EntityHeader.tsx`
- `components/StatusBadge.tsx` with semantic variants
- `lib/ui/status.ts` and `lib/ui/time.ts` for shared mapping/formatting

## Recommended Execution Order

1. Build missing primitives and semantic helpers.
2. Upgrade shared building blocks (`DataTable`, `DetailList`, `StatusBadge`, `PageHeader`) to match design recipes.
3. Migrate highest-traffic pages first: Dashboard, Incidents Index, Incident Show workspace.
4. Migrate remaining CRUD/index/detail pages.
5. Run responsive and accessibility QA pass (focus rings, keyboard nav, contrast, hit targets).

## Definition of Done for UI Polish

- No page-level hardcoded status color mappings.
- No raw `<select>` / `<textarea>` styling strings in page files.
- All list/detail/index sections use composable card-based containers.
- Empty states use a consistent reusable pattern.
- Incident workspace tabs/forms/messages/documents share the same visual grammar.
- Mobile/tablet/desktop layouts have consistent spacing and hierarchy.
