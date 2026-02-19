# UI Audit — February 19, 2026

> Page-by-page audit against the refreshed "warm & polished" design direction.
> Split into two categories: **Token fixes** (CSS-only, zero component changes) and **Structural fixes** (component/layout changes).

---

## Global Token Issues

These affect every page and are fixed by updating `application.css` only.

| Issue | Current | Target | Impact |
|-------|---------|--------|--------|
| Border radius too tight | `--radius: 0.25rem` (4px) | `--radius: 0.5rem` (8px) | Everything looks boxy — cards, buttons, inputs, badges |
| Background too cold | `hsl(210 12% 96.5%)` | `hsl(220 14% 96%)` | Clinical blue-gray feel |
| Borders too harsh | `hsl(210 10% 87%)` | `hsl(220 10% 90%)` | Borders draw too much attention |
| Muted text too cold | `hsl(210 5% 46%)` | `hsl(220 6% 44%)` | Secondary text feels detached |
| Foreground not warm | `hsl(210 10% 12%)` | `hsl(224 10% 14%)` | Primary text slightly cold |
| Sidebar is white | `hsl(0 0% 98%)` | `hsl(222 20% 16%)` dark | No visual anchor, sidebar blends with content |
| Primary slightly dull | `hsl(187 70% 34%)` | `hsl(187 65% 32%)` | Teal could be deeper/richer |
| Status quote purple | `hsl(270 50% 60%)` | `hsl(262 52% 57%)` | Slightly warmer purple |
| Status success green | `hsl(142 76% 36%)` | `hsl(152 60% 36%)` | Slightly warmer green |
| Destructive too hot | `hsl(0 84% 60%)` | `hsl(0 72% 51%)` | Red is too saturated, needs restraint |
| No shadow warmth | Default Tailwind shadows | Warm-tinted shadow color | Shadows feel default/generic |

**Effort: ~30 minutes.** Change CSS variables, refresh browser, done.

---

## Page-by-Page Findings

### Sidebar (`layout/RoleSidebar.tsx`)

**Token fixes:**
- Sidebar background/text colors change automatically via new sidebar tokens
- Active state color changes automatically

**Structural fixes:**
- Sidebar currently uses `bg-sidebar` token — will automatically pick up dark color
- Hover state needs update: `hover:bg-muted` → `hover:bg-sidebar-accent/50` (dark sidebar hover)
- Logo circle `bg-primary` will work on dark bg — may want white outline for contrast
- Logout text `text-muted-foreground` needs to become `text-sidebar-muted-foreground`
- User info section text colors need sidebar-specific tokens

**Risk: Low.** Class name changes only. Fully reversible.

### App Layout (`layout/AppLayout.tsx`)

**Token fixes:**
- `bg-background` picks up new warm tone automatically
- Mobile header `bg-background` picks up automatically

**Structural fixes:**
- Mobile header could use `bg-card border-b shadow-sm` for more presence (optional)

### Flash Messages (`layout/FlashMessages.tsx`)

**Token fixes:**
- Alert component uses shadcn defaults — picks up new radius automatically

**Structural fixes:**
- None needed. Already using shadcn `Alert` component.

### Login (`pages/Login.tsx`)

**Token fixes:**
- Card, inputs, buttons all pick up new radius and colors automatically
- `bg-background` picks up warm tone

**Structural fixes:**
- None needed. This is the most polished page already.

### Dashboard (`pages/Dashboard.tsx`)

**Token fixes:**
- Incident card dividers and borders pick up softer colors automatically
- Badge radius picks up automatically

**Structural fixes:**
- `statusColor()` function (line 48-66) uses hardcoded Tailwind colors (`bg-blue-500`, `bg-green-600`) instead of status tokens (`bg-status-info`, `bg-status-success`). Should use tokens so they're configurable.
- Incident group container `rounded border` → should use card treatment with shadow for depth
- Group header buttons could have slightly more visual weight

**Risk: Low.** Small class changes.

### Incidents Index (`pages/Incidents/Index.tsx`)

**Token fixes:**
- Table borders/backgrounds pick up new tokens automatically
- Badge radius picks up automatically

**Structural fixes:**
- `statusColor()` (line 73-91) same issue — uses tokens correctly here (`bg-status-info`), good
- `FilterSelect` (line 282-306) uses raw `<select>` with manual class strings. Should use shadcn `Select` when available.
- Table wrapper `rounded border` → could benefit from card treatment
- Emergency row highlight `bg-red-50` — hardcoded, should use a token or `bg-destructive/5`

