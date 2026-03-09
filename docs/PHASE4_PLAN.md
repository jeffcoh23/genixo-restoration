# Phase 4: Guest Incident Submission

## Context

Property managers without Genixo accounts need to report incidents (especially emergencies) quickly. Phase 4 adds a public form at `/report` — linked from the login page — that validates email domains, creates an inactive user, submits the incident through `IncidentCreationService`, and sends an invitation to set up their account.

---

## 1. Hardcoded allowed email domains

**File:** `app/services/guest_incident_service.rb`

No migration — allowed domains are hardcoded in the service:

```ruby
ALLOWED_DOMAINS = {
  "greystar.com" => "Greystar Properties",
  "sandalwood.com" => "Sandalwood Management"
}.freeze
```

Lookup: match email domain → find PM org by name. Easy to expand later (move to DB or config) when needed.

---

## 3. Routes

**File:** `config/routes.rb`

```ruby
get  "report",           to: "guest_incidents#new",          as: :new_guest_incident
post "report",           to: "guest_incidents#create",       as: :guest_incidents
get  "report/lookup",    to: "guest_incidents#lookup",       as: :guest_incident_lookup
get  "report/submitted", to: "guest_incidents#confirmation", as: :guest_incident_confirmation
```

---

## 4. GuestIncidentService

**File:** `app/services/guest_incident_service.rb`

Orchestrates the full flow in a transaction:

1. Validate email domain → find PM org via hardcoded `ALLOWED_DOMAINS` map
2. Check existing user: active → error; inactive → reuse; none → create with `active: false`, `user_type: "property_manager"`, no password (`has_secure_password validations: false` + nullable `password_digest` allows this)
3. Validate property belongs to matched PM org
4. Create incident via `IncidentCreationService` (reuses all auto-assign + escalation logic)
5. Create or reuse pending invitation — use mitigation org's first active manager as `invited_by_user` (column is NOT NULL)
6. Send `InvitationMailer.guest_invite` email

Returns `{ status: :ok/:active_user_exists/:domain_not_recognized/:property_not_found/:invalid }`

---

## 5. GuestIncidentsController

**File:** `app/controllers/guest_incidents_controller.rb`

`allow_unauthenticated_access` (all actions). Does NOT include `Authorization` concern.

### `new` — renders form
Props: `lookup_path`, `submit_path`, `project_types`, `damage_types`

### `lookup` — JSON endpoint (not Inertia)
`GET /report/lookup?email=foo@greystar.com`
- Returns `{ valid: true, org_name, properties: [{id, name, address}] }` for valid domains
- Returns `{ valid: false, error: "active_user_exists" | "domain_not_recognized" }` otherwise
- Uses `property.format_address` (from `HasAddress` concern)

### `create` — calls GuestIncidentService
- Success → flash incident info → redirect to confirmation
- Error → redirect back with Inertia errors

### `confirmation` — renders success page
Props from flash: `emergency`, `property_name`, `login_path`

---

## 6. Invitation accept modification

**File:** `app/controllers/invitations_controller.rb`

Branch in `accept` action:

```
existing_user = User.find_by(email_address: @invitation.email)
if existing_user
  # Update: set password, activate, update name/phone if provided
  existing_user.assign_attributes(password:, password_confirmation:, active: true, ...)
  start_new_session_for(existing_user)
  redirect_to incidents_path
else
  # Original flow: create new user
  ...
end
```

---

## 7. Invitation mailer

**File:** `app/mailers/invitation_mailer.rb`
- Add `guest_invite(invitation)` method

**New files:**
- `app/views/invitation_mailer/guest_invite.html.erb`
- `app/views/invitation_mailer/guest_invite.text.erb`

Content: "Your incident has been received. Set up your account to track it."

---

## 8. Frontend

