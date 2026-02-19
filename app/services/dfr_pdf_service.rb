require "prawn"
require "prawn/table"

class DfrPdfService
  include ActionView::Helpers::NumberHelper

  def initialize(incident:, date:, timezone: "America/Chicago")
    @incident = incident
    @date = date.is_a?(String) ? Date.parse(date) : date
    @timezone = timezone
  end

  def generate
    Time.use_zone(@timezone) do
      build_pdf
    end
  end

  private

  def build_pdf
    pdf = Prawn::Document.new(page_size: "LETTER", margin: [ 50, 50, 50, 50 ])

    render_header(pdf)
    render_info_grid(pdf)
    render_employees_section(pdf)
    render_work_details(pdf)
    render_notes(pdf)
    render_summary_fields(pdf)
    render_labor_section(pdf)
    render_photos(pdf)

    pdf.render
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
      [ label_cell("Site Name:"), property.name, label_cell("Job Name:"), property.name ],
      [ label_cell("Job Number:"), @incident.job_id || "—", label_cell("Date:"), @date.strftime("%-m/%-d/%y") ],
      [ label_cell("Project Manager:"), manager&.full_name || "—", label_cell("Superintendent:"), superintendent&.full_name || "—" ],
      [ label_cell("Visitors:"), visitors_for_date || "—", label_cell("Status:"), @incident.display_status_label ]
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

  def render_employees_section(pdf)
    labor = labor_entries_for_date
    return if labor.empty?

    names = labor.map { |e| e.user&.full_name || e.created_by_user.full_name }.uniq
    pdf.font_size(10) do
      pdf.text "Employees on Site: #{names.size} — #{names.join(', ')}", style: :bold
    end
    pdf.move_down 10
  end

  def render_work_details(pdf)
    activities = activities_for_date
    return if activities.empty?

    activities.each do |activity|
      pdf.font_size(10) do
        pdf.text "• #{activity.title}", style: :bold, inline_format: true
        if activity.details.present?
          pdf.indent(15) { pdf.text activity.details }
        end

        activity.equipment_actions.includes(:equipment_type).each do |action|
          parts = [ action_label(action.action_type), action.quantity, action.type_name, action.note ].compact
          pdf.indent(15) { pdf.text "— #{parts.join(' ')}", color: "555555" }
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
        pdf.text "• #{note.note_text}"
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

    fields << [ "Number of Units Affected:", "#{units}#{units_desc.present? ? " — #{units_desc}" : ""}" ] if units.present?
    fields << [ "Affected Room Numbers:", rooms ] if rooms.present?
    fields << [ "Visitors:", visitors ] if visitors.present?
    fields << [ "Usable Rooms Returned:", usable_returned.presence || "None" ] if usable_returned.present? || units.present?
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
        pdf.text "• #{count} #{role}  #{hours} hrs"
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

    photos.each_slice(4) do |batch|
      images_in_row = batch.map do |attachment|
        blob = attachment.file.blob
        next nil unless blob.content_type.start_with?("image/")
        next nil unless blob.service.exist?(blob.key)

        blob.open do |tempfile|
          { file: tempfile.path, width: (pdf.bounds.width / 2) - 10 }
        end
      rescue StandardError
        nil
      end.compact

      images_in_row.each_with_index do |img, i|
        x = i.even? ? 0 : (pdf.bounds.width / 2) + 10
        begin
          pdf.image img[:file], at: [ x, pdf.cursor ], width: img[:width]
        rescue StandardError
          # Skip unreadable images
        end
      end

      pdf.move_down((pdf.bounds.width / 2) + 20) if images_in_row.any?
    end
  end

  # --- Data queries ---

  def activities_for_date
    @activities_for_date ||= @incident.activity_entries
      .includes(:performed_by_user, equipment_actions: :equipment_type)
      .where(occurred_at: date_range)
      .order(occurred_at: :asc)
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
    @photos_for_date ||= @incident.attachments
      .includes(file_attachment: :blob)
      .where(category: "photo", log_date: @date)
      .order(:created_at)
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
