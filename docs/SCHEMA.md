# Database Schema

> Every table, column, relationship, and index for Genixo Restoration.

---

## Entity Relationship Overview

```
Organization (mitigation or property_management)
├── has_many :users
├── has_many :properties (PM org owns, Mitigation org services)
├── has_many :equipment_types (Mitigation org only)
└── has_one  :on_call_configuration (Mitigation org only)

Property
├── belongs_to :property_management_org (Organization)
├── belongs_to :mitigation_org (Organization)
├── has_many :incidents
└── has_many :property_assignments → Users (PM/AM scoping)

User
├── belongs_to :organization
├── has_many :property_assignments (PM/AM users)
├── has_many :incident_assignments
├── has_many :labor_entries (as user or created_by)
└── has_many :sessions (Rails 8 auth)

Incident
├── belongs_to :property
├── belongs_to :created_by (User)
├── has_many :incident_assignments → Users
├── has_many :incident_contacts
├── has_many :messages
├── has_many :activity_events
├── has_many :activity_entries
│   └── has_many :activity_equipment_actions
├── has_many :labor_entries
├── has_many :equipment_entries
├── has_many :operational_notes
└── has_many :attachments (polymorphic, via Active Storage)
```

---

## Tables

### organizations

The top-level tenant. Two types: `mitigation` (service provider) and `property_management` (client).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| name | string | NOT NULL | e.g., "Genixo Construction", "Greystar" |
| organization_type | string | NOT NULL | `mitigation` or `property_management` |
| phone | string | | Main office phone |
| email | string | | Main contact email |
| street_address | string | | |
| city | string | | |
| state | string | | |
| zip | string | | |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes:**
- `index_organizations_on_organization_type`

---

### users

All users across both org types. `user_type` determines permissions.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| organization_id | bigint | NOT NULL, FK | |
| email_address | string | NOT NULL | Normalized lowercase |
| password_digest | string | | Nullable for invited users who haven't set password |
| first_name | string | NOT NULL | |
| last_name | string | NOT NULL | |
| phone | string | | For notifications and escalation |
| timezone | string | NOT NULL, DEFAULT `'America/Chicago'` | IANA timezone for display. All datetimes stored as UTC, displayed in user's timezone. |
| user_type | string | NOT NULL | See user types below |
| notification_preferences | jsonb | NOT NULL, DEFAULT `{}` | See notification preferences |
| active | boolean | NOT NULL, DEFAULT true | Soft deactivation |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**User types (by org type):**

Mitigation org:
- `manager` — Full access to all properties/incidents their org services. Creates properties, invites users, assigns/unassigns users to incidents, manages on-call.
- `technician` — Sees only assigned incidents and their properties. Creates labor entries, equipment entries, operational notes, uploads attachments.
- `office_sales` — Read-only on operational data. Can create properties, PM orgs, and invite users.

Property Management org:
- `property_manager` — Sees assigned properties and their incidents. Creates incidents, uploads intake attachments, sends messages.
- `area_manager` — Same as property_manager but typically assigned to multiple properties.
- `pm_manager` — Same permissions as property_manager. Sees properties via property assignments and incidents via incident assignments. Used for higher-level PM staff. Automatically assigned to new incidents on properties in their PM org.

**Notification preferences (jsonb):**
```json
{
  "message_notifications": true,
  "status_change_notifications": true,
  "daily_digest": false
}
```

**Indexes:**
- `index_users_on_email_address` (unique) — email globally unique
- `index_users_on_organization_id`
- `index_users_on_organization_id_and_user_type`

---

### sessions

Rails 8 authentication sessions.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| user_id | bigint | NOT NULL, FK | |
| ip_address | string | | |
| user_agent | string | | |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes:**
- `index_sessions_on_user_id`

---

### properties

A physical building or complex owned by a PM org, serviced by a mitigation org.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| property_management_org_id | bigint | NOT NULL, FK → organizations | The PM org that owns this property |
| mitigation_org_id | bigint | NOT NULL, FK → organizations | The mitigation org that services it |
| name | string | NOT NULL | e.g., "Park at River Oaks" |
| street_address | string | | |
| city | string | | |
| state | string | | |
| zip | string | | |
| unit_count | integer | | Optional — total units in complex |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes:**
- `index_properties_on_property_management_org_id`
- `index_properties_on_mitigation_org_id`

