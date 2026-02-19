# Genixo Restoration Manager — Design System

> Visual language for the entire application. Every UI decision should trace back to this document.

---

## Brand Identity

**Name:** Genixo Restoration Manager (keep configurable, not hardcoded)
**One-liner:** Incident management for property restoration teams
**Direction:** Warm & polished — a premium SaaS tool that feels intentionally designed but never draws attention away from the data. Think Linear, Raycast, Height.

**Target users:**
- Mitigation managers/techs — blue-collar, on job sites, phones, varying tech comfort
- Property managers — office-based, desktop, moderately tech-savvy

**Design principles:**
1. **Information first** — the UI should disappear. Every element earns its space.
2. **Warm, not cold** — subtle warmth in neutrals, shadows, and backgrounds. Never clinical.
3. **Depth creates hierarchy** — shadows and surfaces do the work so you need less decoration.
4. **Token-driven** — change the CSS variables, change the whole app. No hardcoded colors in components.

---

## Surface & Depth System

Surfaces create hierarchy. Shadows have a warm tint.

```
┌─ Page Background ─────────────────────────────┐
│  Warm off-white (hsl 220 14% 96%)             │
│                                                │
│  ┌─ Card Surface ──────────────────────┐       │
│  │  White + soft border + warm shadow  │       │
│  │                                     │       │
│  │  ┌─ Inset Surface ─────────────┐   │       │
│  │  │  Warm muted bg (headers,    │   │       │
│  │  │  code blocks, grouped rows) │   │       │
│  │  └─────────────────────────────┘   │       │
│  │                                     │       │
│  └─────────────────────────────────────┘       │
│                                                │
│  ┌─ Elevated Surface ──────────────────┐       │
│  │  White + border + deeper shadow     │       │
│  │  (dropdowns, modals, popovers)      │       │
│  └─────────────────────────────────────┘       │
└────────────────────────────────────────────────┘
```

| Layer | Background | Border | Shadow | Usage |
|-------|-----------|--------|--------|-------|
| Page | `bg-background` | — | — | Page canvas behind everything |
| Card | `bg-card` | `border border-border` | `shadow-sm` | Content containers, panels, sections |
| Inset | `bg-muted` | — | — | Table headers, grouped rows, code blocks |
| Elevated | `bg-popover` | `border border-border` | `shadow-md` | Dropdowns, popovers, modals |

**Key rules:**
- White cards on a warm-tinted background create natural grouping without decoration
- Shadows use a warm undertone (not pure black — see Shadow section)
- Every content group should be in a card

---

## Color Palette

Built from the Genixo brand teal. Neutrals carry a warm undertone — not cold blue-gray.

### Primary
| Token | Value | Usage |
|-------|-------|-------|
| `primary` | `hsl(187 65% 32%)` | Main CTAs, active states, nav highlights, links |
| `primary-foreground` | `hsl(0 0% 100%)` | Text on primary surfaces |

### Neutrals (warm-tinted)
| Token | Value | Usage |
|-------|-------|-------|
| `background` | `hsl(220 14% 96%)` | Page canvas — warm off-white that makes cards pop |
| `foreground` | `hsl(224 10% 14%)` | Primary text — near-black with warmth |
| `card` | `hsl(0 0% 100%)` | Card/panel backgrounds — pure white |
| `card-foreground` | `hsl(224 10% 14%)` | Text on cards |
| `popover` | `hsl(0 0% 100%)` | Dropdown/modal backgrounds |
| `popover-foreground` | `hsl(224 10% 14%)` | Text on popovers |
| `muted` | `hsl(220 12% 93.5%)` | Inset surfaces — table headers, alternating rows |
| `muted-foreground` | `hsl(220 6% 44%)` | Secondary text, labels, timestamps |
| `border` | `hsl(220 10% 90%)` | All borders — soft, visible but not heavy |
| `input` | `hsl(220 10% 88%)` | Input field borders — slightly more visible than card borders |
| `ring` | `hsl(187 65% 32%)` | Focus ring color |

