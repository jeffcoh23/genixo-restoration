class CreateProperties < ActiveRecord::Migration[8.0]
  def change
    create_table :properties do |t|
      t.references :property_management_org, null: false, foreign_key: { to_table: :organizations }
      t.references :mitigation_org, null: false, foreign_key: { to_table: :organizations }
      t.string :name, null: false
      t.string :street_address
      t.string :city
      t.string :state
      t.string :zip
      t.integer :unit_count

      t.timestamps
    end
  end
end
