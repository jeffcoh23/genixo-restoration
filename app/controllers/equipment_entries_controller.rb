class EquipmentEntriesController < ApplicationController
  before_action :set_incident
  before_action :authorize_equipment!

  def create
    entry = @incident.equipment_entries.new(equipment_entry_params)
    entry.logged_by_user = current_user

    entry.save!
    context = equipment_action_context(params[:equipment_entry], default_action: "add")

    ActivityLogger.log(
      incident: @incident,
      event_type: "equipment_placed",
      user: current_user,
      metadata: {
        equipment_entry_id: entry.id,
        action_type: context[:action_type],
        reason: context[:reason],
        action_notes: context[:action_notes],
        action_at: context[:action_at]&.iso8601,
        type_name: entry.type_name,
        equipment_identifier: entry.equipment_identifier,
        location_notes: entry.location_notes
      }
    )

    redirect_to incident_path(@incident), notice: "Equipment placed."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not place equipment."
  end

  def update
    entry = find_editable_entry!

    entry.assign_attributes(equipment_entry_params)

    entry.save!
    context = equipment_action_context(params[:equipment_entry], default_action: "other")

    ActivityLogger.log(
      incident: @incident,
      event_type: "equipment_updated",
      user: current_user,
      metadata: {
        equipment_entry_id: entry.id,
        action_type: context[:action_type],
        reason: context[:reason],
        action_notes: context[:action_notes],
        action_at: context[:action_at]&.iso8601,
        type_name: entry.type_name,
        equipment_identifier: entry.equipment_identifier,
        location_notes: entry.location_notes
      }
    )

    redirect_to incident_path(@incident), notice: "Equipment entry updated."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not update equipment entry."
  end

  def remove
    entry = find_editable_entry!

    removal_time = params[:removed_at].present? ? Time.zone.parse(params[:removed_at]) : Time.current
    entry.update!(removed_at: removal_time)
    context = equipment_action_context(params, default_action: "remove")

    ActivityLogger.log(
      incident: @incident,
      event_type: "equipment_removed",
      user: current_user,
      metadata: {
        equipment_entry_id: entry.id,
        action_type: context[:action_type],
        reason: context[:reason],
        action_notes: context[:action_notes],
        action_at: context[:action_at]&.iso8601,
        type_name: entry.type_name,
        equipment_identifier: entry.equipment_identifier,
        location_notes: entry.location_notes
      }
    )

    redirect_to incident_path(@incident), notice: "Equipment removed."
  end

  private

  def set_incident
    @incident = find_visible_incident!(params[:incident_id])
  end

  def authorize_equipment!
    raise ActiveRecord::RecordNotFound unless can_create_equipment?
  end

  def find_editable_entry!
    if mitigation_admin?
      @incident.equipment_entries.find(params[:id])
    else
      @incident.equipment_entries.where(logged_by_user_id: current_user.id).find(params[:id])
    end
  end

  def equipment_entry_params
    params.require(:equipment_entry).permit(
      :equipment_type_id, :equipment_type_other, :equipment_identifier,
      :placed_at, :location_notes
    )
  end

  def equipment_action_context(raw_params, default_action:)
    params_hash = raw_params.is_a?(ActionController::Parameters) ? raw_params : ActionController::Parameters.new(raw_params || {})
    permitted = params_hash.permit(:action_type, :reason, :action_notes, :action_at)

    {
      action_type: permitted[:action_type].presence || default_action,
      reason: permitted[:reason].presence,
      action_notes: permitted[:action_notes].presence,
      action_at: parse_action_time(permitted[:action_at])
    }
  end

  def parse_action_time(raw_value)
    return nil if raw_value.blank?

    Time.zone.parse(raw_value)
  rescue ArgumentError, TypeError
    nil
  end
end
