class EquipmentItemsController < ApplicationController
  before_action :authorize_manage_equipment!

  def index
    org = current_user.organization
    items = org.equipment_items.includes(:equipment_type).order("equipment_types.name, equipment_items.identifier")
    types = org.equipment_types.active.order(:name)

    render inertia: "EquipmentItems/Index", props: {
      items: items.map { |item| serialize_item(item) },
      equipment_types: types.map { |t| { id: t.id, name: t.name } },
      create_path: equipment_items_path
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
    params.require(:equipment_item).permit(:equipment_type_id, :equipment_model, :serial_number, :identifier, :active)
  end

  def serialize_item(item)
    {
      id: item.id,
      identifier: item.identifier,
      equipment_model: item.equipment_model,
      serial_number: item.serial_number,
      type_name: item.equipment_type.name,
      equipment_type_id: item.equipment_type_id,
      active: item.active,
      edit_path: equipment_item_path(item)
    }
  end
end
