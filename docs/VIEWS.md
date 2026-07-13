# Views & Routes

> Every page, what it shows, and who can see it. Presentational reference for building UI.
>
> For data schema, see `SCHEMA.md`. For business logic, see `BUSINESS_RULES.md`. For design tokens, see `DESIGN.md`.

---

## Layout

### App Shell

```
┌────────────┬─────────────────────────────────────────────────────┐
│            │                                                     │
│  [G] Logo  │  Content Area                                      │
│            │  (max-width 1280px)                                 │
│  ────────  │                                                     │
│            │  ┌───────────────────────────────────────────────┐  │
│  Dashboard │  │  Flash messages (success/error, auto-dismiss) │  │
│  Incidents │  └───────────────────────────────────────────────┘  │
│  Properties│                                                     │
│  Orgs      │                                                     │
│  Users     │  Page content renders here                          │
│  On-Call   │                                                     │
│  Equip.    │                                                     │
│  Settings  │                                                     │
│            │                                                     │
│  ────────  │                                                     │
│  Jane Doe  │                                                     │
│  Genixo    │                                                     │
│  Manager   │                                                     │
└────────────┴─────────────────────────────────────────────────────┘
```

- Sidebar is fixed left, collapses to hamburger menu on mobile.
- Links are role-aware (see table below).
- User info at bottom: name, org name, role.

### Sidebar Links by Role

| Link | Manager | Technician | Office/Sales | PM/AM/PM Mgr |
|------|:-------:|:----------:|:------------:|:------------:|
| Dashboard | Yes | Yes | Yes | Yes |
| Incidents | Yes | Yes | Yes | Yes |
| Properties | Yes | - | Yes | Yes |
| Organizations | Yes | - | Yes | - |
| Users | Yes | - | Yes | - |
| On-Call | Yes | - | - | - |
| Equipment | Yes | - | - | - |
| Equipment Types | Yes | - | - | - |
| Settings | Yes | Yes | Yes | Yes |

Unread dot badge on **Dashboard** link when any visible incident has unread messages or activity.

---

## Public Pages

### Login — `GET /login`

```
┌──────────────────────────────────────┐
│                                      │
│         [G] Genixo Restoration       │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  Email                         │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │  Password                      │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │          Sign In               │  │
│  └────────────────────────────────┘  │
│                                      │
│         Forgot password?             │
│                                      │
└──────────────────────────────────────┘
```

No self-serve "sign up" — accounts are created via invitations only. A **"Request access"** link goes to the public request form (below); admins review requests and send invitations. Redirects to dashboard on success.

---

### Request Access — `GET /request-access`

**Page:** `LoginRequest.tsx` · Public, rate-limited (5/min per IP)

Public form: first/last name, email, phone, and **company (free text)** — all required — plus an optional title and message. Company is deliberately typed, not a dropdown: an unauthenticated page must never list the client orgs. Submitting creates a `LoginRequest` (storing `company_name`) and emails active mitigation users holding MANAGE_USERS. The requester gets no account until an admin approves and sends an invitation from the Users page (the admin matches the typed company to an org in the invite modal, which opens with org/role cleared).

---

### Accept Invitation — `GET /invitations/:token`

```
┌──────────────────────────────────────┐
│                                      │
│      You've been invited to join     │
│      Genixo Construction             │
│      as a Technician                 │
│                                      │
│  First Name *          Last Name *   │
│  ┌────────────────┐  ┌────────────┐ │
│  │ (pre-filled?)  │  │            │ │
│  └────────────────┘  └────────────┘ │
│                                      │
│  Phone *                             │
│  ┌────────────────────────────────┐  │
│  │ (pre-filled?)                  │  │
│  └────────────────────────────────┘  │
│                                      │
│  Password *                          │
│  ┌────────────────────────────────┐  │
│  │                                │  │
│  └────────────────────────────────┘  │
│  Confirm Password *                  │
│  ┌────────────────────────────────┐  │
│  │                                │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │       Create Account           │  │
│  └────────────────────────────────┘  │
│                                      │
└──────────────────────────────────────┘
```

Fields pre-filled if the inviter provided them, but still editable. First name, last name, and phone are required. If token is expired/invalid, show error with "Contact your administrator." On success, logs in and redirects to dashboard.

---

## Dashboard — `GET /dashboard`

**Page:** `Dashboard/Show.tsx`
**Access:** All authenticated users

The landing page. Shows incidents grouped by urgency for quick triage. For a flat filterable list, see the Incidents page.

