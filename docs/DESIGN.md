# Genixo Restoration Manager — Design System

> Visual language for the entire application. Every UI decision should trace back to this document.

---

## Brand Identity

**Name:** Genixo Restoration Manager (keep configurable, not hardcoded)
**One-liner:** Incident management for property restoration teams
**Feeling:** Clean, structured, trustworthy. A well-organized tool that respects the user's time. Information-dense but never cluttered — everything earns its space.

**Target users:**
- Mitigation managers/techs — blue-collar, on job sites, phones, varying tech comfort
- Property managers — office-based, desktop, moderately tech-savvy

**Design reference:** Linear, Notion, Height — modern work tools where surfaces create hierarchy, white cards float on tinted backgrounds, and every element has clear purpose.

---

## Surface & Depth System

This is the foundation of the visual language. Surfaces create hierarchy.

```
┌─ Page Background ─────────────────────────────┐
│  Cool-tinted gray (hsl 210 12% 96.5%)         │
│                                                │
│  ┌─ Card Surface ──────────────────────┐       │
│  │  Pure white + border + shadow-sm    │       │
│  │                                     │       │
│  │  ┌─ Inset Surface ─────────────┐   │       │
│  │  │  Muted bg (table headers,   │   │       │
│  │  │  code blocks, grouped rows) │   │       │
│  │  └─────────────────────────────┘   │       │
│  │                                     │       │
│  └─────────────────────────────────────┘       │
│                                                │
│  ┌─ Elevated Surface ──────────────────┐       │
│  │  White + border + shadow-md         │       │
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

**Key rule:** White cards on a tinted background create natural visual grouping without needing extra decoration. Every content group should be in a card.

---

## Color Palette

Built from the Genixo brand teal. Neutrals carry a cool blue undertone that harmonizes with the primary.

### Primary
| Token | Value | Usage |
|-------|-------|-------|
| `primary` | `hsl(187 70% 34%)` | Main CTAs, active states, nav highlights, links |
| `primary-foreground` | `hsl(0 0% 100%)` | Text on primary surfaces |

### Neutrals (cool-tinted)
| Token | Value | Usage |
|-------|-------|-------|
| `background` | `hsl(210 12% 96.5%)` | Page canvas — the tinted gray that makes cards pop |
| `foreground` | `hsl(210 10% 12%)` | Primary text — near-black with slight warmth |
| `card` | `hsl(0 0% 100%)` | Card/panel backgrounds — pure white |
| `card-foreground` | `hsl(210 10% 12%)` | Text on cards |
| `muted` | `hsl(210 8% 93%)` | Inset surfaces — table headers, alternating rows |
| `muted-foreground` | `hsl(210 5% 46%)` | Secondary text, labels, timestamps |
| `border` | `hsl(210 10% 87%)` | All borders and dividers — visible but not heavy |
| `input` | `hsl(210 10% 87%)` | Input field borders |
| `ring` | `hsl(187 70% 34%)` | Focus ring color |

### Accent
| Token | Value | Usage |
|-------|-------|-------|
| `accent` | `hsl(187 15% 93%)` | Hover backgrounds, selected states, active nav items |
| `accent-foreground` | `hsl(187 70% 25%)` | Text on accent backgrounds |

### Semantic
| Token | Value | Usage |
|-------|-------|-------|
| `destructive` | `hsl(0 84% 60%)` | Delete actions, emergency states |
| `destructive-foreground` | `hsl(0 0% 100%)` | Text on destructive |

### Status Colors
| Status | Color | Token |
|--------|-------|-------|
| `new` / `acknowledged` | Blue `hsl(199 89% 48%)` | `status-info` |
| `quote_requested` | Purple `hsl(270 50% 60%)` | `status-quote` |
| `active` | Green `hsl(142 76% 36%)` | `status-success` |
| `on_hold` | Amber `hsl(38 92% 50%)` | `status-warning` |
| `completed` | Muted green `hsl(142 40% 50%)` | `status-completed` |
| `completed_billed` / `paid` / `closed` | Gray `hsl(0 0% 55%)` | `status-neutral` |
| Emergency | Red `hsl(0 84% 60%)` | `status-emergency` |

### Mode
Light mode only. No dark mode for MVP.

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
- `text-sm` (14px) is the default body size, not `text-base` (16px) — this is an information-dense work tool
- Use weight and color for hierarchy, not just size. A bold 14px label reads stronger than a regular 16px body
- `text-muted-foreground` for all secondary/supporting text

---

## Component Recipes

Specific class combinations to use. Copy-paste these, don't reinvent.

### Card
The primary container for all content groups.

```html
<div class="rounded border border-border bg-card shadow-sm">
  <div class="p-5">
    <!-- card content -->
  </div>
</div>
```

**Card with header:**
```html
<div class="rounded border border-border bg-card shadow-sm overflow-hidden">
  <div class="border-b border-border bg-muted/50 px-5 py-3">
    <h2 class="text-sm font-semibold">Section Title</h2>
  </div>
  <div class="p-5">
    <!-- card content -->
  </div>
</div>
```

**Card with footer:**
```html
<div class="rounded border border-border bg-card shadow-sm overflow-hidden">
  <div class="p-5">
    <!-- card content -->
  </div>
  <div class="border-t border-border bg-muted/30 px-5 py-3">
    <!-- actions, pagination -->
  </div>
