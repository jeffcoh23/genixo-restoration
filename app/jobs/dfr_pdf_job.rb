class DfrPdfJob < ApplicationJob
  queue_as :default

  # DFR generation can fail transiently — e.g. one of many S3 photo reads
  # hiccuping into a nil mid-render on a large report. Retry a few times so a
  # flake self-heals instead of leaving the user with a failed report. Safe to
  # retry: perform is idempotent — it regenerates and replaces the report for
  # the date(s), so a retry just redoes the work. After the attempts are
  # exhausted the error re-raises so the failure stays visible (Solid Queue
  # failed jobs / Honeybadger). A deleted incident or user can never succeed →
  # discard those.
  retry_on StandardError, attempts: 3, wait: :polynomially_longer
  discard_on ActiveRecord::RecordNotFound

  # Trailing args keep defaults: jobs enqueued before a deploy carry the old
  # argument list (Solid Queue serializes positional args) and must still run
  # on the new code. end_date makes this a weekly report spanning date..end_date.
  def perform(incident_id, date, user_timezone, user_id, photo_attachment_ids = nil, document_attachment_ids = nil, end_date = nil)
    incident = Incident.find(incident_id)
    user = User.find(user_id)
    parsed_date = Date.parse(date)
    parsed_end_date = end_date ? Date.parse(end_date) : nil
    weekly = parsed_end_date.present?

    # Cached-or-fetched weather for the property/date(s). Both paths return
    # empty-handed on any failure (no key, no address, API error) so the
    # report still generates. Weekly fetches the whole span in one API call
    # and hands the service a date-keyed hash.
    weather = if weekly
      WeatherService.for_range(incident: incident, start_date: parsed_date, end_date: parsed_end_date)
    else
      WeatherService.for(incident: incident, date: parsed_date)
    end

    pdf_data = DfrPdfService.new(
      incident: incident, date: date, end_date: parsed_end_date, timezone: user_timezone,
      include_photos: true, photo_attachment_ids: photo_attachment_ids,
      document_attachment_ids: document_attachment_ids, weather: weather
    ).generate

    filename = build_filename(incident, parsed_date, parsed_end_date)
    category = weekly ? "weekly_report" : "dfr"
    description = weekly ? "Weekly Field Report — #{parsed_date} to #{parsed_end_date}" : "Daily Field Report — #{date}"

    existing = incident.attachments.find_by(category: category, log_date: parsed_date, log_date_end: parsed_end_date)
    if existing
      attach_file(existing, pdf_data, filename, user)
    else
      begin
        attachment = incident.attachments.build(
          category: category,
          description: description,
          log_date: parsed_date,
          log_date_end: parsed_end_date,
          uploaded_by_user: user
        )
        attachment.file.attach(io: StringIO.new(pdf_data), filename: filename, content_type: "application/pdf")
        attachment.save!
      rescue ActiveRecord::RecordNotUnique
        # A concurrent generation for the same span won the insert (partial
        # unique index on generated-report identity) — attach over its row.
        # Weekly-only in practice: DFR rows keep NULL log_date_end, and
        # Postgres NULLs-distinct means the index never fires for them (the
        # daily double-generate race predates this feature; see TODOS.md).
        winner = incident.attachments.find_by!(category: category, log_date: parsed_date, log_date_end: parsed_end_date)
        attach_file(winner, pdf_data, filename, user)
      end
    end
  end

  private

  # Attaching a new file replaces the old one and purges the previous blob
  # (has_one_attached defaults to dependent: :purge_later). Do NOT purge
  # first: purging and then re-attaching left the row without a file if the
  # job died in between (e.g. an R14 memory kill during generation), which
  # 500'd the whole incident page via the daily-log DFR link.
  def attach_file(attachment, pdf_data, filename, user)
    attachment.file.attach(
      io: StringIO.new(pdf_data),
      filename: filename,
      content_type: "application/pdf"
    )
    attachment.update!(uploaded_by_user: user)
  end

  def build_filename(incident, date, end_date)
    property_name = incident.property.name.to_s.gsub(/[\/\\:*?"<>|]/, " ").squeeze(" ").strip
    parts = [ end_date ? "Weekly Report" : "DFR", property_name.presence || "Report" ]
    parts << incident.job_id if incident.job_id.present?
    parts << (end_date ? "#{date} to #{end_date}" : date.to_s)
    "#{parts.join(' - ')}.pdf"
  end
end
