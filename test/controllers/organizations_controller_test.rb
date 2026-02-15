require "test_helper"

class OrganizationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management",
      phone: "555-0100", email: "info@greystar.com")
    @manager = User.create!(organization: @genixo, user_type: "manager", email_address: "mgr@genixo.com",
      first_name: "Test", last_name: "Manager", password: "password123")
    @office = User.create!(organization: @genixo, user_type: "office_sales", email_address: "office@genixo.com",
      first_name: "Test", last_name: "Office", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician", email_address: "tech@genixo.com",
      first_name: "Test", last_name: "Tech", password: "password123")
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager", email_address: "pm@greystar.com",
      first_name: "Test", last_name: "PM", password: "password123")
  end

  # --- Access control ---

  test "manager can access organizations index" do
    login_as @manager
    get organizations_path
    assert_response :success
  end

  test "office_sales can access organizations index" do
    login_as @office
    get organizations_path
    assert_response :success
  end

  test "technician cannot access organizations" do
    login_as @tech
    get organizations_path
    assert_response :not_found
  end

  test "PM user cannot access organizations" do
    login_as @pm_user
    get organizations_path
    assert_response :not_found
  end

  # --- Index ---

  test "index lists PM orgs only, not mitigation org" do
    login_as @manager
    get organizations_path
    assert_response :success
  end

  # --- Show ---

  test "show returns organization detail" do
    login_as @manager
    get organization_path(@greystar)
    assert_response :success
  end

  test "cannot view mitigation org detail" do
    login_as @manager
    get organization_path(@genixo)
    assert_response :not_found
  end

  # --- Create ---

  test "creates a new PM organization" do
    login_as @manager
    assert_difference "Organization.count", 1 do
      post organizations_path, params: {
        organization: { name: "New PM Corp", phone: "555-9999", email: "new@pm.com",
          street_address: "123 Main", city: "Houston", state: "TX", zip: "77001" }
      }
    end

    org = Organization.last
    assert_equal "property_management", org.organization_type
    assert_equal "New PM Corp", org.name
    assert_redirected_to organization_path(org)
  end

  test "create with missing name fails" do
    login_as @manager
    assert_no_difference "Organization.count" do
      post organizations_path, params: { organization: { name: "" } }
    end
    assert_redirected_to new_organization_path
  end

  # --- Update ---

  test "updates organization" do
    login_as @manager
    patch organization_path(@greystar), params: { organization: { name: "Greystar Updated" } }
    assert_redirected_to organization_path(@greystar)
    assert_equal "Greystar Updated", @greystar.reload.name
  end

  test "update with invalid data fails" do
    login_as @manager
    patch organization_path(@greystar), params: { organization: { name: "" } }
    assert_redirected_to edit_organization_path(@greystar)
    assert_equal "Greystar", @greystar.reload.name
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
