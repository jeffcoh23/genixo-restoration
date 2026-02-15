class UsersController < ApplicationController
  before_action :require_mitigation_admin
  before_action :set_user, only: %i[show deactivate reactivate]

  def index
    org_ids = visible_org_ids
    active = User.where(organization_id: org_ids, active: true).includes(:organization).order(:last_name, :first_name)
    deactivated = User.where(organization_id: org_ids, active: false).includes(:organization).order(:last_name, :first_name)

    render inertia: "Users/Index", props: {
      active_users: active.map { |u| serialize_user(u) },
      deactivated_users: deactivated.map { |u| serialize_user(u) }
    }
  end

  def show
    render inertia: "Users/Show", props: {
      user: serialize_user_detail(@user),
      can_deactivate: @user.id != current_user.id
    }
  end

  def deactivate
    if @user.id == current_user.id
      redirect_to user_path(@user), alert: "You cannot deactivate yourself."
      return
    end

    @user.update!(active: false)
    redirect_to user_path(@user), notice: "#{@user.full_name} has been deactivated."
  end

  def reactivate
    @user.update!(active: true)
    redirect_to user_path(@user), notice: "#{@user.full_name} has been reactivated."
  end

  private

  def require_mitigation_admin
    authorize_mitigation_role!(:manager, :office_sales)
  end

  def set_user
    @user = User.where(organization_id: visible_org_ids).find(params[:id])
  end

  # Mitigation admins can see users in their own org + PM orgs they service
  def visible_org_ids
    pm_org_ids = Property.where(mitigation_org_id: current_user.organization_id)
                         .distinct.pluck(:property_management_org_id)
    [current_user.organization_id] + pm_org_ids
  end

  def serialize_user(user)
    {
      id: user.id,
      path: user_path(user),
      full_name: user.full_name,
      email: user.email_address,
      phone: user.phone,
      user_type: user.user_type,
      organization_name: user.organization.name,
      active: user.active
    }
  end

  def serialize_user_detail(user)
    detail = serialize_user(user).merge(
      first_name: user.first_name,
      last_name: user.last_name,
      timezone: user.timezone,
      organization_type: user.organization.organization_type,
      deactivate_path: deactivate_user_path(user),
      reactivate_path: reactivate_user_path(user)
    )

    if user.pm_user?
      detail[:assigned_properties] = user.assigned_properties.order(:name).map { |p|
        { id: p.id, name: p.name, path: property_path(p) }
      }
    end

    detail[:assigned_incidents] = user.assigned_incidents
      .where.not(status: %w[completed completed_billed paid closed])
      .includes(:property).order(created_at: :desc).map { |i|
        { id: i.id, description: i.description, damage_type: i.damage_type,
          status: i.status, property_name: i.property.name, path: incident_path(i) }
      }

    detail
  end
end