---

### property_assignments

Scopes which properties a PM-side user can access.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| user_id | bigint | NOT NULL, FK | PM-side user (property_manager, area_manager, or pm_manager) |
| property_id | bigint | NOT NULL, FK | |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes:**
- `index_property_assignments_on_user_id_and_property_id` (unique)
- `index_property_assignments_on_property_id`

---

### incidents

The core work unit. Tracks a mitigation job from intake through payment.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| property_id | bigint | NOT NULL, FK | |
| created_by_user_id | bigint | NOT NULL, FK → users | Who filed it |
| status | string | NOT NULL, DEFAULT `'new'` | See lifecycle below |
| project_type | string | NOT NULL | `emergency_response`, `mitigation_rfq`, `buildback_rfq`, `capex_rfq`, `other` |
| emergency | boolean | NOT NULL, DEFAULT false | Triggers escalation if true |
| damage_type | string | NOT NULL | `flood`, `fire`, `smoke`, `mold`, `odor`, `other`, `not_applicable` |
| description | text | NOT NULL | Free text — what happened, narrative |
| cause | text | | What caused the damage |
| requested_next_steps | text | | What the requester wants done |
| units_affected | integer | | Number of units impacted |
| affected_room_numbers | text | | Free text — e.g., "238, 239, 240" |
| visitors | text | | People present on-site |
| usable_rooms_returned | text | | Rooms returned to usable condition |
| estimated_date_of_return | date | | Estimated date tenants can return |
| location_of_damage | text | | Free text — where on the property the damage is |
| do_not_exceed_limit | decimal | | Optional dollar amount cap |
| job_id | string | | Optional external job/reference number |
| last_activity_at | datetime | | Denormalized. Updated on any message, activity event, labor, equipment, note, or attachment. |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**`project_type` drives initial status + emergency flag at creation:**
- `emergency_response` → `emergency = true`, status auto-transitions to `acknowledged`
- `mitigation_rfq` → status auto-transitions to `proposal_requested`
- `buildback_rfq` → status auto-transitions to `proposal_requested`
- `capex_rfq` → status auto-transitions to `proposal_requested`
- `other` → status auto-transitions to `acknowledged`

**Statuses:**
```
new → acknowledged → active → on_hold → completed → completed_billed → paid → closed
                   ↘ proposal_requested → proposal_submitted → proposal_signed → active
```

- `new` — Just created (exists momentarily)
- `acknowledged` — Auto-transition on creation for non-RFQ types. Confirmation email sent.
- `proposal_requested` — Auto-transition on creation for RFQ project types. Proposal work begins.
- `proposal_submitted` — Proposal has been sent to the client.
- `proposal_signed` — Client has signed the proposal.
- `active` — Work begins. Standard and quote paths converge here. Techs are assigned at this point.
- `on_hold` — Work paused.
- `completed` — Mitigation work finished.
- `completed_billed` — Invoice sent.
- `paid` — Payment received.
- `closed` — Fully resolved.

**Indexes:**
- `index_incidents_on_property_id`
- `index_incidents_on_property_id_and_status`
- `index_incidents_on_created_by_user_id`
- `index_incidents_on_status`
- `index_incidents_on_status_and_last_activity_at` — dashboard sorting
- `index_incidents_on_last_activity_at` — dashboard sorting
- `index_incidents_on_emergency` (partial: where emergency = true)
- `index_incidents_on_project_type`

---

### incident_assignments

Links users to incidents. **Auto-assigned at creation:** all PM users on the property + all mitigation managers/office_sales. Techs are assigned later by managers. Assignment/unassignment generates activity events.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| incident_id | bigint | NOT NULL, FK | |
| user_id | bigint | NOT NULL, FK → users | Any user |
| assigned_by_user_id | bigint | NOT NULL, FK → users | Who assigned (system for auto-assign, or the manager) |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Auto-assignment at incident creation:**
- All `property_manager` and `area_manager` users assigned to that property (via `property_assignments`)
- All `pm_manager` users in the property's PM org
- All `manager` and `office_sales` users in the servicing mitigation org
- **NOT** technicians — they are assigned by managers, typically when the incident is made active
- `assigned_by_user_id` = the incident creator for auto-assignments

