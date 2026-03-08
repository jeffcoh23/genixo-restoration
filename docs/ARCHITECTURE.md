# Architecture

> Technical decisions, key flows, service objects, and how the pieces connect.
>
> For standard Rails patterns (auth, Inertia, Solid Stack, deployment), see the Rails playbook at `~/.claude/rails-playbook/`.
> This doc covers only what's unique to Genixo Restoration.

---

## System Overview

Genixo Restoration is a multi-tenant incident management platform with two tenant types:

```
┌─────────────────────────────────────────────────────────┐
│                    Genixo Platform                       │
│                                                         │
│  ┌──────────────┐    services    ┌───────────────────┐  │
│  │ Mitigation   │──────────────▶│ PM Org (Greystar) │  │
│  │ Org (Genixo) │               │  ├── Property A    │  │
│  │              │               │  ├── Property B    │  │
│  │  Managers    │               │  └── Property C    │  │
│  │  Technicians │               └───────────────────┘  │
│  │  Office/Sales│                                       │
│  └──────────────┘    services    ┌───────────────────┐  │
│         │        ───────────────▶│ PM Org (Sandal)   │  │
│         │                        │  ├── Property D    │  │
│         │                        │  └── Property E    │  │
│         │                        └───────────────────┘  │
│         │                                               │
│         ▼                                               │
│  Incidents live on Properties                           │
│  Mitigation org staff work across all PM orgs           │
│  PM orgs are isolated from each other                   │
└─────────────────────────────────────────────────────────┘
```

---

## Request Lifecycle

Every request flows through the same pipeline:

```
Request → Authentication → Authorization (org + role scoping) → Controller → Service → Response
```

### Authentication

Rails 8 session-based auth (see `~/.claude/rails-playbook/auth.md`). No OAuth for MVP — email/password only.

- `Current.user` available everywhere
- `Current.session` tracks login sessions
- All controllers require auth by default
- Public pages use `allow_unauthenticated_access`

### Authorization

Authorization has two layers: **scoped queries** for data visibility, and a **centralized Permissions model** for action-level checks.

#### Permissions Model

`app/models/permissions.rb` — defines permission constants, role defaults, and human-readable labels. Each user stores their actual permissions in a `permissions` jsonb array on the `users` table. Defaults are set from the role on user creation.

```ruby
class Permissions
  CREATE_INCIDENT        = :create_incident
  EDIT_INCIDENT          = :edit_incident
  TRANSITION_STATUS      = :transition_status
  CREATE_PROPERTY        = :create_property
  VIEW_PROPERTIES        = :view_properties
  MANAGE_ORGANIZATIONS   = :manage_organizations
  MANAGE_USERS           = :manage_users
  MANAGE_ON_CALL         = :manage_on_call
  MANAGE_EQUIPMENT_TYPES = :manage_equipment_types
  MANAGE_DAILY_LOGS      = :manage_daily_logs
  MANAGE_READINGS        = :manage_readings
  MANAGE_ATTACHMENTS     = :manage_attachments

  ROLE_PERMISSIONS = {
    "manager"          => [all 12],
    "office_sales"     => [CREATE_INCIDENT, EDIT_INCIDENT, CREATE_PROPERTY, VIEW_PROPERTIES,
                           MANAGE_ORGANIZATIONS, MANAGE_USERS, MANAGE_ATTACHMENTS],
    "technician"       => [MANAGE_DAILY_LOGS, MANAGE_READINGS, MANAGE_ATTACHMENTS],
    "property_manager" => [CREATE_INCIDENT, VIEW_PROPERTIES],
    "area_manager"     => [CREATE_INCIDENT, VIEW_PROPERTIES],
    "other"            => [VIEW_PROPERTIES]
  }.freeze

  # Permissions shown as toggleable checkboxes in the user edit modal (mitigation users only)
  MITIGATION_VISIBLE_PERMISSIONS = [
    CREATE_INCIDENT, EDIT_INCIDENT, TRANSITION_STATUS,
    MANAGE_DAILY_LOGS, MANAGE_READINGS, MANAGE_USERS
  ].freeze

  def self.has?(user_type, permission) ... end
  def self.defaults_for(user_type) ... end
end
```