### Accent
| Token | Value | Usage |
|-------|-------|-------|
| `accent` | `hsl(187 12% 93%)` | Hover backgrounds, selected states, active nav items |
| `accent-foreground` | `hsl(187 65% 24%)` | Text on accent backgrounds |

### Semantic
| Token | Value | Usage |
|-------|-------|-------|
| `destructive` | `hsl(0 72% 51%)` | Delete actions, emergency states |
| `destructive-foreground` | `hsl(0 0% 100%)` | Text on destructive |

### Status Colors
| Status | Color | Token |
|--------|-------|-------|
| `new` / `acknowledged` | Blue `hsl(199 89% 48%)` | `status-info` |
| `proposal_*` / `proposal_signed` | Purple `hsl(262 52% 57%)` | `status-quote` |
| `active` | Green `hsl(152 60% 36%)` | `status-success` |
| `on_hold` | Amber `hsl(38 92% 50%)` | `status-warning` |
| `completed` | Muted green `hsl(152 36% 48%)` | `status-completed` |
| `completed_billed` / `paid` / `closed` | Gray `hsl(220 6% 55%)` | `status-neutral` |
| Emergency | Red `hsl(0 72% 51%)` | `status-emergency` |

### Sidebar
| Token | Value | Usage |
|-------|-------|-------|
| `sidebar` | `hsl(222 20% 16%)` | Dark sidebar background — strong left edge |
| `sidebar-foreground` | `hsl(220 10% 85%)` | Primary sidebar text |
| `sidebar-border` | `hsl(222 15% 22%)` | Sidebar internal borders |
| `sidebar-accent` | `hsl(222 15% 22%)` | Active nav item background |
| `sidebar-accent-foreground` | `hsl(0 0% 100%)` | Active nav item text |
| `sidebar-muted-foreground` | `hsl(220 8% 58%)` | Secondary sidebar text |

### Mode
Light mode only. No dark mode for MVP. The dark sidebar provides visual anchoring without needing a full dark mode.

---

## Typography

### Font Stack
- **All UI text:** Inter (Google Fonts) — clean, legible, built for interfaces
- **Monospace:** JetBrains Mono — for IDs, codes, timestamps where monospace helps
- **Fallback:** System sans-serif stack

### Type Scale
| Element | Tailwind | Weight | Usage |
|---------|----------|--------|-------|
| Page title | `text-2xl` (24px) | `font-bold` | One per page, top of content |
| Section title | `text-lg` (18px) | `font-semibold` | Card headers, major sections |
| Subsection | `text-base` (16px) | `font-medium` | Sub-headers within cards |
| Body | `text-sm` (14px) | `font-normal` | Default text, descriptions, form values |
| Label | `text-xs` (12px) | `font-semibold uppercase tracking-wide` | Section labels, column headers |
| Caption | `text-xs` (12px) | `font-normal` | Timestamps, metadata, help text |

**Rules:**
- No type smaller than 12px — users have varying vision
- `text-sm` (14px) is the default body size — this is an information-dense work tool
- Use weight and color for hierarchy, not just size
- `text-muted-foreground` for all secondary/supporting text
- Page titles use `font-bold` (was `font-semibold`) for more presence

---

## Borders & Corners

| Element | Radius | Border |
|---------|--------|--------|
| Cards, containers | `rounded-lg` (8px) | `border border-border` |
| Buttons, inputs | `rounded-md` (6px) | per shadcn |
| Badges | `rounded-md` (6px) | per shadcn |
| Avatars | `rounded-full` | — |
| Modals, sheets | `rounded-lg` (8px) | `border border-border` |
| Dropdowns, popovers | `rounded-md` (6px) | `border border-border` |

**`--radius: 0.5rem`** (8px base). This drives all shadcn component radii. The previous 0.25rem (4px) was too tight and made everything feel boxy.

---

## Shadows

Shadows use a warm-tinted color, not pure black. This is what makes shadows feel "premium" vs "default".

| Level | Class | Usage |
|-------|-------|-------|
| Rest | `shadow-sm` | Cards, panels — default state |
| Elevated | `shadow-md` | Dropdowns, popovers, modals |
| None | — | Inset surfaces, table headers, inline elements |

