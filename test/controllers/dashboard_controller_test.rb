require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(name: "Sunset Apts", mitigation_org: @genixo, property_management_org: @greystar)

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")

    PropertyAssignment.create!(user: @pm_user, property: @property)
  end

  test "manager can access dashboard" do
    login_as @manager
    get dashboard_path
    assert_response :success
  end

  test "technician can access dashboard" do
    login_as @tech
    get dashboard_path
    assert_response :success
  end

  test "PM user can access dashboard" do
    login_as @pm_user
    get dashboard_path
    assert_response :success
  end

  test "unauthenticated user is redirected to login" do
    get dashboard_path
    assert_redirected_to login_path
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
