# Testing Guidelines

> Principles for writing excellent tests. Referenced during development — read this before writing your first test, revisit when something feels wrong.

---

## Testing Layers

| Layer | Tool | Purpose | Volume |
|-------|------|---------|--------|
| **Services + Models** | Minitest | Business logic, validations, scopes | Heavy |
| **Controllers** | Minitest + Inertia helpers | Authorization scoping, correct component/props per role | Heavy |
| **E2E (System)** | Capybara + Playwright | Critical happy paths in a real browser | Light |

**Test at the lowest possible layer.** If you can verify it in a service test, don't write a controller test. If you can verify it in a controller test, don't write a browser test. Higher layers are slower, flakier, and harder to debug.

---

## Principles

### Test the contract, not the implementation

Assert what happens (output, side effects, state changes), not how it happens internally. Tests that verify method calls or internal ordering break on every refactor and provide zero confidence.

### Name tests like sentences

`test "deactivated user cannot log in"` not `test_auth_edge_case_4`. Someone should be able to read test names alone and understand every behavior the system supports.

### Every bug gets a regression test

Before you fix a bug, write a test that reproduces it. Watch it fail. Fix the code. Watch it pass. This is the single highest-ROI testing practice — it guarantees the same bug never ships twice.

### Don't test the framework

Rails already tests that `validates :name, presence: true` works. Test your business rules — the things that are unique to your domain and would break if someone changed them.

### Cover the sad paths

Happy paths are obvious and rarely where bugs live. The real value is in: invalid inputs, unauthorized access, state transitions that shouldn't be allowed, empty collections, nil values, and race conditions.

### Tests are documentation

A new developer should be able to read your test file and understand what the feature does, what the edge cases are, and what's not allowed — without reading the implementation.

### Arrange-Act-Assert, always

Setup the world, do the thing, check the result. One concept per test. If a test fails, you should know exactly what broke from the test name alone.

### Flaky tests are worse than no tests

A test that passes 95% of the time erodes trust in the entire suite. People stop running tests. Fix flaky tests immediately or delete them. Never skip them.

---

## Multi-Tenant Testing

### Always test isolation

Every query that touches scoped data should have a test proving org A cannot see org B's data. This is a security test, not a feature test — treat it accordingly.

### Fixtures should represent the tenant model

Create fixtures that exercise the full hierarchy: multiple orgs, users of each type in each org, properties across different PM orgs, incidents at various statuses. The fixture set should make cross-tenant bugs impossible to miss.

---

## State Machine Testing

### Test the matrix

Test every valid transition works. Test every invalid transition raises. This is one place where exhaustive testing pays for itself — status bugs are expensive and hard to catch in production.

### Test side effects of transitions

A status change doesn't just update a column. It creates activity events, sends notifications, resolves escalations. Test that the full chain fires correctly for each transition.

---

## Authorization Testing

### Test at the controller boundary

Use Inertia test helpers (`assert_inertia_component`, `assert_inertia_props`) to verify each role receives exactly the right component with exactly the right data. Authorization failures should return 404 (not 403) — test for that.

### Test every role

With six user types across two org types, the permission matrix is complex. Each controller action should have tests for: roles that can access it, roles that can't, and roles that can access it but with scoped-down data.

---

## Mocking & Stubbing

### Mock your interfaces, not third-party code

Stub `NotificationDispatchService`, not `Twilio::Client`. If you mock what you don't own, your tests pass while production breaks.

### Prefer real objects when possible

Only stub external services (notification providers, email delivery) and slow dependencies. Let models, services, and database interactions run for real — that's the whole point of the test.

---

## E2E / System Tests

### Playwright over Selenium

We use `capybara-playwright-driver` — same Capybara DSL, but Playwright under the hood. Dramatically more reliable with Inertia/React SPAs.

### Keep E2E tests focused

Each system test should cover one complete user flow (login, do the thing, verify the result). Don't chain multiple features into mega-tests — when they fail, you can't tell what broke.

### E2E is for JavaScript-dependent flows

