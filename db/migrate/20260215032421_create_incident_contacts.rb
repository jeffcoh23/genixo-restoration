class CreateIncidentContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :incident_contacts do |t|
      t.references :incident, null: false, foreign_key: true
      t.string :name, null: false
      t.string :title
      t.string :email
      t.string :phone
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
