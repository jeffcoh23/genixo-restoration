require "application_system_test_case"

class UserProfileTest < ApplicationSystemTestCase
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

  test "manager can open and cancel edit modal on another user profile" do
    login_as @manager
    visit user_path(@tech)

    click_button "Edit"
    assert_text "Edit User"
    assert_button "Cancel"

    click_button "Cancel"
    assert_no_text "Edit User"
  end

  test "technician can edit self through modal form" do
    login_as @tech
    visit user_path(@tech)

    click_button "Edit"
    fill_in "First Name", with: "Taylor"
    click_button "Save Changes"

    assert_text "User details updated."
    assert_text "Taylor Tech"
  end
end