**Indexes:**
- `index_incident_assignments_on_incident_id_and_user_id` (unique)
- `index_incident_assignments_on_user_id`

---

### incident_contacts

Ad-hoc contacts for a specific incident who are not users in the system. For storing contact info of relevant parties (insurance adjusters, building owners, etc.).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| incident_id | bigint | NOT NULL, FK | |
| name | string | NOT NULL | |
| title | string | | Role/position |
| email | string | | |
| phone | string | | |
| onsite | boolean | NOT NULL, DEFAULT false | Whether this contact is on-site |
| created_by_user_id | bigint | NOT NULL, FK → users | |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes:**
- `index_incident_contacts_on_incident_id`

---

### messages

Per-incident chat thread. **Visibility rule: if you can see the incident, you can see all its messages.** No per-message access control. Scoping is enforced at the incident level via `visible_incidents`.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| incident_id | bigint | NOT NULL, FK | |
| user_id | bigint | NOT NULL, FK | Author |
| body | text | NOT NULL | Message content |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

Message attachments use the polymorphic `attachments` table (`attachable_type = 'Message'`).

**Indexes:**
- `index_messages_on_incident_id_and_created_at`

---

### incident_read_states

Tracks unread state per user per incident for both messages and activity. Replaces separate read marker tables.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| incident_id | bigint | NOT NULL, FK | |
| user_id | bigint | NOT NULL, FK | |
| last_message_read_at | datetime | | Messages after this are unread. Null = all unread. |
| last_activity_read_at | datetime | | Activity events after this are unread. Null = all unread. |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes:**
- `index_incident_read_states_on_incident_id_and_user_id` (unique)
- `index_incident_read_states_on_user_id`

---

### activity_events

Append-only audit log. Generated for every meaningful action on an incident.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| incident_id | bigint | NOT NULL, FK | |
| event_type | string | NOT NULL | See event types below |
| performed_by_user_id | bigint | NOT NULL, FK → users | |
| metadata | jsonb | NOT NULL, DEFAULT `{}` | Structured data per event type |
| created_at | datetime | NOT NULL | |

**No `updated_at`** — these are immutable.

**Event types:**
- `incident_created`
- `status_changed` — metadata: `{ old_status, new_status }`
- `user_assigned` — metadata: `{ user_id, user_name, user_type }`
- `user_unassigned` — metadata: `{ user_id, user_name, user_type }`
- `labor_created` — metadata: `{ labor_entry_id, hours, role_label }`
- `labor_updated` — metadata: `{ labor_entry_id, changes }`
- `activity_logged` — metadata: `{ title, status, equipment_action_count }`
- `activity_updated` — metadata: `{ title, status, equipment_action_count }`
- `equipment_placed` — metadata: `{ equipment_entry_id, equipment_type, identifier }`
- `equipment_removed` — metadata: `{ equipment_entry_id }`
- `equipment_updated` — metadata: `{ equipment_entry_id, changes }`
- `attachment_uploaded` — metadata: `{ attachment_id, category, filename }`
- `operational_note_added` — metadata: `{ operational_note_id }`
- `escalation_attempted` — metadata: `{ user_id, method, result }`
- `contact_added` — metadata: `{ incident_contact_id, name }`
- `contact_removed` — metadata: `{ incident_contact_id, name }`

**Indexes:**
- `index_activity_events_on_incident_id_and_created_at`
- `index_activity_events_on_performed_by_user_id`
- `index_activity_events_on_event_type`

---

### activity_entries

Primary day-log records for incident work. This is the activity-first model used by the Daily Log panel.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| incident_id | bigint | NOT NULL, FK | |
| performed_by_user_id | bigint | NOT NULL, FK → users | Who logged the activity |
| title | string | NOT NULL | e.g., "Extract water", "Move fans for final dry pass" |
| details | text | | Why the work was done / context |
| units_affected | integer | | Optional count |
| units_affected_description | text | | Optional freeform descriptor |
| status | string | NOT NULL, DEFAULT `'active'` | `active` or `completed` |
| occurred_at | datetime | NOT NULL | When the activity happened |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes:**
- `index_activity_entries_on_incident_id_and_occurred_at`
- `index_activity_entries_on_status`

---

### activity_equipment_actions

