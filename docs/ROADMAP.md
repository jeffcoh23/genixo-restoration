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

- [ ] `Current` model, `SessionsController`, `require_authentication` (see playbook auth.md)
- [ ] Login page (see VIEWS.md §Login)
- [ ] Redirect logic — dashboard on success, login when unauthenticated
- [ ] Block deactivated users from logging in

### App Shell

- [ ] `AppLayout.tsx` — sidebar + content area (see VIEWS.md §Layout)
- [ ] `RoleSidebar.tsx` — role-aware nav links (see VIEWS.md §Sidebar Links by Role)
- [ ] Responsive sidebar — fixed desktop, hamburger mobile
- [ ] Shared Inertia data — auth user + routes (see ARCHITECTURE.md §Inertia Shared Data)
- [ ] Flash message component
- [ ] Placeholder pages for all routes

**Done when:** Log in as any seed user, see correct sidebar for their role, navigate between placeholder pages.

---

## Phase 2: Core Data Management

Orgs, properties, users, invitations. Multi-tenant authorization.

### Authorization

- [ ] `Authorization` concern — `visible_properties`, `visible_incidents` (see ARCHITECTURE.md §Authorization)
- [ ] `find_visible_incident!` / `find_visible_property!` — 404 on unauthorized
- [ ] `authorize_mitigation_role!` helper
- [ ] Authorization tests — cross-org isolation, technician scoping, PM scoping

### Organizations

- [ ] Organizations controller + tests (see BUSINESS_RULES.md §1)
- [ ] Organizations list page (see VIEWS.md §Organization List)
- [ ] Organization detail page (see VIEWS.md §Organization Detail)
- [ ] New organization page (see VIEWS.md §New Organization)
- [ ] Edit organization

### Properties

- [ ] Properties controller + tests (see BUSINESS_RULES.md §3)
- [ ] Properties list page (see VIEWS.md §Property List)
- [ ] Property detail page with assigned users + incidents (see VIEWS.md §Property Detail)
- [ ] New property page (see VIEWS.md §New Property)
- [ ] Edit property
- [ ] Property assignment management — add/remove PM users

### Users

- [ ] Users controller + tests (see BUSINESS_RULES.md §2)
- [ ] Users list page (see VIEWS.md §User List)
- [ ] User detail page (see VIEWS.md §User Detail)
- [ ] User deactivation — soft delete, block login, hide from dropdowns

### Invitations

- [ ] Invitation create + mailer (see BUSINESS_RULES.md §2 Invitations)
- [ ] Invite User modal on users page
- [ ] Accept invitation page (see VIEWS.md §Accept Invitation)
- [ ] Token validation, expiry, resend
- [ ] Cross-org invitations (mitigation → PM org)
- [ ] Invitation tests — full flow + edge cases

**Done when:** Full CRUD for orgs, properties, users. Invite → accept → login works. PM isolation confirmed by tests.

---

## Phase 3: Incidents — Core

Incident lifecycle, dashboard, detail page, assignments.

### Incident Creation

- [ ] `IncidentCreationService` + tests (see ARCHITECTURE.md §1 Incident Creation)
- [ ] New incident page + controller (see VIEWS.md §New Incident)
- [ ] Auto-assignment logic + tests (see BUSINESS_RULES.md §5 Auto-Assignment)

### Status Transitions

- [ ] `StatusTransitionService` + tests (see ARCHITECTURE.md §3 Status Transitions)
- [ ] Status change endpoint — managers only
- [ ] Transition tests — every valid/invalid transition, escalation resolution

### ActivityLogger

- [ ] `ActivityLogger.log` service (see ARCHITECTURE.md §ActivityLogger)

### Dashboard

- [ ] `DashboardService` + controller (see ARCHITECTURE.md §5 Dashboard Queries)
- [ ] Dashboard page — urgency groups, incident cards, filters (see VIEWS.md §Dashboard)
- [ ] Dashboard controller tests — role-specific scoping

### Incidents List

- [ ] Incidents index controller — paginated, filterable, sortable
- [ ] Incidents list page (see VIEWS.md §Incidents)
- [ ] Controller tests — scoping, pagination

### Incident Detail — Layout

- [ ] Incident show controller — load with associations
- [ ] Split-panel layout + sticky header (see VIEWS.md §Incident Detail)
- [ ] Status change dropdown — managers only, valid transitions
- [ ] Responsive — single column on mobile with tab bar

### Incident Detail — Left Panel

- [ ] Description, cause, next steps display
- [ ] Assigned team section — grouped by org (see VIEWS.md §Left Panel: Overview)
- [ ] Assign/unassign users + activity events (see BUSINESS_RULES.md §5)
- [ ] Contacts section — add/remove (see BUSINESS_RULES.md §5 Incident Contacts)
- [ ] Quick stats (labor hours, equipment counts)

### Incident Detail — Right Panel Shell

- [ ] Tab bar — Messages, Daily Log, Documents
- [ ] Compose area pinned to viewport bottom on Messages tab

**Done when:** Create incident → dashboard → detail → change status → assign users → add contacts. All role scoping works.

---

## Phase 4: Incident Activity

Messages, labor, equipment, notes, attachments, daily log, documents panel.