If a behavior can be verified without rendering React components, test it at the controller layer instead. Reserve browser tests for multi-step interactions that require real JS execution.

---

## E2E Test Plan

> Comprehensive catalog of every user flow that needs browser-level E2E coverage. Organized by feature group with build priority.
>
> **Current state (February 21, 2026):** `test/system/` has 7 files. Two new files were added (`incident_panels_test.rb`, `user_profile_test.rb`) and need a full run.

### Priority Guide

| Priority | Criteria | When to write |
|----------|----------|---------------|
| **P1 — Critical** | Auth, data isolation, primary value flows | First — gates production |
| **P2 — Core** | Standard CRUD, dashboard, team management | After P1 passes |
| **P3 — Edge** | Role restrictions, form validation, UI states | After P2 passes |

---

### Current Coverage Snapshot (February 21, 2026)

| File | Tests | Current Status |
|------|-------|----------------|
| `test/system/authentication_test.rb` | 8 | Passing |
| `test/system/incidents_test.rb` | 4 | Failing after UI refactor (selectors + status UI expectations) |
| `test/system/team_management_test.rb` | 2 | Failing after Manage tab interaction changes |
| `test/system/daily_operations_test.rb` | 3 | One failing due ambiguous selectors |
| `test/system/security_test.rb` | 4 | Failing because assertions expect static 404 copy but test env renders exception details |
| `test/system/incident_panels_test.rb` | 3 | New coverage: incident tab order + messages/photos controls |
| `test/system/user_profile_test.rb` | 2 | New coverage: user edit modal open/cancel/save flows |

Latest full local run (before adding new files): `21 runs, 57 assertions, 5 failures, 6 errors`.

### Immediate E2E Maintenance (P0)

1. Add stable selectors (`data-testid`) for key interaction points: incident create property picker, status transition control, assign-user controls, and labor/equipment add actions.
2. Update tests to use current tab structure and button labels (Manage, Documents, Photos, Messages).
3. Replace brittle text-only 404 assertions with assertions that survive exception rendering mode in system tests.
4. Fix ambiguous selectors in modals (`Add Labor`, assign dropdown options) by scoping to dialog containers.
5. Keep CI Playwright install/version wiring in sync with `playwright-ruby-client` before running `test:system`.

---

### A. Authentication (file: `test/system/authentication_test.rb`)

| ID | Test | Roles | Flow | Verify |
|----|------|-------|------|--------|
| A1 | Login happy path | Manager, Technician, PM user | `/login` → enter credentials → submit | Redirected to incidents; welcome notice; correct sidebar nav for role |
| A2 | Login — deactivated account | Any deactivated | Submit valid credentials | Alert shown; still on login page; no session |
| A3 | Login — invalid credentials | Any | Wrong password or nonexistent email | Alert; stays on login page |
| A4 | Logout | Any | Click logout in sidebar | Redirect to login; session destroyed; subsequent visit → login |
| A5 | Forgot password | Any | "Forgot password?" → enter email → submit | Success message shown (even for nonexistent email — no enumeration) |
| A6 | Password reset — valid token | Any | Visit reset URL → new password + confirm → submit | Redirect to login with success notice |
| A7 | Password reset — expired token | Any | Visit expired/invalid token URL | Redirect to forgot-password with alert |
| A8 | Password reset — mismatch | Any | New password ≠ confirmation | Error on form; password unchanged |
| A9 | Invitation accept — happy path | New user | `/invitations/:token` → pre-filled email/org → fill name + password → submit | Account created; logged in; redirected to dashboard |
| A10 | Invitation — already accepted | Any | Visit already-accepted token URL | Redirect to login with alert |
| A11 | Invitation — expired | Any | Visit expired token URL | Expired page rendered |
| A12 | Deactivated user mid-session | Any | Log in → admin deactivates → next request | Session terminated; redirect to login |
| A13 | Unauthenticated redirect + return-to | Anonymous | Visit `/incidents/:id` → redirect to login → log in | Return to original incident URL |

