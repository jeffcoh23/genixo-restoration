class DfrPdfJob < ApplicationJob
  queue_as :default

  def perform(incident_id, date, user_timezone, user_id)
    incident = Incident.find(incident_id)
    user = User.find(user_id)
    pdf_data = DfrPdfService.new(
      incident: incident, date: date, timezone: user_timezone, include_photos: false
    ).generate

    filename = "DFR-#{incident.job_id || incident.id}-#{date}.pdf"

    attachment = incident.attachments.build(
      category: "general",
      description: "Daily Field Report — #{date}",
      log_date: Date.parse(date),
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
