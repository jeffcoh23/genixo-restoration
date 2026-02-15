class SettingsController < ApplicationController
  def show
    render inertia: "Settings/Profile"
  end

  def on_call
    render inertia: "Settings/OnCall"
  end

  def equipment_types
    render inertia: "Settings/EquipmentTypes"
  end
end
