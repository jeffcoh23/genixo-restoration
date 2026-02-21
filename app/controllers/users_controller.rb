class UsersController < ApplicationController
  before_action :require_users_management_access, only: %i[index deactivate reactivate]
  before_action :set_user, only: %i[show update deactivate reactivate]
  before_action :authorize_update!, only: %i[update]

  def index
    org_ids = visible_org_ids
    active = User.where(organization_id: org_ids, active: true).includes(:organization).order(:last_name, :first_name)
    deactivated = User.where(organization_id: org_ids, active: false).includes(:organization).order(:last_name, :first_name)
    pending = Invitation.where(organization_id: org_ids, accepted_at: nil)
                        .includes(:organization).order(created_at: :desc)

    render inertia: "Users/Index", props: {
      active_users: active.map { |u| serialize_user(u) },
      deactivated_users: deactivated.map { |u| serialize_user(u) },
      pending_invitations: pending.map { |inv| serialize_invitation(inv) },
      org_options: invite_org_options
    }
  end

  def show
    render inertia: "Users/Show", props: {
      user: serialize_user_detail(@user),
      can_edit: can_edit_target_user?,
      can_edit_role: can_edit_role_for_target?,
      can_deactivate: @user.id != current_user.id,
      role_options: can_edit_role_for_target? ? role_options_for(@user.organization) : []
    }
  end

  def update
    if @user.update(user_update_params)
      redirect_to user_path(@user), notice: "User details updated."
    else
      redirect_to user_path(@user), inertia: { errors: @user.errors.to_hash },
        alert: "Could not update user."
    end
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

  def require_users_management_access
    raise ActiveRecord::RecordNotFound unless can_manage_users?
  end

  def set_user
    if params[:id].to_i == current_user.id
      @user = current_user
      return
    end

    raise ActiveRecord::RecordNotFound unless can_manage_users?
    @user = User.where(organization_id: visible_org_ids).find(params[:id])
  end

  # Mitigation admins can see users in their own org + PM orgs they service
  def visible_org_ids
    pm_org_ids = Property.where(mitigation_org_id: current_user.organization_id)
                         .distinct.pluck(:property_management_org_id)
    [ current_user.organization_id ] + pm_org_ids
  end

  def serialize_user(user)
    {
      id: user.id,
      path: user_path(user),
      full_name: user.full_name,
      user_type: user.user_type,
      email: user.email_address,
      phone: user.phone,
      role_label: User::ROLE_LABELS[user.user_type],
      organization_name: user.organization.name,
      active: user.active
    }
  end

  def serialize_invitation(inv)
    {
      id: inv.id,
      display_name: [ inv.first_name, inv.last_name ].filter_map(&:presence).join(" ").presence || inv.email,
      email: inv.email,
      role_label: User::ROLE_LABELS[inv.user_type],
      organization_name: inv.organization.name,
      expired: inv.expired?,
      resend_path: resend_invitation_path(inv)
    }
  end

  # Own org + serviced PM orgs for the invite form, with role options per org
  def invite_org_options
    orgs = [ current_user.organization ]
    pm_org_ids = Property.where(mitigation_org_id: current_user.organization_id)
                         .distinct.pluck(:property_management_org_id)
    orgs += Organization.where(id: pm_org_ids).order(:name) if pm_org_ids.any?
    orgs.map { |o|
      types = o.mitigation? ? User::MITIGATION_TYPES : User::PM_TYPES
      {
        id: o.id,
        name: o.name,
        role_options: types.map { |t| { value: t, label: User::ROLE_LABELS[t] } }
      }
    }
  end

  def serialize_user_detail(user)
    detail = serialize_user(user).merge(
      first_name: user.first_name,
      last_name: user.last_name,
      timezone: user.timezone,
      update_path: user_path(user),
      is_pm_user: user.pm_user?,
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
        { id: i.id, summary: incident_summary(i), status: i.status, status_label: Incident::STATUS_LABELS[i.status],
          property_name: i.property.name, path: incident_path(i) }
      }

    detail
  end

  def incident_summary(incident)
    label = Incident::DAMAGE_LABELS[incident.damage_type] || incident.damage_type
    desc = incident.description.truncate(50)
    "#{label} — #{desc}"
  end

  def role_options_for(organization)
    types = organization.mitigation? ? User::MITIGATION_TYPES : User::PM_TYPES
    types.map { |t| { value: t, label: User::ROLE_LABELS[t] } }
  end

  def can_edit_other_users?
    current_user.organization.mitigation? && current_user.user_type == User::MANAGER
  end

  def can_edit_target_user?
    @user.id == current_user.id || can_edit_other_users?
  end

  def can_edit_role_for_target?
    can_edit_other_users? && @user.id != current_user.id
  end

  def authorize_update!
    raise ActiveRecord::RecordNotFound unless can_edit_target_user?
  end

  def user_update_params
    allowed = [ :first_name, :last_name, :email_address, :phone, :timezone ]
    allowed << :user_type if can_edit_role_for_target?
    params.require(:user).permit(*allowed)
  end
end
