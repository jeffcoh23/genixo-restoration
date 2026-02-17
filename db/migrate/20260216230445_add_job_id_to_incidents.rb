class AddJobIdToIncidents < ActiveRecord::Migration[8.0]
  def change
    add_column :incidents, :job_id, :string
  end
end
