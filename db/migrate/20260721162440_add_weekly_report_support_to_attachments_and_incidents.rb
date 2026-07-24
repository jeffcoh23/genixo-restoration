class AddWeeklyReportSupportToAttachmentsAndIncidents < ActiveRecord::Migration[8.0]
  def change
    add_column :attachments, :log_date_end, :date
    add_column :incidents, :delayed, :boolean, default: false, null: false

    # Weekly reports are found-or-created by their date range; this unique index
    # turns a concurrent double-generate into RecordNotUnique (rescued in the
    # job) instead of two attachment rows. DFRs keep a NULL log_date_end, and
    # Postgres treats NULLs as distinct, so existing DFR rows are unaffected.
    add_index :attachments,
      [ :attachable_type, :attachable_id, :category, :log_date, :log_date_end ],
      unique: true,
      where: "category IN ('dfr', 'weekly_report')",
      name: "index_attachments_on_generated_report_identity"
  end
end