**Per-user permissions:** `user.can?(Permissions::CREATE_INCIDENT)` checks the user's `permissions` jsonb array — NOT `Permissions.has?`. This allows managers to toggle individual permissions per user. Defaults are set from `ROLE_PERMISSIONS` at user creation via `set_default_permissions` callback.

#### Scoped Queries

```ruby
# app/controllers/concerns/authorization.rb
module Authorization
  # Visibility scopes — returns only records the user is allowed to see
  def visible_properties ...
  def visible_incidents ...

  # Record finders — 404 if not in scope
  def find_visible_incident!(id) ...
  def find_visible_property!(id) ...

  # Permission helpers (delegate to user's per-user permissions array)
  def can_create_incident? ...     # Permissions::CREATE_INCIDENT
  def can_edit_incident? ...       # Permissions::EDIT_INCIDENT
  def can_transition_status? ...   # Permissions::TRANSITION_STATUS
  def can_view_properties? ...     # Permissions::VIEW_PROPERTIES
  def can_manage_organizations? ...# Permissions::MANAGE_ORGANIZATIONS
  def can_manage_users? ...        # Permissions::MANAGE_USERS
  def can_create_labor? ...        # Permissions::MANAGE_DAILY_LOGS
  def can_manage_on_call? ...      # Permissions::MANAGE_ON_CALL
  def can_manage_moisture_readings? ... # Permissions::MANAGE_READINGS
  def can_manage_attachments? ...  # Permissions::MANAGE_ATTACHMENTS

  # Resource-scoped checks (need a specific record)
  def mitigation_admin? ...
  def can_edit_property?(property) ...
  def can_assign_to_property?(property) ...
end
```

**Key principles:**
- Never trust the URL. Always scope queries through `visible_incidents` / `visible_properties`.
- Use `find_visible_incident!(id)` instead of `Incident.find(id)` — returns 404 if not in scope, concealing existence.
- Authorization failures render 404 (not 403), so unauthorized users can't probe for valid IDs.
- **Permission checks use constants, never string comparisons.** Write `can_create_incident?` not `user_type == "manager"`.
- **Message visibility:** If you can see the incident, you can see all its messages. No per-message access control. Controllers load messages through the incident: `find_visible_incident!(id).messages`.

---

## Key Flows

### 1. Incident Creation

```
PM/AM user fills intake form
  OR
Mitigation manager enters call-in

        │
        ▼
┌─────────────────────────┐
│ IncidentCreationService │
│                         │
│ 1. Create incident      │
│    status = 'new'       │
│                         │
│ 2. Auto-transition to   │
│    'acknowledged' or    │
│    'proposal_requested' │
│    (based on intake     │
│     selection)          │
│                         │
│ 3. Create activity_event│
│    (incident_created)   │
│                         │
│ 4. Create activity_event│
│    (status_changed)     │
│                         │
│ 5. If emergency:        │
│    Enqueue escalation   │
│    job                  │
│                         │
│ 6. Send confirmation    │
│    email to creator     │
│                         │
│ 7. Touch last_activity  │
└─────────────────────────┘
```

