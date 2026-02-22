require "test_helper"
require "cgi"

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
    @pm_manager = User.create!(organization: @greystar, user_type: "pm_manager",
      email_address: "pmmgr@greystar.com", first_name: "Test", last_name: "PMMgr", password: "password123")
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

  test "PM manager cannot access users" do
    login_as @pm_manager
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

  test "show props allow manager to edit another user including role" do
    login_as @manager
    get user_path(@tech)
    assert_response :success

    props = inertia_props
    assert_equal true, props.fetch("can_edit")
    assert_equal true, props.fetch("can_edit_role")
    assert props.fetch("role_options").any?
  end

  test "show props allow self edit but not self role edit" do
    login_as @manager
    get user_path(@manager)
    assert_response :success

    props = inertia_props
    assert_equal true, props.fetch("can_edit")
    assert_equal false, props.fetch("can_edit_role")
  end

  test "show props prevent office_sales from editing other users" do
    login_as @office
    get user_path(@tech)
    assert_response :success

    props = inertia_props
    assert_equal false, props.fetch("can_edit")
    assert_equal false, props.fetch("can_edit_role")
    assert_equal [], props.fetch("role_options")
  end

  # --- Updates ---

  test "manager can update another user" do
    login_as @manager
    patch user_path(@tech), params: { user: { first_name: "Updated", user_type: User::TECHNICIAN } }
    assert_redirected_to user_path(@tech)
    assert_equal "Updated", @tech.reload.first_name
  end

  test "manager can update role for serviced PM user" do
    login_as @manager
    patch user_path(@pm_user), params: { user: { user_type: User::AREA_MANAGER } }
    assert_redirected_to user_path(@pm_user)
    assert_equal User::AREA_MANAGER, @pm_user.reload.user_type
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

  test "office_sales can update themselves but not role" do
    login_as @office
    patch user_path(@office), params: { user: { first_name: "Officey", user_type: User::MANAGER } }
    assert_redirected_to user_path(@office)
    assert_equal "Officey", @office.reload.first_name
    assert_equal User::OFFICE_SALES, @office.reload.user_type
  end

  test "pm manager can update themselves but not role" do
    login_as @pm_manager
    patch user_path(@pm_manager), params: { user: { first_name: "PMSelf", user_type: User::AREA_MANAGER } }
    assert_redirected_to user_path(@pm_manager)
    assert_equal "PMSelf", @pm_manager.reload.first_name
    assert_equal User::PM_MANAGER, @pm_manager.reload.user_type
  end

  test "pm manager cannot update another user" do
    login_as @pm_manager
    patch user_path(@pm_user), params: { user: { first_name: "Nope" } }
    assert_response :not_found
    assert_not_equal "Nope", @pm_user.reload.first_name
  end

  test "manager cannot update user from unrelated org" do
    login_as @manager
    patch user_path(@unrelated_user), params: { user: { first_name: "Nope" } }
    assert_response :not_found
    assert_not_equal "Nope", @unrelated_user.reload.first_name
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

  test "office_sales can deactivate another user" do
    login_as @office
    patch deactivate_user_path(@tech)
    assert_redirected_to user_path(@tech)
    assert_equal false, @tech.reload.active
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

  def inertia_props
    encoded = response.body.match(/data-page="([^"]+)"/m)&.captures&.first
    raise "Missing Inertia data-page payload" unless encoded

    JSON.parse(CGI.unescapeHTML(encoded)).fetch("props")
  end

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
