class AddGDepToPsychrometricReadings < ActiveRecord::Migration[8.0]
  def change
    add_column :psychrometric_readings, :g_dep, :decimal, precision: 5, scale: 1
  end
end
