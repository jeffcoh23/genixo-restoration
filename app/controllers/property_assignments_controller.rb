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
    raise ActiveRecord::RecordNotFound unless can_assign_to_property?(@property)
  end
end
