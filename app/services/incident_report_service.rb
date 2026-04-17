class IncidentReportService
  include ActionView::Helpers::NumberHelper

  VALID_SECTIONS = %w[labor equipment moisture psychrometric].freeze

  def initialize(incident:, sections: VALID_SECTIONS, timezone: "America/Chicago")
    @incident = incident
    @sections = sections
    @timezone = timezone
  end

  def generate
    require "prawn"
    require "prawn/table"

    Time.use_zone(@timezone) do
      build_pdf
    end
  end

  private

  def build_pdf
    pdf = Prawn::Document.new(page_size: "LETTER", margin: [ 50, 50, 50, 50 ])

    render_header(pdf)
    render_property_info(pdf)
    render_labor_section(pdf) if @sections.include?("labor")
    render_equipment_section(pdf) if @sections.include?("equipment")
    render_moisture_section(pdf) if @sections.include?("moisture")
    render_psychrometric_section(pdf) if @sections.include?("psychrometric")

    pdf.render
  end

  def render_header(pdf)
    pdf.font_size(18) { pdf.text "Incident Report", style: :bold, align: :center }
    pdf.font_size(10) { pdf.text "Generated #{Time.current.strftime("%-m/%-d/%y at %-I:%M %p")}", align: :center, color: "888888" }
    pdf.move_down 15
  end

  def render_property_info(pdf)
    property = @incident.property
    address = [ property.street_address, [ property.city, property.state ].filter_map(&:presence).join(", ") ].filter_map(&:presence).join(", ")

    data = [
      [ "Property:", property.name, "Job #:", @incident.job_id || "—" ],
      [ "Address:", address.presence || "—", "Damage:", Incident::DAMAGE_LABELS[@incident.damage_type] || @incident.damage_type ],
      [ "Status:", @incident.display_status_label, "Project Type:", Incident::PROJECT_TYPE_LABELS[@incident.project_type] || @incident.project_type ]
    ]

    pdf.table(data, width: pdf.bounds.width) do |t|
      t.cells.borders = []
      t.cells.padding = [ 3, 5, 3, 5 ]
      t.cells.size = 10
      t.columns(0).width = 80
      t.columns(2).width = 90
      t.columns(0).font_style = :bold
      t.columns(2).font_style = :bold
    end

    pdf.move_down 5
    pdf.stroke_horizontal_rule
    pdf.move_down 12
  end

  def render_labor_section(pdf)
    entries = @incident.labor_entries.includes(:user, :created_by_user).order(:log_date, :created_at)
    return if entries.empty?

    section_heading(pdf, "Labor Summary")

    by_date = entries.group_by(&:log_date)
    by_date.sort.each do |date, day_entries|
      pdf.font_size(10) { pdf.text date.strftime("%-m/%-d/%y"), style: :bold }
      pdf.move_down 3

      by_role = day_entries.group_by(&:role_label)
      by_role.each do |role, role_entries|
        names = role_entries.map { |e| e.user&.full_name || e.created_by_user.full_name }.uniq
        total_hours = role_entries.sum(&:hours)
        pdf.font_size(9) do
          pdf.text "  • #{role}: #{names.join(', ')}  (#{total_hours} hrs)"
        end
      end
      pdf.move_down 6
    end

    pdf.move_down 4
  end

  def render_equipment_section(pdf)
    entries = @incident.equipment_entries.includes(:equipment_type).order(:placed_at)
    return if entries.empty?

    section_heading(pdf, "Equipment Summary")

    # Group by type, show count and total hours
    by_type = entries.group_by { |e| e.type_name.to_s.strip }.sort_by { |name, _| name.downcase }
    by_type.each do |type_name, type_entries|
      total_hours = type_entries.sum do |e|
        day_end = e.removed_at || Time.current
        ((day_end - e.placed_at) / 1.hour).round(1)
      end
      pdf.font_size(10) { pdf.text "• #{type_entries.size} #{type_name}  —  #{total_hours} hrs total" }
    end

    pdf.move_down 8

    # Detailed list
    pdf.font_size(9) { pdf.text "Detail:", style: :bold, color: "555555" }
    pdf.move_down 3
    entries.each do |entry|
      hours = (((entry.removed_at || Time.current) - entry.placed_at) / 1.hour).round(1)
      placed = entry.placed_at.strftime("%-m/%-d")
      removed = entry.removed_at ? entry.removed_at.strftime("%-m/%-d") : "active"
      identifier = [ entry.tag_number.present? ? "##{entry.tag_number}" : nil, entry.equipment_identifier ].compact.first || "—"
      pdf.font_size(9) do
        pdf.text "  #{entry.type_name}  #{identifier}  #{placed}–#{removed}  #{hours} hrs#{entry.location_notes.present? ? "  (#{entry.location_notes})" : ""}", color: "333333"
      end
    end

    pdf.move_down 10
  end

  def render_moisture_section(pdf)
    points = @incident.moisture_measurement_points.includes(:moisture_readings).order(:created_at)
    return if points.empty?

    section_heading(pdf, "Moisture Readings")

    points.each do |point|
      label = [ point.unit, point.room, point.item ].filter_map(&:presence).join(" / ")
      goal_str = "goal: #{point.goal}#{point.measurement_unit}  material: #{point.material}"
      pdf.font_size(10) { pdf.text label, style: :bold }
      pdf.font_size(8) { pdf.text "  #{goal_str}", color: "888888" }

      readings_by_date = point.moisture_readings.index_by(&:log_date)
      readings_by_date.keys.sort.each do |date|
        r = readings_by_date[date]
        pdf.font_size(9) { pdf.text "  #{date.strftime('%-m/%-d')}: #{r.value}#{point.measurement_unit}" }
      end
      pdf.move_down 5
    end

    pdf.move_down 5
  end

  def render_psychrometric_section(pdf)
    points = @incident.psychrometric_points.includes(:psychrometric_readings).order(:created_at)
    return if points.empty?

    section_heading(pdf, "Psychrometric Readings")

    points.each do |point|
      label = [ point.unit, point.room, point.dehumidifier_label ].filter_map(&:presence).join(" / ")
      pdf.font_size(10) { pdf.text label, style: :bold }

      point.psychrometric_readings.order(:log_date).each do |r|
        pdf.font_size(9) do
          values = [
            r.temperature ? "Temp: #{r.temperature}°F" : nil,
            r.relative_humidity ? "RH: #{r.relative_humidity}%" : nil,
            r.gpp ? "GPP: #{r.gpp}" : nil
          ].compact
          pdf.text "  #{r.log_date.strftime('%-m/%-d')}: #{values.join('  ')}"
        end
      end
      pdf.move_down 5
    end

    pdf.move_down 5
  end

  def section_heading(pdf, title)
    pdf.stroke_horizontal_rule
    pdf.move_down 8
    pdf.font_size(12) { pdf.text title, style: :bold }
    pdf.move_down 6
  end
end