```ruby
# app/services/incident_creation_service.rb
class IncidentCreationService
  def initialize(property:, user:, params:)
    @property = property
    @user = user
    @params = params
  end

  def call
    ActiveRecord::Base.transaction do
      @incident = @property.incidents.create!(
        created_by_user: @user,
        status: "new",
        emergency: @params[:project_type] == "emergency_response",
        **@params
      )

      # Auto-transition based on project_type
      # RFQ types (mitigation_rfq, buildback_rfq, capex_rfq) → proposal_requested
      # All others → acknowledged
      auto_transition_status

      # Auto-assign all relevant users (not techs)
      auto_assign_users!

      # Activity events
      log_event("incident_created")

      # Escalation
      if @incident.emergency?
        EscalationJob.perform_later(@incident.id)
      end

      # Notification
      IncidentMailer.creation_confirmation(@incident).deliver_later
    end

    @incident
  end

  private

  def transition_status!(new_status)
    old_status = @incident.status
    @incident.update!(status: new_status)
    log_event("status_changed", old_status: old_status, new_status: new_status)
  end

  def log_event(event_type, metadata = {})
    ActivityLogger.log(
      incident: @incident,
      event_type: event_type,
      user: @user,
      metadata: metadata
    )
  end

  def assign_users
    users_to_assign = default_auto_assign_users

    # When the UI sends assignment selections, merge with hidden auto-assigns.
    # PM creators can't see mitigation auto-assign users — those are preserved.
    if @params.key?(:additional_user_ids)
      selected_ids = Array(@params[:additional_user_ids]).map(&:to_i)
      selectable_ids = selectable_user_ids_for_creator
      preserved = users_to_assign.reject { |u| selectable_ids.include?(u.id) }
      selected = User.where(id: selected_ids & selectable_ids, active: true)
      users_to_assign = preserved.to_set.merge(selected)
    end

    users_to_assign.each do |u|
      @incident.incident_assignments.create!(user: u, assigned_by_user: @user)
    end
  end

  def default_auto_assign_users
    users = Set.new

    # Mitigation-side: users with auto_assign flag
    @property.mitigation_org.users.active.auto_assigned.find_each { |u| users << u }

    # Mitigation-side (emergency only): add on-call primary user
    if @incident.emergency?
      config = @property.mitigation_org.on_call_configuration
      users << config.primary_user if config&.primary_user
    end

    # PM-side: nobody — PM creator picks manually
    users
  end
end
```

### 2. Emergency Escalation

```
EscalationJob (Solid Queue)
        │
        ▼
┌──────────────────────────┐
│ EscalationService        │
│                          │
│ 1. Load on_call_config   │
│    for mitigation org    │
│                          │
│ 2. Contact primary       │
│    on-call manager       │
│    (via NotificationSvc) │
│                          │
│ 3. Create escalation     │
│    event + activity event│
│                          │
│ 4. Schedule timeout check│
│    (EscalationTimeoutJob)│
└──────────────────────────┘

        │ after timeout_minutes
        ▼
┌──────────────────────────┐
│ EscalationTimeoutJob     │
│                          │
│ 1. Check: is incident    │
│    still not active?     │
│                          │
│ 2. If not active:        │
│    Contact next person   │
│    in escalation_contacts│
│    (ordered by position) │
│                          │
│ 3. Schedule another      │
│    timeout check         │
│                          │
│ 4. Repeat until:         │
│    - Someone marks Active│
│    - List exhausted      │
└──────────────────────────┘
```

**Stopping condition:** When any manager sets `status = 'active'`, all pending escalation events get `resolved_at`, `resolved_by_user_id`, `resolution_reason = 'incident_marked_active'`.

### 3. Status Transitions

```ruby
# app/services/status_transition_service.rb
class StatusTransitionService
  ALLOWED_TRANSITIONS = {
    # Intake — user picks the path
    "new"                => %w[acknowledged proposal_requested],
    # Emergency/standard path
    "acknowledged"       => %w[active on_hold],
    # Quote/proposal path
    "proposal_requested" => %w[proposal_submitted],
    "proposal_submitted" => %w[proposal_signed],
    "proposal_signed"    => %w[active],
    # Shared from active onward
    "active"             => %w[job_started on_hold],
    "job_started"        => %w[completed on_hold],
    "on_hold"            => %w[active job_started completed],
    "completed"          => %w[completed_billed active],
    "completed_billed"   => %w[paid active],
    "paid"               => %w[closed],
  }.freeze

  def initialize(incident:, new_status:, user:)
    @incident = incident
    @new_status = new_status
    @user = user
  end

  def call
    validate_transition!

    ActiveRecord::Base.transaction do
      old_status = @incident.status
      @incident.update!(status: @new_status)

      ActivityLogger.log(
        incident: @incident,
        event_type: "status_changed",
        user: @user,
        metadata: { old_status: old_status, new_status: @new_status }
      )

      # Stop escalation if moving to active
      if @new_status == "active"
        resolve_escalation!
      end

      # Notify relevant users on status change
      StatusChangeNotificationJob.perform_later(@incident.id, old_status, @new_status)
    end
  end

  private

  def validate_transition!
    allowed = ALLOWED_TRANSITIONS[@incident.status] || []
    unless allowed.include?(@new_status)
      raise InvalidTransitionError, "Cannot transition from #{@incident.status} to #{@new_status}"
    end
  end

  def resolve_escalation!
    EscalationEvent.where(incident: @incident, resolved_at: nil)
                   .update_all(
                     resolved_at: Time.current,
                     resolved_by_user_id: @user.id,
                     resolution_reason: "incident_marked_active"
                   )
  end
end
```

