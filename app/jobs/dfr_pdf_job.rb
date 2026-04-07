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

    filename = "DFR-#{incident.job_id || incident.id}-#{date}.pdf"

    existing = incident.attachments.find_by(category: "dfr", log_date: parsed_date)
    if existing
      existing.file.purge
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
end