```
┌──────────────────────────────────────────────────────────────────────┐
│  Dashboard                                          [+ New Incident] │
│                                                                      │
│  ┌─────────────┐ ┌──────────┐ ┌───────────┐ ┌──────────┐ ┌──────┐  │
│  │ Search...    │ │ Status ▼ │ │ Property ▼│ │ Type ▼   │ │ !! ▼ │  │
│  └─────────────┘ └──────────┘ └───────────┘ └──────────┘ └──────┘  │
│                                                                      │
│  ▼ EMERGENCY (2)                                                     │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ !! Park at River Oaks                    [EMERGENCY] [ACTIVE] │  │
│  │ Water pipe burst in unit 238, flooding...                     │  │
│  │ Flood · Emergency Response · 5 min ago                  (3) ● │  │
│  ├────────────────────────────────────────────────────────────────┤  │
│  │ !! Sandalwood Commons                   [EMERGENCY] [ACKNOWL] │  │
│  │ Fire damage to building C, units 301-305...                   │  │
│  │ Fire · Emergency Response · 12 min ago                  (1) ● │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ▼ ACTIVE (4)                                                        │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ Greystar Towers                                      [ACTIVE] │  │
│  │ Mold remediation in basement storage...                       │  │
│  │ Mold · Mitigation · 2 hrs ago                                 │  │
│  ├────────────────────────────────────────────────────────────────┤  │
│  │ ...                                                           │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ▶ NEEDS ATTENTION (1)                                               │
│  ▶ ON HOLD (2)                                                       │
│  ▶ RECENT COMPLETED (5)                                              │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

- Groups are collapsible sections, sorted by most recent activity.
- Emergency cards have red-tinted backgrounds.
- Unread badge shows combined message + activity count.
- Click any card → incident detail.

**Role scoping:**
- **Manager / Office/Sales:** All incidents across their org's properties.
- **Technician:** Only assigned incidents.
- **PM/AM/PM Manager:** Incidents on assigned properties + directly assigned incidents.

---

## Incidents — `GET /incidents`

**Page:** `Incidents/Index.tsx`
**Access:** All authenticated users (scoped by role)

Flat list of all incidents with filters and sorting. Complements the dashboard — the dashboard groups by urgency for triage, this page is for searching and browsing everything.

```
┌──────────────────────────────────────────────────────────────────────┐
│  Incidents                                          [+ New Incident] │
│                                                                      │
│  ┌─────────────┐ ┌──────────┐ ┌───────────┐ ┌──────────┐ ┌──────┐  │
│  │ Search...    │ │ Status ▼ │ │ Property ▼│ │ Type ▼   │ │ !! ▼ │  │
│  └─────────────┘ └──────────┘ └───────────┘ └──────────┘ └──────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ Property         │ Description    │ Status  │ Type  │ Active│   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │ !! Park at R.O.  │ Water pipe...  │ ACTIVE  │ Emrg  │ 5m   │   │
│  │ !! Sandalwood     │ Fire damage... │ ACKNOWL │ Emrg  │ 12m  │   │
│  │ Greystar Towers  │ Mold remed...  │ ACTIVE  │ Mit.  │ 2h   │   │
│  │ Lakewood Hts     │ Odor in unit...│ ON HOLD │ Other │ 1d   │   │
│  │ Park at R.O.     │ Smoke damage...│ COMPLTD │ Build │ 3d   │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ◀ Page 1 of 3 ▶                                                    │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

- Sortable columns (click header to sort).
- Emergency incidents show `!!` prefix and red row tint.
- Click row → incident detail.
- "New Incident" visible to: manager, office_sales, property_manager, area_manager. Not technicians.
- Paginated.
- **My Jobs** toggle in the filter bar scopes the list to the current user's assigned incidents (`?my_jobs=1`, round-trips through pagination/sorting). Hidden for technicians and guests, whose visibility is already assignment-only.

---

## Incident Detail — `GET /incidents/:id`

**Page:** `Incidents/Show.tsx`
**Access:** Users who can see this incident (404 if not)

The primary workspace for an incident. Split-panel layout on desktop so users can see incident info and activity simultaneously.

### Desktop Layout (lg+)