### 4. Activity-First Daily Log

Daily log operations are backed by first-class activity records:

- `activity_entries` — one row per operational activity (`title`, `status`, `occurred_at`, optional units context)
- `activity_equipment_actions` — optional child rows per activity (`add/remove/move/other`, quantity, optional note)

Controller flow:

1. `ActivityEntriesController#create/update` validates and stores activity + child equipment actions.
2. Controller logs `activity_event` (`activity_logged` / `activity_updated`) via `ActivityLogger`.
3. `IncidentsController#show` serializes:
   - `daily_activities` (newest-first)
   - `daily_log_dates` (precomputed server-side date filters)
   - `deployed_equipment` summary derived from equipment actions.

### 5. Dashboard Queries

```ruby
# app/services/dashboard_service.rb
class DashboardService
  def initialize(user:)
    @user = user
  end

  def incidents
    scope = visible_incidents
      .includes(:property, :incident_assignments)
      .order(last_activity_at: :desc)

    {
      emergency: scope.where(emergency: true, status: %w[new acknowledged active]),
      active: scope.where(status: "active"),
      needs_attention: scope.where(status: %w[new acknowledged proposal_requested proposal_submitted proposal_signed]),
      on_hold: scope.where(status: "on_hold"),
      recent_completed: scope.where(status: %w[completed completed_billed paid closed])
                             .limit(20)
    }
  end

  def unread_counts
    # Returns { incident_id => { messages: N, activity: N } }
    # Uses bulk aggregation — 2 queries total, not 2 per incident.
    incident_ids = visible_incidents.pluck(:id)
    read_states = IncidentReadState.where(user: @user, incident_id: incident_ids)
                                    .index_by(&:incident_id)

    # Build per-incident thresholds for a single grouped query each
    message_counts = bulk_unread_count(Message, incident_ids, read_states, :last_message_read_at)
    activity_counts = bulk_unread_count(ActivityEvent, incident_ids, read_states, :last_activity_read_at)

    incident_ids.each_with_object({}) do |id, counts|
      counts[id] = {
        messages: message_counts[id] || 0,
        activity: activity_counts[id] || 0
      }
    end
  end

  private

  def bulk_unread_count(model, incident_ids, read_states, timestamp_field)
    # Group incidents by their read-state threshold, then batch-count
    # For incidents with no read state, count all records
    threshold_groups = incident_ids.group_by { |id| read_states[id]&.send(timestamp_field) }

    counts = {}
    threshold_groups.each do |threshold, ids|
      scope = model.where(incident_id: ids)
      scope = scope.where("created_at > ?", threshold) if threshold
      scope.group(:incident_id).count.each { |id, c| counts[id] = c }
    end
    counts
  end

  private

  def visible_incidents
    # Same scoping logic as Authorization concern
  end
end
```

---

## Service Objects

All business logic lives in `app/services/`. Controllers are thin — they validate params, call a service, and render.

| Service | Purpose |
|---------|---------|
| `IncidentCreationService` | Creates incident, auto-transitions status, triggers escalation, sends confirmation |
| `StatusTransitionService` | Validates and executes status changes, resolves escalation, notifies |
| `EscalationService` | Contacts on-call manager, manages escalation chain |
| `DashboardService` | Compiles dashboard data with unread counts |
| `NotificationDispatchService` | Provider-agnostic notification delivery (email, SMS, voice) |
| `ActivityLogger` | Creates activity events + touches `last_activity_at` (used by all services) |

