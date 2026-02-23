require "application_system_test_case"

class UserPermissionsTest < ApplicationSystemTestCase
  setup do
    @mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm = Organization.create!(name: "Greystar", organization_type: "property_management")
    Property.create!(name: "River Oaks", mitigation_org: @mitigation, property_management_org: @pm)

    @manager = User.create!(
      organization: @mitigation,
      user_type: User::MANAGER,
      email_address: "manager@example.com",
      first_name: "Mia",
      last_name: "Manager",
      password: "password123"
    )
    @tech = User.create!(
      organization: @mitigation,
      user_type: User::TECHNICIAN,
      email_address: "tech@example.com",
      first_name: "Tina",
      last_name: "Tech",
      password: "password123"
    )
  end

  test "user edit is modal and permission scoped by role and self access" do
    login_as @manager
    visit user_path(@tech)

    click_button "Edit"
    within("[role='dialog']") do
      assert_text "Edit User"
      fill_in "First Name", with: "Taylor"
      click_button "Save Changes"
    end

    assert_text "User details updated."
    assert_text "Taylor Tech"
    assert_equal "Taylor", @tech.reload.first_name

    click_button "Log out"

    login_as @tech
    visit user_path(@tech)
    assert_button "Edit"

    visit user_path(@manager)
    assert_not_found_rendered
  end

  test "user role field locking rules are enforced in edit modal" do
    login_as @manager
    visit user_path(@tech)

    click_button "Edit"
    within("[role='dialog']") do
      find("[role='combobox']").click
    end
    find("[role='option']", text: "Office/Sales").click
    within("[role='dialog']") do
      click_button "Save Changes"
    end

    assert_text "User details updated."
    assert_text "Office/Sales at Genixo"
    assert_equal User::OFFICE_SALES, @tech.reload.user_type

    click_button "Log out"

    login_as @tech
    visit user_path(@tech)
    click_button "Edit"

    within("[role='dialog']") do
      assert_selector "input[disabled][value='Office/Sales']"
      assert_no_selector "[role='combobox']"
    end
  end

  private

  def assert_not_found_rendered
    production_404 = page.has_text?("The page you were looking for") && page.has_text?("exist")
    debug_404 = page.has_text?("ActiveRecord::RecordNotFound")

    assert(production_404 || debug_404, "Expected not-found response, got:\n#{page.text}")
  end
end
