class AddFieldsToActivityEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :activity_entries, :visitors, :text
    add_column :activity_entries, :usable_rooms_returned, :string
    add_column :activity_entries, :estimated_date_of_return, :date
  end
end
