# Business Rules

> Domain logic, validation rules, edge cases, and "who can do what when."
>
> For schema details, see `SCHEMA.md`. For technical implementation, see `ARCHITECTURE.md`.

---

## 1. Organization Rules

### Org Types

- **Mitigation org** — the service provider (e.g., Genixo Construction). Performs restoration work.
- **Property management (PM) org** — the client (e.g., Greystar, Sandalwood). Owns properties.

### Isolation

- PM orgs are **completely isolated** from each other. Greystar users never see Sandalwood data.
- A mitigation org works across multiple PM orgs. Mitigation staff see all properties their org services.
- A property has exactly one PM org (owner) and exactly one mitigation org (servicer).

### Creation

- Only mitigation org users (manager, office_sales) can create PM orgs.
- PM orgs cannot create other PM orgs.
- The system can support multiple mitigation orgs, each with their own PM org relationships.

---

## 2. User Rules

### User Types by Org

| Org Type | User Types |
|----------|-----------|
| Mitigation | `manager`, `technician`, `office_sales` |
| Property Management | `property_manager`, `area_manager`, `pm_manager` |

A user belongs to exactly one organization. A user's `user_type` must be valid for their org's type — a PM org cannot have a `technician`, and a mitigation org cannot have a `property_manager`.

### Email Uniqueness

Email is globally unique across all organizations. One email address = one user account in the system.

### Deactivation

- Users are soft-deactivated (`active = false`), never deleted.
- Deactivated users cannot log in.
- Their historical data (labor entries, messages, activity events) remains intact and attributed to them.
- Deactivated users should not appear in assignment dropdowns or active user lists.

### Invitations

- Managers and office_sales can invite users to their own org.
- Managers can invite users to PM orgs they service (to onboard property managers).
- The invitation specifies the `user_type` the invitee will have.
- The inviter can optionally provide the invitee's first name, last name, phone, and email at invite time.
- Invitations expire (configurable, default 7 days).
- Accepting an invitation creates the user account and sets their password. The invitee must fill in any fields not provided by the inviter (first name, last name, phone are required on the account).
- A pending invitation can be resent (generates new token, resets expiry).

---

## 3. Property Rules

### Ownership

- Every property belongs to exactly one PM org (`property_management_org_id`).
- Every property is serviced by exactly one mitigation org (`mitigation_org_id`).
- A PM org can have many properties.
- A mitigation org can service properties across many PM orgs.

### Property Assignments

- PM-side users (property_manager, area_manager, pm_manager) must be **assigned to specific properties** via `property_assignments` to see them.
- PM-side users can also see incidents they're directly assigned to (via `incident_assignments`), even without a property assignment.
- A property_manager is typically assigned to one property. An area_manager is assigned to multiple. A pm_manager may or may not be assigned to properties — they get auto-assigned to incidents instead.
- Assignment is done by mitigation managers or office_sales when setting up the relationship.
- PM-side users (property_manager, area_manager, pm_manager) can also assign/unassign **their own org's users** to/from properties they are assigned to.
- Mitigation-side users do NOT have property assignments — their visibility is org-wide.

### Creation & Editing

- Only mitigation org users (manager, office_sales) can create properties.
- When creating a property, you specify which PM org owns it. The mitigation org is automatically set to the creator's org.
- PM-side users assigned to a property can edit property info (name, address, unit count).

---

## 4. Incident Rules

### Creation

- **Who can create:** Managers (mitigation), office_sales (mitigation), property_managers (PM), area_managers (PM).
- **Technicians cannot create incidents.**
- The creator must have visibility into the property (via org membership or property assignment).
- Required fields: `property_id`, `description`, `damage_type`, `project_type`.
- `emergency` is derived from `project_type` at creation (`emergency_response` → true). Can be changed by managers afterward.
- Optional fields: `cause`, `requested_next_steps`, `units_affected`, `affected_room_numbers`.

### Project Type

- `project_type` is a **persistent field** on the incident — visible in lists and detail views.
- Set at creation from the intake form. Values: `emergency_response`, `mitigation_rfq`, `buildback_rfq`, `other`.
- Drives initial status + emergency flag automatically:
  - `emergency_response` → `emergency = true`, status → `acknowledged`
  - `mitigation_rfq` → status → `quote_requested`
  - `buildback_rfq` → status → `quote_requested`
  - `other` → status → `acknowledged`
- There is no separate `quote_requested` boolean. Status is the single source of truth.

### Damage Type

