class IncidentAssignmentsController < ApplicationController
  before_action :set_incident
  before_action :require_assign_permission

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

  def require_assign_permission
    raise ActiveRecord::RecordNotFound unless can_assign_to_incident?
  end

  # Mitigation managers can assign anyone. PM users can assign their own org's users.
  def can_assign_to_incident?
    mitigation_admin? || current_user.pm_user?
  end

  def can_remove_assignment?(user)
    return true if mitigation_admin?
    current_user.pm_user? && user.organization_id == current_user.organization_id
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