### `app/frontend/pages/GuestIncident/New.tsx`
- Bare centered card layout (like Login page, no AppLayout)
- Two-phase reveal: email first → on blur, AJAX `fetch(lookup_path)` → if valid, show rest of form
- Fields: first_name, last_name, phone, property select, project_type radios, damage_type select, description
- Emergency toggle shows amber callout with phone number (reuse pattern from Incidents/New)
- Email states: `idle | checking | valid | active_user | domain_blocked`
- Active user → "You already have an account" with login link
- Domain blocked → "Your email domain is not recognized"

### `app/frontend/pages/GuestIncident/Confirmation.tsx`
- Bare centered card layout
- CheckCircle icon + "Your incident report has been submitted"
- Emergency → "You will receive a call within 5-10 minutes"
- Non-emergency → "You'll receive a confirmation call on the next business day"
- "Check your email to set up your account"
- Link to login page
- Handles nil props gracefully (direct visit without flash)

---

## 9. Login page

**File:** `app/frontend/pages/Login.tsx`
- Add small link below "Forgot password?": "Submit an incident without an account"
- Add emergency callout below the login card: phone icon + "In case of emergency, call [emergency phone number]" — prominent but not competing with login form. Use `text-destructive` or amber styling to signal urgency.

**File:** `app/controllers/sessions_controller.rb`
- Add `guest_incident_path: new_guest_incident_path` to props
- Add `emergency_phone: ENV["EMERGENCY_PHONE"]` to props (same pattern as Incidents/New)

---

## 10. Tests

### `test/services/guest_incident_service_test.rb` (new)
- Creates incident + inactive user for valid domain
- Reuses existing inactive user
- Returns error for active user
- Returns error for unknown domain
- Returns error for wrong property/org
- Creates invitation, reuses pending invitation
- Emergency triggers escalation

### `test/controllers/guest_incidents_controller_test.rb` (new)
- GET /report renders without auth
- GET /report/lookup returns valid/invalid responses
- POST /report succeeds and redirects to confirmation
- POST /report handles all error cases
- GET /report/submitted renders confirmation

### `test/controllers/invitations_controller_test.rb` (modify)
- Accept activates existing inactive user
- Accept sets password + active: true
- Accept redirects to incidents_path for guest


---

## Files summary

| File | Action |
|------|--------|
| `app/services/guest_incident_service.rb` | New — includes hardcoded `ALLOWED_DOMAINS` |
| `config/routes.rb` | Modify — 4 routes |
| `app/services/guest_incident_service.rb` | New |
| `app/controllers/guest_incidents_controller.rb` | New |
| `app/controllers/invitations_controller.rb` | Modify — accept branch |
| `app/mailers/invitation_mailer.rb` | Modify — add guest_invite |
| `app/views/invitation_mailer/guest_invite.html.erb` | New |
| `app/views/invitation_mailer/guest_invite.text.erb` | New |
| `app/frontend/pages/GuestIncident/New.tsx` | New |
| `app/frontend/pages/GuestIncident/Confirmation.tsx` | New |
| `app/frontend/pages/Login.tsx` | Modify — add link |
| `app/controllers/sessions_controller.rb` | Modify — add prop |
| `docs/ROADMAP.md` | Modify — check off items |
| `test/services/guest_incident_service_test.rb` | New |
| `test/controllers/guest_incidents_controller_test.rb` | New |
| `test/controllers/invitations_controller_test.rb` | Modify |

---

## Verification

1. Visit `/report` without login — form renders
4. Enter unknown domain email — inline error
5. Enter known domain email — property dropdown populates
6. Enter existing active user email — "already have an account" message
7. Submit emergency incident — confirmation shows call-within-5-minutes
8. Submit non-emergency — confirmation shows next-business-day
9. Check email (letter_opener) — guest invitation sent
10. Accept invitation — user activated, logged in, redirected to incidents
11. Submit again with same email — reuses inactive user, new incident created
12. Login page — "Submit an incident without an account" link visible
13. `bin/rails test` + `npx tsc --noEmit` — all clean