- `damage_type` is a required field on every incident.
- Values: `flood`, `fire`, `smoke`, `mold`, `odor`, `other`.
- Set at creation from the intake form.

### Status Lifecycle

```
new → acknowledged → active → on_hold → completed → completed_billed → paid → closed
                   ↘ quote_requested → active (when approved)
```

**Allowed transitions:**

| From | To |
|------|----|
| `acknowledged` | `active`, `quote_requested`, `on_hold` |
| `quote_requested` | `active`, `closed` |
| `active` | `on_hold`, `completed` |
| `on_hold` | `active`, `completed` |
| `completed` | `completed_billed`, `active` (reopen) |
| `completed_billed` | `paid`, `active` (reopen) |
| `paid` | `closed` |

- `new` is transient — exists only momentarily during creation before auto-transitioning.
- **All status changes are manual.** No automatic transitions except during incident creation.
- Status changes are **not reversible** in general, but `active` can be reached from `completed` and `completed_billed` as a reopen path.
- Every status change creates an `activity_event` with `old_status` and `new_status` in metadata.

### Who Can Change Status

- **Managers** can make any valid transition.
- **Technicians** cannot change status.
- **Office/Sales** cannot change status (read-only on operational data).
- **PM/AM users** cannot change status. They can see the current status but cannot modify it.

### Emergency Flag

- Set at creation time. Can be changed by managers afterward.
- If `emergency = true` at creation, triggers the escalation chain immediately.
- The emergency flag is independent of status — an incident can be emergency + any status.

---

## 5. Assignment Rules

### Incident Assignments

- **Mitigation managers** can assign or unassign any user to/from incidents.
- **PM-side users** (property_manager, area_manager, pm_manager) can assign or unassign **their own org's users** to/from incidents they can see. They cannot manage mitigation-side assignments.
- Typically technicians are assigned by managers when the incident is made active, but **any user** can be assigned.
- Technicians are NOT pre-assigned to properties. Assignment is per-incident, based on availability.
- A user can be assigned to multiple incidents simultaneously.
- An incident should always have at least one mitigation org user and at least one PM org user assigned.
- Assignment/unassignment generates an `activity_event` (`user_assigned` / `user_unassigned`).
- Assigned technicians receive a notification when assigned.

### Auto-Assignment at Creation

- When an incident is created, the system **automatically assigns** default users:
  - All `property_manager` and `area_manager` users assigned to that property (via `property_assignments`)
  - All `pm_manager` users in the property's PM org (gives them visibility without needing property assignments)
  - All `manager` and `office_sales` users in the servicing mitigation org
  - **NOT** technicians — they are assigned later by managers, typically when the incident is made active

### Incident Contacts

- Non-user contacts can be added to an incident for reference (insurance adjusters, building owners, etc.).
- These are stored in `incident_contacts` — name, title, email, phone.
- Anyone who can see the incident can view contacts. Managers and PM-side users can add/remove them.
- Adding or removing a contact generates an `activity_event` (`contact_added` / `contact_removed`).
- Incident contacts do NOT receive system notifications — they're informational only.

### Visibility Through Assignment

- Technicians see **only** incidents they are assigned to (and the properties those incidents belong to).
- Removing a technician's assignment removes their access to that incident.
- Historical data they created (labor, equipment, notes) remains even after unassignment.

---

## 6. Escalation Rules

### On-Call Configuration

- Each mitigation org has one `on_call_configuration` with a `primary_user_id` (the on-call manager).
- The `escalation_timeout_minutes` (default 10) determines how long to wait before escalating.
- The escalation contact list is ordered by `position` (1, 2, 3...).
- On-call rotation is **manual** for MVP — a manager updates `primary_user_id` when the rotation changes.

### Escalation Flow

1. Emergency incident created → `EscalationJob` fires immediately.
2. Contact the primary on-call manager via SMS/voice/email.
3. Create `escalation_event` record + `activity_event`.
4. Schedule `EscalationTimeoutJob` to fire after `escalation_timeout_minutes`.
5. Timeout job checks: is the incident status `active` yet?
   - **Yes** → escalation stops. All pending events get `resolved_at`.
   - **No** → contact the next person in `escalation_contacts` (by position). Schedule another timeout.
6. Repeat until someone marks the incident `active` or the contact list is exhausted.

### Stopping Condition

- Escalation stops when **any manager** sets the incident status to `active`.
- When stopped, all unresolved `escalation_events` for that incident get:
  - `resolved_at` = now
  - `resolved_by_user_id` = the manager who marked active
  - `resolution_reason` = `'incident_marked_active'`