### ActivityLogger

Every service that modifies incident state must log through `ActivityLogger` to keep `activity_events` and `last_activity_at` in sync. Never touch one without the other.

```ruby
# app/services/activity_logger.rb
class ActivityLogger
  def self.log(incident:, event_type:, user:, metadata: {})
    incident.activity_events.create!(
      event_type: event_type,
      performed_by_user: user,
      metadata: metadata
    )
    incident.touch(:last_activity_at)
  end
end

# Usage in any service:
ActivityLogger.log(
  incident: @incident,
  event_type: "equipment_placed",
  user: current_user,
  metadata: { equipment_entry_id: entry.id, equipment_type: entry.type_name }
)
```

---

## Notification Architecture

### Provider-Agnostic Design

```
┌─────────────────────────────┐
│ NotificationDispatchService │
│                             │
│  dispatch(                  │
│    user:,                   │
│    method: :sms,            │
│    message:                 │
│  )                          │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────┐
│ NotificationProvider    │ ◀── Abstract interface
│  #send_sms(to, message) │
│  #send_voice(to, msg)   │
│  #send_email(to, msg)   │
└─────────────────────────┘
     ▲          ▲          ▲
     │          │          │
┌────────┐ ┌────────┐ ┌────────┐
│ Twilio │ │ Vonage │ │  AWS   │
│Provider│ │Provider│ │SNS Prov│
└────────┘ └────────┘ └────────┘
```

```ruby
# app/services/notification_dispatch_service.rb
class NotificationDispatchService
  def initialize(provider: nil)
    @provider = provider || configured_provider
  end

  def dispatch(user:, method:, message:, incident: nil)
    case method.to_sym
    when :email
      deliver_email(user, message)
    when :sms
      @provider.send_sms(to: user.phone, message: message)
    when :voice
      @provider.send_voice(to: user.phone, message: message)
    end
  end

  private

  def configured_provider
    provider_name = ENV.fetch("NOTIFICATION_PROVIDER", "twilio")
    "NotificationProviders::#{provider_name.camelize}".constantize.new
  end

  def deliver_email(user, message)
    # Uses ActionMailer — no external provider needed
    NotificationMailer.alert(user, message).deliver_later
  end
end

# app/services/notification_providers/twilio.rb
module NotificationProviders
  class Twilio
    def send_sms(to:, message:)
      # Twilio API call
    end

    def send_voice(to:, message:)
      # Twilio API call
    end
  end
end
```

### Notification Types

| Trigger | Recipients | Method | Timing |
|---------|-----------|--------|--------|
| Incident created | Creator | Email | Immediate |
| Incident created (emergency) | On-call manager → escalation chain | SMS/Voice/Email | Immediate + timeout escalation |
| Any status change | All assigned users (with `status_change_notifications` enabled) | Email | Immediate |
| User assigned to incident | The assigned user | Email | Immediate |
| New message | Incident participants (with `message_notifications` enabled) | Email | Immediate |
| Daily digest | Users with `daily_digest` enabled | Email | Scheduled (once/day via Solid Queue) |

### Background Jobs

| Job | Queue | Purpose |
|-----|-------|---------|
| `EscalationJob` | `urgent` | Initiates emergency escalation chain |
| `EscalationTimeoutJob` | `urgent` | Checks if escalation needs to continue after timeout |
| `StatusChangeNotificationJob` | `default` | Sends status change emails to relevant users |
| `AssignmentNotificationJob` | `default` | Sends assignment notification to newly assigned user |
| `MessageNotificationJob` | `default` | Sends new message notifications |
| `DailyDigestJob` | `low` | Compiles and sends daily digest emails |

```ruby
# config/solid_queue.yml (recurring tasks)
recurring:
  daily_digest:
    class: DailyDigestJob
    schedule: "every day at 6am"
    queue: low
```

