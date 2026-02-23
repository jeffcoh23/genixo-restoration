require "application_system_test_case"
require_relative "planned_system_test_support"

class DashboardTest < ApplicationSystemTestCase
  include PlannedSystemTestSupport

  setup do
    @mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm = Organization.create!(name: "Greystar", organization_type: "property_management")
    @other_pm = Organization.create!(name: "Sandalwood", organization_type: "property_management")

    @property_a = Property.create!(name: "River Oaks", mitigation_org: @mitigation, property_management_org: @pm)
    @property_b = Property.create!(name: "Sandalwood Towers", mitigation_org: @mitigation, property_management_org: @other_pm)

    @manager = User.create!(organization: @mitigation, user_type: User::MANAGER,
      email_address: "manager@example.com", first_name: "Mia", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @mitigation, user_type: User::TECHNICIAN,
      email_address: "tech@example.com", first_name: "Tina", last_name: "Tech", password: "password123")
    @pm_user = User.create!(organization: @pm, user_type: User::PROPERTY_MANAGER,
      email_address: "pm@example.com", first_name: "Pam", last_name: "PM", password: "password123")

    PropertyAssignment.create!(user: @pm_user, property: @property_a)

    @emergency = Incident.create!(property: @property_a, created_by_user: @manager, status: "acknowledged",
      project_type: "emergency_response", damage_type: "flood", emergency: true,
      description: "Burst pipe in unit 305")
    @active = Incident.create!(property: @property_a, created_by_user: @manager, status: "active",
      project_type: "emergency_response", damage_type: "mold", emergency: false,
      description: "Mold remediation underway")
    @needs_attention = Incident.create!(property: @property_a, created_by_user: @manager, status: "proposal_requested",
      project_type: "mitigation_rfq", damage_type: "flood", emergency: false,
      description: "Proposal requested for flood mitigation")
    @on_hold = Incident.create!(property: @property_a, created_by_user: @manager, status: "on_hold",
      project_type: "buildback_rfq", damage_type: "fire", emergency: false,
      description: "Waiting for approval")

    @other_property_incident = Incident.create!(property: @property_b, created_by_user: @manager, status: "active",
      project_type: "emergency_response", damage_type: "flood", emergency: false,
      description: "Visible to mitigation manager only")

    IncidentAssignment.create!(incident: @active, user: @tech, assigned_by_user: @manager)
    IncidentAssignment.create!(incident: @emergency, user: @pm_user, assigned_by_user: @manager)
  end

  test "manager dashboard shows grouped incidents and create request" do
    login_as @manager
    visit dashboard_path

    assert_text "Dashboard"
    assert_link "Create Request"
    assert_text "EMERGENCY (1)"
    assert_text "ACTIVE (2)"
    assert_text "NEEDS ATTENTION (1)"
    assert_text "ON HOLD (1)"

    assert_text "River Oaks"
    assert_text "Burst pipe in unit 305"
    assert_text "Sandalwood Towers"
  end

  test "technician dashboard shows assigned incidents only" do
    login_as @tech
    visit dashboard_path

    assert_text "Dashboard"
    assert_no_link "Create Request"
    assert_text "Mold remediation underway"
    assert_no_text "Burst pipe in unit 305"
    assert_no_text "Visible to mitigation manager only"

    within("aside") do
      assert_no_text "Properties"
      assert_no_text "Users"
    end
  end

  test "pm user dashboard scopes incidents to assigned properties" do
    login_as @pm_user
    visit dashboard_path

    assert_text "Dashboard"
    assert_link "Create Request"
    assert_text "River Oaks"
    assert_no_text "Sandalwood Towers"
    assert_no_text "Visible to mitigation manager only"
  end

  test "dashboard empty state renders correct call to action" do
    empty_org = Organization.create!(name: "Fresh Mitigation", organization_type: "mitigation")
    empty_manager = User.create!(organization: empty_org, user_type: User::MANAGER,
      email_address: "empty-manager@example.com", first_name: "Eve", last_name: "Manager", password: "password123")
    empty_tech = User.create!(organization: empty_org, user_type: User::TECHNICIAN,
      email_address: "empty-tech@example.com", first_name: "Eli", last_name: "Tech", password: "password123")

    login_as empty_manager
    visit dashboard_path
    assert_text "No incidents to show."
    assert_link "Create your first incident"

    Capybara.reset_sessions!
    login_as empty_tech
    visit dashboard_path
    assert_text "No incidents to show."
    assert_no_link "Create your first incident"
    assert_no_link "Create Request"
  end

  test "dashboard unread badges reflect message and activity events" do
    Message.create!(incident: @active, user: @tech, body: "Unread dashboard message")
    ActivityEvent.create!(incident: @active, performed_by_user: @tech, event_type: "activity_logged", metadata: {})

    login_as @manager
    visit dashboard_path

    card = find("[data-testid='dashboard-incident-card-#{@active.id}']")
    within(card) do
      assert_text "Msgs 1"
      assert_text "Activity 1"
    end
  end

  test "dashboard group headers collapse and expand incident lists" do
    login_as @manager
    visit dashboard_path

    assert_text "Burst pipe in unit 305"

    find("[data-testid='dashboard-group-toggle-emergency']").click
    assert_no_text "Burst pipe in unit 305"

    find("[data-testid='dashboard-group-toggle-emergency']").click
    assert_text "Burst pipe in unit 305"
  end

  DASHBOARD_CASES = {
    # Filled
  }.freeze

  DASHBOARD_CASES.each do |id, (description, note)|
    test description do
      pending_e2e id, note
    end
  end
end