- If the contact list is exhausted with no response, the last escalation event is created but no further timeout is scheduled. The incident remains in its current status.

### Non-Emergency Incidents

- No escalation chain is triggered.
- Standard notification flow: confirmation email to creator, visible in dashboard for managers.

---

## 7. Communication Rules

### Messages

- Per-incident chat thread. One thread per incident, no sub-threads.
- **Visibility:** If you can see the incident, you can see all its messages. No per-message access control.
- **Who can send:** Any user who can see the incident (managers, assigned techs, PM/AM users on that property, office_sales).
- Messages are **never edited or deleted**. Append-only.
- Message attachments use the same polymorphic `attachments` table as incident attachments (`attachable_type = 'Message'`). One attachment system for everything — consistent categories and metadata.

### Operational Notes

- Separate from messages. These are technical work notes (e.g., "Performed air duct cleaning to unit 238").
- Append-only — no edits, no deletes.
- **Who can create:** Technicians, managers. (Not PM/AM users — these are internal operational records.)
- Displayed in the day-by-day activity view, not in the message thread.

### Notifications

| Event | Who Gets Notified | How |
|-------|------------------|-----|
| Incident created | Creator | Email confirmation |
| Emergency incident | On-call manager → escalation chain | SMS/Voice/Email |
| Any status change | All users assigned to the incident (with `status_change_notifications` enabled) | Email |
| User assigned to incident | The assigned user | Email |
| New message | Users who can see the incident (with `message_notifications` enabled) | Email |
| Daily digest | Users with `daily_digest` enabled | Email (scheduled) |

- Users control their notification preferences via `notification_preferences` jsonb on their user record.
- Notification delivery is provider-agnostic (see `ARCHITECTURE.md`).

---

## 8. Incident Activity Rules (Daily Log)

- Daily Log is activity-first. Work is logged as an `activity_entry` (not separate "equipment step + note step").
- **Who can create/edit activities:** Technicians and managers. PM-side users are read-only in Daily Log.
- Required activity fields: `title`, `occurred_at`, `status` (`active` or `completed`).
- Optional activity fields: `units_affected`, `units_affected_description`, `details`.
- Each activity can include zero or more optional equipment actions.
- Equipment action `action_type` options: `add`, `remove`, `move`, `other`.
- Equipment action fields are optional (`quantity`, equipment type, specific equipment reference, note).
- Activity rows are shown newest-to-oldest in Daily Log.
- Creating/updating an activity generates an `activity_event` (`activity_logged` / `activity_updated`) and updates `last_activity_at`.

---

## 9. Labor Tracking Rules

- Labor entries track time on an incident. Supports both user-specific and generic role-based entries.
- **Who can create:** Technicians (for themselves), managers (for anyone — including generic labor not tied to a system user).
- **Who can edit:** The person who created it (own entries only), managers (any entry on incidents they can see).
- **Required fields:** `role_label` (freeform string — "Technician", "Supervisor", "General Labor"), `hours` (decimal, must be > 0), `log_date`.
- **Optional fields:** `user_id` (the person who worked — nullable for generic entries), `started_at`, `ended_at`, `notes`.
- If `user_id` is set: this is a specific person's hours (e.g., a tech logging their own time).
- If `user_id` is null: generic role-based hours not tied to a system user (e.g., "General Labor: 1hr").
- If `started_at` and `ended_at` are both provided, `hours` is calculated from them.
- `log_date` determines which day this entry appears in the daily log.
- Creating or updating a labor entry generates an `activity_event` and touches `last_activity_at`.

---

## 10. Equipment Tracking Rules

### Equipment Types

- Predefined list per mitigation org, managed by managers.
- Seeded with: Dehumidifier, Air Mover, Air Blower, Water Extraction Unit.
- Managers can add new types. Types can be soft-deactivated (`active = false`).
- Equipment types are org-scoped — each mitigation org has its own list.

### Equipment Entries

- Track individual physical equipment units placed at an incident (unit-level inventory/reference).
- **Who can create:** Technicians, managers.
- Each entry has either a predefined `equipment_type_id` OR a freeform `equipment_type_other` — never both, never neither (enforced by DB CHECK constraint).
- `equipment_identifier` is a manually entered serial number or label (barcode scanning deferred to post-MVP).
- `placed_at` is required (when the equipment was placed).
- `removed_at` is null until the equipment is removed. Null means still in place.
- `location_notes` describes where in the property (e.g., "Unit 238, bedroom").
- Placing and removing equipment each generate an `activity_event`.
- Daily log equipment chronology should be read from activity equipment actions attached to activity entries.

