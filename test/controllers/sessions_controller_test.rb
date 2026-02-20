require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = Organization.create!(name: "Test Org", organization_type: "mitigation")
    @user = User.create!(
      organization: @org,
      email_address: "auth@test.com",
      first_name: "Auth",
      last_name: "User",
      user_type: "manager",
      password: "password123"
    )
  end

  test "GET /login renders login page" do
    get login_path
    assert_response :success
  end

  test "POST /login with valid credentials creates session and redirects" do
    post login_path, params: { email_address: "auth@test.com", password: "password123" }
    assert_redirected_to incidents_path

    assert_equal 1, @user.sessions.count
    assert cookies[:session_id].present?
  end

  test "POST /login with invalid password redirects back with alert" do
    post login_path, params: { email_address: "auth@test.com", password: "wrong" }
    assert_redirected_to login_path

    assert_equal 0, @user.sessions.count
  end

  test "POST /login with nonexistent email redirects back with alert" do
    post login_path, params: { email_address: "nobody@test.com", password: "password123" }
    assert_redirected_to login_path
  end

  test "POST /login with deactivated user redirects back with alert" do
    @user.update!(active: false)
    post login_path, params: { email_address: "auth@test.com", password: "password123" }
    assert_redirected_to login_path

    assert_equal 0, @user.sessions.count
  end

  test "DELETE /logout terminates session and redirects to login" do
    # Log in first
    post login_path, params: { email_address: "auth@test.com", password: "password123" }
    assert_equal 1, @user.sessions.count

    delete logout_path
    assert_redirected_to login_path
    assert_equal 0, @user.sessions.count
  end

  test "unauthenticated access redirects to login" do
    get dashboard_path
    assert_redirected_to login_path
  end

  test "authenticated access works" do
    post login_path, params: { email_address: "auth@test.com", password: "password123" }
    get dashboard_path
    assert_response :success
  end

  test "deactivated user with existing session gets logged out" do
    post login_path, params: { email_address: "auth@test.com", password: "password123" }
    get dashboard_path
    assert_response :success

    # Deactivate the user
    @user.update!(active: false)

    # Next request should redirect to login
    get dashboard_path
    assert_redirected_to login_path
  end
end