Left panel ~65% width (incident workspace tabs), right panel ~35% (incident details). Both scroll independently.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  ← Dashboard                                                                │
│  Park at River Oaks · 123 River Oaks Dr                                     │
│  [ACTIVE ▼] [!! EMERGENCY]  Flood · Emergency Response                      │
│  Created by Jane Doe · Feb 12, 2026              [JD] [MK] [ST] +2 assigned│
├─────────────────────────────────────────────────┬────────────────────────────┤
│                                                 │                            │
│  [Activity] [Daily Log] [Messages] [Documents] │ DESCRIPTION                 │
│  Water pipe burst in unit 238, flooding         │ [Documents]                │
│  bedroom and hallway. Standing water ~2 in.     │ ────────────────────────   │
│                                                 │                            │
│  CAUSE                                          │ Jane Doe · Greystar · PM   │
│  Frozen pipe burst during overnight cold snap.  │ Can you send someone       │
│                                                 │ ASAP? The tenant is very   │
│  NEXT STEPS                                     │ upset. Water is still      │
│  Emergency water extraction and drying.         │ rising.                    │
│                                                 │              10:30 AM      │
│  UNITS AFFECTED: 238, 239                       │                            │
│  ROOMS: Bedroom, Hallway, Kitchen               │ Mike Kim · Genixo · Mgr   │
│                                                 │ Tech team dispatched.      │
│  ───────────────────────────────────────        │ Sarah en route. ETA 30     │
│  DEPLOYED EQUIPMENT                             │ min.                       │
│   Air Mover x6                                  │                            │
│   Dehumidifier x2                               │                            │
│  ASSIGNED TEAM                                  │                            │
│                                                 │              10:35 AM      │
│  Genixo Construction                            │                            │
│   Mike Kim · Manager                            │ Sarah Torres · Tech        │
│   Sarah Torres · Technician                     │ On site. Starting          │
│   [+ Assign]                                    │ extraction now.            │
│                                                 │ ┌────────────────────┐     │
│  Greystar                                       │ │ 📷 flooding.jpg    │     │
│   Jane Doe · Property Manager                   │ └────────────────────┘     │
│   [+ Assign]                                    │              11:02 AM      │
│                                                 │                            │
│  ───────────────────────────────────────        │                            │
│  CONTACTS                                       │                            │
│   Bob Smith · Insurance Adjuster                │                            │
│   bob@insurance.com · 555-0123                  │                            │
│   [+ Add Contact]                               │                            │
│                                                 │ ──────────────────────     │
│  ───────────────────────────────────────        │ ┌──────────────── 📎 ─┐   │
│  ┌──────────┐ ┌──────────┐                      │ │ Type a message...   │   │
│  │  12.5    │ │    6     │                      │ │              [Send] │   │
│  │  hours   │ │  equip   │                      │ └────────────────────┘   │
│  └──────────┘ └──────────┘                      │                            │
│                                                 │                            │
└─────────────────────────────────────────────────┴────────────────────────────┘
```

- Left panel is wider — incident details, assignments, contacts, and summary stats have room to breathe.
- Left panel tabs order: **Activity → Daily Log → Messages → Documents**.
- Right panel is narrower — description, deployed equipment, assigned team, and contacts.
- Both panels scroll independently.
- **Messages compose area is pinned to the bottom of the viewport** (not the bottom of the scroll content), so it's always visible regardless of how many messages exist above.

### Tablet / Mobile Layout (< lg)

Single column. Overview at top, then tab bar for Activity, Daily Log, Messages, Documents below.

```
┌────────────────────────────────────┐
│  ← Dashboard                      │
│  Park at River Oaks               │
│  [ACTIVE ▼] [!! EMERGENCY]        │
│  Flood · Emergency Response        │
│  [JD] [MK] [ST] +2 assigned      │
│                                    │
│  DESCRIPTION                       │
│  Water pipe burst in unit 238...  │
│                                    │
│  ASSIGNED TEAM                     │
│  Mike Kim · Manager ... [+ Assign]│
│                                    │
│  ┌──────┐ ┌──────┐ ┌──────┐      │
│  │12.5hr│ │6 equp│ │8 plcd│      │
│  └──────┘ └──────┘ └──────┘      │
│                                    │
│  [Activity] [Daily Log] [Messages]│
│  [Documents]                      │
│  ──────────────────────────────── │
│  (selected tab content here)      │
│                                    │
└────────────────────────────────────┘
```

### Header (always visible)

Sticky at the top:
- Property name + address
- Status badge + "Change Status" dropdown (managers only, shows valid transitions)
- Emergency badge + toggle (managers only)
- Project type + damage type labels
- Created by + created date
- Assigned users — avatar/initials row with count
- Back link to dashboard

### Left Panel: Overview

1. **Description** — full description, cause, requested next steps. Three labeled blocks.
2. **Assigned Team** — grouped by org. Add/remove per permissions (managers manage anyone, PM-side manages own org).
3. **Contacts** — non-user contacts (insurance, owners). Add/remove by managers and PM-side.
4. **Quick Stats** — total labor hours by role, active equipment, total placed, last status change.

### Left Panel: Activity (default)

```
┌────────────────────────────────────┐
│  [Activity•] [Daily Log] [Messages] [Docs] │
│  ──────────────────────────────── │
│                                    │
│  Jane Doe · Greystar · PM         │
│  Can you send someone ASAP?       │
│                          10:30 AM  │
│                                    │
│  Mike Kim · Genixo · Manager      │
│  Tech team dispatched. ETA 30min. │
│                          10:35 AM  │
│                                    │
│  Sarah Torres · Genixo · Tech     │
│  On site. Starting extraction.    │
│  ┌──────────────────────────┐     │
│  │ 📷 photo_attachment.jpg  │     │
│  └──────────────────────────┘     │
│                          11:02 AM  │
│                                    │
│  ──────────────────────────────── │
│  ┌──────────────────────── 📎 ┐  │
│  │  Type a message...         │  │
│  │                     [Send] │  │
│  └────────────────────────────┘  │
└────────────────────────────────────┘
```

- Chronological feed of all incident activity (status changes, assignments, activity entries, labor, equipment, notes, documents, messages).
- Newest entries at top.

### Left Panel: Daily Log

### Left Panel: Daily Log

```
┌──────────────────────────────────────────────────────┐
│  [Activity] [Daily Log•] [Messages] [Docs]           │
│  ──────────────────────────────────────────────────  │
│                                                      │
│  ┌─────────────────────────────────────────┐        │
│  │ Feb 14 │ Feb 13 │ Feb 12               │        │
│  └─────────────────────────────────────────┘        │
│                                                      │
│  ACTIVITIES                         [+ Add Activity] │
│  ┌────────────────────────────────────────────────┐ │
│  │ Extract water  [Completed] · Feb 14 9:00 AM    │ │
│  │ Units affected: 3 · Units 237, 238, 239        │ │
│  │ ▲ Add 6 Air Movers · initial dry-down pass     │ │
│  │ ▲ Add 2 Dehumidifiers · reduce humidity        │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  LABOR                                 [+ Add Labor] │
│  ┌────────────────────────────────────────────────┐ │
│  │ Technician  · 4.5 hrs · Sarah Torres           │ │
│  │   9:00 AM – 1:30 PM · Water extraction         │ │
│  │ Supervisor  · 2.0 hrs · Mike Kim               │ │
│  │   9:00 AM – 11:00 AM · On-site oversight       │ │
│  │ General Labor · 1.0 hrs                        │ │
│  │   Debris removal                               │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  NOTES                                  [+ Add Note] │
│  ┌────────────────────────────────────────────────┐ │
│  │ "Extracted approx 40 gallons of standing       │ │
│  │  water. Placed equipment per standard flood    │ │
│  │  protocol. Will return tomorrow for readings." │ │
│  │  — Sarah Torres · 1:30 PM                     │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  DOCUMENTS                       [+ Upload Document] │
│  ┌────────────────────────────────────────────────┐ │
│  │ 📷 moisture_map_238.pdf · Moisture Mapping     │ │
│  │ 📷 photo_before_1.jpg · Photo                  │ │
│  │ 📷 photo_before_2.jpg · Photo                  │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
└──────────────────────────────────────────────────────┘
```

- Date selector at top, with an **"All Dates"** option to see the full chronological timeline across all dates. Most recent date selected by default.
- **All sections expanded by default** — the entire day's log is visible at a glance without clicking to expand.
- When "All Dates" is selected, entries are grouped by date with date headers, scrollable top to bottom (oldest to newest) so you can see how the project has progressed over time.

**Add buttons** (inline forms or slide-up modals):
- "Add Activity" — title, occurred_at, status, units affected, units affected description, details, and optional equipment action rows (`add/remove/move/other`, quantity, type, optional note).
- "Add Labor" — role_label, hours (or start/end time), log_date, notes, user picker (managers only). Visible to technicians and managers.
- "Add Note" — note text, log_date. Visible to technicians and managers.
- "Upload Document" — file picker, name/description (editable, defaults to filename), category dropdown, log_date (defaults to today). Visible to anyone who can see the incident.

PM-side users see this panel as read-only (no add buttons for labor/equipment/notes, but can upload documents).

**DFR generation** (per date group, MANAGE_DAILY_LOGS holders): the DFR button opens a selection modal offering **all** the incident's photos grouped by date — report date first and preselected — plus a Documents section listing the incident's non-photo attachments. Selected PDFs are appended into the generated DFR as real pages; image documents embed like photos; other types are listed by filename. "Skip attachments" generates a bare DFR. Generation is async (Solid Queue) with 5s polling until the link appears; regenerate replaces the file.

Viewing marks activity as read.

### Right Panel: Documents

```
┌──────────────────────────────────────────────────────┐
│  [Messages] [Daily Log] [Docs•]                      │
│  ──────────────────────────────────────────────────  │
│                                                      │
│  Filter: [All ▼]                          [Upload]   │
│                                                      │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                   │
│  │ 📷  │ │ 📷  │ │ 📷  │ │ 📷  │                   │
│  │     │ │     │ │     │ │     │                   │
│  └─────┘ └─────┘ └─────┘ └─────┘                   │
│  Unit 238  Unit 238  Hallway   Bedroom              │
│  flooding  closeup   damage    damage               │
│  Feb 14    Feb 14    Feb 14    Feb 14               │
│  S.Torres  S.Torres  S.Torres  S.Torres            │
│                                                      │
│  ──── Documents ────                                 │
│  📄 moisture_map_238.pdf                             │
│     "Initial moisture mapping"                       │
│     Moisture Mapping · Feb 14, 1:45 PM              │
│     Uploaded by S. Torres                            │
│                                                      │
│  📄 indemnification_signed.pdf                       │
│     "Signed liability waiver"                        │
│     Signed Document · Feb 12, 3:20 PM               │
│     Uploaded by J. Doe                               │
│                                                      │
└──────────────────────────────────────────────────────┘
```

- Filter by category.
- Grid for photos (thumbnail + name + date + uploader), list for other documents.
- Each document shows: name/description, category badge, log_date, upload timestamp, uploaded by.
- All historical, chronological, append-only.
- "Upload" opens form: file picker, name/description, category dropdown, log_date.

---

## New Incident — `GET /incidents/new`

**Page:** `Incidents/New.tsx`
**Access:** Manager, office_sales, property_manager, area_manager (NOT technicians)

```
┌──────────────────────────────────────────────────────────────────┐
│  New Incident                                                    │
│                                                                  │
│  Property *                                                      │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Select a property...                                  ▼  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Project Type *                                                  │
│  ○ Emergency Response                                            │
│  ○ Mitigation                                                    │
│  ○ Buildback                                                     │
│  ○ Other                                                         │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ ⚠ This will trigger the emergency on-call escalation      │  │
│  │   chain immediately.                                      │  │
│  └────────────────────────────────────────────────────────────┘  │
│  (shown only when Emergency Response selected)                   │
│                                                                  │
│  Damage Type *                                                   │
│  ┌────────────────────────────────────────────────┐             │
│  │ Select...                                   ▼  │             │
│  └────────────────────────────────────────────────┘             │
│                                                                  │
│  Description *                                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │                                                            │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Cause                                                           │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Requested Next Steps                                            │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Units Affected              Affected Room Numbers               │
│  ┌──────────────┐           ┌──────────────────────┐            │
│  │              │           │ e.g. 238, 239, 240   │            │
│  └──────────────┘           └──────────────────────┘            │
│                                                                  │
│                              [Cancel]  [Create Incident]         │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