**Priority:** A1–A4, A12, A13 = P1. A5–A11 = P2.

---

### B. Dashboard (file: `test/system/dashboard_test.rb`)

| ID | Test | Roles | Flow | Verify |
|----|------|-------|------|--------|
| B1 | Manager dashboard | Manager | Login → view `/` | All 5 groups visible; "Create Request" button shown; incident cards with property, status, badges |
| B2 | Technician dashboard | Technician | Login → view `/` | Only assigned incidents; no "Create Request" button; limited sidebar |
| B3 | PM user dashboard | Property_Manager | Login → view `/` | Only incidents for assigned properties |
| B4 | Empty state | New user (no incidents) | Login → view `/` | "No incidents" message; "Create your first incident" link if permitted |
| B5 | Unread badges | Any | Another user sends message → current user views dashboard | Blue (messages) or amber (activity) badge on incident card |
| B6 | Group collapse/expand | Any | Click group header | Group toggles; only groups with incidents shown |

**Priority:** B1–B3 = P2. B4–B6 = P3.

---

### C. Incident Lifecycle (file: `test/system/incidents_test.rb`)

| ID | Test | Roles | Flow | Verify |
|----|------|-------|------|--------|
| C1 | Create emergency incident | Manager | "Create Request" → select property → "Emergency Response" → fill form → submit | Status = "acknowledged"; emergency warning shown; escalation triggered; auto-assignments populated |
| C2 | Create quote incident | Manager | Select "Mitigation RFQ" → submit | Status = "proposal_requested" |
| C3 | Create incident — PM user | Property_Manager | Login → "Create Request" → only sees assigned properties → submit | Incident created; mitigation managers auto-assigned |
| C4 | Create incident — validation errors | Manager | Submit without required fields | Inline errors; stays on form |
| C5 | Create with team assignment | Manager | Select property → auto-checked users → uncheck some → submit | Assignments match selections |
| C6 | Create with contacts | Manager | Add contact rows → submit | Contacts shown on incident show page |
| C7 | Filter by status | Manager | Incidents index → select statuses → apply | Table shows only matching; URL params preserved |
| C8 | Filter by property | Manager | Select property filter | Only incidents for that property |
| C9 | Search | Manager | Type in search → submit | Matches by description or property name |
| C10 | Sort columns | Manager | Click column headers | Re-orders; toggle direction on second click |
| C11 | Pagination | Manager (25+ incidents) | Navigate to page 2 | Correct page; controls update |
| C12 | View incident detail | Manager | Click incident → Overview tab | All fields shown: description, cause, project type, property, team |
| C13 | Edit incident | Manager | Click Edit → modify description → save | Updated; notice shown |
| C14 | Technician cannot edit | Technician | View assigned incident | No edit button; direct PATCH → 404 |
| C15 | Status transition — standard | Manager | Open status dropdown → select valid next status | Status updates; activity logged; notification fired |
| C16 | Status transition — quote path | Manager | proposal_requested → proposal_submitted → proposal_signed → active | Each step works in sequence; can't skip |
| C17 | Status transition — invalid rejected | Manager | Attempt invalid transition | Alert; status unchanged |
| C18 | Status transition — non-manager blocked | Technician | Direct PATCH to transition endpoint | 404 |
| C19 | Status transition resolves escalation | Manager | Emergency with open escalation → transition to "active" | Escalation events resolved |
| C20 | Mark read — messages tab | Any | Open incident with unread messages → Messages tab | Badge clears |
| C21 | Mark read — activity tab | Any | Open incident with unread activity → Daily Log tab | Badge clears |
| C22 | DFR PDF download | Any | Click DFR download button | PDF downloads with correct filename |
| C23 | Emergency visual distinction | Manager | View incident list with emergency incident in new/acknowledged | Red highlight; "Emergency" badge instead of status label |

**Priority:** C1, C3, C15, C16 = P1. C7–C13, C20–C21 = P2. C2, C4–C6, C14, C17–C19, C22–C23 = P3.

---

### D. Team Management (file: `test/system/team_management_test.rb`)

