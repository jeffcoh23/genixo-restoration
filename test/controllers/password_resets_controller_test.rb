require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @user = User.create!(organization: @org, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    ActionMailer::Base.deliveries.clear
  end

  # --- Forgot password page ---

  test "forgot password page renders" do
    get forgot_password_path
    assert_response :success
  end

  # --- Request reset ---

  test "sends reset email for valid user" do
    post forgot_password_path, params: { email_address: "mgr@genixo.com" }
    assert_redirected_to forgot_password_path
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal [ "mgr@genixo.com" ], ActionMailer::Base.deliveries.first.to
  end

  test "does not leak email existence for unknown address" do
    post forgot_password_path, params: { email_address: "nobody@genixo.com" }
    assert_redirected_to forgot_password_path
    assert_equal 0, ActionMailer::Base.deliveries.size
    assert_includes flash[:notice], "reset link"
  end

  test "does not send reset email for inactive user" do
    @user.update!(active: false)
    post forgot_password_path, params: { email_address: "mgr@genixo.com" }
    assert_redirected_to forgot_password_path
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  # --- Reset password page ---

  test "valid token renders reset page" do
    token = @user.generate_token_for(:password_reset)
    get edit_password_reset_path(token)
    assert_response :success
  end

  test "invalid token redirects to forgot password" do
    get edit_password_reset_path("bad-token")
    assert_redirected_to forgot_password_path
    assert_includes flash[:alert], "invalid or has expired"
  end

  # --- Update password ---

  test "resets password with valid token" do
    token = @user.generate_token_for(:password_reset)
    patch password_reset_path(token), params: { password: "newpassword456", password_confirmation: "newpassword456" }
    assert_redirected_to login_path
    assert @user.reload.authenticate("newpassword456")
  end

  test "rejects mismatched password confirmation" do
    token = @user.generate_token_for(:password_reset)
    patch password_reset_path(token), params: { password: "newpassword456", password_confirmation: "wrong" }
    assert_redirected_to edit_password_reset_path(token)
  end

  test "rejects blank password" do
    token = @user.generate_token_for(:password_reset)
    patch password_reset_path(token), params: { password: "", password_confirmation: "" }
    assert_redirected_to edit_password_reset_path(token)
  end

  test "expired token is rejected on update" do
    patch password_reset_path("bad-token"), params: { password: "newpassword456", password_confirmation: "newpassword456" }
    assert_redirected_to forgot_password_path
  end

  test "token is invalidated after password change" do
    token = @user.generate_token_for(:password_reset)

    # Use the token to reset password
    patch password_reset_path(token), params: { password: "newpassword456", password_confirmation: "newpassword456" }
    assert_redirected_to login_path

    # Try to use the same token again — should fail because password_salt changed
    get edit_password_reset_path(token)
    assert_redirected_to forgot_password_path
  end
end
