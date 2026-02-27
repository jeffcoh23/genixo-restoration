class OrganizationsController < ApplicationController
  before_action :require_mitigation_admin
  before_action :set_organization, only: %i[show edit update]

  def index
    @organizations = Organization.where(organization_type: "property_management").order(:name)
    org_ids = @organizations.map(&:id)
    property_counts = Property.where(property_management_org_id: org_ids).group(:property_management_org_id).count
    user_counts = User.where(organization_id: org_ids, active: true).group(:organization_id).count

    render inertia: "Organizations/Index", props: {
      organizations: @organizations.map { |org|
        {
          id: org.id,
          name: org.name,
          path: organization_path(org),
          phone: org.phone,
          email: org.email,
          property_count: property_counts[org.id] || 0,
          user_count: user_counts[org.id] || 0
        }
      }
    }
  end

  def show
    properties = @organization.owned_properties.order(:name)
    property_ids = properties.map(&:id)
    active_counts = Incident.where(property_id: property_ids)
      .where.not(status: %w[completed completed_billed paid closed])
      .group(:property_id).count

    render inertia: "Organizations/Show", props: {
      organization: {
        id: @organization.id,
        name: @organization.name,
        path: organization_path(@organization),
        edit_path: edit_organization_path(@organization),
        phone: @organization.phone,
        email: @organization.email,
        address: @organization.format_address,
        contact: [ @organization.phone, @organization.email ].filter_map(&:presence).join(" \u00B7 "),
        properties: properties.map { |p|
          count = active_counts[p.id] || 0
          { id: p.id, name: p.name, path: property_path(p),
            active_incident_summary: "#{count} active #{'incident'.pluralize(count)}" }
        },
        users: @organization.users.where(active: true).order(:last_name, :first_name).map { |u|
          { id: u.id, full_name: u.full_name, email: u.email_address,
            role_label: User::ROLE_LABELS[u.user_type], path: user_path(u) }
        }
      }
    }
  end

  def new
    render inertia: "Organizations/New"
  end

  def create
    @organization = Organization.new(organization_params.merge(organization_type: "property_management"))

    if @organization.save
      redirect_to organization_path(@organization), notice: "Organization created."
    else
      redirect_to new_organization_path, inertia: { errors: @organization.errors.to_hash },
        alert: "Could not create organization."
    end
  end

  def edit
    render inertia: "Organizations/Edit", props: {
      organization: {
        id: @organization.id,
        name: @organization.name,
        path: organization_path(@organization),
        phone: @organization.phone,
        email: @organization.email,
        street_address: @organization.street_address,
        city: @organization.city,
        state: @organization.state,
        zip: @organization.zip
      }
    }
  end

  def update
    if @organization.update(organization_params)
      redirect_to organization_path(@organization), notice: "Organization updated."
    else
      redirect_to edit_organization_path(@organization), inertia: { errors: @organization.errors.to_hash },
        alert: "Could not update organization."
    end
  end

  private

  def require_mitigation_admin
    raise ActiveRecord::RecordNotFound unless can_manage_organizations?
  end

  def set_organization
    @organization = Organization.where(organization_type: "property_management").find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(:name, :phone, :email, :street_address, :city, :state, :zip)
  end
end
