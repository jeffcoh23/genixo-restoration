require "test_helper"
require "pdf/inspector"

class IncidentReportServiceTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "Sunset Apts", mitigation_org: @genixo, property_management_org: @greystar)

    @manager = User.create!(
      organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123"
    )

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Test incident"
    )
  end

  test "generates a valid PDF" do
    pdf_data = IncidentReportService.new(incident: @incident).generate
    assert pdf_data.start_with?("%PDF"), "Should return valid PDF data"
  end

  test "includes property header info" do
    pdf_data = IncidentReportService.new(incident: @incident).generate
    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")

    assert_includes text, "Sunset Apts"
    assert_includes text, "Incident Report"
  end

  test "labor section shows entries grouped by date" do
    @incident.labor_entries.create!(
      role_label: "Technician", log_date: Date.current, hours: 8,
      started_at: Time.current.beginning_of_day + 8.hours,
      ended_at: Time.current.beginning_of_day + 16.hours,
      created_by_user: @manager
    )

    pdf_data = IncidentReportService.new(incident: @incident, sections: %w[labor]).generate
    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")

    assert_includes text, "Labor Summary"
    assert_includes text, "Technician"
  end

  test "equipment section shows type and hours" do
    eq_type = EquipmentType.create!(name: "Dehumidifier", organization: @genixo)
    @incident.equipment_entries.create!(
      equipment_type: eq_type,
      placed_at: 2.days.ago,
      removed_at: 1.day.ago,
      logged_by_user: @manager
    )

    pdf_data = IncidentReportService.new(incident: @incident, sections: %w[equipment]).generate
    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")

    assert_includes text, "Equipment Summary"
    assert_includes text, "Dehumidifier"
  end

  test "skips labor section when not in sections list" do
    @incident.labor_entries.create!(
      role_label: "Technician", log_date: Date.current, hours: 8,
      started_at: Time.current.beginning_of_day + 8.hours,
      ended_at: Time.current.beginning_of_day + 16.hours,
      created_by_user: @manager
    )

    pdf_data = IncidentReportService.new(incident: @incident, sections: %w[equipment]).generate
    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")

    refute_includes text, "Labor Summary"
  end

  test "generates PDF with empty sections gracefully" do
    pdf_data = IncidentReportService.new(incident: @incident, sections: %w[labor equipment]).generate
    assert pdf_data.start_with?("%PDF"), "Should return valid PDF even with no data in sections"
  end

  test "all sections generate without error" do
    eq_type = EquipmentType.create!(name: "Air Mover", organization: @genixo)
    @incident.equipment_entries.create!(
      equipment_type: eq_type, placed_at: 1.day.ago, logged_by_user: @manager
    )
    @incident.labor_entries.create!(
      role_label: "Technician", log_date: Date.current, hours: 4,
      started_at: Time.current.beginning_of_day + 8.hours,
      ended_at: Time.current.beginning_of_day + 12.hours,
      created_by_user: @manager
    )
    point = @incident.moisture_measurement_points.create!(
      unit: "306", room: "Kitchen", item: "Drywall", material: "Wood",
      goal: "16", measurement_unit: "%"
    )
    point.moisture_readings.create!(
      log_date: Date.current, value: 18.5, recorded_by_user: @manager
    )
    psych_point = @incident.psychrometric_points.create!(unit: "306", room: "Kitchen")
    psych_point.psychrometric_readings.create!(
      log_date: Date.current, temperature: 72.0, relative_humidity: 55.0,
      recorded_by_user: @manager
    )

    pdf_data = IncidentReportService.new(
      incident: @incident,
      sections: IncidentReportService::VALID_SECTIONS
    ).generate

    assert pdf_data.start_with?("%PDF")
  end
end
