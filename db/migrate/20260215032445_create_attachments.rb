class CreateAttachments < ActiveRecord::Migration[8.0]
  def change
    create_table :attachments do |t|
      t.references :attachable, polymorphic: true, null: false
      t.references :uploaded_by_user, null: false, foreign_key: { to_table: :users }
      t.string :category, null: false
      t.string :description
      t.date :log_date

      t.timestamps
    end

    add_index :attachments, %i[attachable_type attachable_id category]
    add_index :attachments, %i[attachable_type attachable_id log_date]
  end
end