**Shadow color override in CSS:**
```css
--shadow-color: 220 14% 60%;
```

Tailwind v4 shadow utilities will use this warm tone instead of pure black.

**Rule:** Shadow always pairs with a border. Never shadow without border.

---

## Component Recipes

Use shadcn/ui components wherever possible. Only reach for raw Tailwind classes on structural containers where no shadcn primitive exists.

**Available shadcn components:** `Button`, `Input`, `Badge`, `Card` (`CardHeader`, `CardTitle`, `CardContent`, `CardFooter`), `Label`, `Alert`, `Checkbox`.

**Needed (install via shadcn CLI):** `Select`, `Textarea`, `Tabs`, `Dialog`/`Sheet`, `Popover`, `Tooltip`.

### Card
The primary container for all content groups. Use the shadcn `Card` component.

```tsx
<Card>
  <CardContent className="p-5">
    {/* card content */}
  </CardContent>
</Card>
```

**Card with header:**
```tsx
<Card>
  <CardHeader className="border-b border-border bg-muted/50 px-5 py-3">
    <CardTitle className="text-sm font-semibold">Section Title</CardTitle>
  </CardHeader>
  <CardContent className="p-5">
    {/* card content */}
  </CardContent>
</Card>
```

**Card with footer:**
```tsx
<Card>
  <CardContent className="p-5">
    {/* card content */}
  </CardContent>
  <CardFooter className="border-t border-border bg-muted/30 px-5 py-3">
    {/* actions, pagination */}
  </CardFooter>
</Card>
```

### Table
Always wrapped in a Card container.

```tsx
<Card className="overflow-hidden">
  <table className="w-full text-sm">
    <thead>
      <tr className="border-b border-border bg-muted/50">
        <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">
          Column
        </th>
      </tr>
    </thead>
    <tbody className="divide-y divide-border">
      <tr className="hover:bg-muted/30 transition-colors">
        <td className="px-4 py-3">Value</td>
      </tr>
    </tbody>
  </table>
</Card>
```

**Rules:**
- Header row: `bg-muted/50` with uppercase labels
- Body rows: `divide-y divide-border` for separators
- Hover: `hover:bg-muted/30 transition-colors` on interactive rows
- Clickable rows: add `cursor-pointer` and make entire row a link

### Stat Card
For displaying key metrics.

```tsx
<Card className="p-4">
  <div className="text-xs font-medium text-muted-foreground">Label</div>
  <div className="text-2xl font-bold text-foreground mt-1">42</div>
  <div className="text-xs text-muted-foreground mt-0.5">Supporting detail</div>
</Card>
```

### Key-Value Display
For detail views (incident details, property info).

```tsx
<div className="space-y-3">
  <div>
    <dt className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-1">Label</dt>
    <dd className="text-sm text-foreground">Value goes here</dd>
  </div>
</div>
```

### List Items
For lists within cards (assigned users, contacts, etc.).

```tsx
<div className="divide-y divide-border">
  <div className="flex items-center gap-3 px-4 py-2.5 hover:bg-muted/30 transition-colors">
    {/* item content */}
  </div>
</div>
```

### Empty State
Always within a card, always explains what goes here.

```tsx
<Card className="p-8 text-center">
  <Icon className="h-8 w-8 text-muted-foreground mx-auto mb-3" />
  <p className="text-sm font-medium text-foreground">No items yet</p>
  <p className="text-xs text-muted-foreground mt-1">
    Description of what will appear here and how to add the first one.
  </p>
  <Button className="mt-4" size="sm">Add First Item</Button>
</Card>
```

---

## Interactive States

Every clickable element must have visible feedback.

| State | Pattern | Usage |
|-------|---------|-------|
| Hover (surface) | `hover:bg-muted/30 transition-colors` | Table rows, list items, clickable cards |
| Hover (text) | `hover:text-foreground` | Muted text links, secondary actions |
| Hover (button) | shadcn defaults | Primary/secondary/ghost buttons |
| Focus | `focus-visible:ring-2 focus-visible:ring-ring` | All interactive elements |
| Active/Selected | `bg-accent text-accent-foreground` | Active nav items, selected tabs |
| Disabled | `opacity-50 cursor-not-allowed` | Disabled buttons, locked fields |
| Danger hover | `hover:text-destructive` | Remove buttons, delete actions |

