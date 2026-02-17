class AddMvpFieldsToIncidentsAndContacts < ActiveRecord::Migration[8.0]
  def change
    add_column :incidents, :visitors, :text
    add_column :incidents, :usable_rooms_returned, :text
    add_column :incidents, :estimated_date_of_return, :date

    add_column :incident_contacts, :onsite, :boolean, default: false, null: false
  end
end
