class IncidentsController < ApplicationController
  before_action :authorize_creation!, only: %i[new create]
  before_action :set_incident, only: %i[show update transition mark_read dfr attachments_page]
  before_action :authorize_edit!, only: %i[update]
  before_action :authorize_transition!, only: %i[transition]

  def index
    scope = visible_incidents.includes(property: :property_management_org)

    # Filters
    if params[:status].present?
      statuses = params[:status].split(",").select { |s| Incident::STATUSES.include?(s) }
      scope = scope.where(status: statuses) if statuses.any?
    end
    if params[:property_id].present?
      property_ids = params[:property_id].split(",").map(&:to_i).select(&:positive?)
      scope = scope.where(property_id: property_ids) if property_ids.any?
    end
    if params[:project_type].present?
      types = params[:project_type].split(",").select { |t| Incident::PROJECT_TYPES.include?(t) }
      scope = scope.where(project_type: types) if types.any?
    end
    scope = scope.where(emergency: true) if params[:emergency] == "1"
    scope = scope.where(emergency: false) if params[:emergency] == "0"

    # Hide closed incidents unless a status filter is explicitly applied
    scope = scope.where.not(status: "closed") if params[:status].blank?

    if params[:search].present?
      term = "%#{params[:search]}%"
      scope = scope.left_joins(:property).where(
        "incidents.description ILIKE :term OR properties.name ILIKE :term",
        term: term
      )
    end

    # Sort
    sort_col = %w[property status project_type last_activity_at created_at].include?(params[:sort]) ? params[:sort] : "created_at"
    sort_dir = params[:direction] == "asc" ? :asc : :desc

    scope = case sort_col
    when "property"
      scope.joins(:property).order("properties.name #{sort_dir}")
    else
      scope.order(sort_col => sort_dir)
    end

    # Paginate
    page = [ params.fetch(:page, 1).to_i, 1 ].max
    per_page = 25
    total = scope.count
    incidents = scope.offset((page - 1) * per_page).limit(per_page).to_a

    # Only compute unread for the current page, not all incidents
    page_ids = incidents.map(&:id)
    unread = DashboardService.new(user: current_user).unread_counts_for(page_ids)

    render inertia: "Incidents/Index", props: {
      incidents: incidents.map { |i| serialize_incident(i, unread) },
      pagination: { page: page, per_page: per_page, total: total, total_pages: (total.to_f / per_page).ceil },
      filters: {
        search: params[:search],
        status: params[:status],
        property_id: params[:property_id],
        project_type: params[:project_type],
        emergency: params[:emergency],
        hide_closed: params[:status].blank?
      },
      sort: { column: sort_col, direction: sort_dir.to_s },
      filter_options: {
        statuses: Incident::STATUSES.map { |s| { value: s, label: Incident::STATUS_LABELS[s] } },
        project_types: Incident::PROJECT_TYPES.map { |t| { value: t, label: Incident::PROJECT_TYPE_LABELS[t] } },
        properties: visible_properties.order(:name).map { |p| { id: p.id, name: p.name } }
      },
      can_create: can_create_incident?
    }
  end

  def new
    properties = creatable_properties.includes(:property_management_org)
    render inertia: "Incidents/New", props: {
      properties: properties.map { |p| { id: p.id, name: p.name, address: p.short_address, organization_id: p.property_management_org_id, organization_name: p.property_management_org.name } },
      organizations: properties.map(&:property_management_org).uniq.sort_by(&:name).map { |o| { id: o.id, name: o.name } },
      project_types: Incident::PROJECT_TYPES.map { |t| { value: t, label: Incident::PROJECT_TYPE_LABELS[t] } },
      damage_types: Incident::DAMAGE_TYPES.map { |t| { value: t, label: Incident::DAMAGE_LABELS[t] } },
      can_assign: can_assign_to_incident?,
      can_manage_contacts: can_manage_contacts?,
      property_users: can_assign_to_incident? ? assignable_users_by_property : {}
    }
  end

  def create
    property = creatable_properties.find(params[:incident][:property_id])
    incident = IncidentCreationService.new(
      property: property,
      user: current_user,
      params: incident_params
    ).call

    redirect_to incident_path(incident), notice: "Incident created."
  rescue ActiveRecord::RecordNotFound
    redirect_to new_incident_path, alert: "Property not found."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_incident_path,
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not create incident."
  end

  def update
    @incident.update!(update_incident_params)
    redirect_to incident_path(@incident), notice: "Incident updated."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not update incident."
  end

  def show
    property = @incident.property
    unread = compute_show_unread_counts(@incident)
    deployed_equipment = serialize_deployed_equipment(@incident)
    daily_activities = serialize_daily_activities(@incident)
    labor_entries = serialize_labor_entries(@incident)
    operational_notes = serialize_operational_notes(@incident)
    # Lightweight query for attachment dates (used by daily log) — no full records loaded
    attachment_dates = attachment_date_labels(@incident)
    daily_log_dates = serialize_daily_log_dates(
      daily_activities: daily_activities,
      labor_entries: labor_entries,
      operational_notes: operational_notes,
      attachment_dates: attachment_dates
    )
    daily_log_table_groups = serialize_daily_log_table_groups(
      daily_activities: daily_activities,
      labor_entries: labor_entries,
      operational_notes: operational_notes
    )

    assigned = @incident.incident_assignments.includes(user: :organization)
      .joins(:user).where(users: { active: true })
      .order("users.last_name, users.first_name")

    render inertia: "Incidents/Show", props: {
      incident: {
        id: @incident.id,
        path: incident_path(@incident),
        edit_path: can_edit_incident? ? incident_path(@incident) : nil,
        transition_path: transition_incident_path(@incident),
        description: @incident.description,
        cause: @incident.cause,
        requested_next_steps: @incident.requested_next_steps,
        units_affected: @incident.units_affected,
        affected_room_numbers: @incident.affected_room_numbers,
        visitors: @incident.visitors,
        usable_rooms_returned: @incident.usable_rooms_returned,
        estimated_date_of_return: @incident.estimated_date_of_return&.iso8601,
        estimated_date_of_return_label: format_date(@incident.estimated_date_of_return),
        status: @incident.status,
        status_label: @incident.display_status_label,
        project_type: @incident.project_type,
        project_type_label: Incident::PROJECT_TYPE_LABELS[@incident.project_type],
        damage_type: @incident.damage_type,
        damage_label: Incident::DAMAGE_LABELS[@incident.damage_type],
        emergency: @incident.emergency,
        job_id: @incident.job_id,
        do_not_exceed_limit: @incident.do_not_exceed_limit,
        location_of_damage: @incident.location_of_damage,
        created_at: @incident.created_at.iso8601,
        created_at_label: format_date(@incident.created_at),
        created_by: @incident.created_by_user ? {
          name: @incident.created_by_user.full_name,
          email: @incident.created_by_user.email_address,
          phone: format_phone(@incident.created_by_user.phone),
          phone_raw: @incident.created_by_user.phone
        } : nil,
        property: {
          id: property.id,
          name: property.name,
          address_line1: property.street_address,
          address_line2: [ property.city, property.state ].filter_map(&:presence).join(", ") + (property.zip.present? ? " #{property.zip}" : ""),
          path: property_path(property),
          organization_name: property.property_management_org.name
        },
        deployed_equipment: deployed_equipment,
        assignments_path: incident_assignments_path(@incident),
        mitigation_team: serialize_team_users(assigned.select { |a| a.user.mitigation_user? }),
        pm_team: serialize_team_users(assigned.select { |a| a.user.pm_user? }),
        show_stats: @incident.labor_entries.any? || deployed_equipment.any?,
        stats: incident_stats(@incident, deployed_equipment),
        contacts_path: incident_contacts_path(@incident),
        contacts: @incident.incident_contacts.order(:name).map { |c|
          {
            id: c.id,
            name: c.name,
            title: c.title,
            email: c.email,
            phone: format_phone(c.phone),
            phone_raw: c.phone,
            onsite: c.onsite,
            update_path: can_manage_contacts? ? incident_contact_path(@incident, c) : nil,
            remove_path: can_manage_contacts? ? incident_contact_path(@incident, c) : nil
          }
        },
        pm_contacts: serialize_pm_contacts(@incident),
        messages_path: incident_messages_path(@incident),
        activity_entries_path: incident_activity_entries_path(@incident),
        labor_entries_path: incident_labor_entries_path(@incident),
        equipment_entries_path: incident_equipment_entries_path(@incident),
        operational_notes_path: incident_operational_notes_path(@incident),
        attachments_path: incident_attachments_path(@incident),
        upload_photo_path: upload_photo_incident_attachments_path(@incident),
        dfr_path: dfr_incident_path(@incident),
        attachments_page_path: attachments_page_incident_path(@incident),
        mark_read_path: mark_read_incident_path(@incident),
        unread_messages: unread[:messages],
        unread_activity: unread[:activity],
        valid_transitions: can_transition_status? ? (StatusTransitionService.transitions_for(@incident)[@incident.status] || []).map { |s|
          { value: s, label: Incident::STATUS_LABELS[s] }
        } : []
      },
      daily_activities: daily_activities,
      daily_log_dates: daily_log_dates,
      daily_log_table_groups: daily_log_table_groups,
      labor_entries: labor_entries,
      can_transition: can_transition_status?,
      can_assign: can_assign_to_incident?,
      can_manage_contacts: can_manage_contacts?,
      can_edit: can_edit_incident?,
      can_manage_activities: can_manage_activities?,
      can_manage_labor: can_manage_labor?,
      can_manage_equipment: can_manage_equipment?,
      can_manage_moisture: can_manage_moisture_readings?,
      can_manage_attachments: can_manage_attachments?,
      show_mitigation_team: current_user.mitigation_user?,
      can_create_notes: can_create_operational_note?,
      project_types: Incident::PROJECT_TYPES.map { |t| { value: t, label: Incident::PROJECT_TYPE_LABELS[t] } },
      damage_types: Incident::DAMAGE_TYPES.map { |t| { value: t, label: Incident::DAMAGE_LABELS[t] } },
      back_path: incidents_path,
      # Deferred — fetched on first tab click, then cached by Inertia
      labor_log: InertiaRails.defer(group: "labor") { serialize_labor_log(@incident) },
      assignable_labor_users: InertiaRails.defer(group: "labor") { can_manage_labor? ? assignable_labor_users(@incident) : [] },
      equipment_log: InertiaRails.defer(group: "equipment") { serialize_equipment_log(@incident) },
      equipment_types: InertiaRails.defer(group: "equipment") { can_manage_equipment? ? equipment_types_for_incident(@incident) : [] },
      equipment_items_by_type: InertiaRails.defer(group: "equipment") { can_manage_equipment? ? equipment_items_by_type(@incident) : {} },
      attachable_equipment_entries: InertiaRails.defer(group: "equipment") { can_manage_activities? ? attachable_equipment_entries(@incident) : [] },
      messages: InertiaRails.defer(group: "messages") { serialize_messages(@incident.messages.includes({ user: :organization }, { attachments: [ :uploaded_by_user, { file_attachment: :blob } ] }).order(created_at: :asc)) },
      attachments: InertiaRails.defer(group: "documents") { serialize_attachments(@incident) },
      operational_notes: InertiaRails.defer(group: "documents") { serialize_operational_notes(@incident) },
      activity_entries: InertiaRails.defer(group: "activity") { serialize_activity_entries(@incident) },
      moisture_data: InertiaRails.defer(group: "moisture") { serialize_moisture_data(@incident) },
      assignable_mitigation_users: InertiaRails.defer(group: "team") { can_assign_to_incident? ? assignable_incident_users(@incident, :mitigation) : [] },
      assignable_pm_users: InertiaRails.defer(group: "team") { can_assign_to_incident? ? assignable_incident_users(@incident, :pm) : [] }
    }
  end

  def transition
    StatusTransitionService.new(
      incident: @incident,
      new_status: params[:status],
      user: current_user
    ).call

    redirect_to incident_path(@incident), notice: "Status updated."
  rescue StatusTransitionService::InvalidTransitionError => e
    redirect_to incident_path(@incident), alert: e.message
  end

  def mark_read
    read_state = @incident.incident_read_states.find_or_initialize_by(user: current_user)

    case params[:tab]
    when "messages"
      read_state.last_message_read_at = Time.current
    when "activity"
      read_state.last_activity_read_at = Time.current
    end

    read_state.save!
    redirect_back fallback_location: incident_path(@incident)
  end

  def dfr
    date = params[:date].presence || Date.current.to_s
    DfrPdfJob.perform_later(@incident.id, date, current_user.timezone, current_user.id)
    redirect_to incident_path(@incident), notice: "DFR PDF is being generated. It will appear in documents shortly."
  end

  def attachments_page
    page = [ params.fetch(:page, 1).to_i, 1 ].max
    render json: serialize_attachments_page(@incident, page: page)
  end

  private

  def authorize_creation!
    raise ActiveRecord::RecordNotFound unless can_create_incident?
  end

  def set_incident
    scope = visible_incidents

    # Full page renders need eager loading for the base page (daily log, stats,
    # deployed equipment, etc.). Partial/deferred requests skip it — each deferred
    # block loads its own associations.
    unless request.headers["X-Inertia-Partial-Data"].present?
      scope = scope.includes(
        :created_by_user, :operational_notes, :incident_contacts, :incident_read_states,
        property: [ :property_management_org, :mitigation_org ],
        incident_assignments: { user: :organization },
        activity_entries: [ :performed_by_user, { equipment_actions: [ :equipment_type, :equipment_entry ] } ],
        labor_entries: [ :user, :created_by_user ],
        equipment_entries: :equipment_type
      )
    end

    @incident = scope.find(params[:id])
  end

  def authorize_edit!
    raise ActiveRecord::RecordNotFound unless can_edit_incident?
  end

  def authorize_transition!
    raise ActiveRecord::RecordNotFound unless can_transition_status?
  end

  def creatable_properties
    visible_properties
  end

  def incident_params
    incident_input = params.require(:incident)
    permitted = incident_input.permit(
      :project_type, :damage_type, :description, :cause,
      :requested_next_steps, :units_affected, :affected_room_numbers, :job_id,
      :do_not_exceed_limit, :location_of_damage,
      additional_user_ids: [],
      contacts: [ :name, :title, :email, :phone, :onsite ]
    ).to_h.symbolize_keys

    # Ensure contacts is an array of hashes with symbol keys. Inertia can send
    # nested arrays as indexed hashes, so normalize from the raw param shape.
    raw_contacts = incident_input[:contacts] || params[:contacts]
    normalized_contacts = case raw_contacts
    when ActionController::Parameters
      raw_contacts.values
    when Array
      raw_contacts
    when nil
      nil
    else
      [ raw_contacts ]
    end

    if normalized_contacts
      permitted[:contacts] = normalized_contacts.map do |contact|
        if contact.respond_to?(:to_unsafe_h)
          contact.to_unsafe_h.symbolize_keys
        elsif contact.is_a?(Hash)
          contact.symbolize_keys
        else
          contact
        end
      end
    elsif permitted[:contacts].is_a?(Hash)
      permitted[:contacts] = permitted[:contacts].values.map { |c| c.symbolize_keys }
    elsif permitted[:contacts].is_a?(Array)
      permitted[:contacts] = permitted[:contacts].map { |c| c.is_a?(Hash) ? c.symbolize_keys : c }
    end

    # Inertia form serialization can send arrays as indexed hashes ("0" => "1", "1" => "2").
    raw_additional_user_ids = incident_input[:additional_user_ids] || params[:additional_user_ids]
    normalized_additional_user_ids = case raw_additional_user_ids
    when ActionController::Parameters
      raw_additional_user_ids.values
    when Array
      raw_additional_user_ids
    when nil
      nil
    else
      [ raw_additional_user_ids ]
    end
    permitted[:additional_user_ids] = normalized_additional_user_ids if normalized_additional_user_ids

    permitted
  end

  def update_incident_params
    params.require(:incident).permit(
      :description, :cause, :requested_next_steps,
      :units_affected, :affected_room_numbers, :job_id,
      :project_type, :damage_type,
      :do_not_exceed_limit, :location_of_damage,
      :visitors, :usable_rooms_returned, :estimated_date_of_return
    )
  end

  def can_manage_contacts?
    mitigation_admin? || current_user.pm_user?
  end

  def can_manage_labor?
    can_create_labor?
  end

  def can_manage_equipment?
    can_create_equipment?
  end

  def can_manage_activities?
    can_create_equipment?
  end

  def can_edit_activity_entry?(entry)
    return true if mitigation_admin?

    can_manage_activities? && entry.performed_by_user_id == current_user.id
  end

  def can_edit_labor_entry?(entry)
    return true if mitigation_admin?
    can_create_labor? && entry.created_by_user_id == current_user.id
  end

  def can_edit_equipment_entry?(entry)
    return true if mitigation_admin?
    can_create_equipment? && entry.logged_by_user_id == current_user.id
  end

  def can_assign_to_incident?
    mitigation_admin? || current_user.pm_user?
  end

  def can_remove_assignment?(user)
    return true if mitigation_admin?
    current_user.pm_user? && user.organization_id == current_user.organization_id
  end

  def assignable_users_by_property
    properties = creatable_properties.includes(:mitigation_org, :property_management_org)

    # PM users only assign within their own org; mitigation admins see both orgs
    org_ids = if current_user.pm_user?
      [ current_user.organization_id ]
    else
      properties.flat_map { |p| [ p.mitigation_org_id, p.property_management_org_id ] }.uniq
    end

    all_users = User.where(active: true, organization_id: org_ids).includes(:organization).order(:last_name, :first_name)
    users_by_org = all_users.group_by(&:organization_id)

    prop_assignments = PropertyAssignment.where(property: properties).pluck(:property_id, :user_id)
    assigned_by_property = prop_assignments.group_by(&:first).transform_values { |v| v.map(&:last).to_set }

    result = {}
    properties.each do |property|
      mit_users = current_user.pm_user? ? [] : (users_by_org[property.mitigation_org_id] || [])
      pm_users = users_by_org[property.property_management_org_id] || []
      prop_assigned_ids = assigned_by_property[property.id] || Set.new

      property_user_list = (mit_users + pm_users).map do |u|
        auto = if u.mitigation_user? && !u.technician?
          true # GenXO managers + office/sales
        elsif u.user_type == User::PM_MANAGER
          true # PM managers always auto-assigned
        elsif prop_assigned_ids.include?(u.id) && [ User::PROPERTY_MANAGER, User::AREA_MANAGER ].include?(u.user_type)
          true # PM-side property assignees
        else
          false
        end

        { id: u.id, full_name: u.full_name, role_label: User::ROLE_LABELS[u.user_type], organization_name: u.organization.name, org_type: u.mitigation_user? ? "mitigation" : "pm", auto_assign: auto }
      end

      result[property.id] = property_user_list
    end

    result
  end

  def assignable_incident_users(incident, org_type)
    org_id = org_type == :mitigation ? incident.property.mitigation_org_id : incident.property.property_management_org_id

    # PM users can only assign within their own org
    return [] if current_user.pm_user? && current_user.organization_id != org_id

    User.where(active: true, organization_id: org_id)
      .where.not(id: incident.assigned_user_ids)
      .order(:last_name, :first_name)
      .map { |u| { id: u.id, full_name: u.full_name, role_label: User::ROLE_LABELS[u.user_type] } }
  end

  TEAM_SORT_ORDER = [ User::MANAGER, User::OFFICE_SALES, User::TECHNICIAN, User::PM_MANAGER, User::AREA_MANAGER, User::PROPERTY_MANAGER ].freeze

  def serialize_team_users(assignments)
    assignments.sort_by { |a| [ TEAM_SORT_ORDER.index(a.user.user_type) || 99, a.user.last_name ] }.map do |a|
      {
        id: a.user.id,
        assignment_id: a.id,
        full_name: a.user.full_name,
        initials: a.user.initials,
        role_label: User::ROLE_LABELS[a.user.user_type],
        email: a.user.email_address,
        phone: format_phone(a.user.phone),
        phone_raw: a.user.phone,
        remove_path: can_remove_assignment?(a.user) ? incident_assignment_path(@incident, a) : nil
      }
    end
  end

  def incident_stats(incident, deployed_equipment)
    active = deployed_equipment.sum { |item| item[:quantity].to_i }
    {
      total_labor_hours: incident.labor_entries.sum { |e| e.hours.to_f },
      active_equipment: active,
      total_equipment_placed: active,
      show_removed_equipment: false
    }
  end

  def serialize_deployed_equipment(incident)
    buckets = {}
    activity_actions_seen = false

    incident.activity_entries.each do |activity|
      activity.equipment_actions.each do |action|
        activity_actions_seen = true
        type_name = action.type_name.to_s.strip
        next if type_name.blank?

        key = type_name.downcase
        bucket = buckets[key] ||= {
          id: "type-#{key}",
          type_name: type_name,
          quantity: 0,
          last_event_at: nil,
          last_event_label: nil,
          last_note: nil,
          last_actor_name: nil
        }

        quantity = action.quantity.presence || 1

        case action.action_type
        when "add"
          bucket[:quantity] += quantity
        when "remove"
          bucket[:quantity] -= quantity
        end

        if bucket[:last_event_at].nil? || activity.occurred_at >= bucket[:last_event_at]
          bucket[:last_event_at] = activity.occurred_at
          bucket[:last_event_label] = equipment_action_label(action.action_type)
          bucket[:last_note] = action.note
          bucket[:last_actor_name] = activity.performed_by_user.full_name
        end
      end
    end

    # Backward compatibility for incidents that do not yet use activity equipment actions.
    unless activity_actions_seen
      incident.equipment_entries
        .includes(:equipment_type, :logged_by_user)
        .where(removed_at: nil)
        .find_each do |entry|
        type_name = entry.type_name.to_s.strip
        next if type_name.blank?

        key = type_name.downcase
        bucket = buckets[key] ||= {
          id: "type-#{key}",
          type_name: type_name,
          quantity: 0,
          last_event_at: nil,
          last_event_label: nil,
          last_note: nil,
          last_actor_name: nil
        }

        bucket[:quantity] += 1

        if bucket[:last_event_at].nil? || entry.placed_at >= bucket[:last_event_at]
          bucket[:last_event_at] = entry.placed_at
          bucket[:last_event_label] = "Add"
          bucket[:last_note] = entry.location_notes
          bucket[:last_actor_name] = entry.logged_by_user.full_name
        end
      end
    end

    buckets.values
      .select { |bucket| bucket[:quantity].positive? }
      .sort_by { |bucket| [ -(bucket[:last_event_at]&.to_f || 0), bucket[:type_name] ] }
      .map do |bucket|
      {
        id: bucket[:id],
        type_name: bucket[:type_name],
        quantity: bucket[:quantity],
        last_event_label: bucket[:last_event_label],
        last_event_at_label: format_datetime(bucket[:last_event_at]),
        note: bucket[:last_note],
        actor_name: bucket[:last_actor_name]
      }
    end
  end

  def serialize_daily_activities(incident)
    incident.activity_entries
      .sort_by { |e| [ -e.occurred_at.to_f, -e.created_at.to_f ] }
      .map do |entry|
      editable = can_edit_activity_entry?(entry)
      {
        id: entry.id,
        title: entry.title,
        details: entry.details,
        status: entry.status,
        occurred_at: entry.occurred_at.iso8601,
        occurred_at_value: entry.occurred_at.to_date.iso8601,
        occurred_at_label: format_datetime(entry.occurred_at),
        date_key: entry.occurred_at.to_date.iso8601,
        date_label: format_date(entry.occurred_at),
        units_affected: entry.units_affected,
        units_affected_description: entry.units_affected_description,
        visitors: entry.visitors,
        usable_rooms_returned: entry.usable_rooms_returned,
        estimated_date_of_return: entry.estimated_date_of_return&.iso8601,
        created_by_name: entry.performed_by_user.full_name,
        edit_path: editable ? incident_activity_entry_path(incident, entry) : nil,
        equipment_actions: entry.equipment_actions.map do |action|
          {
            id: action.id,
            action_type: action.action_type,
            action_label: equipment_action_label(action.action_type),
            quantity: action.quantity,
            type_name: action.type_name,
            note: action.note,
            equipment_type_id: action.equipment_type_id,
            equipment_type_other: action.equipment_type_other,
            equipment_entry_id: action.equipment_entry_id
          }
        end
      }
    end
  end

  def serialize_daily_log_dates(daily_activities:, labor_entries:, operational_notes:, attachment_dates: {})
    labels = {}

    daily_activities.each do |entry|
      labels[entry[:date_key]] ||= entry[:date_label]
    end
    labor_entries.each do |entry|
      labels[entry[:log_date]] ||= entry[:log_date_label]
    end
    operational_notes.each do |entry|
      labels[entry[:log_date]] ||= entry[:log_date_label]
    end
    attachment_dates.each do |date_key, date_label|
      labels[date_key] ||= date_label
    end

    labels.keys.sort.reverse.map do |date_key|
      { key: date_key, label: labels[date_key] || date_key }
    end
  end

  def attachment_date_labels(incident)
    incident.attachments
      .where.not(log_date: nil)
      .distinct.pluck(:log_date)
      .each_with_object({}) { |d, h| h[d.iso8601] = format_date(d) }
  end

  def serialize_daily_log_table_groups(daily_activities:, labor_entries:, operational_notes:)
    groups = Hash.new { |hash, key| hash[key] = [] }

    daily_activities.each do |activity|
      groups[activity[:date_key]] << {
        id: "activity-#{activity[:id]}",
        occurred_at: activity[:occurred_at],
        time_label: format_time(Time.zone.parse(activity[:occurred_at])),
        row_type: "activity",
        row_type_label: "Activity",
        primary_label: activity[:title],
        status_label: activity[:status],
        units_label: daily_activity_units_label(activity),
        detail_label: daily_activity_detail_label(activity),
        actor_name: activity[:created_by_name],
        edit_path: activity[:edit_path],
        visitors: activity[:visitors],
        usable_rooms_returned: activity[:usable_rooms_returned],
        estimated_date_of_return: activity[:estimated_date_of_return].present? ? format_date(Time.zone.parse(activity[:estimated_date_of_return])) : nil,
        equipment_actions: activity[:equipment_actions].map { |ea|
          label_parts = [ ea[:action_label], ea[:quantity], ea[:type_name] ].compact
          { label: label_parts.join(" "), note: ea[:note] }
        }
      }
    end

    operational_notes.each do |note|
      groups[note[:log_date]] << {
        id: "note-#{note[:id]}",
        occurred_at: note[:created_at],
        time_label: note[:time_label] || "—",
        row_type: "note",
        row_type_label: "Note",
        primary_label: "Operational note",
        status_label: "—",
        units_label: "—",
        detail_label: note[:note_text],
        actor_name: note[:created_by_name],
        edit_path: nil
      }
    end

    equip_by_date = @incident ? equipment_summary_by_date(@incident) : {}

    # Precompute labor hours per date for the group header
    labor_hours_by_date = labor_entries.each_with_object(Hash.new(0.0)) do |entry, map|
      map[entry[:log_date]] += entry[:hours].to_f
    end

    # Index existing DFR attachments by date
    dfr_by_date = @incident ? @incident.attachments.where(category: "dfr")
      .index_by { |a| a.log_date&.iso8601 } : {}

    groups.keys.sort.reverse.map do |date_key|
      rows = groups[date_key].sort_by do |row|
        parsed = parse_metadata_time(row[:occurred_at]) || Time.zone.parse("#{date_key}T00:00:00")
        -parsed.to_f
      end

      date_equip = equip_by_date[date_key] || []
      dfr_att = dfr_by_date[date_key]

      {
        date_key: date_key,
        date_label: format_date(Time.zone.parse("#{date_key}T00:00:00")),
        rows: rows,
        equipment_summary: date_equip,
        total_labor_hours: labor_hours_by_date[date_key].round(1),
        total_equip_count: date_equip.sum { |e| e[:count] },
        dfr: dfr_att ? {
          url: rails_blob_path(dfr_att.file, disposition: "inline"),
          filename: dfr_att.file.filename.to_s
        } : nil
      }
    end
  end

  def equipment_summary_by_date(incident)
    entries = incident.equipment_entries
    return {} if entries.empty?

    # Build per-entry date ranges once, then group — O(entries * days_active) instead of O(dates * entries)
    result = {}
    entries.each do |entry|
      placed = entry.placed_at.to_date
      removed = entry.removed_at&.to_date || Date.current
      type_name = entry.type_name.to_s.strip
      next if type_name.blank?

      key = type_name.downcase
      (placed..removed).each do |date|
        date_key = date.iso8601
        result[date_key] ||= {}
        bucket = result[date_key][key] ||= { type_name: type_name, count: 0, hours: 0.0 }
        bucket[:count] += 1

        day_start = [ entry.placed_at, date.beginning_of_day ].max
        day_end = [ entry.removed_at || Time.current, date.end_of_day ].min
        bucket[:hours] += ((day_end - day_start) / 1.hour).round(1)
      end
    end

    result.transform_values do |buckets|
      buckets.values
        .sort_by { |b| [ -b[:count], b[:type_name] ] }
        .map { |b| { type_name: b[:type_name], count: b[:count], hours: b[:hours].round(1) } }
    end
  end

  def daily_activity_units_label(activity)
    return "—" if activity[:units_affected].blank? && activity[:units_affected_description].blank?

    [
      activity[:units_affected].presence ? activity[:units_affected].to_s : nil,
      activity[:units_affected_description].presence
    ].compact.join(" · ")
  end

  def daily_activity_detail_label(activity)
    activity[:details].presence || "—"
  end

  def labor_time_window_label(entry)
    return nil if entry[:started_at_label].blank? || entry[:ended_at_label].blank?

    "#{entry[:started_at_label]} - #{entry[:ended_at_label]}"
  end

  def parse_metadata_time(time_string)
    return nil if time_string.blank?
    Time.zone.parse(time_string)
  rescue ArgumentError
    nil
  end

  def serialize_messages(messages)
    prev = nil
    messages.map do |m|
      json = serialize_message(m, prev)
      prev = m
      json
    end
  end

  def serialize_activity_entries(incident)
    event_entries = incident.activity_events.includes(performed_by_user: :organization).map do |event|
      serialize_activity_event(event)
    end

    entries = event_entries.sort_by { |entry| -entry[:occurred_at].to_f }

    previous_date = nil
    entries.map do |entry|
      occurred_at = entry[:occurred_at]
      show_date_separator = previous_date != occurred_at.to_date
      previous_date = occurred_at.to_date

      entry.merge(
        occurred_at: occurred_at.iso8601,
        timestamp_label: format_time(occurred_at),
        date_label: format_date(occurred_at),
        show_date_separator: show_date_separator
      )
    end
  end

  def equipment_action_label(action)
    case action
    when "add"
      "Add"
    when "remove"
      "Remove"
    when "move"
      "Move"
    else
      "Other"
    end
  end

  def serialize_activity_event(event)
    actor = event.performed_by_user
    metadata = event.metadata || {}
    category, title, detail = activity_event_copy(event.event_type, metadata)

    {
      id: "event-#{event.id}",
      occurred_at: event.created_at,
      actor_name: actor.full_name,
      actor_initials: actor.initials,
      actor_role_label: User::ROLE_LABELS[actor.user_type],
      actor_org_name: actor.organization.name,
      category: category,
      title: title,
      detail: detail
    }
  end

  def activity_event_copy(event_type, metadata)
    case event_type
    when "incident_created"
      [ "system", "Incident created", nil ]
    when "status_changed"
      old_status = status_label_for(metadata_value(metadata, :old_status))
      new_status = status_label_for(metadata_value(metadata, :new_status))
      [ "status", "Status changed", "#{old_status} -> #{new_status}" ]
    when "user_assigned"
      user_name = metadata_value(metadata, :assigned_user_name) || metadata_value(metadata, :user_name) || "User"
      [ "assignment", "#{user_name} assigned", nil ]
    when "user_unassigned"
      user_name = metadata_value(metadata, :unassigned_user_name) || metadata_value(metadata, :user_name) || "User"
      [ "assignment", "#{user_name} unassigned", nil ]
    when "labor_created"
      role_label = metadata_value(metadata, :role_label)
      hours = metadata_value(metadata, :hours)
      user_name = metadata_value(metadata, :user_name)
      detail = [ role_label, (hours ? "#{hours}h" : nil), user_name ].compact.join(" · ")
      [ "labor", "Labor logged", detail.presence ]
    when "labor_updated"
      role_label = metadata_value(metadata, :role_label)
      hours = metadata_value(metadata, :hours)
      user_name = metadata_value(metadata, :user_name)
      detail = [ role_label, (hours ? "#{hours}h" : nil), user_name ].compact.join(" · ")
      [ "labor", "Labor updated", detail.presence ]
    when "activity_logged"
      title = metadata_value(metadata, :title) || "Activity"
      status = metadata_value(metadata, :status)&.to_s
      [ "note", "Activity logged", [ title, status ].compact.join(" · ").presence ]
    when "activity_updated"
      title = metadata_value(metadata, :title) || "Activity"
      status = metadata_value(metadata, :status)&.to_s
      [ "note", "Activity updated", [ title, status ].compact.join(" · ").presence ]
    when "equipment_placed"
      type_name = metadata_value(metadata, :type_name) || metadata_value(metadata, :equipment_type)
      identifier = metadata_value(metadata, :equipment_identifier) || metadata_value(metadata, :identifier)
      location = metadata_value(metadata, :location_notes)
      detail_parts = [ type_name, identifier.present? ? "##{identifier}" : nil, location ]
      [ "equipment", "Equipment placed", detail_parts.compact.join(" · ").presence ]
    when "equipment_removed"
      type_name = metadata_value(metadata, :type_name) || metadata_value(metadata, :equipment_type)
      identifier = metadata_value(metadata, :equipment_identifier) || metadata_value(metadata, :identifier)
      location = metadata_value(metadata, :location_notes)
      detail_parts = [ type_name, identifier.present? ? "##{identifier}" : nil, location ]
      [ "equipment", "Equipment removed", detail_parts.compact.join(" · ").presence ]
    when "equipment_updated"
      type_name = metadata_value(metadata, :type_name) || metadata_value(metadata, :equipment_type)
      identifier = metadata_value(metadata, :equipment_identifier) || metadata_value(metadata, :identifier)
      location = metadata_value(metadata, :location_notes)
      detail_parts = [ type_name, identifier.present? ? "##{identifier}" : nil, location ]
      [ "equipment", "Equipment updated", detail_parts.compact.join(" · ").presence ]
    when "attachment_uploaded"
      filename = metadata_value(metadata, :filename)
      category = metadata_value(metadata, :category)
      [ "document", "Document uploaded", [ filename, category&.to_s&.titleize ].compact.join(" · ").presence ]
    when "operational_note_added"
      [ "note", "Operational note added", metadata_value(metadata, :note_preview) ]
    when "contact_added"
      name = metadata_value(metadata, :contact_name) || "Contact"
      [ "contact", "#{name} added to contacts", nil ]
    when "contact_removed"
      name = metadata_value(metadata, :contact_name) || "Contact"
      [ "contact", "#{name} removed from contacts", nil ]
    when "escalation_attempted"
      method = metadata_value(metadata, :method)
      result = metadata_value(metadata, :result)
      [ "system", "Escalation attempted", [ method, result ].compact.join(" · ").presence ]
    else
      [ "system", event_type.to_s.humanize, nil ]
    end
  end

  def metadata_value(metadata, key)
    metadata[key.to_s] || metadata[key.to_sym]
  end

  def status_label_for(status)
    return nil if status.blank?

    Incident::STATUS_LABELS[status] || status.to_s.humanize
  end

  def serialize_message(message, prev = nil)
    user = message.user
    show_date = prev.nil? || message.created_at.to_date != prev.created_at.to_date
    same_sender = !show_date && prev&.user_id == message.user_id
    attachments = message.attachments.sort_by(&:created_at).map do |attachment|
      {
        id: attachment.id,
        filename: attachment.file.filename.to_s,
        category_label: attachment.category.titleize,
        url: rails_blob_path(attachment.file, disposition: "inline"),
        content_type: attachment.file.content_type,
        byte_size: attachment.file.byte_size,
        created_at: attachment.created_at.iso8601,
        created_at_label: format_datetime(attachment.created_at),
        uploaded_by_name: attachment.uploaded_by_user&.full_name || user.full_name,
        thumbnail_url: thumbnail_url_for(attachment.file)
      }
    end

    {
      id: message.id,
      body: message.body,
      timestamp_label: format_time(message.created_at),
      date_label: format_date(message.created_at),
      show_date_separator: show_date,
      grouped: same_sender,
      is_current_user: user.id == current_user.id,
      sender: {
        full_name: user.full_name,
        initials: user.initials,
        role_label: User::ROLE_LABELS[user.user_type],
        org_name: user.organization.name
      },
      attachments: attachments
    }
  end

  def serialize_labor_entries(incident)
    incident.labor_entries.includes(:user, :created_by_user).order(log_date: :desc, created_at: :desc).map do |entry|
      editable = can_edit_labor_entry?(entry)
      data = {
        id: entry.id,
        role_label: entry.role_label,
        hours: entry.hours.to_f,
        log_date: entry.log_date.iso8601,
        log_date_label: format_date(entry.log_date),
        created_at: entry.created_at.iso8601,
        occurred_at: (entry.started_at || entry.created_at).iso8601,
        time_label: format_time(entry.started_at || entry.created_at),
        started_at_label: format_time(entry.started_at),
        ended_at_label: format_time(entry.ended_at),
        notes: entry.notes,
        user_name: entry.user&.full_name,
        created_by_name: entry.created_by_user.full_name,
        edit_path: editable ? incident_labor_entry_path(incident, entry) : nil
      }
      if editable
        data[:started_at] = format_time_value(entry.started_at)
        data[:ended_at] = format_time_value(entry.ended_at)
        data[:user_id] = entry.user_id
      end
      data
    end
  end

  def assignable_labor_users(incident)
    if mitigation_admin?
      users = User.where(active: true, organization_id: incident.property.mitigation_org_id)
        .order(:last_name, :first_name)
      sorted = users.sort_by { |u| [ User::LABOR_SORT_ORDER.index(u.user_type) || 99, u.last_name, u.first_name ] }
      sorted.map { |u| { id: u.id, full_name: u.full_name, role_label: User::ROLE_LABELS[u.user_type] } }
    else
      [ { id: current_user.id, full_name: current_user.full_name, role_label: User::ROLE_LABELS[current_user.user_type] } ]
    end
  end

  def serialize_attachments(incident)
    incident.attachments.includes(:uploaded_by_user, file_attachment: :blob)
      .order(created_at: :desc)
      .limit(200)
      .map { |att| serialize_single_attachment(att) }
  end

  def serialize_attachments_page(incident, page: 1, per_page: 20)
    scope = incident.attachments.includes(:uploaded_by_user, file_attachment: :blob)
      .order(created_at: :desc)
    total = scope.count
    attachments = scope.offset((page - 1) * per_page).limit(per_page)

    {
      items: attachments.map { |att| serialize_single_attachment(att) },
      pagination: { page: page, per_page: per_page, total: total, total_pages: (total.to_f / per_page).ceil }
    }
  end

  def serialize_single_attachment(att)
    data = {
      id: att.id,
      filename: att.file.filename.to_s,
      category: att.category,
      category_label: att.category.titleize,
      description: att.description,
      log_date: att.log_date&.iso8601,
      log_date_label: format_date(att.log_date),
      created_at: att.created_at.iso8601,
      time_label: format_time(att.created_at),
      created_at_label: format_datetime(att.created_at),
      uploaded_by_name: att.uploaded_by_user.full_name,
      content_type: att.file.content_type,
      byte_size: att.file.byte_size,
      url: rails_blob_path(att.file, disposition: "inline"),
      thumbnail_url: thumbnail_url_for(att.file)
    }
    if can_manage_attachments?
      data[:update_path] = incident_attachment_path(@incident, att)
      data[:destroy_path] = incident_attachment_path(@incident, att)
    end
    data
  end

  def serialize_operational_notes(incident)
    incident.operational_notes.includes(:created_by_user)
      .order(log_date: :desc, created_at: :desc).map do |note|
      {
        id: note.id,
        note_text: note.note_text,
        log_date: note.log_date.iso8601,
        log_date_label: format_date(note.log_date),
        created_at: note.created_at.iso8601,
        time_label: format_time(note.created_at),
        created_at_label: format_time(note.created_at),
        created_by_name: note.created_by_user.full_name
      }
    end
  end

  def thumbnail_url_for(file)
    return nil unless file.content_type&.start_with?("image/")
    return nil unless image_variants_available?
    return nil unless file.variable?

    rails_representation_path(file.variant(:thumbnail), disposition: "inline")
  end

  def image_variants_available?
    @image_variants_available ||= begin
      require "image_processing"
      true
    rescue LoadError
      false
    end
  end

  def serialize_pm_contacts(incident)
    property = incident.property
    pm_org = property.property_management_org
    pm_user_ids = PropertyAssignment.where(property: property)
      .joins(:user).where(users: { active: true, organization_id: pm_org.id })
      .pluck(:user_id)

    User.where(id: pm_user_ids).order(:last_name, :first_name).map do |u|
      {
        id: u.id,
        name: u.full_name,
        title: User::ROLE_LABELS[u.user_type],
        email: u.email_address,
        phone: format_phone(u.phone),
        phone_raw: u.phone
      }
    end
  end

  def equipment_types_for_incident(incident)
    EquipmentType.where(organization_id: incident.property.mitigation_org_id)
      .active.order(:name)
      .map { |t| { id: t.id, name: t.name } }
  end

  def equipment_items_by_type(incident)
    items = EquipmentItem.where(organization_id: incident.property.mitigation_org_id)
      .active.includes(:equipment_type).order(:identifier)

    items.group_by(&:equipment_type_id).transform_values do |type_items|
      type_items.map { |i| { id: i.id, identifier: i.identifier, model_name: i.equipment_model } }
    end
  end

  def attachable_equipment_entries(incident)
    incident.equipment_entries.includes(:equipment_type)
      .where(removed_at: nil)
      .order(placed_at: :desc, created_at: :desc)
      .map do |entry|
      label_parts = [ entry.type_name ]
      label_parts << "##{entry.equipment_identifier}" if entry.equipment_identifier.present?
      label_parts << entry.location_notes if entry.location_notes.present?

      {
        id: entry.id,
        label: label_parts.join(" · ")
      }
    end
  end

  def serialize_equipment_log(incident)
    incident.equipment_entries.includes(:equipment_type, :logged_by_user)
      .order(placed_at: :desc, created_at: :desc)
      .map do |entry|
      editable = can_edit_equipment_entry?(entry)
      hours = (((entry.removed_at || Time.current) - entry.placed_at) / 1.hour).round(1)
      data = {
        id: entry.id,
        type_name: entry.type_name,
        equipment_model: entry.equipment_model,
        equipment_identifier: entry.equipment_identifier,
        location_notes: entry.location_notes,
        placed_at_label: format_date(entry.placed_at),
        removed_at_label: entry.removed_at ? format_date(entry.removed_at) : nil,
        total_hours: hours,
        edit_path: editable ? incident_equipment_entry_path(incident, entry) : nil,
        remove_path: editable && entry.removed_at.nil? ? remove_incident_equipment_entry_path(incident, entry) : nil
      }
      if editable
        data[:equipment_type_id] = entry.equipment_type_id
        data[:equipment_type_other] = entry.equipment_type_other
        data[:placed_at] = entry.placed_at.to_date.iso8601
        data[:removed_at] = entry.removed_at&.to_date&.iso8601
      end
      data
    end
  end

  def serialize_moisture_data(incident)
    points = incident.moisture_measurement_points.includes(:moisture_readings).to_a
    readings_by_point = points.each_with_object({}) do |point, hash|
      hash[point.id] = point.moisture_readings.index_by { |r| r.log_date.iso8601 }
    end

    dates = points.flat_map { |p| p.moisture_readings.map(&:log_date) }.uniq.sort

    {
      supervisor_pm: incident.moisture_supervisor_pm,
      dates: dates.map(&:iso8601),
      date_labels: dates.map { |d| d.strftime("%b %-d") },
      points: points.map { |p|
        {
          id: p.id, unit: p.unit, room: p.room, item: p.item,
          material: p.material, goal: p.goal,
          measurement_unit: p.measurement_unit, position: p.position,
          readings: dates.each_with_object({}) { |d, h|
            r = readings_by_point[p.id]&.[](d.iso8601)
            h[d.iso8601] = r ? { id: r.id, value: r.value&.to_f } : nil
          },
          destroy_path: incident_moisture_point_path(incident, p)
        }
      },
      create_point_path: create_point_incident_moisture_readings_path(incident),
      batch_save_path: batch_save_incident_moisture_readings_path(incident),
      update_supervisor_path: update_supervisor_incident_moisture_readings_path(incident),
      moisture_reading_path_template: incident_moisture_reading_path(incident, "READING_ID")
    }
  end

  def serialize_labor_log(incident)
    entries = incident.labor_entries.includes(:user, :created_by_user).order(:log_date, :created_at)
    dates = entries.map(&:log_date).uniq.sort.reverse
    date_labels = dates.map { |d| format_date(d) }

    # Group by employee identity: use user if present, fall back to role_label
    employee_map = {}
    entries.each do |entry|
      key = entry.user_id ? "user-#{entry.user_id}" : "role-#{entry.role_label}"
      employee_map[key] ||= {
        name: entry.user&.full_name || entry.role_label,
        title: entry.role_label,
        hours_by_date: {},
        total_hours: 0
      }
      date_key = entry.log_date.iso8601
      employee_map[key][:hours_by_date][date_key] ||= 0
      employee_map[key][:hours_by_date][date_key] += entry.hours.to_f
      employee_map[key][:total_hours] += entry.hours.to_f
    end

    {
      dates: dates.map(&:iso8601),
      date_labels: date_labels,
      employees: employee_map.values
    }
  end

  def compute_show_unread_counts(incident)
    read_state = incident.incident_read_states.detect { |rs| rs.user_id == current_user.id }

    msg_threshold = read_state&.last_message_read_at
    unread_messages = incident.messages.where.not(user_id: current_user.id)
    unread_messages = unread_messages.where("created_at > ?", msg_threshold) if msg_threshold
    msg_count = unread_messages.count

    act_threshold = read_state&.last_activity_read_at
    unread_activity = incident.activity_events.for_daily_log_notifications.where.not(performed_by_user_id: current_user.id)
    unread_activity = unread_activity.where("created_at > ?", act_threshold) if act_threshold
    act_count = unread_activity.count

    { messages: msg_count, activity: act_count }
  end

  def serialize_incident(incident, unread = {})
    counts = unread[incident.id]
    {
      id: incident.id,
      path: incident_path(incident),
      property_name: incident.property.name,
      organization_name: incident.property.property_management_org.name,
      description: incident.description.truncate(80),
      status: incident.status,
      status_label: incident.display_status_label,
      project_type: incident.project_type,
      project_type_label: Incident::PROJECT_TYPE_LABELS[incident.project_type],
      damage_label: Incident::DAMAGE_LABELS[incident.damage_type],
      emergency: incident.emergency,
      last_activity_label: format_relative_time(incident.last_activity_at),
      created_at: incident.created_at.iso8601,
      unread_messages: counts&.dig(:messages) || 0,
      unread_activity: counts&.dig(:activity) || 0
    }
  end
end