**Transitions:** Always `transition-colors` on hover backgrounds. Duration is Tailwind default (150ms).

---

## Spacing System

Consistent spacing creates visual rhythm.

| Context | Padding | Gap |
|---------|---------|-----|
| Card internal | `p-5` | — |
| Card header/footer | `px-5 py-3` | — |
| Table cells | `px-4 py-3` | — |
| Page sections | — | `space-y-6` between cards |
| Within a card | — | `space-y-4` between sections |
| Form fields | — | `space-y-3` between fields |
| Inline items | — | `gap-3` or `gap-4` |
| Compact lists | — | `space-y-1` or `divide-y` |

**Page structure:**
```html
<div class="space-y-6">
  <!-- Page title -->
  <div>
    <h1 class="text-2xl font-bold">Page Title</h1>
    <p class="text-sm text-muted-foreground mt-1">Optional subtitle</p>
  </div>

  <!-- Content cards -->
  <Card>
    ...
  </Card>
</div>
```

---

## Layout

**Max content width:** `max-w-5xl` (64rem / 1024px) for default, `max-w-7xl` for wide pages (index/list pages)
**Sidebar:** Fixed left, dark background, collapsible on mobile
**Page padding:** `px-4 py-6 sm:px-6`

### Responsive Breakpoints
| Breakpoint | Target |
|-----------|--------|
| Default (< 640px) | Phone — single column, stacked |
| `sm` (640px) | Large phone / small tablet |
| `md` (768px) | Tablet — two columns where appropriate |
| `lg` (1024px) | Desktop — full sidebar + content |

### Split Panel Pages
For detail views (incidents, properties) with main content + sidebar:
```html
<div class="flex flex-col lg:flex-row gap-6">
  <div class="order-2 lg:order-1 lg:w-[65%]">Main content</div>
  <div class="order-1 lg:order-2 lg:w-[35%]">Sidebar</div>
</div>
```
On mobile: sidebar stacks first (order-1), main below (order-2).
On desktop: main is left (order-1), sidebar is right (order-2).

---

## Buttons

| Variant | Usage | Classes |
|---------|-------|---------|
| Primary | Main CTAs (Save, Create, Assign) | shadcn `default` — teal bg, white text |
| Secondary | Cancel, Back, secondary actions | shadcn `outline` — white bg, border, dark text |
| Ghost | Tertiary actions, icon buttons | shadcn `ghost` — no border, no bg |
| Destructive | Remove, delete, unassign | shadcn `destructive` — red bg, white text |

**Size:** Default `size="default"` for main actions. `size="sm"` for inline/compact actions.
**Minimum touch target:** 44px height on mobile.

---

## Forms

- Use shadcn `Label`, `Input`, `Textarea`, `Select`, `Checkbox` components — never raw HTML controls with manual class strings
- Labels above inputs, never floating or inline
- Required fields: append ` *` to label text
- Validation errors: red text below the field, `text-destructive text-xs mt-1`
- Inputs: minimum 44px height for touch
- Group related fields in a Card with a header
- Use Inertia `useForm()` for all form state — `post(url)` / `patch(url)` with `processing`, `errors`, `setData`

```tsx
<Card className="overflow-hidden">
  <CardHeader className="border-b border-border bg-muted/50 px-5 py-3">
    <CardTitle className="text-sm font-semibold">Section</CardTitle>
  </CardHeader>
  <CardContent className="p-5 space-y-3">
    <div>
      <Label>Field Label *</Label>
      <Input className="mt-1.5" value={data.field} onChange={(e) => setData("field", e.target.value)} />
      {errors.field && <p className="text-destructive text-xs mt-1">{errors.field}</p>}
    </div>
  </CardContent>
</Card>
```

### Form Tiers

Three form patterns. Choose based on complexity — never mix patterns for the same tier.

