class AddRequestFieldsToIncidents < ActiveRecord::Migration[8.0]
  def change
    add_column :incidents, :do_not_exceed_limit, :decimal
    add_column :incidents, :location_of_damage, :text
  end
end
