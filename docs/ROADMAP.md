# Roadmap

> Build phases for Genixo Restoration MVP. Each checkbox is roughly one commit.
>
> Check items off as completed. Any developer or LLM can pick up from the last unchecked item.
>
> **The spec docs are the source of truth for what to build.** This doc is the source of truth for **build order and progress**.
>
> Specs: [SCHEMA.md](SCHEMA.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [BUSINESS_RULES.md](BUSINESS_RULES.md) · [VIEWS.md](VIEWS.md) · [DESIGN.md](DESIGN.md) · [TESTING.md](TESTING.md) · [CODE_QUALITY.md](CODE_QUALITY.md)

---

## Phase 1: Foundation

App setup, database, auth, and app shell.

### App Setup

- [x] Generate Rails 8 app with PostgreSQL
- [x] Install and configure Vite Rails
- [x] Install and configure Inertia Rails + React
- [x] Install and configure Tailwind CSS v4
- [x] Install and configure shadcn/ui with theme tokens (see DESIGN.md)
- [x] Configure Solid Queue + Solid Cache (single-database, see PROJECT_SETUP.md)
- [x] Configure Active Storage (local disk for dev)
- [x] Set up `Procfile.dev` (Puma + Vite)

### Database & Models

Each item = migration + model + validations + associations per SCHEMA.md.

- [x] `organizations` table + model
- [x] `users` table + model (including user_type validation per org type)
- [x] `sessions` table + model
- [x] `properties` table + model (dual org FKs)
- [x] `property_assignments` table + model
- [x] `incidents` table + model (all indexes including dashboard composites)
- [x] `incident_assignments` table + model
- [x] `incident_contacts` table + model
- [x] `messages` table + model
- [x] `incident_read_states` table + model
- [x] `activity_events` table + model (immutable — no updated_at)
- [x] `labor_entries` table + model
- [x] `equipment_types` table + model
- [x] `equipment_entries` table + model (with DB CHECK constraint)
- [x] `operational_notes` table + model (immutable — no updated_at)
- [x] `attachments` table + model (polymorphic + Active Storage)
- [x] `on_call_configurations` + `escalation_contacts` tables + models
- [x] `escalation_events` table + model
- [x] `invitations` table + model

### Seeds

Per PROJECT_SETUP.md seed data section.

- [x] Seed organizations (3 orgs: 1 mitigation, 2 PM)
- [x] Seed users (14 Genixo + 3 Greystar + 1 Sandalwood = 18 users)
- [x] Seed properties (3 properties) + property assignments
- [x] Seed equipment types + on-call configuration
- [x] Seed sample incidents with messages, labor, equipment, activity events

### Authentication

- [x] `Current` model, `SessionsController`, `require_authentication` (see playbook auth.md)
- [x] Login page (see VIEWS.md §Login)
- [x] Redirect logic — dashboard on success, login when unauthenticated
- [x] Block deactivated users from logging in

### App Shell

- [x] `AppLayout.tsx` — sidebar + content area (see VIEWS.md §Layout)
- [x] `RoleSidebar.tsx` — role-aware nav links (see VIEWS.md §Sidebar Links by Role)
- [x] Responsive sidebar — fixed desktop, hamburger mobile
- [x] Shared Inertia data — auth user + routes (see ARCHITECTURE.md §Inertia Shared Data)
- [x] Flash message component
- [x] Placeholder pages for all routes

**Done when:** Log in as any seed user, see correct sidebar for their role, navigate between placeholder pages.

---

## Phase 2: Core Data Management

Orgs, properties, users, invitations. Multi-tenant authorization.

### Authorization

- [x] `Authorization` concern — `visible_properties`, `visible_incidents` (see ARCHITECTURE.md §Authorization)
- [x] `find_visible_incident!` / `find_visible_property!` — 404 on unauthorized
- [x] `authorize_mitigation_role!` helper
- [x] Authorization tests — cross-org isolation, technician scoping, PM scoping

### Organizations

- [x] Organizations controller + tests (see BUSINESS_RULES.md §1)
- [x] Organizations list page (see VIEWS.md §Organization List)
- [x] Organization detail page (see VIEWS.md §Organization Detail)
- [x] New organization page (see VIEWS.md §New Organization)
- [x] Edit organization

### Properties

- [x] Properties controller + tests (see BUSINESS_RULES.md §3)
- [x] Properties list page (see VIEWS.md §Property List)
- [x] Property detail page with assigned users + incidents (see VIEWS.md §Property Detail)
- [x] New property page (see VIEWS.md §New Property)
- [x] Edit property
- [x] Property assignment management — add/remove PM users

### Users

- [x] Users controller + tests (see BUSINESS_RULES.md §2)
- [x] Users list page (see VIEWS.md §User List)
- [x] User detail page (see VIEWS.md §User Detail)
- [x] User deactivation — soft delete, block login, hide from dropdowns

### Invitations

- [x] Invitation create + mailer (see BUSINESS_RULES.md §2 Invitations)
- [x] Invite User modal on users page
- [x] Accept invitation page (see VIEWS.md §Accept Invitation)
- [x] Token validation, expiry, resend
- [x] Cross-org invitations (mitigation → PM org)
- [x] Invitation tests — full flow + edge cases

**Done when:** Full CRUD for orgs, properties, users. Invite → accept → login works. PM isolation confirmed by tests.

---

## Phase 3: Incidents — Core

Incident lifecycle, dashboard, detail page, assignments.

### Incident Creation

- [x] `IncidentCreationService` + tests (see ARCHITECTURE.md §1 Incident Creation)
- [x] New incident page + controller (see VIEWS.md §New Incident)
- [x] Auto-assignment logic + tests (see BUSINESS_RULES.md §5 Auto-Assignment)

### Status Transitions

- [x] `StatusTransitionService` + tests (see ARCHITECTURE.md §3 Status Transitions)
- [x] Status change endpoint — managers only
- [x] Transition tests — every valid/invalid transition, escalation resolution

### ActivityLogger

- [x] `ActivityLogger.log` service (see ARCHITECTURE.md §ActivityLogger)

### Dashboard

- [x] `DashboardService` + controller (see ARCHITECTURE.md §5 Dashboard Queries)
- [x] Dashboard page — urgency groups, incident cards, filters (see VIEWS.md §Dashboard)
- [x] Dashboard controller tests — role-specific scoping

### Incidents List

- [x] Incidents index controller — paginated, filterable, sortable
- [x] Incidents list page (see VIEWS.md §Incidents)
- [x] Controller tests — scoping, pagination

### Incident Detail — Layout

- [x] Incident show controller — load with associations
- [x] Split-panel layout + sticky header (see VIEWS.md §Incident Detail)
- [x] Status change dropdown — managers only, valid transitions
- [x] Responsive — single column on mobile with tab bar

### Incident Detail — Left Panel

- [x] Description, cause, next steps display
- [x] Assigned team section — grouped by org (see VIEWS.md §Left Panel: Overview)
- [x] Assign/unassign users + activity events (see BUSINESS_RULES.md §5)
- [x] Contacts section — add/remove (see BUSINESS_RULES.md §5 Incident Contacts)
- [x] Quick stats (labor hours, equipment counts)

### Incident Detail — Right Panel Shell

- [x] Tab bar — Activity, Daily Log, Messages, Documents
- [x] Compose area pinned to viewport bottom on Messages tab

**Done when:** Create incident → dashboard → detail → change status → assign users → add contacts. All role scoping works.

---

## Phase 4: Incident Activity

Messages, labor, equipment, notes, attachments, daily log, documents panel.

### Messages

- [x] Messages controller + tests (see BUSINESS_RULES.md §7 Messages)
- [x] Messages panel UI — thread + compose (see VIEWS.md §Right Panel: Messages)

### Labor Entries

- [x] Labor entries controller + tests (see BUSINESS_RULES.md §9)
- [x] Add/edit labor forms — role permissions per BUSINESS_RULES.md
- [x] Activity events on create/update

### Equipment Entries

- [x] Equipment entries controller + tests (see BUSINESS_RULES.md §10)
- [x] Add/edit equipment form with type dropdown + "Other" freeform
- [x] Remove equipment (set removed_at)
- [x] Activity events on place/remove

### Operational Notes

- [x] Operational notes controller + tests (see BUSINESS_RULES.md §7 Operational Notes)
- [x] Add note form — techs + managers only

### Attachments

- [x] Attachments controller + tests (see BUSINESS_RULES.md §11)
- [x] Active Storage config — local dev, S3 production
- [x] Upload form — file, description, category, log_date
- [x] Message attachment support

### Daily Log Panel

- [x] Activity-first data model: `activity_entries` + `activity_equipment_actions`
- [x] Daily log UI — date selector, activities/labor/notes/documents (see VIEWS.md §Left Panel: Daily Log)
- [x] "All Dates" timeline mode
- [x] PM users see read-only (no add buttons except documents)

### Documents Panel

- [x] Documents panel UI — photo grid + document list (see VIEWS.md §Right Panel: Documents)
- [x] Category filter

**Done when:** Labor, equipment, notes, files, messages all work. Everything appears in daily log. Documents panel shows all attachments with filtering.

---

## Phase 5: Notifications & Escalation

Email delivery and emergency response chain.

### Email Infrastructure

- [x] Configure ActionMailer — Resend production, letter_opener_web dev (see PROJECT_SETUP.md)
- [x] Base mailer layout matching brand (see DESIGN.md)

### Notification Services

- [x] `NotificationService` SMS/voice stub for MVP (log-only)

### Transactional Emails

- [x] Incident creation confirmation email
- [x] Status change notification job + email
- [x] New message notification job + email
- [x] User assignment notification email
- [x] Tests — recipients, preference filtering, job enqueuing

### Emergency Escalation

- [x] `EscalationService` + `EscalationJob` (see ARCHITECTURE.md §2 Emergency Escalation)
- [x] `EscalationTimeoutJob` — timeout → escalate to next contact
- [x] Escalation resolution when incident marked active
- [x] Edge cases — no on-call config, list exhausted (see BUSINESS_RULES.md §6)
- [x] Escalation tests — full chain, timeout, resolution, edge cases

### On-Call Configuration

- [x] On-call settings page + controller (see VIEWS.md §On-Call)
- [x] Escalation chain — add/remove/reorder contacts

### Notification Preferences

- [x] Preference toggles on settings page
- [x] All notification jobs respect user preferences
- [x] Tests — preferences honored

**Done when:** Emails fire on correct triggers. Escalation chain works end-to-end. Preferences respected.

---

## Phase 6: Polish & Remaining Features

Complete the app for production use.

### Unread Tracking

- [x] `IncidentReadState` — lazy creation, timestamp updates on tab view (see BUSINESS_RULES.md §11)
- [x] `DashboardService#unread_counts` — bulk aggregation (see ARCHITECTURE.md §5)
- [x] Unread badges — dashboard cards, tab badges, sidebar dot
- [x] Tests — read states, count accuracy

### Daily Digest

- [x] `DailyDigestJob` — Solid Queue recurring, timezone-correct (see ARCHITECTURE.md §Background Jobs)
- [x] `DailyDigestMailer` — yesterday's activity summary per user
- [x] Tests — content, timezone, preferences

### Equipment Type Management

- [x] Equipment types page + controller (see VIEWS.md §Equipment Types)
- [x] Add, deactivate, reactivate — manager only

### Settings Page

- [x] Settings page + controller (see VIEWS.md §Profile)
- [x] Profile edit, password change, timezone picker

### Password Reset

- [x] Password reset flow — request, email, reset form, token expiry
- [x] "Forgot password?" link on login page

### Timezone Handling

- [x] `around_action :set_timezone` in ApplicationController (see ARCHITECTURE.md §Timezone Handling)
- [x] TimeFormatting helper — centralized date/time formatting

### Empty States

- [x] Empty states for all lists and panels (see VIEWS.md §Empty States)

### Phase 6A: Token Refresh (CSS-only, no component changes)

Update `application.css` tokens and global styles. Zero component code changes — the whole app gets prettier instantly.

- [x] Refresh DESIGN.md with "warm & polished" direction — new color palette, typography, shadow/depth system
- [x] Audit every page against new design tokens, document findings in `docs/UI_AUDIT.md`
- [x] Update `application.css` — new color tokens, warmer neutrals, richer shadows, refined borders
- [x] Typography refresh — font pairing, weight hierarchy, size tuning
- [x] Status color tuning — better contrast and vibrancy against warm backgrounds
- [x] Deploy and visual QA — verify token changes look good across all pages

### Phase 6B: Structural Polish (component + layout changes)

Component-level work. Only start after 6A is deployed and validated.

- [x] Replace ugly default flash messages with a polished toast/notification component
- [x] Install missing shadcn primitives: `Select`, `Textarea` (Tabs, Sheet, Dialog already existed)
- [x] Replace all raw HTML form controls (`<select>`, `<textarea>`, `<button>`) with shadcn components
- [x] Migrate all hardcoded colors (`text-blue-600`, `bg-red-50`, `bg-amber-100`, etc.) to design tokens
- [x] Convert all hand-rolled modals to shadcn Dialog (NoteForm, LaborForm, EquipmentForm, ActivityForm, IncidentEditForm, OverviewPanel)
- [x] StatusBadge uses `statusColor()` — colored badges on Users/Show and Properties/Show
- [x] Daily Log visual separation — accent headers, row hover, breathing room
- [x] Table polish — Equipment + Labor panels with `px-4 py-3` padding + hover states
- ~~Add composable layout primitives~~ — N/A: current Card + manual structure is fine
- ~~Refactor DataTable/DetailList~~ — N/A: already correct at 65 and 22 lines
- ~~Centralize statusColor + timeAgo~~ — N/A: statusColor shared, dates formatted server-side
- ~~Migrate remaining CRUD/detail pages~~ — N/A: low-traffic, working fine
- ~~Redesign on-call settings page~~ — N/A: functional, low priority
- [ ] Accessibility + polish pass: focus states, keyboard nav, contrast, tap targets, spacing consistency
- [ ] Visual QA sign-off across mobile/tablet/desktop for all six roles

### Final QA

- [ ] Loading states + user-friendly errors (see DESIGN.md §Tone & Voice)
- [ ] 404 page
- [ ] Responsive QA — mobile, tablet, desktop
- [x] E2E system tests — critical happy paths (see list below)
- [ ] Cross-browser check
- [ ] Performance testing — production-scale data (300+ properties per PM org, 1000+ incidents, 50+ users). Profile N+1 queries, pagination efficiency, index page load times, incident show with 100+ attachments

### E2E Test Paths (Capybara + Playwright)

Full test plan with 100 test cases across 8 files: see [TESTING.md §E2E Test Plan](TESTING.md#e2e-test-plan).

#### P1 — Critical (gates production, ~20 tests)

- [x] **Authentication basics** (A1–A4, A12–A13) — login all roles, logout, deactivated mid-session, return-to redirect
- [x] **Data isolation** (H1–H4) — PM cross-org incidents, PM cross-org properties, cross-org equipment, technician unassigned
- [x] **Incident creation** (C1, C3) — emergency incident (manager), standard incident (PM user)
- [x] **Status transitions** (C15–C16) — standard path, quote/proposal path
- [x] **Messages** (E1) — send message on incident
- [x] **Labor** (E4) — technician logs labor entry
- [x] **Equipment** (E9) — place equipment on incident
- [x] **Team assignment** (D1–D2) — assign mitigation user, assign PM user (own org)

#### P2 — Core Workflows (~40 tests)

- [x] **Auth extended** (A5–A11) — forgot password, reset, invitation accept/expired
- [x] **Dashboard** (B1–B3) — manager, technician, PM views
- [x] **Incident list** (C7–C13) — filters, search, sort, pagination, detail view, edit
- [x] **Daily ops** (E2, E5–E7, E12, E15–E17) — attachments, manager labor, delete, equipment removal, activity entries, notes, documents
- [x] **Team extended** (D3–D7) — PM restrictions, remove user, property assignments
- [x] **Admin CRUD** (F1, F3, F6, F9) — create org, create property, invite user, deactivate user
- [x] **Settings** (G1–G2) — update profile, change password
- [x] **Role blocking** (H5–H10) — technician/PM blocked from admin pages

#### P3 — Edge Cases (~40 tests)

- [x] **Incident edge cases** (C2, C4–C6, C14, C17–C19, C22–C23) — quote type, validation, team assignment form, technician restrictions, escalation resolution, DFR download, emergency indicators
- [x] **Daily ops edge cases** (E3, E8, E10–E11, E13–E14, E18–E20) — empty message, ownership restrictions, inventory picker, "Other" type, contacts CRUD
- [x] **Admin edge cases** (F2, F4–F5, F7–F8, F10–F22) — edit restrictions, PM org limits, resend invitation, self-deactivation blocked, equipment inventory management, on-call config
- [x] **Settings edge cases** (G3–G6) — wrong password, mismatch, preferences, read-only display
- [x] **Cross-cutting** (H11–H15, B4–B6, C20–C21) — login redirect, emergency visuals, pagination+filters, unread badge lifecycle

**Done when:** Fully usable by all six roles. No dead ends, no missing states. Ready for production.

---

## Scratchpad

> Active backlog of fixes, improvements, and features. Check off as completed. Remove if no longer needed.

### Quick Fixes

- [x] Hide dashboard from sidebar, make `/` → incidents index, redirect logged-in users away from login page
- [x] "Organizations" verbiage → "Property Management" in UI text (code/models stay same)
- [x] Modal forms: don't close when clicking outside the overlay
- [x] Equipment placed_at and removed_at: date-only inputs, remove time
- [x] PM users cannot edit incidents after creation (add permission check)
- [x] Incidents Index: separate "Unread" column from "Activity" timestamp column
- [x] Daily log activity form: default status to "Complete" instead of "Active"

### Medium

- [x] Properties Index: add organization filter dropdown for mitigation users
- [x] New Incident form: split user assignment into two selects (Mitigation Team / PM Team), PM users only see their own
- [x] Add "Job Started" status between Active and Completed — update StatusTransitionService, model constants, labels, frontend statusColor
- [x] Equipment change history: "Where is DH-042 right now?" — add last-seen/current-incident column to inventory page, per-item placement history

### Larger Features

- [x] Equipment inventory: new `equipment_items` table (belongs to equipment_type, has model name + identifier). Cascading dropdown on placement form: pick type → shows available items of that type. `equipment_entries` references specific item instead of free-text model/identifier
- [x] Camera capture + bulk photo upload — HTML5 `capture="environment"` for rear camera on mobile. Multi-file input, shared category/date, upload progress. Optimized for techs snapping 10+ photos per visit

---

## Post-MVP

Deferred features. Infrastructure is in place for all of these.

| Feature | Notes |
|---------|-------|
| Gantt chart / project timeline | Interactive incident timeline view using [SVAR React Gantt](https://svar.dev/react/gantt/) (MIT). Visualize incident phases, equipment deployments, and labor across a drag-and-drop timeline. Managers get a bird's-eye view of all active jobs. |
| Real-time updates | ActionCable / Solid Cable tables created. Add live updates. |
| SMS/voice notifications | Plug provider into `NotificationDispatchService`. |
| Equipment barcode scanning | `equipment_identifier` field exists. Add camera scan. |
| Structured moisture data | File uploads for MVP. In-app data entry post-MVP. |
| Invoicing/billing | Status fields exist. Add invoice generation. |
| Signature capture | File uploads for MVP. In-app signature pad post-MVP. |
| On-call rotation scheduling | Manual for MVP. Automated rotation post-MVP. |
| Structured daily summaries | Operational notes for MVP. Dedicated model if needed. |
| Dark mode | Design tokens are semantic — theming straightforward. |
| Mobile native app | Responsive web for MVP. Evaluate React Native / PWA. |
| OAuth / SSO | Email/password for MVP. Add if PM orgs require. |
| Analytics / reporting | Add dashboards for volume, response times, costs. |

---

## Build Principles

- **Build vertically.** One feature end-to-end (model → service → controller → page → tests) before starting the next.
- **Test as you go.** Service and controller tests alongside the code. E2E tests after each phase.
- **Authorization from day one.** Every controller action scoped from the start.
- **Seed data is your testing ground.** Keep seeds current as schema evolves.
- **Deploy early.** Get on Heroku after Phase 1. Deploy after each phase.
