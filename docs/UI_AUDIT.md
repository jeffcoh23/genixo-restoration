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

## Layer 2: Brand & Visual Polish — MOSTLY COMPLETE

### Monochrome Panels — DONE

- `DailyLogPanel` — date headers now use `bg-accent/30`, group footers use `bg-muted/70` with thicker border, all rows have hover
- `EquipmentPanel` — rows have `hover:bg-muted/30 transition-colors`
- `LaborPanel` — rows have `hover:bg-muted/30 transition-colors`
- `OverviewPanel` — acceptable as-is (different layout pattern, not a data table)

### Table Hover States — DONE

`EquipmentPanel` and `LaborPanel` now have `hover:bg-muted/30 transition-colors` on all rows. `DailyLogPanel` activity rows also have hover.

### Table Padding — DONE

`EquipmentPanel`, `LaborPanel`, and `DailyLogPanel` all updated from `px-3 py-2` to `px-4 py-3` per DESIGN.md.

### Flash Messages — DONE

Rewritten from inline Alert to fixed-position overlay with icon, colored left border, close button, shadow elevation.

### StatusBadge — DONE

Now uses `statusColor()` + shadcn `Badge` instead of gray chips. Users/Show and Properties/Show display colored status badges.

### Remaining (deferred)

| Item | Status | Rationale |
|------|--------|-----------|
| Tables wrapped in Card | Deferred | Working fine without Card wrapper, low visual impact |
| `EquipmentItems/Index.tsx` extraction | Deferred | 719 lines but functional, low-traffic page |
| Form spacing standardization | Deferred | Minor inconsistency, all forms work correctly |
| Accessibility pass | TODO | On ROADMAP as separate line item |

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

### Layer 2 Complete

- `Incidents/components/EquipmentPanel.tsx` — hover states + padding
- `Incidents/components/LaborPanel.tsx` — hover states + padding
- `Incidents/components/DailyLogPanel.tsx` — accent headers, hover, padding, spacing

### Deferred (functional, low priority)

| Page | Issue |
|------|-------|
| `EquipmentItems/Index.tsx` | 719 lines — component extraction deferred |
| `Incidents/components/OverviewPanel.tsx` | Monochrome — acceptable for non-table layout |

### Minor

| Page | Issue |
|------|-------|
| `Invitations/Expired.tsx` | Barebones — no Card container, minimal styling |