### Messages

- [ ] Messages controller + tests (see BUSINESS_RULES.md §7 Messages)
- [ ] Messages panel UI — thread + compose (see VIEWS.md §Right Panel: Messages)

### Labor Entries

- [ ] Labor entries controller + tests (see BUSINESS_RULES.md §8)
- [ ] Add/edit labor forms — role permissions per BUSINESS_RULES.md
- [ ] Activity events on create/update

### Equipment Entries

- [ ] Equipment entries controller + tests (see BUSINESS_RULES.md §9)
- [ ] Add equipment form with type dropdown + "Other" freeform
- [ ] Remove equipment (set removed_at)
- [ ] Activity events on place/remove

### Operational Notes

- [ ] Operational notes controller + tests (see BUSINESS_RULES.md §7 Operational Notes)
- [ ] Add note form — techs + managers only

### Attachments

- [ ] Attachments controller + tests (see BUSINESS_RULES.md §10)
- [ ] Active Storage config — local dev, S3 production
- [ ] Upload form — file, description, category, log_date
- [ ] Message attachment support

### Daily Log Panel

- [ ] `DailyActivityService` (see ARCHITECTURE.md §4 Day-by-Day Activity)
- [ ] Daily log UI — date selector, all sections (see VIEWS.md §Right Panel: Daily Log)
- [ ] "All Dates" timeline mode
- [ ] PM users see read-only (no add buttons except documents)

### Documents Panel

- [ ] Documents panel UI — photo grid + document list (see VIEWS.md §Right Panel: Documents)
- [ ] Category filter

**Done when:** Labor, equipment, notes, files, messages all work. Everything appears in daily log. Documents panel shows all attachments with filtering.

---

## Phase 5: Notifications & Escalation

Email delivery and emergency response chain.

### Email Infrastructure

- [ ] Configure ActionMailer — Resend production, letter_opener_web dev (see PROJECT_SETUP.md)
- [ ] Base mailer layout matching brand (see DESIGN.md)

### Notification Services

- [ ] `NotificationDispatchService` (see ARCHITECTURE.md §Notification Architecture)
- [ ] SMS/voice stub provider for MVP (log-only)

### Transactional Emails

- [ ] Incident creation confirmation email
- [ ] Status change notification job + email
- [ ] New message notification job + email
- [ ] Technician assignment notification email
- [ ] Tests — recipients, preference filtering, job enqueuing

### Emergency Escalation

- [ ] `EscalationService` + `EscalationJob` (see ARCHITECTURE.md §2 Emergency Escalation)
- [ ] `EscalationTimeoutJob` — timeout → escalate to next contact
- [ ] Escalation resolution when incident marked active
- [ ] Edge cases — no on-call config, list exhausted (see BUSINESS_RULES.md §6)
- [ ] Escalation tests — full chain, timeout, resolution, edge cases

### On-Call Configuration

- [ ] On-call settings page + controller (see VIEWS.md §On-Call)
- [ ] Escalation chain — add/remove/reorder contacts

### Notification Preferences

- [ ] Preference toggles on settings page
- [ ] All notification jobs respect user preferences
- [ ] Tests — preferences honored

**Done when:** Emails fire on correct triggers. Escalation chain works end-to-end. Preferences respected.

---

## Phase 6: Polish & Remaining Features

Complete the app for production use.

### Unread Tracking

- [ ] `IncidentReadState` — lazy creation, timestamp updates on tab view (see BUSINESS_RULES.md §11)
- [ ] `DashboardService#unread_counts` — bulk aggregation (see ARCHITECTURE.md §5)
- [ ] Unread badges — dashboard cards + sidebar dot
- [ ] Tests — read states, count accuracy

### Daily Digest

- [ ] `DailyDigestJob` — Solid Queue recurring, timezone-correct (see ARCHITECTURE.md §Background Jobs)
- [ ] `DailyDigestMailer` — yesterday's activity summary per user
- [ ] Tests — content, timezone, preferences

### Equipment Type Management

- [ ] Equipment types page + controller (see VIEWS.md §Equipment Types)
- [ ] Add, deactivate, reactivate — manager only

### Settings Page

- [ ] Settings page + controller (see VIEWS.md §Profile)
- [ ] Profile edit, password change, timezone picker, notification toggles

### Password Reset

- [ ] Password reset flow — request, email, reset form, token expiry
- [ ] "Forgot password?" link on login page

### Timezone Handling

- [ ] `around_action :set_timezone` in ApplicationController (see ARCHITECTURE.md §Timezone Handling)
- [ ] Frontend timestamp formatting helper

### Empty States

- [ ] Empty states for all lists and panels (see VIEWS.md §Empty States)

### Final QA

- [ ] Loading states + user-friendly errors (see DESIGN.md §Tone & Voice)
- [ ] 404 page
- [ ] Responsive QA — mobile, tablet, desktop
- [ ] E2E system tests — critical happy paths
- [ ] Cross-browser check

**Done when:** Fully usable by all six roles. No dead ends, no missing states. Ready for production.

---

## Post-MVP

Deferred features. Infrastructure is in place for all of these.

| Feature | Notes |
|---------|-------|
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