On submit → redirects to the new incident's detail page.

---

## Properties

### Property List — `GET /properties`

**Page:** `Properties/Index.tsx`
**Access:** Manager, office_sales, property_manager, area_manager, pm_manager (NOT technicians)

```
┌──────────────────────────────────────────────────────────────────────┐
│  Properties                                       [+ New Property]   │
│                                                                      │
│  ┌──────────────────────────────────────┐                           │
│  │ Search by name or address...         │                           │
│  └──────────────────────────────────────┘                           │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ Name               │ Address        │ PM Org    │Active│Total│   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │ Park at River Oaks │ 123 River Oaks │ Greystar  │  3   │  8  │   │
│  │ Sandalwood Commons │ 456 Oak St     │ Sandalwoo │  1   │  4  │   │
│  │ Greystar Towers    │ 789 Main Ave   │ Greystar  │  2   │ 12  │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

Click row → property detail. "New Property" visible to manager/office_sales only.

---

### Property Detail — `GET /properties/:id`

**Page:** `Properties/Show.tsx`
**Access:** Users who can see this property (404 if not)

```
┌──────────────────────────────────────────────────────────────────────┐
│  ← Properties                                                        │
│  Park at River Oaks                                       [Edit]     │
│  123 River Oaks Dr, Houston, TX 77001 · 48 units                    │
│  PM: Greystar · Mitigation: Genixo Construction                     │
│                                                                      │
│  ──────────────────────────────────────────────────────────────────  │
│  ASSIGNED USERS                                      [+ Assign]     │
│                                                                      │
│  Jane Doe · Property Manager                                        │
│  Bob Wilson · Area Manager                                          │
│                                                                      │
│  ──────────────────────────────────────────────────────────────────  │
│  INCIDENTS                                        [+ New Incident]  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ !! Water pipe burst in 238...  [EMERGENCY] [ACTIVE]  5m ago  │  │
│  ├────────────────────────────────────────────────────────────────┤  │
│  │ Mold remediation basement...   [ACTIVE]              2h ago  │  │
│  ├────────────────────────────────────────────────────────────────┤  │
│  │ Smoke damage unit 104...       [COMPLETED]           3d ago  │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

