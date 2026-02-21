# UI Audit Report

> Phase 6A audit of every page against the design token system. Findings organized as the Phase 6B punch list.
>
> **Layer 1** = mechanical fixes (wrong component, wrong color, missing primitive). **COMPLETE.**
> **Layer 2** = brand & visual polish (color application, visual hierarchy, component extraction). Up next.

---

## Layer 1: Mechanical Fixes — COMPLETE

All Layer 1 items were resolved in Phase 6B Sessions 1–2.

### 1. Missing Primitives — DONE

Installed `Select` and `Textarea` via `npx shadcn@latest add select textarea`. `Dialog`, `Sheet`, and `Tabs` already existed.

### 2. Raw HTML → shadcn — DONE

Replaced all 8 raw `<select>` elements, all 12 raw `<textarea>` elements, and 2 raw `<button>` elements with shadcn components. Also replaced 1 inline badge `<span>` with shadcn `Badge`.

### 3. Hardcoded Colors → Design Tokens — DONE

Migrated all 11 hardcoded color instances across 5 files to design tokens (`text-status-info`, `text-status-warning`, `bg-status-emergency/10`, `bg-status-warning/15`, `bg-status-success/15`, etc.).

### 4. Custom Modals → shadcn Dialog — DONE

Converted all 7 hand-rolled modals to shadcn Dialog: EquipmentForm, LaborForm, NoteForm, ActivityForm, IncidentEditForm, OverviewPanel (contact form + confirmation dialog).

---

## Layer 2: Brand & Visual Polish

### Monochrome Panels

`EquipmentPanel`, `LaborPanel`, `DailyLogPanel`, and `OverviewPanel` all lack accent color — they read as flat gray. `MessagePanel` is the one good example, using `bg-accent` for visual interest. Apply similar treatment to the other panels.

### Table Hover States

`EquipmentPanel` and `LaborPanel` are missing `hover:bg-muted/30 transition-colors` on table rows per DESIGN.md.

### Tables Not Wrapped in Card

DESIGN.md specifies tables should be in `<Card className="overflow-hidden">` with `bg-muted/50` headers. Several tables use raw `<table>` without the Card wrapper.

### Oversized Pages

`EquipmentItems/Index.tsx` is 719 lines with four nested components. Extract into separate files:
- `InventoryTable` — main table view
- `AddItemDialog` — add item modal
- `TypesSheet` — equipment types side panel
- `PlacementHistorySheet` — item history side panel

### Unused Primitives

`Tabs` and `Sheet` components exist in `components/ui/` but aren't imported by any page. Wire them up during Layer 1 modal migration.

### Visual Hierarchy

Strategic use of `primary`/`accent` colors to create focal points — assigned users, active items, important data points. Most panels are monochrome gray which makes everything feel equally (un)important.

### Form Consistency

Spacing varies between forms — some use `space-y-3`, others `space-y-4`. No `FormSection` wrapper for grouping related fields. Standardize during Layer 1 form migration.

### Accessibility Pass

- Focus ring visibility on all interactive elements
- Keyboard navigation through modals and panels
- Color contrast verification (especially status badges on colored backgrounds)
- Touch target sizing for mobile (min 44x44px)

---

## Page-by-Page Status

### Clean (Layer 1 complete, no Layer 2 issues)

- `Login.tsx`
- `ForgotPassword.tsx`
- `ResetPassword.tsx`
- `AcceptInvitation.tsx`
- `Organizations/Index.tsx`, `Show.tsx`, `New.tsx`, `Edit.tsx`
- `Properties/Index.tsx`, `New.tsx`, `Show.tsx`, `Edit.tsx`
- `Users/Index.tsx`, `Show.tsx`
- `Settings/Profile.tsx`, `OnCall.tsx`
- `Incidents/New.tsx`, `Index.tsx`
- `Dashboard/Dashboard.tsx`
- `Incidents/components/EquipmentForm.tsx`, `LaborForm.tsx`, `NoteForm.tsx`, `ActivityForm.tsx`, `IncidentEditForm.tsx`
- `Incidents/components/MessagePanel.tsx`

### Layer 2 Only (Layer 1 complete, visual polish remaining)

| Page | Layer 2 Issues |
|------|---------------|
| `EquipmentItems/Index.tsx` | 719 lines — needs component extraction |
| `Incidents/components/OverviewPanel.tsx` | Monochrome — needs accent color |
| `Incidents/components/EquipmentPanel.tsx` | Monochrome, missing hover states |
| `Incidents/components/LaborPanel.tsx` | Monochrome, missing hover states |
| `Incidents/components/DailyLogPanel.tsx` | Monochrome — needs accent color |

### Minor

| Page | Issue |
|------|-------|
| `Invitations/Expired.tsx` | Barebones — no Card container, minimal styling |