**Digest timezone:** The cron schedule fires at 6am server time (UTC on Heroku). The `DailyDigestJob` iterates users and computes "yesterday's activity" relative to each user's configured timezone, so digest content is timezone-correct regardless of when the job runs.

---

## Timezone Handling

All datetimes stored in UTC in the database. Displayed in the user's configured timezone.

```ruby
# app/controllers/application_controller.rb
around_action :set_timezone

def set_timezone(&block)
  Time.use_zone(current_user&.timezone || "America/Chicago", &block)
end
```

On the frontend, timestamps are passed as ISO 8601 UTC strings. React components format them using the user's timezone from shared props:

```tsx
// Timezone available via shared Inertia data
const { auth } = usePage().props;
const userTimezone = auth.user.timezone;

// Format timestamps in user's timezone
function formatTime(isoString: string): string {
  return new Date(isoString).toLocaleString("en-US", {
    timeZone: userTimezone
  });
}
```

---

## File Storage

### Active Storage Configuration

```ruby
# config/storage.yml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

amazon:
  service: S3
  access_key_id: <%= ENV["AWS_ACCESS_KEY_ID"] %>
  secret_access_key: <%= ENV["AWS_SECRET_ACCESS_KEY"] %>
  region: <%= ENV["AWS_REGION"] %>
  bucket: <%= ENV["AWS_S3_BUCKET"] %>
```

```ruby
# config/environments/development.rb
config.active_storage.service = :local

# config/environments/production.rb
config.active_storage.service = :amazon
```

### Attachment Model

```ruby
# app/models/attachment.rb
class Attachment < ApplicationRecord
  belongs_to :attachable, polymorphic: true
  belongs_to :uploaded_by_user, class_name: "User"

  has_one_attached :file

  validates :category, inclusion: {
    in: %w[photo moisture_mapping moisture_readings psychrometric_log signed_document general]
  }
end
```

---

## Inertia Shared Data

Extends the standard playbook pattern with Genixo-specific data:

```ruby
# app/controllers/application_controller.rb
inertia_share auth: -> {
  {
    user: Current.user ? {
      id: Current.user.id,
      email: Current.user.email_address,
      first_name: Current.user.first_name,
      last_name: Current.user.last_name,
      full_name: Current.user.full_name,
      initials: Current.user.initials,
      user_type: Current.user.user_type,
      organization_type: Current.user.organization.organization_type,
      organization_name: Current.user.organization.name,
      timezone: Current.user.timezone
    } : nil,
    authenticated: !!Current.user
  }
},
emergency_phone: -> {
  # For PM users: mitigation org phone number, displayed in sidebar
  next nil unless current_user&.pm_user?
  mit_org_id = Property.where(property_management_org_id: current_user.organization_id)
                       .pick(:mitigation_org_id)
  next nil unless mit_org_id
  format_phone(Organization.find(mit_org_id).phone)
},
routes: -> {
  # Genixo-specific routes shared with frontend
  {
    dashboard: dashboard_path,
    incidents: incidents_path,
    # ... etc
  }
}
```

---

## Frontend Page Structure

```
app/frontend/pages/
├── Auth/
│   ├── Login.tsx
│   └── AcceptInvitation.tsx
├── Dashboard/
│   └── Show.tsx              # Main hub — incident list grouped by urgency
├── Incidents/
│   ├── Index.tsx              # Flat filterable incident list
│   ├── Show.tsx               # Split-panel incident detail
│   ├── New.tsx                # Intake form
│   └── components/
│       ├── StatusBadge.tsx
│       ├── OverviewPanel.tsx  # Detail rail: description, deployed equipment, team, contacts
│       ├── MessagePanel.tsx   # Tab panel: chat thread
│       ├── DailyLogPanel.tsx  # Tab panel: activity-first daily log
│       ├── DocumentPanel.tsx  # Tab panel: all attachments
│       ├── LaborEntryForm.tsx
│       ├── EquipmentLog.tsx
│       ├── OperationalNotes.tsx
│       └── AttachmentUpload.tsx
├── Properties/
│   ├── Index.tsx
│   ├── Show.tsx
│   └── New.tsx
├── Organizations/
│   ├── Index.tsx
│   ├── Show.tsx
│   └── New.tsx
├── Users/
│   ├── Index.tsx
│   └── Show.tsx
├── EquipmentItems/
│   └── Index.tsx              # Equipment inventory management (mitigation only)
├── Settings/
│   ├── Profile.tsx            # Profile, password, notifications, timezone
│   ├── OnCall.tsx             # On-call configuration (mitigation only)
│   └── EquipmentTypes.tsx     # Equipment type management (mitigation only)
└── layout/
    ├── AppLayout.tsx          # Authenticated shell
    └── RoleSidebar.tsx        # Navigation varies by role
```

