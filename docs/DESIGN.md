# Genixo Restoration Manager - Design System

> Design decisions and brand guidelines. Reference this when building any UI.

---

## Brand Identity

**Name:** Genixo Restoration Manager (may change — keep name configurable, not hardcoded in UI strings)
**One-liner:** Incident management for property restoration teams
**Target users:** Mitigation managers/techs (blue-collar, on job sites, varying tech comfort) and property managers (office-based, moderately tech-savvy)
**Feeling:** Professional, reliable, clean, utilitarian. Effective and straightforward — not trying to win design awards. Functional over stylish.

### Design Reference
Clean personal finance / consumer app dashboards — the kind where information density is high but nothing feels cluttered. Think clear data hierarchy, obvious CTAs, no decorative elements.

### Existing Brand
- Logo: "GENIXO CONSTRUCTION" with circular G mark
- Logo colors: Dark teal/cyan text, charcoal secondary
- Industry: Construction / property restoration

---

## Color Palette

Derived from the Genixo brand teal. Intentionally muted — this is a work tool, not a marketing site.

### Primary Colors
| Name | Value | Usage |
|------|-------|-------|
| Primary | `hsl(187 70% 34%)` | Main CTAs, active states, nav highlights |
| Primary Foreground | `hsl(0 0% 100%)` | Text on primary |

### Accent Colors
| Name | Value | Usage |
|------|-------|-------|
| Accent | `hsl(187 15% 95%)` | Secondary actions, hover states, selected rows |
| Accent Foreground | `hsl(187 70% 25%)` | Text on accent backgrounds |

### Semantic Colors
| Name | Value | Usage |
|------|-------|-------|
| Emergency | `hsl(0 84% 60%)` | Emergency flag, urgent badges, destructive actions |
| Warning | `hsl(38 92% 50%)` | On-hold status, caution states |
| Success | `hsl(142 76% 36%)` | Active/completed status, positive confirmations |
| Info | `hsl(199 89% 48%)` | Informational badges, links |

### Status Colors
| Status | Color | Reasoning |
|--------|-------|-----------|
| `new` / `acknowledged` | Info blue | Needs attention, not urgent |
| `quote_requested` | Muted purple `hsl(270 50% 60%)` | Distinct from action statuses |
| `active` | Success green | Work in progress |
| `on_hold` | Warning amber | Paused, needs awareness |
| `completed` | Muted green `hsl(142 40% 50%)` | Done but not fully closed |
| `completed_billed` / `paid` | Neutral gray | Administrative, low visual priority |
| `closed` | Neutral gray | Archived feel |
| Emergency badge | Emergency red | Always visible, high contrast |

### Neutrals
| Name | Value | Usage |
|------|-------|-------|
| Background | `hsl(0 0% 99%)` | Page background |
| Foreground | `hsl(0 0% 9%)` | Primary text |
| Muted | `hsl(0 0% 46%)` | Secondary text, timestamps, labels |
| Muted Background | `hsl(0 0% 96%)` | Subtle backgrounds, table stripes |
| Border | `hsl(0 0% 90%)` | Borders, dividers |
| Card | `hsl(0 0% 100%)` | Card backgrounds |

### Mode
Light mode only. No dark mode for MVP.

---

## Typography

### Font Stack
- **Headings + Body:** Inter (Google Fonts) — clean, highly legible, built for UI
- **Monospace:** JetBrains Mono (for any code/ID display)
- **Fallback:** System sans-serif stack

### Type Scale
| Element | Size | Weight | Usage |
|---------|------|--------|-------|
| Page title (H1) | 1.875rem (30px) | 700 | Page headers only |
| Section title (H2) | 1.5rem (24px) | 600 | Card/section headers |
| Subsection (H3) | 1.25rem (20px) | 600 | Sub-headers |
| Body | 1rem (16px) | 400 | Default text |
| Small | 0.875rem (14px) | 400 | Timestamps, metadata, labels |
| Tiny | 0.75rem (12px) | 500 | Badges, status chips |

**Notes:**
- No type smaller than 12px — users have varying vision.
- Labels and form headers: 14px, semi-bold (500).
- Data values: 16px, regular (400).

