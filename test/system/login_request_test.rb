require "application_system_test_case"

class LoginRequestSystemTest < ApplicationSystemTestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Jane", last_name: "Manager", password: "password123")
  end

  test "visitor requests access and an admin approves into a prefilled invitation" do
    # --- Public form ---
    visit "/login"
    click_link "Request access"
    assert_text "Request Access"

    fill_in "First name", with: "Dan"
    fill_in "Last name", with: "Hutson"
    fill_in "Email", with: "dan@acme.com"
    fill_in "Company", with: "Acme PM"
    click_button "Request Access"

    assert_text "Request received"
    request = LoginRequest.find_by!(email: "dan@acme.com")
    assert request.pending?

    # --- Admin review ---
    login_as @manager
    visit "/users"
    assert_text "Login Requests (1)"
    assert_text "Dan Hutson"

    find("[data-testid='login-request-approve-#{request.id}']").click

    # Approve opens the invite modal prefilled from the request
    assert_text "Invite User"
    assert_equal "dan@acme.com", find("#invite_email").value
    assert_equal "Dan", find("#invite_first").value
    assert_equal "Hutson", find("#invite_last").value
    assert request.reload.approved?

    # Complete the invitation through the normal flow (Genixo is the only
    # org in this test, so the role options are the mitigation roles)
    find("button", text: "Select a role...").click
    find("[role='option']", text: "Technician").click
    click_button "Send Invitation"

    assert_text "Invitation sent to dan@acme.com"
    invitation = Invitation.find_by(email: "dan@acme.com")
    assert invitation.present?, "approval flow should end in a real invitation"

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
