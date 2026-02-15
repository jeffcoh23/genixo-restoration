class InvitationsController < ApplicationController
  allow_unauthenticated_access only: %i[show accept]
  before_action :require_mitigation_admin, only: %i[create resend]

  # POST /invitations — create and send invitation
  def create
    org = target_organization
    invitation = org.invitations.new(
      invited_by_user: current_user,
      email: params[:email]&.strip&.downcase,
      user_type: params[:user_type],
      first_name: params[:first_name].presence,
      last_name: params[:last_name].presence,
      phone: params[:phone].presence,
      expires_at: 7.days.from_now
    )

    if invitation.save
      InvitationMailer.invite(invitation).deliver_later
      redirect_to users_path, notice: "Invitation sent to #{invitation.email}."
    else
      redirect_to users_path, inertia: { errors: invitation.errors.to_hash },
        alert: "Could not send invitation."
    end
  end

  # PATCH /invitations/:id/resend
  def resend
    invitation = Invitation.where(accepted_at: nil).find(params[:id])
    invitation.update!(token: SecureRandom.urlsafe_base64(32), expires_at: 7.days.from_now)
    InvitationMailer.invite(invitation).deliver_later
    redirect_to users_path, notice: "Invitation resent to #{invitation.email}."
  end

  # GET /invitations/:token — show acceptance form (unauthenticated)
  def show
    @invitation = Invitation.find_by!(token: params[:token])

    if @invitation.accepted?
      redirect_to login_path, alert: "This invitation has already been accepted."
      return
    end

    if @invitation.expired?
      render inertia: "Invitations/Expired"
      return
    end

    render inertia: "Invitations/Accept", props: {
      invitation: {
        token: @invitation.token,
        email: @invitation.email,
        organization_name: @invitation.organization.name,
        role_label: User::ROLE_LABELS[@invitation.user_type],
        first_name: @invitation.first_name,
        last_name: @invitation.last_name,
        phone: @invitation.phone
      }
    }
  end

  # POST /invitations/:token/accept — create user account (unauthenticated)
  def accept
    @invitation = Invitation.find_by!(token: params[:token])

    if @invitation.accepted? || @invitation.expired?
      redirect_to login_path, alert: "This invitation is no longer valid."
      return
    end

    user = @invitation.organization.users.new(
      email_address: @invitation.email,
      user_type: @invitation.user_type,
      first_name: params[:first_name],
      last_name: params[:last_name],
      phone: params[:phone].presence,
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )

    if user.save
      @invitation.update!(accepted_at: Time.current)
      start_new_session_for(user)
      redirect_to dashboard_path, notice: "Welcome to #{@invitation.organization.name}!"
    else
      redirect_to invitation_path(@invitation.token),
        inertia: { errors: user.errors.to_hash },
        alert: "Could not create your account."
    end
  end

  private

  def require_mitigation_admin
    raise ActiveRecord::RecordNotFound unless can_manage_users?
  end

  def target_organization
    org_id = params[:organization_id]
    if org_id.present? && org_id.to_i != current_user.organization_id
      # Cross-org: must be a PM org they service
      pm_org_ids = Property.where(mitigation_org_id: current_user.organization_id)
                           .distinct.pluck(:property_management_org_id)
      Organization.where(id: pm_org_ids).find(org_id)
    else
      current_user.organization
    end
  end
end