---

## Component Patterns

### Borders
- **Radius:** Sharp — `4px` (or Tailwind `rounded`)
- **Weight:** Subtle — `1px solid border` (Tailwind `border`)

### Shadows
- **Style:** Subtle — slight depth for cards only
- **Card shadow:** `shadow-sm` (Tailwind)
- **Elevated shadow:** `shadow-md` for modals/dropdowns only

### Buttons
- **Primary:** Teal background, white text. Used for main actions (Save, Create, Assign).
- **Secondary:** White background, teal border, teal text. Used for secondary actions (Cancel, Back).
- **Ghost:** No border, no background. Used for tertiary actions and icon buttons.
- **Destructive:** Red background, white text. Used for remove/unassign actions. Always requires confirmation.
- **Size:** Default padding `px-4 py-2`. All buttons minimum 44px touch target height on mobile.

### Cards
- White background, 1px border, 4px radius, `shadow-sm`
- No colored card backgrounds except for emergency incidents (subtle red tint `bg-red-50`)

### Tables
- Used heavily for incident lists, labor entries, equipment logs
- Alternating row backgrounds (`bg-muted-background` on even rows)
- Sortable column headers where applicable
- Row click navigates to detail view (entire row is clickable)

### Status Badges
- Small rounded chips with colored background + white or dark text
- Always show status text, not just color (accessibility)
- Emergency badge: red with white text, always appears first/leftmost

### Forms
- Labels above inputs (not inline/floating)
- Clear required field indicators
- Validation errors shown inline below the field, in red
- Large touch targets on all inputs (minimum 44px height)

---

## Layout

**Approach:** Desktop-first with strong mobile responsiveness. Tech-facing views (incident detail, labor entry, equipment log) must work well on phones.

**Max content width:** `max-w-7xl` (1280px) for main content area
**Sidebar:** Fixed left sidebar for navigation (collapsible on mobile to hamburger menu)
**Spacing:** Tailwind default scale. Consistent `p-4` / `p-6` for card padding, `gap-4` / `gap-6` for grid gaps.

### Responsive Breakpoints
| Breakpoint | Target |
|-----------|--------|
| Default (< 640px) | Phone — single column, stacked layout |
| `sm` (640px) | Large phone / small tablet |
| `md` (768px) | Tablet — two-column where appropriate |
| `lg` (1024px) | Desktop — full sidebar + content |
| `xl` (1280px) | Wide desktop — max content width |

### Navigation (Sidebar)
- Logo at top
- Role-aware links (different items per user_type)
- Unread indicators (dot badges) on Incidents link
- Active state: teal background highlight
- Mobile: hamburger menu, slide-in drawer

---

## Tone & Voice

**Style:** Plain language, direct, no jargon. Write for someone who doesn't use software all day.

**Do:**
- Use short, clear labels ("Add Equipment", not "Register New Equipment Entry")
- Use verbs for buttons ("Save", "Assign", "Mark Active")
- Show confirmation after actions ("Technician assigned to incident")
- Use real words ("3 hours ago", not "2024-02-14T10:30:00Z")

**Don't:**
- Use technical terms in UI ("polymorphic", "webhook", "dispatch")
- Use passive voice ("The incident was created" → "You created this incident")
- Use corporate language ("Please be advised that..." → just state the thing)
- Abbreviate unless universally understood (OK: "hrs", "min". Not OK: "cfg", "esc")

**Error messages:** Friendly and actionable. Say what went wrong and what to do.
- Good: "Couldn't save — duration must be at least 1 minute."
- Bad: "Validation failed: duration_minutes must be greater than 0"

**Empty states:** Always explain what goes here and how to add the first item.
- "No equipment placed yet. Use 'Add Equipment' to log equipment for this incident."

---

## Accessibility

**Target:** WCAG AA
**Requirements:**
- All interactive elements keyboard-navigable
- Color is never the only indicator (status badges always include text)
- Minimum contrast ratio 4.5:1 for text
- Focus rings visible on all interactive elements
- Form inputs have associated labels (not placeholder-only)
- Touch targets minimum 44x44px on mobile views