**Tier 1: Inline Form** — 1-2 fields, stays on the page.
Use for: adding an equipment type, adding a contact, quick settings toggles.

```
┌─ Card ─────────────────────────────────────────┐
│  [Input field...............] [+ Add]           │
│                                                 │
│  Existing Item 1                     [Actions]  │
│  Existing Item 2                     [Actions]  │
└─────────────────────────────────────────────────┘
```

**Tier 2: Sheet/Modal** — 3-8 fields, contextual to current page.
Use for: placing equipment, logging labor, uploading attachments, editing a record.

```
┌─ Modal ──────────────────────────────── [✕] ─┐
│  Title                                        │
│                                               │
│  [Field 1                              ]      │
│  [Field 2          ] [Field 3          ]      │
│  [Field 4                              ]      │
│                                               │
│                        [Cancel]  [Save]       │
└───────────────────────────────────────────────┘
```

**Tier 3: Full Page** — 8+ fields, multi-section, or requires context not on current page.
Use for: creating an incident, creating a property, editing profile.

```
┌─ PageHeader ─────────────────────────────────┐
│  Create New Incident                         │
└──────────────────────────────────────────────┘

┌─ Card: Section 1 ───────────────────────────┐
│  [Fields...]                                 │
└──────────────────────────────────────────────┘

┌─ Card: Section 2 ───────────────────────────┐
│  [Fields...]                                 │
└──────────────────────────────────────────────┘

                              [Cancel]  [Submit]
```

### Form Action Buttons (Openers)

| Location | Button Style | Example |
|----------|-------------|---------|
| Card toolbar bar | Ghost `size="sm"` with icon | `+ Add Equipment` |
| Table row action | Ghost `size="sm"` icon-only | Pencil icon, Trash icon |
| Page header | Primary or outline `size="default"` | `Create Request` |
| Empty state | Primary `size="sm"` centered | `Add First Item` |

---

## Status Badges

Small rounded chips: colored background + text. Always show text label (accessibility).

```html
<Badge class="bg-status-info text-white text-xs">New</Badge>
<Badge class="bg-destructive text-white text-xs">
  <AlertTriangle class="h-3 w-3 mr-1" />
  Emergency
</Badge>
```

Emergency badge always appears first/leftmost.

---

## Navigation (Sidebar)

**Dark sidebar** — creates a strong visual anchor on the left edge. The contrast with the light content area gives the app structure.

- Dark background (`bg-sidebar`)
- Light text (`text-sidebar-foreground`)
- Logo at top
- Role-aware links (different items per user_type)
- Active state: `bg-sidebar-accent text-sidebar-accent-foreground`
- Hover: `hover:bg-sidebar-accent/50`
- Unread indicators: small dot badge on relevant links
- Mobile: hamburger menu, slide-in drawer
- User info at bottom: name, org, role, logout

---

## Tone & Voice

**Style:** Plain language, direct, no jargon. Write for someone who doesn't use software all day.

**Do:**
- Short, clear labels ("Add Equipment", not "Register New Equipment Entry")
- Verbs for buttons ("Save", "Assign", "Mark Active")
- Show confirmation after actions ("Technician assigned to incident")
- Real words ("3 hours ago", not timestamps)

**Don't:**
- Technical terms in UI ("polymorphic", "webhook", "dispatch")
- Passive voice ("The incident was created" → "You created this incident")
- Corporate language ("Please be advised..." → just state the thing)

**Error messages:** Friendly and actionable. Say what went wrong and what to do.
- Good: "Couldn't save — duration must be at least 1 minute."
- Bad: "Validation failed: duration_minutes must be greater than 0"

**Empty states:** Always explain what goes here and how to add the first item.

---

## Accessibility

**Target:** WCAG AA

- All interactive elements keyboard-navigable
- Color is never the only indicator (badges always include text)
- Minimum contrast ratio 4.5:1 for text
- Focus rings visible on all interactive elements (`focus-visible:ring-2`)
- Form inputs have associated labels (not placeholder-only)
- Touch targets minimum 44x44px on mobile
- No type smaller than 12px