Optional equipment actions attached to an `activity_entry`.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| activity_entry_id | bigint | NOT NULL, FK | Parent activity |
| equipment_type_id | bigint | FK → equipment_types | Optional predefined type |
| equipment_entry_id | bigint | FK → equipment_entries | Optional specific unit reference |
| equipment_type_other | string | | Optional freeform type |
| action_type | string | NOT NULL | `add`, `remove`, `move`, `other` |
| quantity | integer | | Optional |
| note | text | | Optional reasoning/context |
| position | integer | NOT NULL, DEFAULT `0` | Ordering within activity |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes:**
- `index_act_eq_actions_on_entry_and_position`
- `index_activity_equipment_actions_on_action_type`

---

### labor_entries

Time tracking per incident. Supports both user-specific entries (a technician's own hours) and role-based entries (generic "Supervisor: 2hrs" not tied to a system user).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| incident_id | bigint | NOT NULL, FK | |
| user_id | bigint | FK → users | The person who worked. **Nullable** — null for generic role-based entries. |
| role_label | string | NOT NULL | "Technician", "Supervisor", "General Labor", etc. Freeform. |
| log_date | date | NOT NULL | The date this labor was performed |
| started_at | datetime | | When work began. Optional. |
| ended_at | datetime | | When work ended. Optional. |
| hours | decimal(5,2) | NOT NULL | Total hours worked. Calculated from started_at/ended_at if both present, otherwise entered directly. |
| notes | text | | Optional description of work |
| created_by_user_id | bigint | NOT NULL, FK → users | Who entered this (tech, manager, etc.) |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Notes:**
- If `user_id` is set: this is a specific person's hours (e.g., tech logging their own time).
- If `user_id` is null: generic role-based hours (e.g., "General Labor: 1hr" — person not in the system).
- `role_label` is always present and describes the type of labor.
- `hours` is the canonical value. If `started_at` and `ended_at` are both provided, `hours` is calculated from them.
- `log_date` groups entries for the daily log view.

**Indexes:**
- `index_labor_entries_on_incident_id`
- `index_labor_entries_on_user_id`
- `index_labor_entries_on_incident_id_and_log_date`

---

### equipment_types

Predefined equipment types scoped to a mitigation org. Managers can add to this list.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| organization_id | bigint | NOT NULL, FK → organizations | Mitigation org |
| name | string | NOT NULL | e.g., "Dehumidifier", "Air Mover" |
| active | boolean | NOT NULL, DEFAULT true | Soft delete |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Seed data** (per mitigation org):
- Dehumidifier
- Air Mover
- Air Blower
- Water Extraction Unit

**Indexes:**
- `index_equipment_types_on_organization_id`
- `index_equipment_types_on_organization_id_and_name` (unique)

---

### equipment_entries

Individual physical equipment units. Still used for optional specific-unit references and active deployment tracking.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| incident_id | bigint | NOT NULL, FK | |
| equipment_type_id | bigint | FK → equipment_types | Nullable if using freeform |
| equipment_type_other | string | | Freeform type name when not in predefined list |
| equipment_model | string | | Model name (e.g., "LGR 7000XLi") |
| equipment_identifier | string | | Serial number or barcode string. Manual entry for MVP. |
| placed_at | datetime | NOT NULL | When equipment was placed |
| removed_at | datetime | | When removed. Null = still in place. |
| location_notes | text | | e.g., "Unit 238, bedroom" |
| logged_by_user_id | bigint | NOT NULL, FK → users | |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Constraints:**
- **Model validation:** Exactly one of `equipment_type_id` or `equipment_type_other` must be present (XOR). Empty strings are normalized to NULL before validation.

**Indexes:**
- `index_equipment_entries_on_incident_id`
- `index_equipment_entries_on_equipment_type_id`
- `index_equipment_entries_on_equipment_identifier`

---

### operational_notes

Technician work notes. Distinct from messages and labor entries. Things like "Extract Water", "Deploy 4 Fans", "Fog ductwork to prevent microbial growth."

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| incident_id | bigint | NOT NULL, FK | |
| created_by_user_id | bigint | NOT NULL, FK → users | |
| note_text | text | NOT NULL | Multi-line free text |
| log_date | date | NOT NULL | The date this note applies to (for daily log grouping) |
| created_at | datetime | NOT NULL | |

**No `updated_at`** — operational notes are append-only like activity events.

**Indexes:**
- `index_operational_notes_on_incident_id_and_log_date`
- `index_operational_notes_on_incident_id_and_created_at`

---

### attachments

File uploads. Polymorphic — can attach to an Incident or a Message. Uses Active Storage for the actual file blob. **Attachments are append-only** — new uploads never replace previous ones. Historical viewing is the default (e.g., moisture mappings from different dates are all visible chronologically).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| attachable_type | string | NOT NULL | `Incident` or `Message` |
| attachable_id | bigint | NOT NULL | |
| uploaded_by_user_id | bigint | NOT NULL, FK → users | |
| category | string | NOT NULL | See categories below |
| description | string | | Optional label |
| log_date | date | | The date this attachment applies to (for daily log grouping). Nullable for message attachments. |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

Each attachment `has_one_attached :file` via Active Storage.

**Categories:**
- `photo`
- `moisture_mapping`
- `moisture_readings`
- `psychrometric_log`
- `signed_document`
- `sign_in_sheet`
- `general`

**Indexes:**
- `index_attachments_on_attachable` (attachable_type, attachable_id)
- `index_attachments_on_attachable_and_category` (attachable_type, attachable_id, category)
- `index_attachments_on_uploaded_by_user_id`
- `index_attachments_on_attachable_and_log_date` (attachable_type, attachable_id, log_date)

---

### on_call_configurations

Global on-call settings per mitigation org. One active config per org.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| organization_id | bigint | NOT NULL, FK → organizations | Mitigation org |
| primary_user_id | bigint | NOT NULL, FK → users | Current on-call manager |
| escalation_timeout_minutes | integer | NOT NULL, DEFAULT 10 | Minutes before escalating to next person |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes:**
- `index_on_call_configurations_on_organization_id` (unique)

---

### escalation_contacts

Ordered list of people to contact if the primary on-call doesn't respond.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| on_call_configuration_id | bigint | NOT NULL, FK | |
| user_id | bigint | NOT NULL, FK → users | |
| position | integer | NOT NULL | Order in escalation chain (1, 2, 3...) |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes:**
- `index_escalation_contacts_on_config_id_and_position` (unique)
- `index_escalation_contacts_on_user_id`

---

### escalation_events

Tracks each notification attempt during emergency escalation. Provider-agnostic. Escalation stops when a manager marks the incident as Active (not an "acknowledge" action).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| incident_id | bigint | NOT NULL, FK | |
| user_id | bigint | NOT NULL, FK → users | Who was contacted |
| contact_method | string | NOT NULL | `voice`, `sms`, `email` |
| provider | string | | e.g., `twilio`, `vonage`, `aws_sns` — set by config |
| status | string | NOT NULL | `pending`, `sent`, `delivered`, `failed` |
| attempted_at | datetime | NOT NULL | |
| resolved_at | datetime | | When the escalation chain stopped for this incident |
| resolved_by_user_id | bigint | FK → users | Who took the stopping action |
| resolution_reason | string | | e.g., `incident_marked_active`, `manually_dismissed` |
| provider_response | jsonb | DEFAULT `{}` | Raw response from provider for debugging |
| created_at | datetime | NOT NULL | |

**Notes:**
- `resolved_at` / `resolved_by_user_id` / `resolution_reason` are set when the escalation chain stops (e.g., a manager marks the incident Active).
- Individual escalation_events track each contact attempt. The resolved fields are set on all pending events when escalation stops.

**Indexes:**
- `index_escalation_events_on_incident_id`
- `index_escalation_events_on_user_id`
- `index_escalation_events_on_status`

---

### invitations

User invitation flow. Manager or Office/Sales creates an invitation, system sends email with signup link.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK | |
| organization_id | bigint | NOT NULL, FK | Org the user will join |
| invited_by_user_id | bigint | NOT NULL, FK → users | |
| email | string | NOT NULL | |
| user_type | string | NOT NULL | Role they'll have |
| first_name | string | | Optional — pre-filled by inviter |
| last_name | string | | Optional — pre-filled by inviter |
| phone | string | | Optional — pre-filled by inviter |
| token | string | NOT NULL, UNIQUE | Signup token |
| accepted_at | datetime | | Null until accepted |
| expires_at | datetime | NOT NULL | |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes:**
- `index_invitations_on_token` (unique)
- `index_invitations_on_email`
- `index_invitations_on_organization_id`

---

## Active Storage Tables

Rails Active Storage provides these automatically:
- `active_storage_blobs` — File metadata (filename, content_type, byte_size, checksum)
- `active_storage_attachments` — Polymorphic join (links blobs to records)
- `active_storage_variant_records` — Image variant tracking

No custom schema needed. Configured to use S3 in production, local disk in development.

---

## Solid Stack Tables

Single-database setup per Rails playbook (`~/.claude/rails-playbook/solid-stack.md`):
- Solid Queue tables (background jobs)
- Solid Cache tables
- Solid Cable tables (ActionCable)

Generated via consolidated migration. See playbook for details.

---

## Access Control Summary

| User Type | Properties Visible | Incidents Visible | Can Create | Can Modify |
|-----------|-------------------|-------------------|------------|------------|
| **Manager** (Mitigation) | All properties their org services | All incidents on those properties | Properties, PM orgs, users, incidents, labor, equipment, notes | Status, assignments, labor, equipment |
| **Technician** (Mitigation) | Only via assigned incidents | Only assigned incidents | Labor (own), equipment, operational notes, attachments | Own labor entries |
| **Office/Sales** (Mitigation) | All properties their org services | All incidents (read-only operational) | Properties, PM orgs, users | Nothing operational |
| **Property Manager** (PM) | Assigned properties only | Incidents on assigned properties | Incidents, messages, intake attachments | Nothing operational |
| **Area Manager** (PM) | Assigned properties (multiple) | Incidents on assigned properties | Same as Property Manager | Same as Property Manager |
| **PM Manager** (PM) | Assigned properties + via incident assignments | Assigned incidents + incidents on assigned properties | Same as Property Manager | Same as Property Manager |

---

## Key Scoping Queries

```ruby
# Mitigation Manager / Office Sales — all properties their org services
Property.where(mitigation_org_id: current_user.organization_id)

# Mitigation Technician — properties via assigned incidents
Property.joins(incidents: :incident_assignments)
        .where(incident_assignments: { user_id: current_user.id })
        .distinct

# PM / AM / PM Manager — assigned properties
Property.joins(:property_assignments)
        .where(property_assignments: { user_id: current_user.id })

# Incidents for PM / AM / PM Manager — via property assignments + incident assignments
Incident.joins(property: :property_assignments)
        .where(property_assignments: { user_id: current_user.id })
        .or(Incident.joins(:incident_assignments)
                    .where(incident_assignments: { user_id: current_user.id }))

# Dashboard — incidents sorted by most recent activity
Incident.where(property_id: visible_property_ids)
        .order(last_activity_at: :desc)

# Unread message count for a user on an incident
read_state = IncidentReadState.find_by(incident_id: id, user_id: current_user.id)
Message.where(incident_id: id)
       .where("created_at > ?", read_state&.last_message_read_at || Time.at(0))
       .count

# Daily log — all activity for an incident on a specific date
LaborEntry.where(incident_id: id, log_date: date)
EquipmentEntry.where(incident_id: id).where(placed_at: date.all_day)
              .or(EquipmentEntry.where(incident_id: id, removed_at: date.all_day))
OperationalNote.where(incident_id: id, log_date: date)
Attachment.where(attachable_type: "Incident", attachable_id: id, log_date: date)
```

---

## Deferred (Post-MVP)

- **Billback/invoicing tables** — statuses (`completed_billed`, `paid`) track billing state for now. Actual invoicing deferred.
- **On-call scheduling** — rotation is manual (manager updates primary_user_id). Automated scheduling deferred.
- **Equipment barcode scanning** — `equipment_identifier` is manual text entry. Barcode scanning + auto-populate planned post-MVP.
- **Structured moisture/psychrometric data** — file uploads only for MVP. In-app data entry (unit/room/material/readings by date) planned post-MVP.
- **Signature capture** — deferred. Indemnification/liability docs uploaded as files for now.

- **Structured daily summaries** — per-day fields like "usable rooms returned" and "estimated return date" captured in operational notes for MVP. Dedicated daily summary model if needed post-MVP.
