require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @unrelated_pm = Organization.create!(name: "Unrelated PM", organization_type: "property_management")

    # Genixo services Greystar (via a property), but not Unrelated PM
    Property.create!(name: "Test Property", property_management_org: @greystar, mitigation_org: @genixo)

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @office = User.create!(organization: @genixo, user_type: "office_sales",
      email_address: "office@genixo.com", first_name: "Test", last_name: "Office", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")
    @unrelated_user = User.create!(organization: @unrelated_pm, user_type: "property_manager",
      email_address: "other@unrelated.com", first_name: "Other", last_name: "User", password: "password123")
  end

  # --- Access control ---

  test "manager can access users index" do
    login_as @manager
    get users_path
    assert_response :success
  end

  test "office_sales can access users index" do
    login_as @office
    get users_path
    assert_response :success
  end

  test "technician cannot access users" do
    login_as @tech
    get users_path
    assert_response :not_found
  end

  test "PM user cannot access users" do
    login_as @pm_user
    get users_path
    assert_response :not_found
  end

  test "technician can view their own user page" do
    login_as @tech
    get user_path(@tech)
    assert_response :success
  end

  test "pm user can view their own user page" do
    login_as @pm_user
    get user_path(@pm_user)
    assert_response :success
  end

  # --- Visibility scoping ---

  test "manager can view users from own org" do
    login_as @manager
    get user_path(@tech)
    assert_response :success
  end

  test "manager can view users from serviced PM org" do
    login_as @manager
    get user_path(@pm_user)
    assert_response :success
  end

  test "manager cannot view users from unrelated PM org" do
    login_as @manager
    get user_path(@unrelated_user)
    assert_response :not_found
  end

  # --- Updates ---

  test "manager can update another user" do
    login_as @manager
    patch user_path(@tech), params: { user: { first_name: "Updated", user_type: User::TECHNICIAN } }
    assert_redirected_to user_path(@tech)
    assert_equal "Updated", @tech.reload.first_name
  end

  test "office_sales cannot update another user" do
    login_as @office
    patch user_path(@tech), params: { user: { first_name: "Nope" } }
    assert_response :not_found
    assert_not_equal "Nope", @tech.reload.first_name
  end

  test "technician can update themselves" do
    login_as @tech
    patch user_path(@tech), params: { user: { first_name: "Techy", timezone: "UTC" } }
    assert_redirected_to user_path(@tech)
    assert_equal "Techy", @tech.reload.first_name
  end

  test "technician cannot update their own role" do
    login_as @tech
    patch user_path(@tech), params: { user: { user_type: User::MANAGER } }
    assert_redirected_to user_path(@tech)
    assert_equal User::TECHNICIAN, @tech.reload.user_type
  end

  # --- Deactivation ---

  test "manager can deactivate another user" do
    login_as @manager
    patch deactivate_user_path(@tech)
    assert_redirected_to user_path(@tech)
    assert_equal false, @tech.reload.active
  end

  test "manager cannot deactivate themselves" do
    login_as @manager
    patch deactivate_user_path(@manager)
    assert_redirected_to user_path(@manager)
    assert_equal true, @manager.reload.active
    assert_equal "You cannot deactivate yourself.", flash[:alert]
  end

  test "manager can deactivate PM user from serviced org" do
    login_as @manager
    patch deactivate_user_path(@pm_user)
    assert_redirected_to user_path(@pm_user)
    assert_equal false, @pm_user.reload.active
  end

  # --- Reactivation ---

  test "manager can reactivate a deactivated user" do
    @tech.update!(active: false)
    login_as @manager
    patch reactivate_user_path(@tech)
    assert_redirected_to user_path(@tech)
    assert_equal true, @tech.reload.active
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