- Property info editable by managers, office_sales, and assigned PM-side users.
- Assignment management per permission rules.
- "New Incident" pre-fills this property.

---

### New Property — `GET /properties/new`

**Page:** `Properties/New.tsx`
**Access:** Manager, office_sales only

```
┌──────────────────────────────────────────────────┐
│  New Property                                    │
│                                                  │
│  Name *                                          │
│  ┌────────────────────────────────────────────┐  │
│  │                                            │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  PM Organization *                               │
│  ┌────────────────────────────────────────────┐  │
│  │ Select...                               ▼  │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  Street Address                                  │
│  ┌────────────────────────────────────────────┐  │
│  │                                            │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  City              State         Zip             │
│  ┌────────────┐   ┌──────────┐  ┌──────────┐   │
│  │            │   │          │  │          │   │
│  └────────────┘   └──────────┘  └──────────┘   │
│                                                  │
│  Unit Count                                      │
│  ┌──────────────┐                               │
│  │              │                               │
│  └──────────────┘                               │
│                                                  │
│                   [Cancel]  [Create Property]    │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## Organizations

### Organization List — `GET /organizations`

**Page:** `Organizations/Index.tsx`
**Access:** Manager, office_sales (mitigation org users only)

```
┌──────────────────────────────────────────────────────────────────────┐
│  Organizations                                 [+ New Organization]  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ Name           │ Phone        │ Email          │Props│Users │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │ Greystar       │ 555-0100     │ info@grey.com  │  5  │  8   │   │
│  │ Sandalwood Mgmt│ 555-0200     │ info@sand.com  │  3  │  4   │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

