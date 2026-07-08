class DropIncidentTasksAndUnits < ActiveRecord::Migration[8.0]
  # Dead tables: no models, no code references. They exist only in dev
  # databases — production never had them (verified 2026-07-07 read-only),
  # hence if_exists so this no-ops there.
  def up
    drop_table :incident_tasks, if_exists: true
    drop_table :incident_units, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
