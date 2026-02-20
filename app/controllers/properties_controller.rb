class PropertiesController < ApplicationController
  before_action :require_view_properties, only: %i[index]
  before_action :require_create_property, only: %i[new create]
  before_action :set_property, only: %i[show edit update]
  before_action :require_edit_permission, only: %i[edit update]

  def index
    @properties = visible_properties.includes(:property_management_org).order(:name)
    @properties = @properties.where(property_management_org_id: params[:pm_org_id].split(",")) if params[:pm_org_id].present?

    render inertia: "Properties/Index", props: {
      properties: @properties.map { |p|
        {
          id: p.id,
          name: p.name,
          path: property_path(p),
          address: p.short_address,
          pm_org_name: p.property_management_org.name,
          active_incident_count: p.incidents.where.not(status: %w[completed completed_billed paid closed]).count,
          total_incident_count: p.incidents.count
        }
      },
      can_create: can_create_property?,
      filters: { pm_org_id: params[:pm_org_id] },
      filter_options: mitigation_user? ? {
        pm_organizations: visible_properties
          .joins(:property_management_org)
          .select("DISTINCT organizations.id, organizations.name")
          .order("organizations.name")
          .map { |p| { id: p.id, name: p.name } }
      } : {}
    }
  end

  def show
    render inertia: "Properties/Show", props: {
      property: {
        id: @property.id,
        name: @property.name,
        path: property_path(@property),
        edit_path: edit_property_path(@property),
        assignments_path: property_assignments_path(@property),
        address: @property.format_address,
        unit_summary: @property.unit_count ? "#{@property.unit_count} #{'unit'.pluralize(@property.unit_count)}" : nil,
        pm_org: { id: @property.property_management_org.id, name: @property.property_management_org.name,
                  path: organization_path(@property.property_management_org) },
        mitigation_org: { id: @property.mitigation_org.id, name: @property.mitigation_org.name },
        assigned_users: @property.property_assignments.includes(:user)
          .joins(:user).where(users: { active: true }).order("users.last_name, users.first_name").map { |a|
          { id: a.user.id, assignment_id: a.id, full_name: a.user.full_name, email: a.user.email_address,
            role_label: User::ROLE_LABELS[a.user.user_type], path: user_path(a.user),
            remove_path: property_assignment_path(@property, a) }
        },
        incidents: @property.incidents.order(created_at: :desc).limit(20).map { |i|
          { id: i.id, summary: incident_summary(i), status_label: Incident::STATUS_LABELS[i.status],
            path: incident_path(i) }
        }
      },
      can_edit: can_edit_property?(@property),
      can_assign: can_assign_to_property?(@property),
      assignable_users: can_assign_to_property?(@property) ? assignable_pm_users(@property) : []
    }
  end

  def new
    render inertia: "Properties/New", props: {
      pm_organizations: pm_org_options
    }
  end

  def create
    @property = Property.new(property_params.merge(mitigation_org_id: current_user.organization_id))

    if @property.save
      redirect_to property_path(@property), notice: "Property created."
    else
      redirect_to new_property_path, inertia: { errors: @property.errors.to_hash },
        alert: "Could not create property."
    end
  end

  def edit
    render inertia: "Properties/Edit", props: {
      property: {
        id: @property.id,
        name: @property.name,
        path: property_path(@property),
        street_address: @property.street_address,
        city: @property.city,
        state: @property.state,
        zip: @property.zip,
        unit_count: @property.unit_count,
        property_management_org_id: @property.property_management_org_id
      },
      pm_organizations: pm_org_options,
      can_change_org: mitigation_user?
    }
  end

  def update
    permitted = mitigation_user? ? property_params : property_params.except(:property_management_org_id)

    if @property.update(permitted)
      redirect_to property_path(@property), notice: "Property updated."
    else
      redirect_to edit_property_path(@property), inertia: { errors: @property.errors.to_hash },
        alert: "Could not update property."
    end
  end

  private

  def require_view_properties
    raise ActiveRecord::RecordNotFound unless can_view_properties?
  end

  def require_create_property
    raise ActiveRecord::RecordNotFound unless can_create_property?
  end

  def set_property
    @property = find_visible_property!(params[:id])
  end

  def require_edit_permission
    raise ActiveRecord::RecordNotFound unless can_edit_property?(@property)
  end

  def property_params
    params.require(:property).permit(:name, :property_management_org_id, :street_address, :city, :state, :zip, :unit_count)
  end

  def assignable_pm_users(property)
    property.property_management_org.users
      .where(active: true, user_type: User::PM_TYPES)
      .where.not(id: property.assigned_user_ids)
      .order(:last_name, :first_name)
      .map { |u| { id: u.id, full_name: u.full_name, role_label: User::ROLE_LABELS[u.user_type] } }
  end

  def pm_org_options
    Organization.where(organization_type: "property_management").order(:name).map { |o| { id: o.id, name: o.name } }
  end

  def incident_summary(incident)
    label = Incident::DAMAGE_LABELS[incident.damage_type] || incident.damage_type
    desc = incident.description.truncate(60)
    "#{label} — #{desc}"
  end
end