Click row → org detail.

---

### Organization Detail — `GET /organizations/:id`

**Page:** `Organizations/Show.tsx`
**Access:** Manager, office_sales

```
┌──────────────────────────────────────────────────────────────────────┐
│  ← Organizations                                                     │
│  Greystar                                                  [Edit]    │
│  555-0100 · info@greystar.com                                       │
│  100 Corporate Blvd, Dallas, TX 75001                               │
│                                                                      │
│  ──────────────────────────────────────────────────────────────────  │
│  PROPERTIES                                                         │
│                                                                      │
│  Park at River Oaks · 3 active incidents                            │
│  Greystar Towers · 2 active incidents                               │
│  Lakewood Heights · 0 active incidents                              │
│                                                                      │
│  ──────────────────────────────────────────────────────────────────  │
│  USERS                                                              │
│                                                                      │
│  Jane Doe · jane@grey.com · Property Manager · Active               │
│  Bob Wilson · bob@grey.com · Area Manager · Active                  │
│  Carol Park · carol@grey.com · PM Manager · Active                  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

### New Organization — `GET /organizations/new`

**Page:** `Organizations/New.tsx`
**Access:** Manager, office_sales

```
┌──────────────────────────────────────────────────┐
│  New Organization                                │
│                                                  │
│  Name *                                          │
│  ┌────────────────────────────────────────────┐  │
│  │                                            │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  Phone               Email                       │
│  ┌──────────────┐   ┌────────────────────────┐  │
│  │              │   │                        │  │
│  └──────────────┘   └────────────────────────┘  │
│                                                  │
│  Street Address                                  │
│  ┌────────────────────────────────────────────┐  │
│  │                                            │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  City              State         Zip             │
│  ┌────────────────┐ ┌──────────┐ ┌──────────┐  │
│  │                │ │          │ │          │  │
│  └────────────────┘ └──────────┘ └──────────┘  │
│                                                  │
│                [Cancel]  [Create Organization]   │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## Users

