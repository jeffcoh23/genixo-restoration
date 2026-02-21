require "application_system_test_case"

class SecurityTest < ApplicationSystemTestCase
  setup do
    # Show production-style 404 pages instead of debug error pages
    @original_local = Rails.application.config.consider_all_requests_local
    Rails.application.config.consider_all_requests_local = false

    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @other_pm = Organization.create!(name: "Sandalwood", organization_type: "property_management")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo, street_address: "100 Sunset Blvd",
      city: "Houston", state: "TX", zip: "77001", unit_count: 24
    )

    @other_property = Property.create!(
      name: "Sandalwood Towers", property_management_org: @other_pm,
      mitigation_org: @genixo, street_address: "200 Oak St",
      city: "Houston", state: "TX", zip: "77002", unit_count: 50
    )

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")

    @pm_greystar = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Grey", last_name: "Star", password: "password123")
    @pm_sandalwood = User.create!(organization: @other_pm, user_type: "property_manager",
      email_address: "pm@sandalwood.com", first_name: "Sandy", last_name: "Wood", password: "password123")

    PropertyAssignment.create!(user: @pm_greystar, property: @property)
    PropertyAssignment.create!(user: @pm_sandalwood, property: @other_property)

    @incident_on_sunset = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Flood at Sunset", emergency: true
    )

    @incident_on_sandalwood = Incident.create!(
      property: @other_property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "fire", description: "Fire at Sandalwood", emergency: true
    )
  end

  teardown do
    Rails.application.config.consider_all_requests_local = @original_local
  end

  # H1: PM user from Greystar cannot see Sandalwood incident
  test "pm user cannot view incident from another org" do
    login_as @pm_greystar
    visit incident_path(@incident_on_sandalwood)
    assert_text "The page you were looking for doesn't exist"
  end

  # H2: PM user cannot view unassigned property
  test "pm user cannot view unassigned property" do
    login_as @pm_greystar
    visit property_path(@other_property)
    assert_text "The page you were looking for doesn't exist"
  end

  # H3: PM user cannot access equipment items page (mitigation-only)
  test "pm user cannot access equipment items page" do
    login_as @pm_greystar
    visit equipment_items_path
    assert_text "The page you were looking for doesn't exist"
  end

  # H4: Technician cannot see unassigned incident
  test "technician cannot view incident they are not assigned to" do
    login_as @tech
    visit incident_path(@incident_on_sunset)
    assert_text "The page you were looking for doesn't exist"
  end
end
