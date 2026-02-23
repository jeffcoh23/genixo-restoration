require "application_system_test_case"
require_relative "planned_system_test_support"

class AdminOperationsTest < ApplicationSystemTestCase
  include PlannedSystemTestSupport

  setup do
    @mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm = Organization.create!(name: "Greystar", organization_type: "property_management")
    @manager = User.create!(organization: @mitigation, user_type: User::MANAGER,
      email_address: "manager@example.com", first_name: "Mia", last_name: "Manager", password: "password123")
  end

  test "create property management organization" do
    login_as @manager
    visit organizations_path

    click_link "New Company"
    fill_in "Name", with: "Sandalwood Management"
    fill_in "Phone", with: "713-555-2222"
    fill_in "Email", with: "info@sandalwood.com"
    fill_in "Street Address", with: "100 Main St"
    fill_in "City", with: "Houston"
    fill_in "State", with: "TX"
    fill_in "Zip", with: "77002"
    click_button "Create Company"

    assert_text "Organization created."
    assert_text "Sandalwood Management"

    org = Organization.find_by!(name: "Sandalwood Management")
    assert_equal "property_management", org.organization_type
  end

  test "create property" do
    login_as @manager
    visit properties_path

    click_link "New Property"
    fill_in "Name", with: "Park at River Oaks"
    fill_in "Street Address", with: "200 Oak Dr"
    fill_in "City", with: "Houston"
    fill_in "State", with: "TX"
    fill_in "Zip", with: "77003"
    fill_in "Unit Count", with: "120"

    find("[role='combobox']").click
    find("[role='option']", text: "Greystar").click

    click_button "Create Property"

    assert_text "Property created."
    assert_text "Park at River Oaks"

    property = Property.find_by!(name: "Park at River Oaks")
    assert_equal @mitigation.id, property.mitigation_org_id
    assert_equal @pm.id, property.property_management_org_id
  end

  test "invite user in own org" do
    # Include a serviced PM org to ensure the organization picker is present and role scoping works.
    Property.create!(name: "River Oaks", mitigation_org: @mitigation, property_management_org: @pm)

    login_as @manager
    visit users_path

    click_button "Invite User"
    within("[role='dialog']") do
      fill_in "Email", with: "newtech@example.com"

      all("[role='combobox']")[0].click
    end
    find("[role='option']", text: "Genixo").click

    within("[role='dialog']") do
      all("[role='combobox']")[1].click
    end
    find("[role='option']", text: "Technician").click

    within("[role='dialog']") do
      fill_in "First Name", with: "Nina"
      fill_in "Last Name", with: "New"
      click_button "Send Invitation"
    end

    assert_text "Invitation sent to newtech@example.com."
    assert_text "Pending Invitations (1)"
    assert_text "newtech@example.com"

    invitation = Invitation.find_by!(email: "newtech@example.com")
    assert_equal @mitigation.id, invitation.organization_id
    assert_equal User::TECHNICIAN, invitation.user_type
  end

  test "deactivate user" do
    user = User.create!(organization: @mitigation, user_type: User::TECHNICIAN,
      email_address: "deactivate@example.com", first_name: "Dana", last_name: "Deactivate", password: "password123")

    login_as @manager
    visit user_path(user)

    click_button "Deactivate"
    within("[role='dialog']") do
      assert_text "Deactivate User"
      click_button "Deactivate"
    end

    assert_text "has been deactivated"
    assert_text "Deactivated"
    assert_button "Reactivate"
    assert_equal false, user.reload.active
  end

  ADMIN_CASES = {
    "F2" => "edit property management organization",
    "F4" => "mitigation admin edits property and can change pm org",
    "F5" => "pm user editing property cannot change org",
    "F7" => "invite user to serviced property management org",
    "F8" => "resend invitation",
    "F10" => "manager cannot deactivate self",
    "F11" => "reactivate user",
    "F12" => "add equipment item",
    "F13" => "edit equipment item inline",
    "F14" => "deactivate equipment item",
    "F15" => "add equipment type",
    "F16" => "deactivate equipment type",
    "F17" => "reactivate equipment type",
    "F18" => "view equipment placement history",
    "F19" => "configure on-call primary and timeout",
    "F20" => "add escalation contact",
    "F21" => "reorder escalation chain",
    "F22" => "remove escalation contact"
  }.freeze

  ADMIN_CASES.each do |id, description|
    test description do
      pending_e2e id, "Admin E2E backlog; selectors and workflows need stabilization after UI cleanup"
    end
  end
end