### User List — `GET /users`

**Page:** `Users/Index.tsx`
**Access:** Manager, office_sales

```
┌──────────────────────────────────────────────────────────────────────┐
│  Users                                             [+ Invite User]   │
│                                                                      │
│  ACTIVE USERS                                                        │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ Name             │ Email            │ Role        │ Phone   │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │ Mike Kim         │ mike@genixo.com  │ Manager     │ 555-001 │   │
│  │ Sarah Torres     │ sarah@genixo.com │ Technician  │ 555-002 │   │
│  │ Alex Chen        │ alex@genixo.com  │ Office/Sales│ 555-003 │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ▶ DEACTIVATED USERS (1)                                            │
│                                                                      │
│  PENDING INVITATIONS                                                 │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ Email               │ Role        │ Expires    │            │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │ new@genixo.com      │ Technician  │ Feb 21     │ [Resend]  │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

Click user → user detail. "Invite User" opens modal with: email (required), user_type dropdown (required), first name, last name, phone (all optional — invitee fills in anything missing on signup).

A **"Request access link"** row sits at the top of the page (always visible): the shareable public `/request-access` URL with a Copy button, so admins can send it to prospective users.

**Login Requests** section (above Pending Invitations, shown when any exist): pending `/request-access` submissions with name, email, company, phone, requested date, and the requester's message. Actions per row:
- **Approve** — marks the request approved and opens the invite modal prefilled from the request: the requester's chosen client org **and a default Property Manager role** (one invitation path; the admin can still adjust the role/title before sending). If the admin cancels the modal, the approved row keeps an **Invite** button until an invitation or account exists for that email, then disappears.
- **Reject** — optional reason recorded, nothing emailed to the requester.
- Rows whose email already has an account or pending invitation show that status instead of actions.

---

### User Detail — `GET /users/:id`

**Page:** `Users/Show.tsx`
**Access:** Manager, office_sales

```
┌──────────────────────────────────────────────────────────────────────┐
│  ← Users                                                             │
│  Sarah Torres                              [Edit]  [Deactivate]     │
│  sarah@genixo.com · Technician · Genixo Construction               │
│  555-0002 · Eastern Time                                            │
│                                                                      │
│  ──────────────────────────────────────────────────────────────────  │
│  PROPERTY ASSIGNMENTS (PM-side users only)                          │
│                                                                      │
│  (Not applicable — mitigation user)                                 │
│                                                                      │
│  ──────────────────────────────────────────────────────────────────  │
│  ACTIVE INCIDENTS                                                   │
│                                                                      │
│  Park at River Oaks · Water pipe burst... · Active                  │
│  Greystar Towers · Mold remediation... · Active                     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Settings

### Profile — `GET /settings`

**Page:** `Settings/Profile.tsx`
**Access:** All authenticated users

```
┌──────────────────────────────────────────────────────────────────────┐
│  Settings                                                            │
│                                                                      │
│  PROFILE                                                             │
│                                                                      │
│  First Name                    Last Name                             │
│  ┌──────────────────────┐     ┌──────────────────────┐              │
│  │ Sarah                │     │ Torres               │              │
│  └──────────────────────┘     └──────────────────────┘              │
│                                                                      │
│  Phone                                                               │
│  ┌──────────────────────┐                                           │
│  │ 555-0002             │                                           │
│  └──────────────────────┘                                           │
│                                               [Save Profile]        │
│                                                                      │
│  ──────────────────────────────────────────────────────────────────  │
│  PASSWORD                                                            │
│                                                                      │
│  Current Password        New Password          Confirm               │
│  ┌──────────────────┐   ┌──────────────────┐  ┌──────────────────┐ │
│  │                  │   │                  │  │                  │ │
│  └──────────────────┘   └──────────────────┘  └──────────────────┘ │
│                                              [Change Password]      │
│                                                                      │
│  ──────────────────────────────────────────────────────────────────  │
│  TIMEZONE                                                            │
│                                                                      │
│  ┌────────────────────────────────────────┐                         │
│  │ Eastern Time (America/New_York)     ▼  │                         │
│  └────────────────────────────────────────┘                         │
│                                                                      │
│  ──────────────────────────────────────────────────────────────────  │
│  NOTIFICATIONS                                                       │
│                                                                      │
│  Message notifications          [====●]  On                         │
│  Status change notifications    [====●]  On                         │
│  Daily digest                   [●====]  Off                        │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

### On-Call — `GET /settings/on-call`

**Page:** `Settings/OnCall.tsx`
**Access:** Manager (mitigation org) only

```
┌──────────────────────────────────────────────────────────────────────┐
│  On-Call Configuration                                               │
│                                                                      │
│  PRIMARY ON-CALL                                                     │
│                                                                      │
│  ┌────────────────────────────────────────┐                         │
│  │ Mike Kim                            ▼  │                         │
│  └────────────────────────────────────────┘                         │
│                                                                      │
│  ESCALATION TIMEOUT                                                  │
│                                                                      │
│  ┌──────┐ minutes before escalating to next contact                 │
│  │  10  │                                                           │
│  └──────┘                                                           │
│                                                                      │
│  ──────────────────────────────────────────────────────────────────  │
│  ESCALATION CHAIN                                    [+ Add]        │
│                                                                      │
│  1. ≡ Sarah Torres · Manager               [✕]                     │
│  2. ≡ Alex Chen · Office/Sales             [✕]                     │
│  3. ≡ David Park · Manager                 [✕]                     │
│                                                                      │
│  (drag ≡ to reorder)                                                │
│                                                                      │
│                                                       [Save]        │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

