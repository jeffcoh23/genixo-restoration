class DfrPdfJob < ApplicationJob
  queue_as :default

  def perform(incident_id, date, user_timezone, user_id, photo_attachment_ids = nil)
    incident = Incident.find(incident_id)
    user = User.find(user_id)
    parsed_date = Date.parse(date)

    pdf_data = DfrPdfService.new(
      incident: incident, date: date, timezone: user_timezone,
      include_photos: true, photo_attachment_ids: photo_attachment_ids
    ).generate

    filename = build_filename(incident, date)

    existing = incident.attachments.find_by(category: "dfr", log_date: parsed_date)
    if existing
      # Attaching a new file replaces the old one and purges the previous blob
      # (has_one_attached defaults to dependent: :purge_later). Do NOT purge
      # first: purging and then re-attaching left the row without a file if the
      # job died in between (e.g. an R14 memory kill during generation), which
      # 500'd the whole incident page via the daily-log DFR link.
      existing.file.attach(
        io: StringIO.new(pdf_data),
        filename: filename,
        content_type: "application/pdf"
      )
      existing.update!(uploaded_by_user: user)
    else
      attachment = incident.attachments.build(
        category: "dfr",
        description: "Daily Field Report — #{date}",
        log_date: parsed_date,
        uploaded_by_user: user
      )
      attachment.file.attach(
        io: StringIO.new(pdf_data),
        filename: filename,
        content_type: "application/pdf"
      )
      attachment.save!
    end
  end

  private

  def build_filename(incident, date)
    property_name = incident.property.name.to_s.gsub(/[\/\\:*?"<>|]/, " ").squeeze(" ").strip
    parts = [ "DFR", property_name.presence || "Report" ]
    parts << incident.job_id if incident.job_id.present?
    parts << date
    "#{parts.join(' - ')}.pdf"
  end
end