### Role-Aware UI

The dashboard and navigation adapt based on `auth.user.user_type`:

- **Manager**: Full dashboard with all incidents, emergency highlights, assignment controls
- **Technician**: Dashboard filtered to assigned incidents only, quick-action buttons for labor/equipment/notes
- **Office/Sales**: Full incident visibility, user/property/org management, read-only on operational data
- **PM/AM/Other**: Incidents on assigned properties + directly assigned incidents, messaging, can manage own org's assignments

---

## Data Flow Summary

```
                    ┌──────────────┐
                    │   Browser    │
                    │  (React +   │
                    │   Inertia)  │
                    └──────┬───────┘
                           │ Inertia requests
                           ▼
                    ┌──────────────┐
                    │  Controller  │
                    │  (thin)      │
                    │  - auth      │
                    │  - authorize │
                    │  - params    │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │   Service    │
                    │  (business   │
                    │   logic)     │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
       ┌───────────┐ ┌──────────┐ ┌──────────┐
       │  Models   │ │  Mailers │ │  Jobs    │
       │  (data)   │ │  (email) │ │  (async) │
       └───────────┘ └──────────┘ └──────────┘
              │                         │
              ▼                         ▼
       ┌───────────┐           ┌──────────────┐
       │ PostgreSQL│           │ Solid Queue   │
       │           │           │ (background   │
       │           │           │  processing)  │
       └───────────┘           └──────────────┘
```

---

## Testing Strategy

- **Models:** Validations, scoping, state machine transitions
- **Services:** Core business logic — incident creation, status transitions, escalation, notifications
- **Controllers:** Integration tests — auth, authorization scoping, correct service invocation
- **System tests:** Critical user flows — incident creation, escalation, messaging

```bash
bin/rails test                           # All tests
bin/rails test test/services/            # Service tests
bin/rails test test/models/incident_test.rb:42  # Specific test
```

Stub external services (notification providers) in tests. Use `ActiveJob::TestHelper` for job assertions.

---

## Technical Decisions

### Why Permissions model instead of Pundit/CanCanCan?

The `Permissions` model defines permission constants and role defaults. Each user stores their actual permissions in a `permissions` jsonb array on the `users` table. Roles provide sensible defaults via `Permissions.defaults_for(user_type)` at user creation, but managers can toggle individual permissions per user through the edit modal. The `user.can?(permission)` interface checks the user's stored permissions array, enabling per-user customization without a full RBAC gem.

### Why `last_activity_at` denormalization?

Dashboard sorting by "most recent activity" is the primary query. Computing this via joins across 6 tables on every page load is expensive. A single denormalized column with an `after_create` touch is simple, fast, and correct.

### Why polymorphic attachments instead of two tables?

Incidents and messages both need file attachments with the same metadata (category, uploader, file). One table with `attachable_type`/`attachable_id` avoids duplication and keeps attachment logic in one place.

### Why provider-agnostic notifications?

The notification provider (Twilio, Vonage, etc.) hasn't been chosen yet. The service interface (`send_sms`, `send_voice`) is the same regardless of provider. Swapping providers means writing one new class, not refactoring the entire notification flow.

### Why no ActionCable/WebSocket for MVP?

Real-time updates add significant complexity (connection management, presence tracking, offline handling). For MVP, page refreshes and email notifications are sufficient. The Solid Cable infrastructure is in place via the playbook, so adding live updates later is straightforward.