### Equipment Types — `GET /settings/equipment-types`

**Page:** `Settings/EquipmentTypes.tsx`
**Access:** Manager (mitigation org) only

```
┌──────────────────────────────────────────────────────────────────────┐
│  Equipment Types                                                     │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ Dehumidifier                                        [Active]  │  │
│  │ Air Mover                                           [Active]  │  │
│  │ Air Blower                                          [Active]  │  │
│  │ Water Extraction Unit                               [Active]  │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────┐  [Add]                        │
│  │ New equipment type name...       │                               │
│  └──────────────────────────────────┘                               │
│                                                                      │
│  INACTIVE                                                            │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ Ozone Generator                                [Reactivate]   │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

### Equipment Inventory — `GET /equipment_items`

**Page:** `EquipmentItems/Index.tsx`
**Access:** Manager (mitigation org) only

Table of individual equipment units grouped into active/inactive sections. Inline add form at top. Inline edit rows. Each item belongs to an equipment type and has a unique identifier within the org.

Columns: Identifier, Type, Model, Serial #, Actions (edit, deactivate/reactivate).

The equipment placement form on incidents shows a cascading dropdown: pick type → pick item from inventory (or enter manually).

---

## Route Summary

| Route | Page | Access |
|-------|------|--------|
| `GET /login` | Login | Public |
| `GET /request-access` | Request Access form | Public (rate-limited) |
| `GET /invitations/:token` | Accept Invitation | Public |
| `GET /dashboard` | Dashboard (grouped triage) | All users |
| `GET /incidents` | Incident List (flat, filterable) | All users (scoped) |
| `GET /incidents/new` | New Incident | Manager, office_sales, PM, AM |
| `GET /incidents/:id` | Incident Detail | Visible incident |
| `GET /properties` | Property List | All except technician |
| `GET /properties/new` | New Property | Manager, office_sales |
| `GET /properties/:id` | Property Detail | Visible property |
| `GET /organizations` | Organization List | Manager, office_sales |
| `GET /organizations/new` | New Organization | Manager, office_sales |
| `GET /organizations/:id` | Organization Detail | Manager, office_sales |
| `GET /users` | User List | Manager, office_sales |
| `GET /users/:id` | User Detail | Manager, office_sales |
| `GET /settings` | Profile & Preferences | All users |
| `GET /settings/on-call` | On-Call Config | Manager only |
| `GET /equipment_items` | Equipment Inventory | Manager only |
| `GET /settings/equipment-types` | Equipment Types | Manager only |

---

## Empty States

Every list/panel needs a clear empty state:

| View | Empty State |
|------|------------|
| Dashboard | "No incidents yet. Use 'New Incident' to report one." |
| Properties list | "No properties yet. Use 'New Property' to add one." |
| Organizations list | "No property management companies yet. Use 'New Organization' to add one." |
| Users list | "No team members yet. Use 'Invite User' to add someone." |
| Messages panel | "No messages yet. Start the conversation below." |
| Daily Log panel | "No activity recorded yet." |
| Documents panel | "No documents uploaded yet. Use 'Upload' to add files." |
| Equipment types | "No equipment types defined. Use 'Add Equipment Type' to create one." |
| Incident contacts | "No contacts added. Use 'Add Contact' for insurance adjusters, building owners, etc." |
