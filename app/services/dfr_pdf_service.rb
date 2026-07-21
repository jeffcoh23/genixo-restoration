class DfrPdfService
  include ActionView::Helpers::NumberHelper
  include PdfFontSupport

  # Appended-document limits: CombinePDF parses a whole file into Ruby objects
  # (roughly 3-5x the file size in memory), so a per-file AND an aggregate cap
  # keep DFR generation inside the worker's memory quota. Oversized documents
  # are still listed by filename in the Documents section.
  MAX_DOCUMENT_BYTES = 15.megabytes
  MAX_TOTAL_DOCUMENT_BYTES = 40.megabytes

  # Photos render in batches to separate PDFs that are concatenated on disk with
  # pdfunite. A single Prawn document holding every photo spikes memory at render
  # time (O(photos): a 673-photo report serialized ~175MB in one shot and OOM'd
  # the 512MB worker — Heroku R15). Batching bounds the render peak to one batch.
  # 20 keeps each batch's render spike trivial (<10MB) and renders 2-up photo pages.
  PHOTO_BATCH_SIZE = 20

  # Ceiling for the in-memory CombinePDF fallback used only when pdfunite is
  # unavailable. CombinePDF loads every part at once (~3-5x file size in RAM), so
  # above this we ship the body alone rather than risk re-OOMing the worker — the
  # exact failure batching exists to prevent. A hard OOM-kill would bypass rescue.
  MAX_FALLBACK_MERGE_BYTES = 50.megabytes

  # PDF actions that execute script or launch programs have no place in a
  # report page shipped under the mitigation org's name. CombinePDF drops the
  # source document's catalog on merge, but page-level annotations and
  # additional-actions survive — strip them from every parsed object.
  ACTIVE_CONTENT_KEYS = %i[JS JavaScript AA OpenAction Launch].freeze
  ACTIVE_ACTION_TYPES = %i[JavaScript Launch].freeze

  # Longest allowed report span. The controller enforces the same limit
  # pre-enqueue; this guard keeps a bad caller from rendering an unbounded PDF.
  MAX_REPORT_DAYS = 31

  def initialize(incident:, date:, end_date: nil, timezone: "America/Chicago", include_photos: true,
                 photo_attachment_ids: nil, document_attachment_ids: nil, weather: nil)
    @incident = incident
    @date = date.is_a?(String) ? Date.parse(date) : date
    @end_date = end_date ? (end_date.is_a?(String) ? Date.parse(end_date) : end_date) : @date
    raise ArgumentError, "end_date (#{@end_date}) precedes date (#{@date})" if @end_date < @date
    raise ArgumentError, "report span exceeds #{MAX_REPORT_DAYS} days" if (@end_date - @date).to_i >= MAX_REPORT_DAYS
    @timezone = timezone
    @include_photos = include_photos
    @photo_attachment_ids = photo_attachment_ids
    @document_attachment_ids = document_attachment_ids
    # Daily: a WeatherSnapshot (or nil). Weekly: a Hash of Date => WeatherSnapshot.
    # Fetched by the caller so the PDF service stays pure and testable without
    # HTTP; nil/missing days simply omit the weather line.
    @weather = weather
  end

  def generate
    require "prawn"
    require "prawn/table"
    require "mini_magick"
    require "combine_pdf"
    require "tmpdir"
    require "open3"

    with_glyph_fallback do
      Time.use_zone(@timezone) do
        build_pdf
      end
    end
  end

  private

  # Assembly pipeline. Peak memory is bounded to one photo batch, not the whole
  # report:
  #
  #   body.pdf ─────────────────────────────┐
  #   photos_0.pdf (batch of PHOTO_BATCH_SIZE)│
  #   photos_1.pdf ...                        ├─ pdfunite (streams on disk) ─► PDF bytes
  #   documents.pdf (inline images + listings)│
  #   appended_0.pdf (scrubbed source PDFs) ..┘
  #
  # Each sub-PDF is rendered, flushed to disk, and dropped before the next, so no
  # single render holds all photos. pdfunite concatenates without parsing page
  # contents into Ruby (unlike CombinePDF), keeping the merge memory-flat too.
  def build_pdf
    Dir.mktmpdir("dfr") do |dir|
      parts = []
      parts << render_part(dir, "body") { |pdf| render_body(pdf) }
      parts.concat(render_photo_parts(dir)) if @include_photos
      # document_results parses/scrubs selected PDFs up front (classifying each as
      # appended/embedded/listed) — referenced by both the section and the append.
      parts << render_part(dir, "documents") { |pdf| render_documents_body(pdf) } if document_results.any?
      parts.concat(appended_document_parts(dir))
      concat_parts(parts, dir)
    end
  end

  # Single-day output is pinned by DfrPdfServiceTest ("fully-populated
  # single-day report..."): the daily flow must stay byte-for-byte-in-spirit
  # identical through the range generalization. Multi-day prepends a heading
  # per day and renders the same section stack day by day.
  def render_body(pdf)
    render_header(pdf)
    render_info_grid(pdf)
    if multi_day?
      (@date..@end_date).each_with_index do |day, i|
        render_day_heading(pdf, day, first: i.zero?)
        if day_empty?(day)
          # Weather still renders on an empty day — a rain day with no work is
          # exactly what a delay needs documented.
          render_weather(pdf, weather_for(day))
          pdf.font_size(10) { pdf.text "No activity recorded.", color: "777777" }
          pdf.move_down 10
        else
          render_day_sections(pdf, day)
        end
      end
    else
      render_day_sections(pdf, @date)
    end
  end

  def render_day_sections(pdf, day)
    render_weather(pdf, weather_for(day))
    render_employees_section(pdf, day)
    render_work_details(pdf, day)
    render_notes(pdf, day)
    render_summary_fields(pdf, day)
    render_labor_section(pdf, day)
    render_equipment_section(pdf, day)
  end

  def render_day_heading(pdf, day, first:)
    pdf.move_down 8 unless first
    pdf.font_size(13) { pdf.text day.strftime("%A, %B %-d, %Y"), style: :bold }
    pdf.move_down 2
    pdf.stroke_horizontal_rule
    pdf.move_down 8
  end

  def day_empty?(day)
    activities_for_date(day).empty? &&
      labor_entries_for_date(day).empty? &&
      notes_for_date(day).empty? &&
      equipment_entries_for_date(day).empty?
  end

  def multi_day?
    @end_date > @date
  end

  # Renders a Prawn document via the block, flushes it to a temp PDF, and returns
  # the path. The document falls out of scope after render so its (potentially
  # large) buffers can be reclaimed before the next part is built.
  def render_part(dir, name)
    pdf = Prawn::Document.new(page_size: "LETTER", margin: [ 50, 50, 50, 50 ])
    apply_noto_sans(pdf)
    yield pdf
    path = File.join(dir, "#{name}.pdf")
    File.binwrite(path, pdf.render)
    path
  end

  def render_header(pdf)
    title = multi_day? ? "Weekly Field Report" : "Daily Field Report"
    pdf.font_size(18) { pdf.text title, style: :bold, align: :center }
    pdf.move_down 15
  end

  def render_info_grid(pdf)
    property = @incident.property
    manager = assigned_by_role("manager").first
    superintendent = assigned_by_role("technician").first

    data = [
      [ label_cell("Site Name:"), t(property.name), label_cell("Job Name:"), t(property.name) ],
      [ label_cell("Job Number:"), t(@incident.job_id) || "-", label_cell("Date:"), report_date_label ],
      [ label_cell("Project Manager:"), t(manager&.full_name) || "-", label_cell("Superintendent:"), t(superintendent&.full_name) || "-" ],
      # Visitors are day-scoped; a weekly report lists them under each day's
      # summary fields instead of pretending one value covers the whole span.
      [ label_cell("Visitors:"), multi_day? ? "-" : (t(visitors_for_date(@date)) || "-"), label_cell("Status:"), t(@incident.display_status_label) ]
    ]

    pdf.table(data, width: pdf.bounds.width) do |t|
      t.cells.borders = []
      t.cells.padding = [ 3, 5, 3, 5 ]
      t.cells.size = 10
      t.columns(0).width = 110
      t.columns(2).width = 110
      t.columns(0).font_style = :bold
      t.columns(2).font_style = :bold
    end

    pdf.move_down 5
    pdf.stroke_horizontal_rule
    pdf.move_down 10
  end

  def render_weather(pdf, snapshot)
    line = snapshot&.summary_line
    return if line.blank?

    pdf.font_size(10) do
      # conditions comes from the weather API — escape it so external content
      # is never parsed as Prawn inline_format markup.
      pdf.text t("<b>Weather:</b> #{CGI.escapeHTML(line)}"), inline_format: true
    end
    # Visual Crossing's free tier requires attribution.
    pdf.font_size(7) { pdf.text "Weather data by Visual Crossing", color: "999999" }
    pdf.move_down 8
  rescue StandardError => e
    Rails.logger.warn("[DfrPdfService] weather line skipped for incident #{@incident.id}: #{e.message}")
  end

  def render_employees_section(pdf, day)
    labor = labor_entries_for_date(day)
    return if labor.empty?

    names = labor.map { |e| e.user&.full_name || e.created_by_user.full_name }.uniq
    pdf.font_size(10) do
      pdf.text t("Employees on Site: #{names.size} — #{names.join(', ')}"), style: :bold
    end
    pdf.move_down 10
  end

  def render_work_details(pdf, day)
    activities = activities_for_date(day)
    return if activities.empty?

    activities.each do |activity|
      pdf.font_size(10) do
        pdf.text t("• #{activity.title}"), style: :bold, inline_format: true
        if activity.details.present?
          pdf.indent(15) { pdf.text t(activity.details) }
        end

        activity.equipment_actions.includes(:equipment_type).each do |action|
          parts = [ action_label(action.action_type), action.quantity, action.type_name, action.note ].compact
          pdf.indent(15) { pdf.text t("— #{parts.join(' ')}"), color: "555555" }
        end
      end
      pdf.move_down 5
    end
    pdf.move_down 5
  end

  def render_notes(pdf, day)
    notes = notes_for_date(day)
    return if notes.empty?

    pdf.font_size(10) do
      pdf.text "Additional Notes:", style: :bold
      pdf.move_down 3
      notes.each do |note|
        pdf.text t("• #{note.note_text}")
        pdf.move_down 3
      end
    end
    pdf.move_down 10
  end

  def render_summary_fields(pdf, day)
    # Use the most recent activity's metadata for this date, or fall back to
    # incident-level. In a weekly report the incident-level fallbacks (units,
    # rooms, EDR) would repeat identically under every day, so multi-day mode
    # renders only what that day's activity actually recorded.
    activity = activities_for_date(day).first

    fields = []
    units = activity&.units_affected || (multi_day? ? nil : @incident.units_affected)
    units_desc = activity&.units_affected_description
    rooms = multi_day? ? nil : @incident.affected_room_numbers
    visitors = activity&.visitors
    usable_returned = activity&.usable_rooms_returned
    edr = activity&.estimated_date_of_return || (multi_day? ? nil : @incident.estimated_date_of_return)

    fields << [ "Number of Units Affected:", t("#{units}#{units_desc.present? ? " — #{units_desc}" : ""}") ] if units.present?
    fields << [ "Affected Room Numbers:", t(rooms) ] if rooms.present?
    fields << [ "Visitors:", t(visitors) ] if visitors.present?
    fields << [ "Usable Rooms Returned:", t(usable_returned.presence) || "None" ] if usable_returned.present? || units.present?
    fields << [ "Estimated Date of Return:", edr.present? ? edr.strftime("%-m/%-d/%y") : "TBD" ] if units.present?

    return if fields.empty?

    pdf.stroke_horizontal_rule
    pdf.move_down 8

    fields.each do |label, value|
      pdf.font_size(10) do
        pdf.text "<b>#{label}</b> #{value}", inline_format: true
      end
      pdf.move_down 3
    end
    pdf.move_down 5
  end

  def render_labor_section(pdf, day)
    labor = labor_entries_for_date(day)
    return if labor.empty?

    pdf.stroke_horizontal_rule
    pdf.move_down 8

    pdf.font_size(10) { pdf.text "Time:", style: :bold }
    pdf.move_down 3

    # Group by role and sum hours
    by_role = labor.group_by(&:role_label).map do |role, entries|
      count = entries.map { |e| e.user_id || e.created_by_user_id }.uniq.size
      hours = entries.sum(&:hours)
      [ count, role, hours ]
    end

    by_role.each do |count, role, hours|
      pdf.font_size(10) do
        pdf.text t("• #{count} #{role}  #{hours} hrs")
      end
    end
    pdf.move_down 10
  end

  def render_equipment_section(pdf, day)
    entries = equipment_entries_for_date(day)
    return if entries.empty?

    pdf.stroke_horizontal_rule
    pdf.move_down 8

    pdf.font_size(10) { pdf.text "Equipment:", style: :bold }
    pdf.move_down 3

    by_type = entries.group_by { |e| e.type_name.to_s.strip }.sort_by { |name, _| name.downcase }
    by_type.each do |type_name, type_entries|
      total_hours = type_entries.sum { |e| equipment_hours_for_date(e, day) }
      pdf.font_size(10) do
        pdf.text t("• #{type_entries.size} #{type_name}  #{total_hours} hrs")
      end
    end

    pdf.move_down 10
  end

  # Photos in batches of PHOTO_BATCH_SIZE, each rendered to its own PDF part (see
  # build_pdf). The "Photos" heading leads the first batch; later batches are
  # photos only, so concatenation reproduces one continuous Photos section. A
  # batch boundary forces a page break — cosmetically identical since photos
  # already paginate 2-up.
  def render_photo_parts(dir)
    photos = photos_for_date
    return [] if photos.empty?

    photos.each_slice(PHOTO_BATCH_SIZE).with_index.map do |batch, idx|
      path = render_part(dir, "photos_#{idx}") do |pdf|
        if idx.zero?
          pdf.font_size(12) { pdf.text "Photos", style: :bold }
          pdf.move_down 10
        end

        # Cap each photo at half-page height so two stack per page. Without a
        # height cap, full-width portrait photos dominate a page each and Prawn
        # paginates fresh between them, leaving large blank gaps.
        max_height = (pdf.bounds.height - 30) / 2 - 15

        batch.each { |attachment| embed_image_attachment(pdf, attachment, max_height) }
      end
      GC.start
      path
    end
  end

  def embed_image_attachment(pdf, attachment, max_height)
    blob = attachment.file.blob
    return unless blob.content_type.start_with?("image/")
    return unless blob.service.exist?(blob.key)

    blob.open do |tempfile|
      # Phone photos store the sensor's native (landscape) pixels and an EXIF
      # orientation tag; Prawn ignores EXIF, so portraits would render sideways.
      # auto_orient bakes the rotation into the pixels and strips the tag.
      # Resize: source images are full sensor resolution (often 24MP), but the
      # PDF only renders them at ~4in wide. Cap longest side at 1600px so the
      # embedded copy is roughly print-resolution, keeping the PDF small and
      # cutting peak memory during generation.
      image = MiniMagick::Image.open(tempfile.path)
      image.auto_orient
      image.resize "1600x1600>"
      image.quality 85
      image.write(tempfile.path)

      pdf.image tempfile.path, fit: [ pdf.bounds.width, max_height ], position: :center
      pdf.move_down 15
    end
  rescue StandardError => e
    Rails.logger.warn("[DfrPdfService] could not embed image attachment #{attachment.id} (#{attachment.file.filename}): #{e.message}")
    nil
  end

  # Documents section (heading + inline image documents + filename listings) as
  # its own PDF part. The leading page break is provided by concatenation, so no
  # start_new_page here. Caller guards on document_results.any?.
  def render_documents_body(pdf)
    pdf.font_size(12) { pdf.text "Documents", style: :bold }
    pdf.move_down 10

    image_max_height = (pdf.bounds.height - 30) / 2 - 15

    document_results.each do |result|
      case result[:disposition]
      when :embedded_image
        pdf.font_size(10) { pdf.text t("• #{result[:filename]}") }
        pdf.move_down 5
        embed_image_attachment(pdf, result[:attachment], image_max_height)
      when :appended
        pdf.font_size(10) { pdf.text t("• #{result[:filename]} (attached)") }
        pdf.move_down 3
      else
        label = result[:note] ? "• #{result[:filename]} (#{result[:note]})" : "• #{result[:filename]}"
        pdf.font_size(10) { pdf.text t(label) }
        pdf.move_down 3
      end
    end
  end

  # Selected PDF documents become their own concatenation parts, appended after
  # the body/photos/documents section. Each was already parsed and scrubbed of
  # active content up front (document_results), so here we only re-serialize the
  # scrubbed copy to disk — no giant merge, no re-parsing the photo pages.
  def appended_document_parts(dir)
    parts = []
    document_results.each_with_index do |result, i|
      parsed = result[:parsed]
      next unless parsed

      begin
        path = File.join(dir, "appended_#{i}.pdf")
        File.binwrite(path, parsed.to_pdf)
        parts << path
      rescue StandardError => e
        # A bad appended document must never kill the DFR: skip it. The Documents
        # section still lists it as "(attached)" — preferable to no report at all.
        Rails.logger.warn("[DfrPdfService] could not serialize appended document #{result[:filename]}: #{e.message}")
      end
    end
    parts
  end

  # Concatenate the PDF parts on disk with pdfunite (poppler), which streams
  # pages without parsing their contents into Ruby, keeping merge memory flat
  # regardless of photo count. pdfunite ships with the Heroku stack; the
  # in-memory fallback below is only for its (rare) absence or failure.
  def concat_parts(parts, dir)
    return "".b if parts.empty?
    # parts.first is always the body part (build_pdf adds it first), so a
    # single-part return / fallback always yields a valid report body.
    return File.binread(parts.first) if parts.one?

    output = File.join(dir, "dfr.pdf")
    reason =
      begin
        _out, err, status = Open3.capture3("pdfunite", *parts, output)
        return File.binread(output) if status.success?
        err.to_s.strip.presence || "exit #{status.exitstatus}"
      rescue StandardError => e
        # e.g. pdfunite not installed (Errno::ENOENT) — capture3 raises where
        # system() would return nil; both mean "fall back".
        e.message
      end

    Rails.logger.warn("[DfrPdfService] pdfunite unavailable (#{reason}); falling back to in-memory merge")
    combine_parts_fallback(parts)
  end

  # In-memory fallback for a missing/failed pdfunite. CombinePDF loads every part
  # at once, so on a large photo report this could itself blow the worker's memory
  # quota (a hard OOM-kill would even bypass the rescue). So above a size ceiling
  # we ship the body alone — a valid, if incomplete, report — and log loudly so
  # the broken pdfunite is caught. Parts are merged individually so one bad file
  # can't sink the whole report.
  def combine_parts_fallback(parts)
    total = parts.sum { |path| File.size(path) }
    if total > MAX_FALLBACK_MERGE_BYTES
      Rails.logger.error("[DfrPdfService] pdfunite unavailable and parts too large to merge in memory (#{total} bytes); shipping body only")
      return File.binread(parts.first)
    end

    # Load the body first: it anchors the report, so if even it can't be parsed
    # there's nothing worth shipping but the raw body bytes. Remaining parts are
    # merged individually so one bad file can't sink the whole report.
    body, *rest = parts
    combined =
      begin
        CombinePDF.load(body)
      rescue StandardError => e
        Rails.logger.error("[DfrPdfService] fallback could not load body part: #{e.message}")
        return File.binread(body)
      end

    rest.each do |path|
      combined << CombinePDF.load(path)
    rescue StandardError => e
      Rails.logger.warn("[DfrPdfService] fallback merge skipped a bad part #{File.basename(path)}: #{e.message}")
    end
    combined.to_pdf
  rescue StandardError => e
    Rails.logger.error("[DfrPdfService] fallback merge failed: #{e.message}")
    File.binread(parts.first)
  end

  def document_results
    @document_results ||= build_document_results
  end

  def build_document_results
    return [] if @document_attachment_ids.blank?

    docs = @incident.attachments
      .includes(file_attachment: :blob)
      .where.not(category: %w[photo dfr])
      .where(id: @document_attachment_ids)
      .order(:created_at)

    appended_bytes = 0
    docs.filter_map do |att|
      next unless att.file.attached?

      blob = att.file.blob
      result = { attachment: att, filename: blob.filename.to_s, disposition: :listed, parsed: nil }

      if blob.content_type.to_s.start_with?("image/")
        # Same per-file cap as PDFs: MiniMagick decodes the full image, so an
        # oversized "image" document must not reach the embed path.
        if blob.byte_size <= MAX_DOCUMENT_BYTES
          result[:disposition] = :embedded_image
        else
          result[:note] = "too large to attach"
        end
      elsif blob.content_type == "application/pdf"
        if blob.byte_size <= MAX_DOCUMENT_BYTES &&
           appended_bytes + blob.byte_size <= MAX_TOTAL_DOCUMENT_BYTES
          begin
            result[:parsed] = strip_active_content!(CombinePDF.parse(blob.download))
            result[:disposition] = :appended
            appended_bytes += blob.byte_size
          rescue StandardError => e
            # Corrupt/encrypted PDF: fall back to a filename listing, never
            # fail the whole DFR over one bad document.
            Rails.logger.warn("[DfrPdfService] could not parse document #{att.id} (#{result[:filename]}): #{e.message}")
            result[:note] = "could not be attached"
          end
        else
          result[:note] = "too large to attach"
        end
      end

      result
    end
  end

  def strip_active_content!(parsed)
    seen = {}
    parsed.objects.each { |obj| scrub_active_content!(obj, seen) }
    parsed
  end

  def scrub_active_content!(node, seen)
    case node
    when Hash
      return if seen[node.object_id]
      seen[node.object_id] = true
      ACTIVE_CONTENT_KEYS.each { |key| node.delete(key) }
      if (action = node[:A]).is_a?(Hash)
        target = action[:referenced_object].is_a?(Hash) ? action[:referenced_object] : action
        node.delete(:A) if ACTIVE_ACTION_TYPES.include?(target[:S])
      end
      node.each_value { |value| scrub_active_content!(value, seen) }
    when Array
      node.each { |value| scrub_active_content!(value, seen) }
    end
  end

  # --- Data queries ---
  #
  # Each collection is fetched ONCE for the whole report span and grouped by
  # day, so a 7-day weekly report issues the same number of queries as a
  # single-day DFR instead of 7x.

  def activities_for_date(day)
    activities_by_day[day] || []
  end

  def activities_by_day
    @activities_by_day ||= @incident.activity_entries
      .includes(:performed_by_user, equipment_actions: :equipment_type)
      .where(occurred_at: full_range)
      .order(occurred_at: :asc)
      .group_by { |a| a.occurred_at.in_time_zone.to_date }
  end

  def equipment_entries_for_date(day)
    range = day_range(day)
    equipment_entries_in_range.select do |e|
      e.placed_at <= range.last && (e.removed_at.nil? || e.removed_at >= range.first)
    end
  end

  def equipment_entries_in_range
    @equipment_entries_in_range ||= @incident.equipment_entries
      .includes(:equipment_type)
      .where("placed_at <= ? AND (removed_at IS NULL OR removed_at >= ?)",
        full_range.last, full_range.first)
      .order(:placed_at)
      .to_a
  end

  def equipment_hours_for_date(entry, day)
    range = day_range(day)
    day_start = [ entry.placed_at, range.first ].max
    day_end = [ entry.removed_at || Time.current, range.last ].min
    ((day_end - day_start) / 1.hour).round(1)
  end

  def labor_entries_for_date(day)
    labor_by_day[day] || []
  end

  def labor_by_day
    @labor_by_day ||= @incident.labor_entries
      .includes(:user, :created_by_user)
      .where(log_date: @date..@end_date)
      .order(:created_at)
      .group_by(&:log_date)
  end

  def notes_for_date(day)
    notes_by_day[day] || []
  end

  def notes_by_day
    @notes_by_day ||= @incident.operational_notes
      .includes(:created_by_user)
      .where(log_date: @date..@end_date)
      .order(:created_at)
      .group_by(&:log_date)
  end

  def photos_for_date
    @photos_for_date ||= begin
      scope = @incident.attachments
        .includes(file_attachment: :blob)
        .where(category: "photo")
      # An explicit selection may span any date ("select any photos, not just
      # photos for that day"); without one, default to the report span's photos.
      # Scoping through @incident.attachments means foreign IDs can never leak in.
      scope = if @photo_attachment_ids
        scope.where(id: @photo_attachment_ids)
      else
        scope.where(log_date: @date..@end_date)
      end
      scope.order(:created_at)
    end
  end

  def assigned_by_role(role_key)
    @incident.assigned_users
      .where(user_type: User.const_get(role_key.upcase))
  rescue NameError
    User.none
  end

  def visitors_for_date(day)
    activities_for_date(day).filter_map(&:visitors).last
  end

  def weather_for(day)
    return @weather[day] if @weather.is_a?(Hash)
    day == @date ? @weather : nil
  end

  def report_date_label
    return @date.strftime("%-m/%-d/%y") unless multi_day?
    "#{@date.strftime("%-m/%-d/%y")} – #{@end_date.strftime("%-m/%-d/%y")}"
  end

  def day_range(day)
    start_of_day = Time.zone.local(day.year, day.month, day.day).beginning_of_day
    start_of_day..start_of_day.end_of_day
  end

  def full_range
    day_range(@date).first..day_range(@end_date).last
  end

  def label_cell(text)
    text
  end

  def action_label(action_type)
    { "add" => "Add", "remove" => "Remove", "move" => "Move", "other" => "" }[action_type] || action_type
  end
end
