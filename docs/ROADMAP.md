# Roadmap

> Build phases for Genixo Restoration MVP. Each checkbox is roughly one commit.
>
> Check items off as completed. Any developer or LLM can pick up from the last unchecked item.
>
> **The spec docs are the source of truth for what to build.** This doc is the source of truth for **build order and progress**.
>
> Specs: [SCHEMA.md](SCHEMA.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [BUSINESS_RULES.md](BUSINESS_RULES.md) · [VIEWS.md](VIEWS.md) · [DESIGN.md](DESIGN.md) · [TESTING.md](TESTING.md) · [CODE_QUALITY.md](CODE_QUALITY.md)

---

## Phase 1: Quick Fixes & Cleanup

Small independent items to polish the current app.

- [ ] **Labor edit/delete** — add "Entries" section below summary grid in `LaborPanel.tsx`:
  - Desktop (sm+): compact table — Employee | Date | Time | Hours | pencil/trash icons
  - Mobile (<sm): card stack — each entry is a card with name, hours, date, time range, edit/trash icons (no horizontal scroll)
  - Pencil opens existing `LaborForm` pre-filled (already supports `entry` prop)
  - Trash shows confirm dialog → `router.delete(entry.edit_path)`
  - Backend: `update`/`destroy` already exist — wire delete path into props, add activity logging
  - Uses `labor_entries` prop already passed to LaborPanel (currently unused)
  - Files: `LaborPanel.tsx`, `labor_entries_controller.rb`, `incidents_controller.rb` (serialize delete_path)
- [ ] **Remove DFR auto-generation from documents panel**
- [ ] **Add "Proposal" as a document category** in upload form dropdown
- [ ] **Loading states + user-friendly errors** — empty/loading/error states across all pages
- [ ] **404 page** — branded not-found page

---

## Phase 2: Greystar Seed Data & Branding

Real client data for demos and onboarding.

- [ ] **Seed Greystar construction team** (5 users with titles, phones, regions, notification prefs)
- [ ] **Client logo per PM org** — configurable logo displayed in the app (start with Greystar)
- [ ] **Show assigned Genixo team on incident detail** — needs more thought. Maybe show assigned managers on Manage tab (exclude Office/Sales roles). Needs discussion before implementing.

---

## Phase 3: Incident Creation & Auto-Assignment Rework

Biggest workflow change — how incidents get created and who gets auto-assigned.

- [ ] PM creates **emergency** → PM picks PM-side people, backend auto-assigns on-call + `auto_assign_emergencies` users
- [ ] PM creates **non-emergency** → PM picks PM-side people, backend auto-assigns on-call only
- [ ] Genixo creates incident → on-call + auto-assign users pre-selected, creator can modify
- [ ] **On-call settings**: new `auto_assign_emergencies` user list section
- [ ] Update `IncidentCreationService` + auto-assignment tests
- [ ] **Emergency auto-reply**: on-screen confirmation message
- [ ] **Non-emergency auto-reply**: "confirmation call on next business day"
- [ ] **Emergency phone number** displayed prominently in app

---

## Phase 4: Guest Incident Submission

Unauthenticated emergency requests from property managers without accounts.

- [ ] "Don't have an account?" link on login page
- [ ] Guest incident form — name, email, phone, property, description, emergency toggle
- [ ] Email domain allowlist (hardcode `@greystar.com` + others)
- [ ] Auto-recognize existing properties
- [ ] Create incident + send invitation
- [ ] Confirmation: "you will receive a call within 5-10 minutes"

---

## Phase 5: Per-Incident Notifications & Client-Facing Views

Refinement features for notification control and client-appropriate data views.

### Per-incident notification overrides

- [ ] Messages + status changes toggles per incident
- [ ] Default: inherit from global, override per-incident
- [ ] PM users control their own; mitigation controls anyone assigned
- [ ] UI: settings icon on Manage tab
- [ ] All notification jobs check per-incident override first

### Client-facing moisture view

- [ ] Client sees: initial (wet) + most recent (dry) only
- [ ] "Dry" indicator when fully dry
- [ ] Full daily readings for Genixo team only

---

## Post-MVP

Deferred features. Infrastructure is in place for all of these.

| Feature | Notes |
|---------|-------|
| External stakeholder access | Adjusters & third parties with per-incident, read-only (no messages) access |
| Messaging overhaul | Email bridge (reply-from-email), per-incident recipient config, weekly executive digest |
| Reports & data export | CSV + formatted PDF export for daily logs, readings, labor, equipment |
| Accessibility + QA pass | Focus states, keyboard nav, contrast, responsive QA, cross-browser, perf testing |
| Gantt chart / project timeline | Interactive incident timeline view using [SVAR React Gantt](https://svar.dev/react/gantt/) (MIT). Visualize incident phases, equipment deployments, and labor across a drag-and-drop timeline. |
| Visual moisture mapping | Color-coded unit floor plans with grid drawing tool. Reference Cotton's approach. |
| Real-time updates | ActionCable / Solid Cable tables created. Add live updates. |
| SMS/voice notifications | Plug provider into `NotificationDispatchService`. Required for emergency auto-reply SMS. |
| Equipment barcode scanning | `equipment_identifier` field exists. Add camera scan. |
| Invoicing/billing | Status fields exist. Add invoice generation. |
| Signature capture | File uploads for MVP. In-app signature pad post-MVP. |
| On-call rotation scheduling | Manual for MVP. Automated rotation post-MVP. |
| Dark mode | Design tokens are semantic — theming straightforward. |
| OAuth / SSO | Email/password for MVP. Add if PM orgs require. |
| Analytics / reporting | Add dashboards for volume, response times, costs. |
| Mobile app (PWA or React Native) | Persistent login, push notifications, tablet support for moisture mapping. Top priority per Greystar. |
| DFR formatting | Dress up daily field report PDF — reference Cotton's format for a more professional look |

---

## Build Principles

- **Build vertically.** One feature end-to-end (model → service → controller → page → tests) before starting the next.
- **Test as you go.** Service and controller tests alongside the code. E2E tests after each phase.
- **Authorization from day one.** Every controller action scoped from the start.
- **Seed data is your testing ground.** Keep seeds current as schema evolves.
- **Deploy early.** Get on Heroku after Phase 1. Deploy after each phase.

---

## Archived

> Completed phases and scratchpad items preserved for reference.

<details>
<summary>Phase 1: Foundation (completed)</summary>

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

</details>

<details>
<summary>Phase 2: Core Data Management (completed)</summary>

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

</details>

<details>
<summary>Phase 3: Incidents — Core (completed)</summary>

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

</details>

<details>
<summary>Phase 4: Incident Activity (completed)</summary>

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

</details>

<details>
<summary>Phase 5: Notifications & Escalation (completed)</summary>

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

</details>

<details>
<summary>Phase 6: Polish & Remaining Features (completed)</summary>

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

### Phase 6A: Token Refresh

- [x] Refresh DESIGN.md with "warm & polished" direction — new color palette, typography, shadow/depth system
- [x] Audit every page against new design tokens, document findings in `docs/UI_AUDIT.md`
- [x] Update `application.css` — new color tokens, warmer neutrals, richer shadows, refined borders
- [x] Typography refresh — font pairing, weight hierarchy, size tuning
- [x] Status color tuning — better contrast and vibrancy against warm backgrounds
- [x] Deploy and visual QA — verify token changes look good across all pages

### Phase 6B: Structural Polish

- [x] Replace ugly default flash messages with a polished toast/notification component
- [x] Install missing shadcn primitives: `Select`, `Textarea` (Tabs, Sheet, Dialog already existed)
- [x] Replace all raw HTML form controls with shadcn components
- [x] Migrate all hardcoded colors to design tokens
- [x] Convert all hand-rolled modals to shadcn Dialog
- [x] StatusBadge uses `statusColor()` — colored badges on Users/Show and Properties/Show
- [x] Daily Log visual separation — accent headers, row hover, breathing room
- [x] Table polish — Equipment + Labor panels with `px-4 py-3` padding + hover states

### E2E Tests

- [x] P1 — Critical (~20 tests): auth, data isolation, incident creation, status transitions, messages, labor, equipment, team assignment
- [x] P2 — Core Workflows (~40 tests): auth extended, dashboard, incident list, daily ops, team extended, admin CRUD, settings, role blocking
- [x] P3 — Edge Cases (~40 tests): incident edge cases, daily ops edge cases, admin edge cases, settings edge cases, cross-cutting

</details>

<details>
<summary>Completed scratchpad items</summary>

- [x] Hide dashboard from sidebar, make `/` → incidents index
- [x] "Organizations" verbiage → "Property Management"
- [x] Modal forms: don't close when clicking outside
- [x] Equipment placed_at/removed_at: date-only inputs
- [x] PM users cannot edit incidents after creation
- [x] Incidents Index: separate "Unread" from "Activity" column
- [x] Daily log activity form: default status "Complete"
- [x] Properties Index: org filter dropdown
- [x] New Incident form: split Mitigation/PM team selects
- [x] "Job Started" status between Active and Completed
- [x] Equipment change history + inventory tracking
- [x] Equipment inventory with cascading dropdowns
- [x] Camera capture + bulk photo upload
- [x] Moisture readings — in-app structured tracking with inline editing, batch recording, copy from previous
- [x] Psychrometric readings — in-app tracking with inline editing, GPP auto-calculation, G-Dep, batch recording
- [x] Manage tab: clarify "PM Manager" vs "Property Manager" role labels — renamed `pm_manager` → `other`
- [x] Remove daily digest email notification — job disabled, removed from settings UI
- [x] Status change notifications off by default for all users
- [x] Merge incident creation + assignment notifications into one — `incident_user_assignment`
- [x] Add `title` string column to users (display-only, shown on profiles and team lists)
- [x] Add title field to invite/create user forms

</details>
