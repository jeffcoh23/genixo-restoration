class DfrPdfService
  include ActionView::Helpers::NumberHelper
  include PdfFontSupport

  # Appended-document limits: CombinePDF parses a whole file into Ruby objects
  # (roughly 3-5x the file size in memory), so a per-file AND an aggregate cap
  # keep DFR generation inside the worker's memory quota. Oversized documents
  # are still listed by filename in the Documents section.
  MAX_DOCUMENT_BYTES = 15.megabytes
  MAX_TOTAL_DOCUMENT_BYTES = 40.megabytes

  # PDF actions that execute script or launch programs have no place in a
  # report page shipped under the mitigation org's name. CombinePDF drops the
  # source document's catalog on merge, but page-level annotations and
  # additional-actions survive — strip them from every parsed object.
  ACTIVE_CONTENT_KEYS = %i[JS JavaScript AA OpenAction Launch].freeze
  ACTIVE_ACTION_TYPES = %i[JavaScript Launch].freeze

  def initialize(incident:, date:, timezone: "America/Chicago", include_photos: true,
                 photo_attachment_ids: nil, document_attachment_ids: nil, weather: nil)
    @incident = incident
    @date = date.is_a?(String) ? Date.parse(date) : date
    @timezone = timezone
    @include_photos = include_photos
    @photo_attachment_ids = photo_attachment_ids
    @document_attachment_ids = document_attachment_ids
    # A WeatherSnapshot (or nil). Fetched by the caller so the PDF service stays
    # pure and testable without HTTP; nil simply omits the weather line.
    @weather = weather
  end

  def generate
    require "prawn"
    require "prawn/table"
    require "mini_magick"
    require "combine_pdf"

    with_glyph_fallback do
      Time.use_zone(@timezone) do
        build_pdf
      end
    end
  end

  private

  def build_pdf
    pdf = Prawn::Document.new(page_size: "LETTER", margin: [ 50, 50, 50, 50 ])
    apply_noto_sans(pdf)

    render_header(pdf)
    render_info_grid(pdf)
    render_weather(pdf)
    render_employees_section(pdf)
    render_work_details(pdf)
    render_notes(pdf)
    render_summary_fields(pdf)
    render_labor_section(pdf)
    render_equipment_section(pdf)
    render_photos(pdf) if @include_photos
    # render_documents_section triggers document parsing (document_results), so
    # each file is classified appended/embedded/listed before append_documents runs.
    render_documents_section(pdf)

    append_documents(pdf.render)
  end

  def render_header(pdf)
    pdf.font_size(18) { pdf.text "Daily Field Report", style: :bold, align: :center }
    pdf.move_down 15
  end

  def render_info_grid(pdf)
    property = @incident.property
    manager = assigned_by_role("manager").first
    superintendent = assigned_by_role("technician").first

    data = [
      [ label_cell("Site Name:"), t(property.name), label_cell("Job Name:"), t(property.name) ],
      [ label_cell("Job Number:"), t(@incident.job_id) || "-", label_cell("Date:"), @date.strftime("%-m/%-d/%y") ],
      [ label_cell("Project Manager:"), t(manager&.full_name) || "-", label_cell("Superintendent:"), t(superintendent&.full_name) || "-" ],
      [ label_cell("Visitors:"), t(visitors_for_date) || "-", label_cell("Status:"), t(@incident.display_status_label) ]
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

  def render_weather(pdf)
    line = @weather&.summary_line
    return if line.blank?

    pdf.font_size(10) do
      pdf.text t("<b>Weather:</b> #{line}"), inline_format: true
    end
    # Visual Crossing's free tier requires attribution.
    pdf.font_size(7) { pdf.text "Weather data by Visual Crossing", color: "999999" }
    pdf.move_down 8
  rescue StandardError => e
    Rails.logger.warn("[DfrPdfService] weather line skipped for incident #{@incident.id}: #{e.message}")
  end

  def render_employees_section(pdf)
    labor = labor_entries_for_date
    return if labor.empty?

    names = labor.map { |e| e.user&.full_name || e.created_by_user.full_name }.uniq
    pdf.font_size(10) do
      pdf.text t("Employees on Site: #{names.size} — #{names.join(', ')}"), style: :bold
    end
    pdf.move_down 10
  end

  def render_work_details(pdf)
    activities = activities_for_date
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

  def render_notes(pdf)
    notes = notes_for_date
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

  def render_summary_fields(pdf)
    # Use the most recent activity's metadata for this date, or fall back to incident-level
    activity = activities_for_date.first

    fields = []
    units = activity&.units_affected || @incident.units_affected
    units_desc = activity&.units_affected_description
    rooms = @incident.affected_room_numbers
    visitors = activity&.visitors
    usable_returned = activity&.usable_rooms_returned
    edr = activity&.estimated_date_of_return || @incident.estimated_date_of_return

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

  def render_labor_section(pdf)
    labor = labor_entries_for_date
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

  def render_equipment_section(pdf)
    entries = equipment_entries_for_date
    return if entries.empty?

    pdf.stroke_horizontal_rule
    pdf.move_down 8

    pdf.font_size(10) { pdf.text "Equipment:", style: :bold }
    pdf.move_down 3

    by_type = entries.group_by { |e| e.type_name.to_s.strip }.sort_by { |name, _| name.downcase }
    by_type.each do |type_name, type_entries|
      total_hours = type_entries.sum { |e| equipment_hours_for_date(e) }
      pdf.font_size(10) do
        pdf.text t("• #{type_entries.size} #{type_name}  #{total_hours} hrs")
      end
    end

    pdf.move_down 10
  end

  def render_photos(pdf)
    photos = photos_for_date
    return if photos.empty?

    pdf.start_new_page
    pdf.font_size(12) { pdf.text "Photos", style: :bold }
    pdf.move_down 10

    # Cap each photo at half-page height so two stack per page. Without a
    # height cap, full-width portrait photos dominate a page each and Prawn
    # paginates fresh between them, leaving large blank gaps.
    max_height = (pdf.bounds.height - 30) / 2 - 15

    photos.each do |attachment|
      embed_image_attachment(pdf, attachment, max_height)
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

  def render_documents_section(pdf)
    return if document_results.empty?

    pdf.start_new_page
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

  # Selected PDF documents get their pages appended after the Prawn body.
  # Parsing happened up front (document_results), so a corrupt or oversized
  # file was already downgraded to a filename listing — appending can only
  # see successfully parsed documents.
  def append_documents(data)
    parsed_docs = document_results.filter_map { |r| r[:parsed] }
    return data if parsed_docs.empty?

    combined = CombinePDF.parse(data)
    parsed_docs.each { |doc| combined << doc }
    combined.to_pdf
  rescue StandardError => e
    # A merge failure must never kill the DFR: ship the Prawn body without the
    # appended pages. (The Documents section will overstate "(attached)" for
    # this rare case — preferable to no report at all.)
    Rails.logger.warn("[DfrPdfService] could not append documents to DFR: #{e.message}")
    data
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

  def activities_for_date
    @activities_for_date ||= @incident.activity_entries
      .includes(:performed_by_user, equipment_actions: :equipment_type)
      .where(occurred_at: date_range)
      .order(occurred_at: :asc)
  end

  def equipment_entries_for_date
    @equipment_entries_for_date ||= @incident.equipment_entries
      .includes(:equipment_type)
      .where("placed_at <= ? AND (removed_at IS NULL OR removed_at >= ?)",
        date_range.last, date_range.first)
      .order(:placed_at)
  end

  def equipment_hours_for_date(entry)
    day_start = [ entry.placed_at, date_range.first ].max
    day_end = [ entry.removed_at || Time.current, date_range.last ].min
    ((day_end - day_start) / 1.hour).round(1)
  end

  def labor_entries_for_date
    @labor_entries_for_date ||= @incident.labor_entries
      .includes(:user, :created_by_user)
      .where(log_date: @date)
      .order(:created_at)
  end

  def notes_for_date
    @notes_for_date ||= @incident.operational_notes
      .includes(:created_by_user)
      .where(log_date: @date)
      .order(:created_at)
  end

  def photos_for_date
    @photos_for_date ||= begin
      scope = @incident.attachments
        .includes(file_attachment: :blob)
        .where(category: "photo")
      # An explicit selection may span any date ("select any photos, not just
      # photos for that day"); without one, default to the report date's photos.
      # Scoping through @incident.attachments means foreign IDs can never leak in.
      scope = if @photo_attachment_ids
        scope.where(id: @photo_attachment_ids)
      else
        scope.where(log_date: @date)
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

  def visitors_for_date
    activities_for_date.filter_map(&:visitors).last
  end

  def date_range
    start_of_day = Time.zone.local(@date.year, @date.month, @date.day).beginning_of_day
    start_of_day..start_of_day.end_of_day
  end

  def label_cell(text)
    text
  end

  def action_label(action_type)
    { "add" => "Add", "remove" => "Remove", "move" => "Move", "other" => "" }[action_type] || action_type
  end
end