---

## 11. Attachment Rules

- Polymorphic — can attach to `Incident` or `Message`.
- **Who can upload:** Any user who can see the incident/message.
- Each attachment has a `category`: `photo`, `moisture_mapping`, `moisture_readings`, `psychrometric_log`, `signed_document`, `general`.
- Files are stored via Active Storage (local disk in dev, S3 in production).
- Attachments are **never deleted** for audit trail purposes.
- Uploading an attachment generates an `activity_event` on the parent incident.

---

## 12. Read State / Unread Tracking

- Each user has an `incident_read_state` per incident they've viewed.
- Two independent timestamps: `last_message_read_at` and `last_activity_read_at`.
- Messages created after `last_message_read_at` are "unread" for that user.
- Activity events created after `last_activity_read_at` are "unread" for that user.
- When a user views the messages tab, update `last_message_read_at` to now.
- When a user views the activity tab, update `last_activity_read_at` to now.
- Read states are created lazily — only when a user first views an incident.
- If no read state exists, everything is considered unread.

---

## 13. Dashboard Rules

### Incident Grouping

The dashboard shows incidents grouped by urgency:

1. **Emergency** — `emergency = true` AND status in (`new`, `acknowledged`, `active`)
2. **Active** — `status = 'active'` (non-emergency)
3. **Needs Attention** — `status` in (`new`, `acknowledged`) — awaiting manager action
4. **On Hold** — `status = 'on_hold'`
5. **Recent Completed** — status in (`completed`, `completed_billed`, `paid`, `closed`) — last 20

All groups sorted by `last_activity_at` descending (most recent activity first).

### Role-Specific Views

- **Manager:** Sees all groups. Can take action on any incident.
- **Technician:** Sees only assigned incidents. Grouped the same way but filtered.
- **Office/Sales:** Same view as manager but read-only on operational data.
- **PM/AM/PM Manager:** Sees incidents on assigned properties + directly assigned incidents. Cannot modify operational data.

---

## 13. Validation Summary

| Model | Rule | Enforcement |
|-------|------|-------------|
| User | `user_type` valid for org's `organization_type` | Model validation |
| User | Email globally unique | DB unique index on `email_address` |
| Incident | Status transitions follow allowed map | Service-level validation (`StatusTransitionService`) |
| Incident | `property_id` must be visible to creator | Controller-level (scoped query) |
| Equipment Entry | Exactly one of `equipment_type_id` or `equipment_type_other` | DB CHECK constraint |
| Labor Entry | `hours` > 0 | Model validation |
| Labor Entry | `role_label` present | Model validation |
| Incident | `damage_type` in allowed list | Model validation |
| Incident | `project_type` in allowed list | Model validation |
| Attachment | `category` in allowed list | Model validation |
| Escalation Contact | `position` unique per `on_call_configuration_id` | DB unique index |
| Property Assignment | `(user_id, property_id)` unique | DB unique index |
| Incident Assignment | `(incident_id, user_id)` unique | DB unique index |

---

## 14. Edge Cases

### What happens when...

**...a technician is unassigned from an incident?**
They lose visibility immediately. Their historical labor entries, equipment entries, notes, and messages remain. An `activity_event` is logged.

**...a PM user is unassigned from a property?**
They lose visibility of that property and all its incidents. Their messages and incident creation history remain attributed to them.

**...a user is deactivated?**
They cannot log in. Their data stays. They don't appear in assignment dropdowns. Active incident assignments remain (manager should manually unassign if needed).

**...an incident is reopened (completed → active)?**
Previous assignments are still in place (assignment records aren't deleted on completion). Technicians regain active visibility.

**...the escalation list is exhausted?**
The last escalation event is logged, but no further timeout jobs are scheduled. The incident stays in its pre-active status. Dashboard shows it under "Needs Attention."

**...someone creates an incident on a property with no on-call configuration?**
Emergency escalation is skipped (no one to escalate to). An `activity_event` should note that escalation was not possible. Standard notifications still fire.

**...a message is sent on a completed incident?**
Allowed. Incidents are never "locked" for messaging. Communication can continue through any status.

**...two managers both mark an incident active at nearly the same time?**
The first `StatusTransitionService` call succeeds. The second sees status is already `active` and raises `InvalidTransitionError` (since `active → active` is not an allowed transition). This is safe.
