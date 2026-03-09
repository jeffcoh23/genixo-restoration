class IncidentAssignmentsController < ApplicationController
  before_action :set_incident
  before_action :require_assign_permission, except: :update_notifications
  before_action :set_assignment, only: :update_notifications

  def create
    user = assignable_users.find(params[:user_id])
    assignment = @incident.incident_assignments.create!(user: user, assigned_by_user: current_user)

    ActivityLogger.log(
      incident: @incident, event_type: "user_assigned", user: current_user,
      metadata: { assigned_user_id: user.id, assigned_user_name: user.full_name }
    )

    AssignmentNotificationJob.perform_later(assignment.id)

    redirect_to incident_path(@incident), notice: "#{user.full_name} assigned."
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    redirect_to incident_path(@incident), alert: "User is already assigned."
  end

  def update_notifications
    raise ActiveRecord::RecordNotFound unless can_update_notification_overrides?(@assignment.user)

    overrides = {}
    IncidentAssignment::OVERRIDABLE_NOTIFICATION_KEYS.each do |key|
      overrides[key] = params[key] == "1" if params.key?(key)
    end

    @assignment.update!(notification_overrides: overrides)
    redirect_to incident_path(@incident), notice: "Notification preferences updated."
  end

  def create_guest
    external_org = Organization.find_by!(organization_type: "external")
    email = params[:email]&.strip&.downcase

    user = User.find_by(email_address: email)

    if user && !user.guest?
      redirect_to incident_path(@incident), alert: "#{email} already has a non-guest account."
      return
    end

    if user.nil?
      user = external_org.users.new(
        email_address: email,
        first_name: params[:first_name],
        last_name: params[:last_name],
        title: params[:title].presence,
        user_type: User::GUEST,
        password: SecureRandom.hex(20),
        active: false
      )
      unless user.save
        redirect_to incident_path(@incident), alert: "Could not create guest: #{user.errors.full_messages.first}"
        return
      end

      invitation = external_org.invitations.create!(
        invited_by_user: current_user,
        email: email,
        user_type: User::GUEST,
        first_name: user.first_name,
        last_name: user.last_name,
        title: user.title,
        permissions: [],
        expires_at: 30.days.from_now
      )
      InvitationMailer.invite(invitation).deliver_later
    end

    assignment = @incident.incident_assignments.find_or_create_by!(user: user) do |a|
      a.assigned_by_user = current_user
    end

    if assignment.previously_new_record?
      ActivityLogger.log(
        incident: @incident, event_type: "user_assigned", user: current_user,
        metadata: { assigned_user_id: user.id, assigned_user_name: user.full_name }
      )
      AssignmentNotificationJob.perform_later(assignment.id) if user.active?
    end

    redirect_to incident_path(@incident), notice: "#{user.full_name} invited as guest."
  end

  def destroy
    assignment = @incident.incident_assignments.find(params[:id])
    user = assignment.user

    # PM users can only remove their own org's users
    unless can_remove_assignment?(user)
      raise ActiveRecord::RecordNotFound
    end

    assignment.destroy!

    ActivityLogger.log(
      incident: @incident, event_type: "user_unassigned", user: current_user,
      metadata: { unassigned_user_id: user.id, unassigned_user_name: user.full_name }
    )

    redirect_to incident_path(@incident), notice: "#{user.full_name} removed."
  end

  private

  def set_incident
    @incident = find_visible_incident!(params[:incident_id])
  end

  def set_assignment
    @assignment = @incident.incident_assignments.find(params[:id])
  end

  def require_assign_permission
    raise ActiveRecord::RecordNotFound unless can_assign_to_incident?
  end

  # Mitigation managers can assign anyone. PM users can assign their own org's users.
  def can_assign_to_incident?
    mitigation_admin? || current_user.pm_user?
  end

  def assignable_users
    if mitigation_admin?
      # Can assign any active user from either org
      User.where(active: true)
        .where(organization_id: [ @incident.property.mitigation_org_id, @incident.property.property_management_org_id ])
        .where.not(id: @incident.assigned_user_ids)
    else
      # PM users can only assign their own org's users
      User.where(active: true, organization_id: current_user.organization_id)
        .where.not(id: @incident.assigned_user_ids)
    end
  end
end
