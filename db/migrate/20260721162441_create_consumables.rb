class CreateConsumables < ActiveRecord::Migration[8.0]
  # Daniel's standard consumables list, in the order it appears on his sheet.
  DEFAULT_TYPES = [
    "HEPA Filter Air Scrubber Small",
    "HEPA Filter Air Scrubber Large",
    "HEPA Vacuum Small",
    "HEPA Vacuum Large",
    "Hydroxyl Unit",
    "Portable Water Extractor",
    "Truck Mount Unit",
    "Truck/Van Vehicle",
    "Decontamination of Equipment",
    "Filter Replacement",
    "Disposal"
  ].freeze

  def up
    create_table :consumable_types do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
      t.index [ :organization_id, :name ], unique: true
    end

    create_table :consumable_entries do |t|
      t.references :incident, null: false, foreign_key: true
      t.references :consumable_type, foreign_key: true
      t.string :custom_name
      t.integer :quantity, null: false
      t.date :log_date, null: false
      t.references :logged_by_user, null: false, foreign_key: { to_table: :users }
      t.timestamps
      t.index [ :incident_id, :log_date ]
      t.check_constraint "(consumable_type_id IS NOT NULL AND custom_name IS NULL) OR (consumable_type_id IS NULL AND custom_name IS NOT NULL)",
        name: "consumable_entries_type_xor_custom"
    end

    # Prefill the standard list for every existing mitigation org (new orgs get
    # theirs from db/seeds.rb in dev; production has a single mitigation org).
    say_with_time "seeding default consumable types" do
      org_ids = select_values("SELECT id FROM organizations WHERE organization_type = 'mitigation'")
      org_ids.each do |org_id|
        DEFAULT_TYPES.each_with_index do |name, position|
          execute <<~SQL
            INSERT INTO consumable_types (organization_id, name, position, active, created_at, updated_at)
            VALUES (#{Integer(org_id)}, #{quote(name)}, #{position}, TRUE, NOW(), NOW())
            ON CONFLICT (organization_id, name) DO NOTHING
          SQL
        end
      end
      org_ids.size
    end
  end

  def down
    drop_table :consumable_entries
    drop_table :consumable_types
  end
end
