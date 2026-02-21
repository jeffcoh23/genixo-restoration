require "application_system_test_case"

class IncidentsTest < ApplicationSystemTestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo, street_address: "100 Sunset Blvd",
      city: "Houston", state: "TX", zip: "77001", unit_count: 24
    )

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @office = User.create!(organization: @genixo, user_type: "office_sales",
      email_address: "office@genixo.com", first_name: "Test", last_name: "Office", password: "password123")

    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")
    @pm_mgr = User.create!(organization: @greystar, user_type: "pm_manager",
      email_address: "pmmgr@greystar.com", first_name: "Test", last_name: "PMMgr", password: "password123")

    PropertyAssignment.create!(user: @pm_user, property: @property)
  end

  # C1: Manager creates emergency incident
  test "manager creates emergency incident" do
    login_as @manager

    click_link "Create Request"

    # Fill out the form
    select "Sunset Apartments", from: "property_id"
    find("label", text: "Emergency Response").click
    select "Flood", from: "damage_type"
    fill_in "description", with: "Major water leak in unit 4B. Pipe burst overnight."

    click_button "Create Request"

    # Should land on the incident show page
    assert_text "Sunset Apartments"
    assert_text "Flood"
    assert_text "Major water leak in unit 4B"

    # Emergency incidents get auto-acknowledged
    incident = Incident.last
    assert_equal "acknowledged", incident.status

    # Team auto-assigned: manager + office from mitigation side, PM users from PM side
    assert incident.assigned_users.include?(@manager)
    assert incident.assigned_users.include?(@office)
  end

  # C3: PM user creates incident — only sees assigned properties
  test "pm user creates incident and only sees assigned properties" do
    # Add a second property that PM is NOT assigned to
    other_pm_org = Organization.create!(name: "Other PM", organization_type: "property_management")
    Property.create!(
      name: "Hidden Building", property_management_org: other_pm_org,
      mitigation_org: @genixo
    )

    login_as @pm_user

    click_link "Create Request"

    # Should see assigned property but not the other one
    assert_text "Sunset Apartments"
    assert_no_text "Hidden Building"

    # Fill and submit
    select "Sunset Apartments", from: "property_id"
    find("label", text: "Emergency Response").click
    select "Flood", from: "damage_type"
    fill_in "description", with: "Water damage in lobby area"

    click_button "Create Request"

    assert_text "Sunset Apartments"
    assert_text "Water damage in lobby area"

    # Mitigation managers should be auto-assigned
    incident = Incident.last
    assert incident.assigned_users.include?(@manager)
  end

  # C15: Manager transitions incident status
  test "manager transitions incident status" do
    incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "acknowledged", project_type: "emergency_response",
      damage_type: "flood", description: "Test incident", emergency: true
    )

    login_as @manager
    visit incident_path(incident)

    # Status button should be clickable for managers
    assert_text "Acknowledged"
    click_button "Acknowledged"

    # Dropdown appears with valid transitions
    click_button "Active"

    # Page should update to show new status
    assert_text "Active"
    assert_equal "active", incident.reload.status
  end

  # C16: Manager walks through quote path
  test "manager walks through quote path statuses" do
    incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "acknowledged", project_type: "mitigation_rfq",
      damage_type: "flood", description: "RFQ for flood mitigation"
    )

    login_as @manager
    visit incident_path(incident)

    # Acknowledged → Proposal Requested
    click_button "Acknowledged"
    click_button "Proposal Requested"
    assert_text "Proposal Requested"
    assert_equal "proposal_requested", incident.reload.status

    # Proposal Requested → Proposal Submitted
    click_button "Proposal Requested"
    click_button "Proposal Submitted"
    assert_text "Proposal Submitted"
    assert_equal "proposal_submitted", incident.reload.status

    # Proposal Submitted → Proposal Signed
    click_button "Proposal Submitted"
    click_button "Proposal Signed"
    assert_text "Proposal Signed"
    assert_equal "proposal_signed", incident.reload.status

    # Proposal Signed → Active
    click_button "Proposal Signed"
    click_button "Active"
    assert_text "Active"
    assert_equal "active", incident.reload.status
  end
end
