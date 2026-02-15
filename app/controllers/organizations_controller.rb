class OrganizationsController < ApplicationController
  before_action :require_mitigation_admin
  before_action :set_organization, only: %i[show edit update]

  def index
    @organizations = Organization.where(organization_type: "property_management")
                                 .order(:name)
    render inertia: "Organizations/Index", props: {
      organizations: @organizations.map { |org| serialize_org(org) }
    }
  end

  def show
    render inertia: "Organizations/Show", props: {
      organization: serialize_org_detail(@organization)
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
      redirect_to new_organization_path, inertia: { errors: @organization.errors.to_hash }, alert: "Could not create organization."
    end
  end

  def edit
    render inertia: "Organizations/Edit", props: {
      organization: serialize_org(@organization)
    }
  end

  def update
    if @organization.update(organization_params)
      redirect_to organization_path(@organization), notice: "Organization updated."
    else
      redirect_to edit_organization_path(@organization), inertia: { errors: @organization.errors.to_hash }, alert: "Could not update organization."
    end
  end

  private

  def require_mitigation_admin
    authorize_mitigation_role!(:manager, :office_sales)
  end

  def set_organization
    @organization = Organization.where(organization_type: "property_management").find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(:name, :phone, :email, :street_address, :city, :state, :zip)
  end

  def serialize_org(org)
    {
      id: org.id,
      name: org.name,
      phone: org.phone,
      email: org.email,
      property_count: org.owned_properties.count,
      user_count: org.users.where(active: true).count
    }
  end

  def serialize_org_detail(org)
    {
      id: org.id,
      name: org.name,
      phone: org.phone,
      email: org.email,
      street_address: org.street_address,
      city: org.city,
      state: org.state,
      zip: org.zip,
      properties: org.owned_properties.order(:name).map { |p|
        {
          id: p.id,
          name: p.name,
          active_incident_count: p.incidents.where.not(status: %w[completed completed_billed paid closed]).count
        }
      },
      users: org.users.where(active: true).order(:last_name, :first_name).map { |u|
        {
          id: u.id,
          full_name: u.full_name,
          email: u.email_address,
          user_type: u.user_type,
          active: u.active
        }
      }
    }
  end
end
