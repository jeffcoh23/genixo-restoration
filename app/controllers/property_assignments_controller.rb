class PropertyAssignmentsController < ApplicationController
  before_action :set_property
  before_action :require_assign_permission

  def create
    user = @property.property_management_org.users
      .where(active: true, user_type: User::PM_TYPES)
      .find(params[:user_id])
    @property.property_assignments.create!(user: user)
    redirect_to property_path(@property), notice: "#{user.full_name} assigned."
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    redirect_to property_path(@property), alert: "User is already assigned."
  end

  def destroy
    assignment = @property.property_assignments.find(params[:id])
    name = assignment.user.full_name
    assignment.destroy!
    redirect_to property_path(@property), notice: "#{name} removed."
  end

  private

  def set_property
    @property = find_visible_property!(params[:property_id])
  end

  def require_assign_permission
    raise ActiveRecord::RecordNotFound unless can_assign?
  end

  def can_assign?
    return true if current_user.organization.mitigation? &&
                   %w[manager office_sales].include?(current_user.user_type)
    return true if current_user.pm_user? &&
                   @property.assigned_users.exists?(id: current_user.id)
    false
  end

  def assignable_users
    @property.property_management_org.users
      .where(active: true, user_type: User::PM_TYPES)
      .where.not(id: @property.assigned_user_ids)
  end
end
