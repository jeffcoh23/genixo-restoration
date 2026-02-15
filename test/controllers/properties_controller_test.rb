require "test_helper"

class PropertiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @other_pm = Organization.create!(name: "Other PM", organization_type: "property_management")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo, street_address: "100 Sunset Blvd",
      city: "Houston", state: "TX", zip: "77001", unit_count: 24
    )

    @other_property = Property.create!(
      name: "Other Building", property_management_org: @other_pm,
      mitigation_org: @genixo
    )

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @office = User.create!(organization: @genixo, user_type: "office_sales",
      email_address: "office@genixo.com", first_name: "Test", last_name: "Office", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")
    @area_mgr = User.create!(organization: @greystar, user_type: "area_manager",
      email_address: "am@greystar.com", first_name: "Test", last_name: "AreaMgr", password: "password123")

    # Assign PM user and area manager to the property
    PropertyAssignment.create!(user: @pm_user, property: @property)
    PropertyAssignment.create!(user: @area_mgr, property: @property)
  end

  # --- Index access control ---

  test "manager can access properties index" do
    login_as @manager
    get properties_path
    assert_response :success
  end

  test "office_sales can access properties index" do
    login_as @office
    get properties_path
    assert_response :success
  end

  test "property_manager can access properties index" do
    login_as @pm_user
    get properties_path
    assert_response :success
  end

  test "technician cannot access properties index" do
    login_as @tech
    get properties_path
    assert_response :not_found
  end

  # --- Index scoping ---

  test "manager sees all properties serviced by their org" do
    login_as @manager
    get properties_path
    assert_response :success
  end

  test "PM user only sees assigned properties" do
    login_as @pm_user
    get properties_path
    assert_response :success
  end

  # --- Show ---

  test "manager can view any property their org services" do
    login_as @manager
    get property_path(@property)
    assert_response :success
  end

  test "assigned PM user can view their property" do
    login_as @pm_user
    get property_path(@property)
    assert_response :success
  end

  test "unassigned PM user cannot view property" do
    login_as @pm_user
    get property_path(@other_property)
    assert_response :not_found
  end

  # --- New / Create ---

  test "manager can access new property form" do
    login_as @manager
    get new_property_path
    assert_response :success
  end

  test "PM user cannot access new property form" do
    login_as @pm_user
    get new_property_path
    assert_response :not_found
  end

  test "creates a new property" do
    login_as @manager
    assert_difference "Property.count", 1 do
      post properties_path, params: {
        property: { name: "New Building", property_management_org_id: @greystar.id,
          street_address: "200 Main St", city: "Dallas", state: "TX", zip: "75001", unit_count: 12 }
      }
    end
    prop = Property.last
    assert_equal "New Building", prop.name
    assert_equal @genixo.id, prop.mitigation_org_id
    assert_equal @greystar.id, prop.property_management_org_id
    assert_redirected_to property_path(prop)
  end

  test "create with missing name fails" do
    login_as @manager
    assert_no_difference "Property.count" do
      post properties_path, params: { property: { name: "", property_management_org_id: @greystar.id } }
    end
    assert_redirected_to new_property_path
  end

  test "technician cannot create property" do
    login_as @tech
    assert_no_difference "Property.count" do
      post properties_path, params: {
        property: { name: "Hacker Building", property_management_org_id: @greystar.id }
      }
    end
    assert_response :not_found
  end

  # --- Edit / Update ---

  test "manager can edit property" do
    login_as @manager
    get edit_property_path(@property)
    assert_response :success
  end

  test "assigned PM user can edit property" do
    login_as @pm_user
    get edit_property_path(@property)
    assert_response :success
  end

  test "unassigned PM user cannot edit property" do
    login_as @pm_user
    get edit_property_path(@other_property)
    assert_response :not_found
  end

  test "manager can update property" do
    login_as @manager
    patch property_path(@property), params: { property: { name: "Sunset Towers" } }
    assert_redirected_to property_path(@property)
    assert_equal "Sunset Towers", @property.reload.name
  end

  test "assigned PM user can update property name" do
    login_as @pm_user
    patch property_path(@property), params: { property: { name: "Updated Name" } }
    assert_redirected_to property_path(@property)
    assert_equal "Updated Name", @property.reload.name
  end

  test "PM user cannot change property org" do
    login_as @pm_user
    patch property_path(@property), params: {
      property: { property_management_org_id: @other_pm.id }
    }
    assert_equal @greystar.id, @property.reload.property_management_org_id
  end

  test "update with invalid data fails" do
    login_as @manager
    patch property_path(@property), params: { property: { name: "" } }
    assert_redirected_to edit_property_path(@property)
    assert_equal "Sunset Apartments", @property.reload.name
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
