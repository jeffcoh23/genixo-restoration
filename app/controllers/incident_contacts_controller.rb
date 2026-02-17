class IncidentContactsController < ApplicationController
  before_action :set_incident
  before_action :require_manage_permission

  def create
    contact = @incident.incident_contacts.create!(
      contact_params.merge(created_by_user: current_user)
    )

    ActivityLogger.log(
      incident: @incident, event_type: "contact_added", user: current_user,
      metadata: { contact_name: contact.name, contact_title: contact.title }
    )

    redirect_to incident_path(@incident), notice: "Contact added."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident), alert: "Could not add contact: #{e.record.errors.full_messages.join(', ')}"
  end

  def update
    contact = @incident.incident_contacts.find(params[:id])
    contact.update!(contact_params)
    redirect_to incident_path(@incident), notice: "Contact updated."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident), alert: "Could not update contact: #{e.record.errors.full_messages.join(', ')}"
  end

  def destroy
    contact = @incident.incident_contacts.find(params[:id])
    name = contact.name
    contact.destroy!

    ActivityLogger.log(
      incident: @incident, event_type: "contact_removed", user: current_user,
      metadata: { contact_name: name }
    )

    redirect_to incident_path(@incident), notice: "#{name} removed."
  end

  private

  def set_incident
    @incident = find_visible_incident!(params[:incident_id])
  end

  def require_manage_permission
    raise ActiveRecord::RecordNotFound unless can_manage_contacts?
  end

  # Managers and PM-side users can manage contacts
  def can_manage_contacts?
    mitigation_admin? || current_user.pm_user?
  end

  def contact_params
    params.require(:contact).permit(:name, :title, :email, :phone, :onsite)
  end
end