**Risk: Low.** FilterSelect is the biggest change — could be deferred to Phase 6B.

### Incident Detail (`pages/Incidents/Show.tsx`)

**Token fixes:**
- Header borders, text colors pick up automatically
- Badge, buttons pick up new radius

**Structural fixes:**
- `statusColor()` (line 18-36) uses hardcoded colors (`bg-blue-500`, `bg-purple-500`, `bg-green-600`, `bg-amber-500`, `bg-gray-500`) instead of status tokens. **This is the #1 offender** — hardcoded colors won't respond to token changes.
- Status dropdown menu (line 145-157) manually styled — works fine structurally

**Risk: Low.** Just changing class names in the statusColor function.

### Incident Sub-panels

**RightPanelShell** (`components/RightPanelShell.tsx`)
- Tab bar uses hand-rolled `border-b-2` tabs. Functional, no token issues.
- Unread badge uses `bg-primary` — picks up token change automatically.

**MessagePanel**, **DailyLogPanel**, **EquipmentPanel**, **LaborPanel**, **DocumentPanel**
- These are complex panels — need individual audit but token changes will flow through automatically.
- Known: DailyLogPanel and LaborPanel use raw `<select>` for date pickers.

**OverviewPanel** (`components/OverviewPanel.tsx`)
- Team member lists, contact forms — mostly uses shadcn components.
- Some raw `<select>` for user assignment dropdowns.

**IncidentEditForm** (`components/IncidentEditForm.tsx`)
- Modal overlay — uses raw `<select>` and `<textarea>` with manual styling.

### New Incident (`pages/Incidents/New.tsx`)

**Token fixes:**
- Form card `bg-card border shadow-sm` picks up automatically
- Radio cards `border-primary bg-accent` pick up new tokens

**Structural fixes:**
- Raw `<select>` elements (lines 137, 154, 224) with long manual class strings
- Raw `<textarea>` elements (lines 241, 265, 279, 293) with long manual class strings
- These are the main form controls that need shadcn replacements (Phase 6B)

### Organizations Index (`pages/Organizations/Index.tsx`)

**Token fixes:**
- DataTable picks up border/hover changes automatically

**Structural fixes:**
- None. Clean page using DataTable properly.

### Organization Detail (`pages/Organizations/Show.tsx`)

**Token fixes:**
- DetailList border picks up softer color automatically

**Structural fixes:**
- Contact/address info section is bare text — could benefit from a Card wrapper
- DetailList/DetailRow are functional but visually minimal

### Properties Index (`pages/Properties/Index.tsx`)

**Token fixes:**
- Table borders/headers pick up automatically
- Sort buttons pick up new styles

**Structural fixes:**
- Custom table implementation (not using DataTable) — line 75-120
- Table wrapper `rounded border` → card treatment
- Works fine, just not using shared components

### Property Detail (`pages/Properties/Show.tsx`)

**Token fixes:**
- DetailList, StatusBadge pick up changes automatically

**Structural fixes:**
- Assign form uses raw `<select>` (line 104-113)
- Remove button uses raw `<button>` (line 128) instead of shadcn Button
- StatusBadge (line 145) renders as generic gray `bg-muted` — doesn't use status colors. Should map status labels to colors.

### Users Index (`pages/Users/Index.tsx`)

**Token fixes:**
- DataTable picks up changes automatically

**Structural fixes:**
- Invite form (line 93-138) uses raw `<select>` elements (lines 103, 113)
- Active users grouping uses `reduce()` on frontend (line 172-178) — should come pre-grouped from server per CODE_QUALITY.md

### User Detail (`pages/Users/Show.tsx`)

**Token fixes:**
- DetailList picks up changes automatically

**Structural fixes:**
- Deactivated badge (line 65) uses `bg-destructive/10` — may need adjustment
- StatusBadge on incidents shows generic gray, not status-colored

### Settings Profile (`pages/Settings/Profile.tsx`)

**Token fixes:**
- Form inputs, buttons, checkboxes pick up new styles

**Structural fixes:**
- Timezone uses raw `<select>` (line 69-78)
- Sections are bare `<section>` with `<h2>` headers — could be wrapped in Cards for visual grouping
- Notification preferences form is clean (uses Checkbox component)

### Settings On-Call (`pages/Settings/OnCall.tsx`)