</div>
```

### Table
Always wrapped in a card container.

```html
<div class="rounded border border-border bg-card shadow-sm overflow-hidden">
  <table class="w-full text-sm">
    <thead>
      <tr class="border-b border-border bg-muted/50">
        <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">
          Column
        </th>
      </tr>
    </thead>
    <tbody class="divide-y divide-border">
      <tr class="hover:bg-muted/30 transition-colors">
        <td class="px-4 py-3">Value</td>
      </tr>
    </tbody>
  </table>
</div>
```

**Rules:**
- Header row: `bg-muted/50` with uppercase labels
- Body rows: `divide-y divide-border` for separators
- Hover: `hover:bg-muted/30 transition-colors` on interactive rows
- Clickable rows: add `cursor-pointer` and make entire row a link
- Emergency rows: `bg-red-50` background override

### Stat Card
For displaying key metrics.

```html
<div class="rounded border border-border bg-card shadow-sm p-4">
  <div class="text-xs font-medium text-muted-foreground">Label</div>
  <div class="text-2xl font-bold text-foreground mt-1">42</div>
  <div class="text-xs text-muted-foreground mt-0.5">Supporting detail</div>
</div>
```

**Stat row (inline):**
```html
<div class="flex gap-4">
  <div class="rounded border border-border bg-card shadow-sm px-4 py-3 flex items-center gap-3">
    <Icon class="h-5 w-5 text-muted-foreground" />
    <div>
      <div class="text-lg font-semibold">12.5h</div>
      <div class="text-xs text-muted-foreground">hours logged</div>
    </div>
  </div>
  <!-- more stats -->
</div>
```

### Key-Value Display
For detail views (incident details, property info).

```html
<div class="space-y-3">
  <div>
    <dt class="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-1">Label</dt>
    <dd class="text-sm text-foreground">Value goes here</dd>
  </div>
</div>
```

### List Items
For lists within cards (assigned users, contacts, etc.).

```html
<div class="divide-y divide-border">
  <div class="flex items-center gap-3 px-4 py-2.5 hover:bg-muted/30 transition-colors">
    <!-- item content -->
  </div>
</div>
```

### Empty State
Always within a card, always explains what goes here.

```html
<div class="rounded border border-border bg-card shadow-sm p-8 text-center">
  <Icon class="h-8 w-8 text-muted-foreground mx-auto mb-3" />
  <p class="text-sm font-medium text-foreground">No items yet</p>
  <p class="text-xs text-muted-foreground mt-1">
    Description of what will appear here and how to add the first one.
  </p>
  <Button class="mt-4" size="sm">Add First Item</Button>
</div>
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

## Borders & Corners

| Element | Radius | Border |
|---------|--------|--------|
| Cards, containers | `rounded` (4px) | `border border-border` |
| Buttons, inputs | `rounded` (4px) | per shadcn |
| Badges | `rounded` (4px) | per shadcn |
| Avatars | `rounded-full` | — |
| Dropdowns, popovers | `rounded` (4px) | `border border-border` |

**Sharp, not rounded.** `4px` radius everywhere. No `rounded-lg` or `rounded-xl`. This is a work tool.

---

## Shadows

| Level | Class | Usage |
|-------|-------|-------|
| Rest | `shadow-sm` | Cards, panels — default state |
| Elevated | `shadow-md` | Dropdowns, popovers, modals |
| None | — | Inset surfaces, table headers, inline elements |

**Rule:** Shadow always pairs with a border. Never shadow without border.

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
  <div class="rounded border border-border bg-card shadow-sm p-5">
    ...
  </div>
</div>
```

---

## Layout

**Max content width:** `max-w-5xl` (64rem / 1024px) for main content
**Sidebar:** Fixed left, `bg-sidebar`, collapsible on mobile
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

- Labels above inputs, never floating or inline
- Required fields: append ` *` to label text
- Validation errors: red text below the field, `text-destructive text-xs mt-1`
- Inputs: minimum 44px height for touch
- Group related fields in a card with a header

```html
<div class="rounded border border-border bg-card shadow-sm overflow-hidden">
  <div class="border-b border-border bg-muted/50 px-5 py-3">
    <h2 class="text-sm font-semibold">Section</h2>
  </div>
  <div class="p-5 space-y-3">
    <div>
      <label class="text-sm font-medium mb-1.5 block">Field Label *</label>
      <Input ... />
      {error && <p class="text-destructive text-xs mt-1">{error}</p>}
    </div>
  </div>
</div>
```

---

## Status Badges

Small rounded chips: colored background + text. Always show text label (accessibility).

```html
<Badge class="bg-blue-500 text-white text-xs">New</Badge>
<Badge class="bg-destructive text-white text-xs">
  <AlertTriangle class="h-3 w-3 mr-1" />
  Emergency
</Badge>
```

Emergency badge always appears first/leftmost.

---

## Navigation (Sidebar)

- Logo at top
- Role-aware links (different items per user_type)
- Active state: `bg-accent text-accent-foreground` with left border accent
- Hover: `hover:bg-muted/50`
- Unread indicators: small dot badge on relevant links
- Mobile: hamburger menu, slide-in drawer

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
