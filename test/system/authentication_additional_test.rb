require "application_system_test_case"
require_relative "planned_system_test_support"

class AuthenticationAdditionalTest < ApplicationSystemTestCase
  include PlannedSystemTestSupport

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
  end

  test "forgot password shows generic success message" do
    visit forgot_password_path

    fill_in "Email", with: @manager.email_address
    click_button "Send Reset Link"
    assert_text "If that email is in our system"
    assert_current_path forgot_password_path

    fill_in "Email", with: "nobody@example.com"
    click_button "Send Reset Link"
    assert_text "If that email is in our system"
    assert_current_path forgot_password_path
  end

  test "password reset accepts valid token" do
    token = @manager.generate_token_for(:password_reset)

    visit edit_password_reset_path(token)
    assert_text "Set New Password"

    fill_in "New Password", with: "newpass123"
    fill_in "Confirm Password", with: "newpass123"
    click_button "Reset Password"

    assert_current_path login_path
    assert_text "Your password has been reset"

    fill_in "Email", with: @manager.email_address
    fill_in "Password", with: "newpass123"
    click_button "Sign In"

    assert_text "Mia Manager"
  end

  test "password reset rejects expired or invalid token" do
    visit edit_password_reset_path("invalid-token")

    assert_current_path forgot_password_path
    assert_text "invalid or has expired"
  end

  test "password reset rejects mismatched confirmation" do
    token = @manager.generate_token_for(:password_reset)

    visit edit_password_reset_path(token)
    fill_in "New Password", with: "newpass123"
    fill_in "Confirm Password", with: "different123"
    click_button "Reset Password"

    assert_current_path edit_password_reset_path(token)
    assert_text "doesn't match password"

    visit login_path
    fill_in "Email", with: @manager.email_address
    fill_in "Password", with: "password123"
    click_button "Sign In"
    assert_text "Mia Manager"
  end

  test "invitation accept happy path" do
    invitation = Invitation.create!(
      organization: @pm,
      invited_by_user: @manager,
      email: "newpm@example.com",
      user_type: User::PROPERTY_MANAGER,
      expires_at: 3.days.from_now
    )

    visit invitation_path(invitation.token)
    assert_text "You've been invited!"
    assert_text "Greystar"
    assert_text "Property Manager"

    fill_in "First Name", with: "Nina"
    fill_in "Last Name", with: "Newman"
    fill_in "Phone", with: "713-555-0100"
    fill_in "password", with: "password123"
    fill_in "password_confirmation", with: "password123"
    click_button "Create Account"

    assert_current_path dashboard_path
    assert_text "Welcome to Greystar!"
    assert_text "Dashboard"

    user = User.find_by!(email_address: "newpm@example.com")
    assert_equal "Nina", user.first_name
    assert invitation.reload.accepted?
  end

  test "invitation already accepted redirects to login" do
    invitation = Invitation.create!(
      organization: @pm,
      invited_by_user: @manager,
      email: "accepted@example.com",
      user_type: User::PROPERTY_MANAGER,
      expires_at: 3.days.from_now,
      accepted_at: Time.current
    )

    visit invitation_path(invitation.token)

    assert_current_path login_path
    assert_text "already been accepted"
  end

  test "invitation expired renders expired state" do
    invitation = Invitation.create!(
      organization: @pm,
      invited_by_user: @manager,
      email: "expired@example.com",
      user_type: User::PROPERTY_MANAGER,
      expires_at: 1.day.ago
    )

    visit invitation_path(invitation.token)

    assert_text "Invitation Expired"
    assert_text "no longer valid"
    assert_link "Go to Login"
  end
end
