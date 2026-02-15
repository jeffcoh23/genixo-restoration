class CreateOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :organization_type, null: false
      t.string :phone
      t.string :email
      t.string :street_address
      t.string :city
      t.string :state
      t.string :zip

      t.timestamps
    end

    add_index :organizations, :organization_type
  end
end
