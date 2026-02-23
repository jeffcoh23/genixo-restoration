class ActivityEntriesController < ApplicationController
  before_action :set_incident
  before_action :authorize_activity!

  def create
    entry = @incident.activity_entries.new(activity_entry_attributes)
    entry.performed_by_user = current_user

    ActivityEntry.transaction do
      entry.save!
      replace_equipment_actions!(entry)
    end

    ActivityLogger.log(
      incident: @incident,
      event_type: "activity_logged",
      user: current_user,
      metadata: {
        title: entry.title,
        status: entry.status,
        equipment_action_count: entry.equipment_actions.count
      }
    )

    redirect_to incident_path(@incident), notice: "Activity added."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not save activity."
  end

  def update
    entry = find_editable_entry!
    entry.assign_attributes(activity_entry_attributes)

    ActivityEntry.transaction do
      entry.save!
      replace_equipment_actions!(entry)
    end

    ActivityLogger.log(
      incident: @incident,
      event_type: "activity_updated",
      user: current_user,
      metadata: {
        title: entry.title,
        status: entry.status,
        equipment_action_count: entry.equipment_actions.count
      }
    )

    redirect_to incident_path(@incident), notice: "Activity updated."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not update activity."
  end

  private

  def set_incident
    @incident = find_visible_incident!(params[:incident_id])
  end

  def authorize_activity!
    raise ActiveRecord::RecordNotFound unless can_create_equipment?
  end

  def find_editable_entry!
    if mitigation_admin?
      @incident.activity_entries.find(params[:id])
    else
      @incident.activity_entries.where(performed_by_user_id: current_user.id).find(params[:id])
    end
  end

  def activity_entry_params
    params.require(:activity_entry).permit(
      :title,
      :details,
      :status,
      :occurred_at,
      :units_affected,
      :units_affected_description,
      :visitors,
      :usable_rooms_returned,
      :estimated_date_of_return,
      equipment_actions: [
        :action_type,
        :quantity,
        :equipment_type_id,
        :equipment_entry_id,
        :equipment_type_other,
        :note,
        :position
      ]
    )
  end

  def activity_entry_attributes
    permitted = activity_entry_params
    attrs = permitted.to_h
    attrs.delete("equipment_actions")
    attrs.symbolize_keys
  end

  def replace_equipment_actions!(entry)
    entry.equipment_actions.destroy_all

    permitted_actions.each_with_index do |raw_action, index|
      action_attributes = normalize_equipment_action(raw_action, index)
      next unless action_attributes

      entry.equipment_actions.create!(action_attributes)
    end
  end

  def permitted_actions
    actions = activity_entry_params[:equipment_actions]
    return [] unless actions.present?

    case actions
    when ActionController::Parameters
      actions.values
    when Hash
      actions.values
    when Array
      actions
    else
      [ actions ]
    end
  end

  def normalize_equipment_action(raw_action, index)
    action_hash = raw_action.to_h.symbolize_keys

    action_type = action_hash[:action_type].to_s.downcase
    action_type = "other" unless ActivityEquipmentAction::ACTION_TYPES.include?(action_type)

    quantity = action_hash[:quantity].presence&.to_i
    equipment_type_id = action_hash[:equipment_type_id].to_s.match?(/\A\d+\z/) ? action_hash[:equipment_type_id].to_i : nil
    equipment_entry_id = action_hash[:equipment_entry_id].to_s.match?(/\A\d+\z/) ? action_hash[:equipment_entry_id].to_i : nil
    equipment_type_other = action_hash[:equipment_type_other].to_s.strip.presence
    note = action_hash[:note].to_s.strip.presence
    position = action_hash[:position].presence&.to_i || index

    has_content = quantity.present? || equipment_type_id.present? || equipment_entry_id.present? ||
      equipment_type_other.present? || note.present?
    return nil unless has_content

    {
      action_type: action_type,
      quantity: quantity,
      equipment_type_id: equipment_type_id,
      equipment_entry_id: equipment_entry_id,
      equipment_type_other: equipment_type_other,
      note: note,
      position: position
    }
  end
end
