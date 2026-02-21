require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo, street_address: "100 Sunset Blvd",
      city: "Houston", state: "TX", zip: "77001", unit_count: 24
    )

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Jane", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Bob", last_name: "Tech", password: "password123")
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Carol", last_name: "PM", password: "password123")

    PropertyAssignment.create!(user: @pm_user, property: @property)
  end

  # A1: Manager login — lands on incidents, sees full sidebar
  test "manager logs in and sees incidents page with full navigation" do
    login_as @manager
    assert_text "Incidents"
    assert_text "Jane Manager"
    assert_text "Properties"
    assert_text "Users"
  end

  # A1b: Technician login — limited sidebar
  test "technician logs in and sees limited navigation" do
    # Assign tech to an incident so they can see incidents page
    incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Test", emergency: true
    )
    IncidentAssignment.create!(incident: incident, user: @tech, assigned_by_user: @manager)

    login_as @tech
    within("aside") do
      assert_text "Bob Tech"
      assert_text "Incidents"
      assert_no_text "Properties"
      assert_no_text "Users"
    end
  end

  # A1c: PM user login
  test "pm user logs in and sees incidents page" do
    login_as @pm_user
    assert_text "Carol PM"
    assert_text "Incidents"
    assert_text "Properties"
    assert_no_text "Users"
  end

  # A2: Deactivated account login
  test "deactivated user cannot log in" do
    @manager.update!(active: false)
    visit "/login"
    fill_in "Email", with: @manager.email_address
    fill_in "Password", with: "password123"
    click_button "Sign In"

    assert_text "Your account has been deactivated"
    assert_current_path "/login"
  end

  # A3: Wrong password
  test "wrong password shows error and stays on login" do
    visit "/login"
    fill_in "Email", with: @manager.email_address
    fill_in "Password", with: "wrongpassword"
    click_button "Sign In"

    assert_text "Invalid email or password"
    assert_current_path "/login"
  end

  # A4: Logout
  test "logout redirects to login and clears session" do
    login_as @manager
    assert_text "Jane Manager"

    click_button "Log out"

    assert_text "You have been logged out"
    assert_current_path "/login"
  end

  # A12: Deactivated during session — next page load redirects to login
  test "deactivated user with active session gets redirected on next request" do
    login_as @manager
    assert_text "Incidents"

    # Deactivate the user while session is active
    @manager.update!(active: false)

    # Navigate to another page
    visit "/settings"

    # Should be kicked back to login
    assert_current_path "/login"
  end

  # A13: Unauthenticated redirect — visit protected page, login, return to it
  test "unauthenticated user redirected to login then back to intended page" do
    visit "/incidents"
    assert_current_path "/login"

    fill_in "Email", with: @manager.email_address
    fill_in "Password", with: "password123"
    click_button "Sign In"

    assert_current_path "/incidents"
    assert_text "Incidents"
  end
end