**Token fixes:**
- Inputs, buttons pick up new styles

**Structural fixes:**
- No `PageHeader` component (line 96 uses raw `<h1>`)
- Raw `<select>` elements (lines 107, 202)
- Escalation contacts list has no card wrapper — just floating items
- Overall the page feels unfinished — no card surfaces, no section grouping
- **This is the ugliest page in the app** — highest priority for Phase 6B

### Settings Equipment Types (`pages/Settings/EquipmentTypes.tsx`)

- Not read in this audit. Should be checked separately.

### Auth Pages (`pages/Auth/ForgotPassword.tsx`, `pages/Auth/ResetPassword.tsx`)

**Token fixes:**
- Card, inputs, buttons pick up new tokens automatically

**Structural fixes:**
- None needed. Similar structure to Login page.

### Invitation Pages (`pages/Invitations/Accept.tsx`, `pages/Invitations/Expired.tsx`)

- Not read in this audit. Should be checked separately.

---

## Shared Components

### DataTable (`components/DataTable.tsx`)

**Token fixes:**
- `rounded-md` → will become `rounded-lg` with new radius token (via shadcn, if it uses the token)
- Wait — DataTable uses hardcoded `rounded-md` (line 22). This needs to change to `rounded-lg` to match card radius.
- `bg-muted/50` header picks up new muted color

**Structural fixes:**
- No shadow on the table wrapper. Should add `shadow-sm` for card depth.
- Empty state is bare `<p>` text (line 18) — should use card-based empty state.

### DetailList (`components/DetailList.tsx`)

**Token fixes:**
- `rounded-md` → should be `rounded-lg` to match card radius
- Border picks up softer color

**Structural fixes:**
- No shadow. Should add `shadow-sm`.
- Empty state is bare `<p>` text — should use card treatment.

### StatusBadge (`components/StatusBadge.tsx`)

**Token + Structural fixes:**
- Renders as generic gray (`bg-muted text-muted-foreground`) for all statuses
- Should accept a `status` prop and map to status color tokens
- Currently useless as a design element — every badge looks the same

### PageHeader (`components/PageHeader.tsx`)

**Token fixes:**
- `font-semibold` → should be `font-bold` per new type scale

**Structural fixes:**
- None. Clean and functional.

### FormField (`components/FormField.tsx`)

**Token fixes:**
- Uses shadcn Input/Label — picks up changes automatically

**Structural fixes:**
- None needed.

---

## Priority Summary

### Phase 6A (Token refresh — CSS only)

1. Update `application.css` with new color tokens, radius, shadows
2. Fix sidebar colors in `RoleSidebar.tsx` (class names for dark sidebar)
3. Fix `statusColor()` in `Show.tsx` and `Dashboard.tsx` to use status tokens
4. Update `DataTable` and `DetailList` radius from `rounded-md` to `rounded-lg`
5. Update `PageHeader` font weight to `font-bold`

### Phase 6B (Structural polish — component changes)

Ordered by visual impact:

1. On-call settings page redesign (ugliest page)
2. Replace raw `<select>` with shadcn Select (12+ instances across app)
3. Replace raw `<textarea>` with shadcn Textarea (4+ instances in New Incident)
4. Add `shadow-sm` to DataTable and DetailList wrappers
5. StatusBadge: add status-aware color mapping
6. Settings Profile: wrap sections in Cards
7. Card-based empty states (DataTable, DetailList)
8. Centralize `statusColor()` into shared utility
9. Accessibility pass: focus states, contrast, touch targets

---

## Files Modified by Token Refresh (Phase 6A)

| File | Change |
|------|--------|
| `app/frontend/entrypoints/application.css` | All color tokens, radius, shadow color |
| `app/frontend/layout/RoleSidebar.tsx` | Sidebar class names for dark theme |
| `app/frontend/layout/AppLayout.tsx` | Sidebar `bg-sidebar` classes (minor) |
| `app/frontend/pages/Dashboard.tsx` | `statusColor()` → use tokens |
| `app/frontend/pages/Incidents/Show.tsx` | `statusColor()` → use tokens |
| `app/frontend/components/DataTable.tsx` | `rounded-md` → `rounded-lg`, add `shadow-sm` |
| `app/frontend/components/DetailList.tsx` | `rounded-md` → `rounded-lg`, add `shadow-sm` |
| `app/frontend/components/PageHeader.tsx` | `font-semibold` → `font-bold` |