| ID | Test | Roles | Flow | Verify |
|----|------|-------|------|--------|
| D1 | Assign mitigation user | Manager | Incident → Mitigation Team → add user | User in list; activity logged; notification sent |
| D2 | Assign PM user (own org) | Property_Manager | Incident → PM Team → add PM user | Only own-org users available |
| D3 | PM cannot assign mitigation users | Property_Manager | Direct POST with mitigation user_id | 404 |
| D4 | Remove user from incident | Manager | Click Remove on team member | Removed; activity logged |
| D5 | PM cannot remove mitigation user | Property_Manager | Attempt remove mitigation team member | 404 |
| D6 | Assign user to property | Manager | Property → assign PM user | User added to assigned list |
| D7 | Remove user from property | Manager | Click Remove on property assignment | Assignment removed |

**Priority:** D1–D2 = P1. D3–D7 = P2.

---

### E. Daily Operations (file: `test/system/daily_operations_test.rb`)

| ID | Test | Roles | Flow | Verify |
|----|------|-------|------|--------|
| E1 | Send message | Any | Incident → Messages → type → send | Message in thread; timestamp shown |
| E2 | Send message with attachment | Any | Attach file + type message → send | Message + file stored; visible in thread |
| E3 | Empty message rejected | Any | Submit empty body | Alert; message not sent |
| E4 | Log labor — technician (self) | Technician | Incident → Labor → fill form → submit | Entry created with user = self |
| E5 | Log labor — manager (any user) | Manager | Select different user from dropdown → submit | Entry with specified user; hours calculated |
| E6 | Edit own labor entry | Technician | Click edit → change hours → save | Updated; activity logged |
| E7 | Delete labor entry | Manager | Click delete on entry | Removed; activity logged |
| E8 | Technician cannot edit other's labor | Technician | PATCH entry not created by self | 404 |
| E9 | Place equipment | Manager | Equipment tab → Place → select type → submit | Entry created; activity logged |
| E10 | Place equipment — inventory picker | Manager | Select type → pick specific item from inventory | Identifier + model auto-populated |
| E11 | Place equipment — "Other" type | Technician | Select "Other" → enter custom type | Entry with `equipment_type_other` set |
| E12 | Remove equipment | Manager | Click Remove on active entry | `removed_at` set; activity logged |
| E13 | Edit equipment entry | Manager | Edit equipment location/dates | Updated; activity logged |
| E14 | Technician cannot edit other's equipment | Technician | PATCH entry not created by self | 404 |
| E15 | Log activity entry with equipment actions | Manager | Daily Log → "Log Activity" → fill + add equipment actions → submit | Entry + actions created; equipment summary updated |
| E16 | Add operational note | Technician | Daily Log → Add Note → fill text + date → submit | Note in daily log; activity logged |
| E17 | Upload document | Any | Documents tab → upload file with category → submit | File stored; in document list; activity logged |
| E18 | Add incident contact | Manager | Incident → Contacts → add name/email/phone → submit | Contact added; activity logged |
| E19 | Update incident contact | Manager | Edit existing contact fields | Updated |
| E20 | Remove incident contact | Manager | Click remove on contact | Removed; activity logged |

**Priority:** E1, E4, E9 = P1. E2, E5–E7, E12, E15–E17 = P2. E3, E8, E10–E11, E13–E14, E18–E20 = P3.

---

### F. Admin Operations (file: `test/system/admin_operations_test.rb`)

