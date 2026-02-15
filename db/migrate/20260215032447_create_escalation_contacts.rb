class CreateEscalationContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :escalation_contacts do |t|
      t.references :on_call_configuration, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :position, null: false

      t.timestamps
    end

    add_index :escalation_contacts, %i[on_call_configuration_id position], unique: true, name: "index_escalation_contacts_on_config_id_and_position"
  end
end
