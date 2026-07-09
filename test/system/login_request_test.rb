require "application_system_test_case"

class LoginRequestSystemTest < ApplicationSystemTestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Jane", last_name: "Manager", password: "password123")
    # A client org Genixo services — the requester picks it, and the approving
    # admin can invite into it because a property links the two orgs.
    @pm_org = Organization.create!(name: "Acme PM", organization_type: "property_management")
    Property.create!(name: "Acme Tower", mitigation_org: @genixo, property_management_org: @pm_org)
  end

  test "visitor requests access and an admin approves into a prefilled invitation" do
    # --- Public form ---
    visit "/login"
    click_link "Request access"
    assert_text "Request Access"

    fill_in "First name", with: "Dan"
    fill_in "Last name", with: "Hutson"
    fill_in "Email", with: "dan@acme.com"
    find("button", text: "Select your company").click
    find("[role='option']", text: "Acme PM").click
    click_button "Request Access"

    assert_text "Request received"
    request = LoginRequest.find_by!(email: "dan@acme.com")
    assert request.pending?
    assert_equal @pm_org, request.organization

    # --- Admin review ---
    login_as @manager
    visit "/users"
    assert_text "Login Requests (1)"
    assert_text "Dan Hutson"

    find("[data-testid='login-request-approve-#{request.id}']").click

    # Approve opens the invite modal prefilled from the request — including the
    # org they chose and a default Property Manager role.
    assert_text "Invite User"
    assert_equal "dan@acme.com", find("#invite_email").value
    assert_equal "Dan", find("#invite_first").value
    assert_equal "Hutson", find("#invite_last").value
    assert_text "Acme PM"
    assert_text "Property Manager"
    assert request.reload.approved?

    # Role is already prefilled — the admin just sends it.
    click_button "Send Invitation"

    assert_text "Invitation sent to dan@acme.com"
    invitation = Invitation.find_by(email: "dan@acme.com")
    assert invitation.present?, "approval flow should end in a real invitation"
    assert_equal @pm_org, invitation.organization
    assert_equal "property_manager", invitation.user_type

    # The approved request row is resolved and disappears
    visit "/users"
    assert_no_text "Login Requests"
  end

  test "validation errors surface on the public form" do
    visit "/request-access"
    click_button "Request Access"
    assert_text "can't be blank"
    assert_equal 0, LoginRequest.count
  end
end
