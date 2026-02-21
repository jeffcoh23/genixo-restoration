class EquipmentItemsController < ApplicationController
  before_action :authorize_manage_equipment!

  def index
    org = current_user.organization
    items = org.equipment_items.active
      .includes(:equipment_type, equipment_entries: { incident: :property })
      .order("equipment_types.name, equipment_items.identifier")

    active_types = org.equipment_types.active.order(:name)
    inactive_types = org.equipment_types.where(active: false).order(:name)

    render inertia: "EquipmentItems/Index", props: {
      items: items.map { |item| serialize_item(item) },
      equipment_types: active_types.map { |t| { id: t.id, name: t.name } },
      all_types: (active_types + inactive_types).map { |t| serialize_type(t) },
      create_item_path: equipment_items_path,
      create_type_path: create_equipment_type_path
    }
  end

  def create
    org = current_user.organization
    item = org.equipment_items.new(item_params)

    if item.save
      redirect_to equipment_items_path, notice: "#{item.identifier} added."
    else
      redirect_to equipment_items_path,
        inertia: { errors: item.errors.to_hash },
        alert: item.errors.full_messages.join(", ")
    end
  end

  def update
    item = current_user.organization.equipment_items.find(params[:id])

    if item.update(item_params)
      redirect_to equipment_items_path, notice: "#{item.identifier} updated."
    else
      redirect_to equipment_items_path,
        inertia: { errors: item.errors.to_hash },
        alert: item.errors.full_messages.join(", ")
    end
  end

  private

  def authorize_manage_equipment!
    raise ActiveRecord::RecordNotFound unless current_user.can?(Permissions::MANAGE_EQUIPMENT_TYPES)
  end

  def item_params
    params.require(:equipment_item).permit(:equipment_type_id, :equipment_model, :identifier, :active)
  end

  def serialize_item(item)
    entries = item.equipment_entries.sort_by { |e| e.placed_at }.reverse
    current = entries.find { |e| e.removed_at.nil? }

    {
      id: item.id,
      identifier: item.identifier,
      equipment_model: item.equipment_model,
      type_name: item.equipment_type.name,
      equipment_type_id: item.equipment_type_id,
      active: item.active,
      edit_path: equipment_item_path(item),
      deployed: current.present?,
      deployed_property: current&.incident&.property&.name,
      deployed_incident_id: current&.incident_id,
      placements: entries.map { |e| serialize_placement(e) }
    }
  end

  def serialize_placement(entry)
    {
      incident_id: entry.incident_id,
      property_name: entry.incident.property.name,
      job_id: entry.incident.job_id,
      placed_at: entry.placed_at.iso8601,
      placed_at_formatted: I18n.l(entry.placed_at.to_date, format: :short),
      removed_at: entry.removed_at&.iso8601,
      removed_at_formatted: entry.removed_at ? I18n.l(entry.removed_at.to_date, format: :short) : nil,
      location_notes: entry.location_notes
    }
  end

  def serialize_type(et)
    {
      id: et.id,
      name: et.name,
      active: et.active,
      deactivate_path: et.active ? deactivate_equipment_type_path(et) : nil,
      reactivate_path: et.active ? nil : reactivate_equipment_type_path(et)
    }
  end
end