| ID | Test | Roles | Flow | Verify |
|----|------|-------|------|--------|
| F1 | Create PM organization | Manager | Organizations → New → fill fields → submit | Created; type = property_management |
| F2 | Edit PM organization | Manager | Organization show → Edit → modify → save | Updated |
| F3 | Create property | Manager | Properties → New → fill name/org/address → submit | Created; mitigation_org = current user's org |
| F4 | Edit property — mitigation admin | Manager | Edit → change PM org → save | PM org updated |
| F5 | Edit property — PM cannot change org | Property_Manager | Edit property → org field disabled | Org change stripped from params |
| F6 | Invite user — own org | Manager | Users → Invite → fill email/role → send | Invitation created; email sent; pending in list |
| F7 | Invite user — to PM org | Manager | Users → select PM org → PM role → send | Invitation for PM org created |
| F8 | Resend invitation | Manager | Click Resend on pending invitation | Token reset; email resent |
| F9 | Deactivate user | Manager | Users → user → Deactivate | Deactivated; next login blocked |
| F10 | Cannot deactivate self | Manager | View own profile | Button disabled or blocked |
| F11 | Reactivate user | Manager | Deactivated users → Reactivate | User can log in again |
| F12 | Add equipment item | Manager | Equipment → Add Item → type/identifier → save | Item in inventory table |
| F13 | Edit equipment item inline | Manager | Click pencil → edit → Save | Row updates |
| F14 | Deactivate equipment item | Manager | Click Remove on item | Item active=false |
| F15 | Add equipment type | Manager | Manage Types → Add Type → name → submit | Type in list; available in forms |
| F16 | Deactivate equipment type | Manager | Manage Types → Deactivate | Type inactive; not selectable |
| F17 | Reactivate equipment type | Manager | Manage Types → Reactivate | Type active again |
| F18 | Equipment placement history | Manager | Equipment index → click identifier | Sheet shows deployment timeline |
| F19 | Configure on-call primary + timeout | Manager | Settings → On-Call → select primary → set timeout → save | Configuration created/updated |
| F20 | Add escalation contact | Manager | On-Call → add contact | Contact at bottom of chain |
| F21 | Reorder escalation chain | Manager | Click up/down arrows | Position updated; UI reflects |
| F22 | Remove escalation contact | Manager | Click trash on contact | Removed; remaining reordered |

**Priority:** F1, F3, F6, F9 = P2. Everything else = P3.

---

### G. Settings & Profile (file: `test/system/settings_test.rb`)

| ID | Test | Roles | Flow | Verify |
|----|------|-------|------|--------|
| G1 | Update profile | Any | Settings → change name/email/timezone → Save | Fields updated; timezone affects display |
| G2 | Change password — happy path | Any | Settings → current password + new password → submit | Password updated; success notice |
| G3 | Change password — wrong current | Any | Enter incorrect current password | Error "is incorrect" |
| G4 | Change password — mismatch | Any | New ≠ confirmation | Error "doesn't match" |
| G5 | Notification preferences | Any | Toggle checkboxes → save | Preferences persisted (reload confirms) |
| G6 | Role/org display read-only | Any | Navigate to settings | Role label + org name shown; not editable |

**Priority:** G1–G2 = P2. G3–G6 = P3.

---

### H. Cross-Cutting & Security (file: `test/system/security_test.rb`)

| ID | Test | Roles | Flow | Verify |
|----|------|-------|------|--------|
| H1 | PM cross-org incident isolation | PM user (Org A) | GET `/incidents/:id` for Org B's incident | 404 |
| H2 | PM cross-org property isolation | PM user | GET `/properties/:id` for unassigned property | 404 |
| H3 | Cross-org equipment isolation | Manager | PATCH equipment item from another mitigation org | 404 |
| H4 | Technician unassigned incident | Technician | GET `/incidents/:id` (not assigned) | 404 |
| H5 | Technician cannot create incident | Technician | GET `/incidents/new` | 404 |
| H6 | PM_Manager cannot create incident | PM_Manager | GET `/incidents/new` | 404 |
| H7 | Non-manager blocked from on-call | Technician, PM user | GET `/settings/on-call` | 404 |
| H8 | Non-manager blocked from equipment inventory | Technician, PM user | GET `/equipment-items` | 404 |
| H9 | Non-manager blocked from organizations | Technician, PM user | GET `/organizations` | 404 |
| H10 | Non-manager blocked from user management | Technician, PM user | GET `/users` | 404 |
| H11 | Authenticated user redirected from login | Any | Visit `/login` while logged in | Redirect to incidents |
| H12 | Emergency visual indicators | Any | View emergency incident in new/acknowledged status | Red highlight; "Emergency" badge; AlertTriangle icon |
| H13 | Pagination preserves filters | Manager | Apply status filter → page 2 | Both filter + page in URL; preserved on reload |
| H14 | Technician labor auto-assigned to self | Technician | POST labor with another user's ID | user_id stripped; entry created with own user |
| H15 | Invitation cross-org targeting | Manager | Invite to serviced PM org vs. unrelated PM org | Serviced: works. Unrelated: not available |

