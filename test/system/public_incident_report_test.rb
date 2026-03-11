require "application_system_test_case"

class PublicIncidentReportTest < ApplicationSystemTestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation", phone: "5551234567")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo, street_address: "100 Sunset Blvd",
      city: "Houston", state: "TX", zip: "77001", unit_count: 24
    )

    @manager = User.create!(organization: @genixo, user_type: "manager", auto_assign: true,
      email_address: "mgr@genixo.com", first_name: "Jane", last_name: "Manager", password: "password123")
  end

  test "login page shows report incident link and emergency phone" do
    visit "/login"
    assert_text "Report an Incident"
    assert_text "(555) 123-4567"
  end

  test "submit public incident report successfully" do
    visit "/report-incident"

    assert_text "Report an Incident"

    # Fill in required fields
    fill_in "Work Email", with: "reporter@example.com"
    fill_in "reporter_name", with: "Jane Doe"
    fill_in "reporter_phone", with: "5551234567"
    fill_in "Property Name / Address", with: "Sunset Apartments, 100 Sunset Blvd"

    # Select emergency response
    find("label", text: "Emergency Response").click

    # Select damage type
    find("[data-testid]", text: "Select damage type...", visible: :all, wait: 2).click rescue find("button", text: "Select damage type...").click
    find("[role='option']", text: "Flood").click

    fill_in "Description", with: "Water damage in unit 205, ceiling is leaking badly"

    click_button "Submit Report"

    assert_text "Your report has been submitted"
  end

  test "public report form shows validation errors for missing fields" do
    visit "/report-incident"

    click_button "Submit Report"

    assert_text "Please fix the highlighted fields"
  end

  test "emergency checkbox shows escalation warning" do
    visit "/report-incident"

    find("button[role='checkbox']").click

    assert_text "Emergency escalation will be triggered"
    assert_text "(555) 123-4567"
  end

  test "back to login link works" do
    visit "/report-incident"

    click_link "Back to login"

    assert_current_path "/login"
  end
end
