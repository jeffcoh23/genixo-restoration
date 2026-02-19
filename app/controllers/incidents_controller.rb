class IncidentsController < ApplicationController
  before_action :authorize_creation!, only: %i[new create]
  before_action :set_incident, only: %i[show update transition]
  before_action :authorize_edit!, only: %i[update]
  before_action :authorize_transition!, only: %i[transition]

  def index
    scope = visible_incidents.includes(property: :property_management_org)

    # Filters
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(property_id: params[:property_id]) if params[:property_id].present?
    scope = scope.where(project_type: params[:project_type]) if params[:project_type].present?
    scope = scope.where(emergency: true) if params[:emergency] == "1"

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
    incidents = scope.offset((page - 1) * per_page).limit(per_page)

    render inertia: "Incidents/Index", props: {
      incidents: incidents.map { |i| serialize_incident(i) },
      pagination: { page: page, per_page: per_page, total: total, total_pages: (total.to_f / per_page).ceil },
      filters: {
        search: params[:search],
        status: params[:status],
        property_id: params[:property_id]&.to_i,
        project_type: params[:project_type],
        emergency: params[:emergency]
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
    deployed_equipment = serialize_deployed_equipment(@incident)
    daily_activities = serialize_daily_activities(@incident)
    labor_entries = serialize_labor_entries(@incident)
    operational_notes = serialize_operational_notes(@incident)
    attachments = serialize_attachments(@incident)
    daily_log_dates = serialize_daily_log_dates(
      daily_activities: daily_activities,
      labor_entries: labor_entries,
      operational_notes: operational_notes,
      attachments: attachments
    )
    daily_log_table_groups = serialize_daily_log_table_groups(
      daily_activities: daily_activities,
      labor_entries: labor_entries,
      operational_notes: operational_notes,
      attachments: attachments
    )

    assigned = @incident.incident_assignments.includes(user: :organization)
      .joins(:user).where(users: { active: true })
      .order("users.last_name, users.first_name")

    messages = @incident.messages.includes(user: :organization).order(created_at: :asc)

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
        location_of_damage: @incident.location_of_damage,
        created_at: @incident.created_at.iso8601,
        created_at_label: format_date(@incident.created_at),
        created_by: @incident.created_by_user ? {
          name: @incident.created_by_user.full_name,
          email: @incident.created_by_user.email_address,
          phone: @incident.created_by_user.phone
        } : nil,
        property: {
          id: property.id,
          name: property.name,
          address: property.format_address,
          path: property_path(property),
          organization_name: property.property_management_org.name
        },
        deployed_equipment: deployed_equipment,
        assignments_path: incident_assignments_path(@incident),
        assigned_team: assigned_team_groups(assigned),
        assigned_summary: {
          count: assigned.size,
          avatars: assigned.first(4).map { |a| { id: a.user.id, initials: a.user.initials, full_name: a.user.full_name } },
          overflow: [ assigned.size - 4, 0 ].max
        },
        show_stats: @incident.labor_entries.any? || deployed_equipment.any?,
        stats: incident_stats(@incident, deployed_equipment),
        contacts_path: incident_contacts_path(@incident),
        contacts: @incident.incident_contacts.order(:name).map { |c|
          {
            id: c.id,
            name: c.name,
            title: c.title,
            email: c.email,
            phone: c.phone,
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
        valid_transitions: can_transition_status? ? (StatusTransitionService.transitions_for(@incident)[@incident.status] || []).map { |s|
          { value: s, label: Incident::STATUS_LABELS[s] }
        } : []
      },
      activity_entries: serialize_activity_entries(@incident),
      daily_activities: daily_activities,
      daily_log_dates: daily_log_dates,
      daily_log_table_groups: daily_log_table_groups,
      messages: serialize_messages(messages),
      labor_entries: labor_entries,
      operational_notes: operational_notes,
      attachments: attachments,
      equipment_log: serialize_equipment_log(@incident),
      labor_log: serialize_labor_log(@incident),
      can_transition: can_transition_status?,
      can_assign: can_assign_to_incident?,
      can_manage_contacts: can_manage_contacts?,
      can_edit: can_edit_incident?,
      can_manage_activities: can_manage_activities?,
      can_manage_labor: can_manage_labor?,
      can_manage_equipment: can_manage_equipment?,
      can_create_notes: can_create_operational_note?,
      assignable_users: can_assign_to_incident? ? assignable_incident_users(@incident) : [],
      assignable_labor_users: can_manage_labor? ? assignable_labor_users(@incident) : [],
      equipment_types: can_manage_equipment? ? equipment_types_for_incident(@incident) : [],
      attachable_equipment_entries: can_manage_activities? ? attachable_equipment_entries(@incident) : [],
      project_types: Incident::PROJECT_TYPES.map { |t| { value: t, label: Incident::PROJECT_TYPE_LABELS[t] } },
      damage_types: Incident::DAMAGE_TYPES.map { |t| { value: t, label: Incident::DAMAGE_LABELS[t] } },
      back_path: incidents_path
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

  private

  def authorize_creation!
    raise ActiveRecord::RecordNotFound unless can_create_incident?
  end

  def set_incident
    @incident = find_visible_incident!(params[:id])
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
    permitted = params.require(:incident).permit(
      :project_type, :damage_type, :description, :cause,
      :requested_next_steps, :units_affected, :affected_room_numbers, :job_id,
      :do_not_exceed_limit, :location_of_damage,
      additional_user_ids: [],
      contacts: [ :name, :title, :email, :phone, :onsite ]
    ).to_h.symbolize_keys

    # Ensure contacts is an array of hashes with symbol keys
    if permitted[:contacts].is_a?(Hash)
      permitted[:contacts] = permitted[:contacts].values.map { |c| c.symbolize_keys }
    elsif permitted[:contacts].is_a?(Array)
      permitted[:contacts] = permitted[:contacts].map { |c| c.is_a?(Hash) ? c.symbolize_keys : c }
    end

    permitted
  end

  def update_incident_params
    params.require(:incident).permit(
      :description, :cause, :requested_next_steps,
      :units_affected, :affected_room_numbers, :job_id,
      :project_type, :damage_type,
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

        { id: u.id, full_name: u.full_name, role_label: User::ROLE_LABELS[u.user_type], organization_name: u.organization.name, auto_assign: auto }
      end

      result[property.id] = property_user_list
    end

    result
  end

  def assignable_incident_users(incident)
    scope = if mitigation_admin?
      User.where(active: true, organization_id: [ incident.property.mitigation_org_id, incident.property.property_management_org_id ])
    else
      User.where(active: true, organization_id: current_user.organization_id)
    end

    scope.where.not(id: incident.assigned_user_ids)
      .order(:last_name, :first_name)
      .map { |u| { id: u.id, full_name: u.full_name, role_label: User::ROLE_LABELS[u.user_type] } }
  end

  def assigned_team_groups(assignments)
    assignments.group_by { |a| a.user.organization.name }.map do |org_name, group|
      {
        organization_name: org_name,
        users: group.map { |a|
          {
            id: a.user.id,
            assignment_id: a.id,
            full_name: a.user.full_name,
            initials: a.user.initials,
            role_label: User::ROLE_LABELS[a.user.user_type],
            email: a.user.email_address,
            phone: a.user.phone,
            remove_path: can_remove_assignment?(a.user) ? incident_assignment_path(@incident, a) : nil
          }
        }
      }
    end
  end

  def incident_stats(incident, deployed_equipment)
    active = deployed_equipment.sum { |item| item[:quantity].to_i }
    {
      total_labor_hours: incident.labor_entries.sum(:hours).to_f,
      active_equipment: active,
      total_equipment_placed: active,
      show_removed_equipment: false
    }
  end

  def serialize_deployed_equipment(incident)
    buckets = {}
    activity_actions_seen = false

    incident.activity_entries
      .includes(:performed_by_user, equipment_actions: %i[equipment_type equipment_entry])
      .each do |activity|
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
      .sort_by { |bucket| [ -bucket[:quantity], bucket[:type_name] ] }
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
      .includes(:performed_by_user, equipment_actions: %i[equipment_type equipment_entry])
      .order(occurred_at: :desc, created_at: :desc)
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

  def serialize_daily_log_dates(daily_activities:, labor_entries:, operational_notes:, attachments:)
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
    attachments.each do |entry|
      next if entry[:log_date].blank?

      labels[entry[:log_date]] ||= entry[:log_date_label]
    end

    labels.keys.sort.reverse.map do |date_key|
      { key: date_key, label: labels[date_key] || date_key }
    end
  end

  def serialize_daily_log_table_groups(daily_activities:, labor_entries:, operational_notes:, attachments:)
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

    labor_entries.each do |entry|
      groups[entry[:log_date]] << {
        id: "labor-#{entry[:id]}",
        occurred_at: entry[:occurred_at] || entry[:created_at],
        time_label: entry[:time_label] || "—",
        row_type: "labor",
        row_type_label: "Labor",
        primary_label: [ entry[:role_label], entry[:user_name] ].compact.join(" · "),
        status_label: "#{entry[:hours]}h",
        units_label: "—",
        detail_label: entry[:notes].presence || labor_time_window_label(entry),
        actor_name: entry[:created_by_name],
        edit_path: entry[:edit_path]
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

    attachments.each do |attachment|
      date_key = attachment[:log_date].presence || Time.zone.parse(attachment[:created_at]).to_date.iso8601
      groups[date_key] << {
        id: "attachment-#{attachment[:id]}",
        occurred_at: attachment[:created_at],
        time_label: attachment[:time_label] || "—",
        row_type: "document",
        row_type_label: "Document",
        primary_label: attachment[:filename],
        status_label: attachment[:category_label],
        units_label: "—",
        detail_label: attachment[:description].presence || "Uploaded document",
        actor_name: attachment[:uploaded_by_name],
        edit_path: nil,
        url: attachment[:url]
      }
    end

    equip_by_date = @incident ? equipment_summary_by_date(@incident) : {}

    # Precompute labor hours per date for the group header
    labor_hours_by_date = labor_entries.each_with_object(Hash.new(0.0)) do |entry, map|
      map[entry[:log_date]] += entry[:hours].to_f
    end

    groups.keys.sort.reverse.map do |date_key|
      rows = groups[date_key].sort_by do |row|
        parsed = parse_metadata_time(row[:occurred_at]) || Time.zone.parse("#{date_key}T00:00:00")
        -parsed.to_f
      end

      date_equip = equip_by_date[date_key] || []

      {
        date_key: date_key,
        date_label: format_date(Time.zone.parse("#{date_key}T00:00:00")),
        rows: rows,
        equipment_summary: date_equip,
        total_labor_hours: labor_hours_by_date[date_key].round(1),
        total_equip_count: date_equip.sum { |e| e[:count] }
      }
    end
  end

  def equipment_summary_by_date(incident)
    entries = incident.equipment_entries.includes(:equipment_type)
    return {} if entries.empty?

    # Collect all dates that have activity in the daily log
    all_dates = entries.flat_map { |e|
      dates = [ e.placed_at.to_date ]
      dates << e.removed_at.to_date if e.removed_at
      dates
    }.uniq.sort

    all_dates.each_with_object({}) do |date, result|
      date_key = date.iso8601
      buckets = {}

      entries.each do |entry|
        # Equipment is active on this date if placed on or before this date and not yet removed (or removed on/after this date)
        next if entry.placed_at.to_date > date
        next if entry.removed_at && entry.removed_at.to_date < date

        type_name = entry.type_name.to_s.strip
        next if type_name.blank?

        key = type_name.downcase
        bucket = buckets[key] ||= { type_name: type_name, count: 0, hours: 0.0 }
        bucket[:count] += 1

        # Hours for this date: from start of day (or placed_at) to end of day (or removed_at)
        day_start = [ entry.placed_at, date.beginning_of_day ].max
        day_end = [ entry.removed_at || Time.current, date.end_of_day ].min
        bucket[:hours] += ((day_end - day_start) / 1.hour).round(1)
      end

      next if buckets.empty?

      result[date_key] = buckets.values
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
      }
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
      .order(created_at: :desc).map do |att|
      {
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
        url: rails_blob_path(att.file, disposition: "inline")
      }
    end
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
        phone: u.phone
      }
    end
  end

  def equipment_types_for_incident(incident)
    EquipmentType.where(organization_id: incident.property.mitigation_org_id)
      .active.order(:name)
      .map { |t| { id: t.id, name: t.name } }
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
      .order(placed_at: :asc, created_at: :asc)
      .map do |entry|
      editable = can_edit_equipment_entry?(entry)
      hours = (((entry.removed_at || Time.current) - entry.placed_at) / 1.hour).round(1)
      data = {
        id: entry.id,
        type_name: entry.type_name,
        equipment_model: entry.equipment_model,
        equipment_identifier: entry.equipment_identifier,
        location_notes: entry.location_notes,
        placed_at_label: format_datetime(entry.placed_at),
        removed_at_label: entry.removed_at ? format_datetime(entry.removed_at) : nil,
        total_hours: hours,
        edit_path: editable ? incident_equipment_entry_path(incident, entry) : nil,
        remove_path: editable && entry.removed_at.nil? ? remove_incident_equipment_entry_path(incident, entry) : nil
      }
      if editable
        data[:equipment_type_id] = entry.equipment_type_id
        data[:equipment_type_other] = entry.equipment_type_other
        data[:placed_at] = format_datetime_value(entry.placed_at)
        data[:removed_at] = entry.removed_at ? format_datetime_value(entry.removed_at) : nil
      end
      data
    end
  end

  def serialize_labor_log(incident)
    entries = incident.labor_entries.includes(:user, :created_by_user).order(:log_date, :created_at)
    dates = entries.map(&:log_date).uniq.sort
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

  def serialize_incident(incident)
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
      created_at: incident.created_at.iso8601
    }
  end
end