**Priority:** H1–H4 = P1. H5–H10 = P2. H11–H15 = P3.

---

### I. Recent Refactor Coverage (new)

| ID | Test | Roles | Flow | Verify |
|----|------|-------|------|--------|
| I1 | Incident tab order remains fixed | Any | Incident show page | Tab order is stable and does not regress after UI refactors |
| I2 | Activity badge only tracks daily log activity entries | Any | Create message/labor/equipment vs daily activity entry | Daily Log unread badge increments only for `activity_logged` events |
| I3 | Photos panel includes incident + message image attachments | Any | Upload photo in Photos tab + send image in Messages | Both appear in Photos library with source marker |
| I4 | Photos filters work at scale | Any | Seed large photo set, filter by search/uploader/date, load more | Correct subset shown and pagination batch increases deterministically |
| I5 | Photo upload actions preserve scroll/state | Any | Upload Photos and Take Photos actions | Panel updates without full-page jump/reset |
| I6 | Documents grouped by type + ordered + paged | Any | Upload mixed categories, browse with filters | Group ordering and per-type ordering are correct; load-more works |
| I7 | Messages allow attachment-only send | Any | Send message with file but empty body | Message persists and renders attachments in thread |
| I8 | Manage tab assignment flows remain operable | Manager, PM user | Assign mitigation and PM-side users from Manage | Assignment succeeds; role scoping enforced |
| I9 | User edit is modal and permission-scoped | Manager, non-manager | Open User page and edit self/others | Mitigation manager can edit others; everyone else can edit self only |
| I10 | User role field locking rules | Manager, non-manager | Open edit modal for self/other | Only allowed editors can change role; restricted users see locked role control |

**Priority:** I2, I8, I9 = P1. I3–I7, I10 = P2. I1 = P3.

---

### Build Order

Write E2E tests in this order — each group builds on the previous:

1. **Repair current failures first** (P0 maintenance above) — keep the suite trusted
2. **Auth basics** (A1–A4, A12–A13) — can't test anything else without login working
3. **Data isolation** (H1–H4) — security gates production
4. **Incident create + status** (C1, C3, C15–C16) — primary value loop
5. **Daily ops core + refactor criticals** (E1, E4, E9, I2, I8, I9)
6. **Dashboard + list + media browsing** (B1–B3, C7–C13, I3–I7)
7. **Admin CRUD** (F1, F3, F6, F9) — org, property, user management
8. **Settings** (G1–G2) — profile and password
9. **Remaining P2 + P3** — edge cases, validation, role restrictions

### Test File Organization

```
test/system/
├── authentication_test.rb    # A1–A13
├── incidents_test.rb         # C1–C23
├── team_management_test.rb   # D1–D7
├── daily_operations_test.rb  # E1–E20
├── security_test.rb          # H1–H15
├── incident_panels_test.rb   # I1 + media controls (implemented)
├── user_profile_test.rb      # user edit modal workflows (implemented)
├── media_workflows_test.rb   # I3–I7 (planned)
├── user_permissions_test.rb  # I9–I10 + relevant F/H permissions (planned)
├── dashboard_test.rb         # B1–B6 (planned)
├── admin_operations_test.rb  # F1–F22 (planned)
├── settings_test.rb          # G1–G6 (planned)
└── navigation_ui_test.rb     # I1 + tab-order and badge smoke checks (planned)
```

**Current:** 7 implemented files (test count pending next full run).  
**Target:** 11 files after planned expansion, with P0 + P1 completed first.
