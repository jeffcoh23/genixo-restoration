class PropertiesController < ApplicationController
  before_action :reject_technicians, only: %i[index]
  before_action :require_mitigation_admin, only: %i[new create]
  before_action :set_property, only: %i[show edit update]
  before_action :require_edit_permission, only: %i[edit update]

  def index
    @properties = visible_properties.includes(:property_management_org).order(:name)
    render inertia: "Properties/Index", props: {
      properties: @properties.map { |p|
        {
          id: p.id,
          name: p.name,
          path: property_path(p),
          address: format_address(p),
          pm_org_name: p.property_management_org.name,
          active_incident_count: p.incidents.where.not(status: %w[completed completed_billed paid closed]).count,
          total_incident_count: p.incidents.count
        }
      },
      can_create: can_create_property?
    }
  end

  def show
    render inertia: "Properties/Show", props: {
      property: {
        id: @property.id,
        name: @property.name,
        path: property_path(@property),
        edit_path: edit_property_path(@property),
        street_address: @property.street_address,
        city: @property.city,
        state: @property.state,
        zip: @property.zip,
        unit_count: @property.unit_count,
        pm_org: { id: @property.property_management_org.id, name: @property.property_management_org.name,
                  path: organization_path(@property.property_management_org) },
        mitigation_org: { id: @property.mitigation_org.id, name: @property.mitigation_org.name },
        assigned_users: @property.assigned_users.where(active: true).order(:last_name, :first_name).map { |u|
          { id: u.id, full_name: u.full_name, email: u.email_address, user_type: u.user_type,
            path: user_path(u) }
        },
        incidents: @property.incidents.order(created_at: :desc).limit(20).map { |i|
          { id: i.id, description: i.description, damage_type: i.damage_type, status: i.status,
            path: incident_path(i) }
        }
      },
      can_edit: can_edit_property?(@property)
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

  def reject_technicians
    raise ActiveRecord::RecordNotFound if current_user.user_type == "technician"
  end

  def require_mitigation_admin
    authorize_mitigation_role!(:manager, :office_sales)
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

  def can_create_property?
    current_user.organization.mitigation? && %w[manager office_sales].include?(current_user.user_type)
  end

  def can_edit_property?(property = nil)
    return true if current_user.organization.mitigation? && %w[manager office_sales].include?(current_user.user_type)
    return true if %w[property_manager area_manager pm_manager].include?(current_user.user_type) &&
                   property&.assigned_users&.exists?(id: current_user.id)
    false
  end

  def mitigation_user?
    current_user.organization.mitigation?
  end

  def pm_org_options
    Organization.where(organization_type: "property_management").order(:name).map { |o| { id: o.id, name: o.name } }
  end

  def format_address(property)
    [property.street_address, property.city, property.state].filter_map(&:presence).join(", ")
  end
end
