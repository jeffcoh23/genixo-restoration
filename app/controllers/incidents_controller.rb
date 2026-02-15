class IncidentsController < ApplicationController
  before_action :authorize_creation!, only: %i[new create]
  before_action :set_incident, only: %i[show transition]
  before_action :authorize_transition!, only: %i[transition]

  def index
    scope = visible_incidents.includes(:property)

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
    page = [params.fetch(:page, 1).to_i, 1].max
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
    render inertia: "Incidents/New", props: {
      properties: creatable_properties.map { |p| { id: p.id, name: p.name } },
      project_types: Incident::PROJECT_TYPES.map { |t| { value: t, label: Incident::PROJECT_TYPE_LABELS[t] } },
      damage_types: Incident::DAMAGE_TYPES.map { |t| { value: t, label: Incident::DAMAGE_LABELS[t] } }
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

  def show
    @incident = find_visible_incident!(params[:id])
    property = @incident.property

    assigned = @incident.incident_assignments.includes(user: :organization)
      .joins(:user).where(users: { active: true })
      .order("users.last_name, users.first_name")

    render inertia: "Incidents/Show", props: {
      incident: {
        id: @incident.id,
        path: incident_path(@incident),
        transition_path: transition_incident_path(@incident),
        description: @incident.description,
        cause: @incident.cause,
        requested_next_steps: @incident.requested_next_steps,
        units_affected: @incident.units_affected,
        affected_room_numbers: @incident.affected_room_numbers,
        status: @incident.status,
        status_label: Incident::STATUS_LABELS[@incident.status],
        project_type: @incident.project_type,
        project_type_label: Incident::PROJECT_TYPE_LABELS[@incident.project_type],
        damage_type: @incident.damage_type,
        damage_label: Incident::DAMAGE_LABELS[@incident.damage_type],
        emergency: @incident.emergency,
        created_at: @incident.created_at.iso8601,
        created_at_label: @incident.created_at.strftime("%b %-d, %Y"),
        created_by: @incident.created_by_user&.full_name,
        property: {
          id: property.id,
          name: property.name,
          address: property.short_address,
          path: property_path(property)
        },
        assignments_path: incident_assignments_path(@incident),
        assigned_team: assigned_team_groups(assigned),
        assigned_summary: {
          count: assigned.size,
          avatars: assigned.first(4).map { |a| { id: a.user.id, initials: a.user.initials, full_name: a.user.full_name } },
          overflow: [assigned.size - 4, 0].max
        },
        show_stats: @incident.labor_entries.any? || @incident.equipment_entries.any?,
        stats: incident_stats(@incident),
        contacts_path: incident_contacts_path(@incident),
        contacts: @incident.incident_contacts.order(:name).map { |c|
          {
            id: c.id,
            name: c.name,
            title: c.title,
            email: c.email,
            phone: c.phone,
            remove_path: can_manage_contacts? ? incident_contact_path(@incident, c) : nil
          }
        },
        valid_transitions: can_transition_status? ? (StatusTransitionService::ALLOWED_TRANSITIONS[@incident.status] || []).map { |s|
          { value: s, label: Incident::STATUS_LABELS[s] }
        } : []
      },
      can_transition: can_transition_status?,
      can_assign: can_assign_to_incident?,
      can_manage_contacts: can_manage_contacts?,
      assignable_users: can_assign_to_incident? ? assignable_incident_users(@incident) : [],
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

  def authorize_transition!
    raise ActiveRecord::RecordNotFound unless can_transition_status?
  end

  def creatable_properties
    visible_properties
  end

  def incident_params
    params.require(:incident).permit(
      :project_type, :damage_type, :description, :cause,
      :requested_next_steps, :units_affected, :affected_room_numbers
    ).to_h.symbolize_keys
  end

  def can_manage_contacts?
    mitigation_admin? || current_user.pm_user?
  end

  def can_assign_to_incident?
    mitigation_admin? || current_user.pm_user?
  end

  def can_remove_assignment?(user)
    return true if mitigation_admin?
    current_user.pm_user? && user.organization_id == current_user.organization_id
  end

  def assignable_incident_users(incident)
    scope = if mitigation_admin?
      User.where(active: true, organization_id: [incident.property.mitigation_org_id, incident.property.property_management_org_id])
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
            remove_path: can_remove_assignment?(a.user) ? incident_assignment_path(@incident, a) : nil
          }
        }
      }
    end
  end

  def incident_stats(incident)
    active = incident.equipment_entries.where(removed_at: nil).count
    total_placed = incident.equipment_entries.count
    {
      total_labor_hours: incident.labor_entries.sum(:hours).to_f,
      active_equipment: active,
      total_equipment_placed: total_placed,
      show_removed_equipment: total_placed > active
    }
  end

  def serialize_incident(incident)
    {
      id: incident.id,
      path: incident_path(incident),
      property_name: incident.property.name,
      description: incident.description.truncate(80),
      status: incident.status,
      status_label: Incident::STATUS_LABELS[incident.status],
      project_type: incident.project_type,
      project_type_label: Incident::PROJECT_TYPE_LABELS[incident.project_type],
      damage_label: Incident::DAMAGE_LABELS[incident.damage_type],
      emergency: incident.emergency,
      last_activity_at: incident.last_activity_at&.iso8601,
      created_at: incident.created_at.iso8601
    }
  end
end
