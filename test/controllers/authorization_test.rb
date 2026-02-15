require "test_helper"

class AuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    # Orgs
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @sandalwood = Organization.create!(name: "Sandalwood", organization_type: "property_management")

    # Users
    @manager = create_user(@genixo, "manager", "manager@genixo.com")
    @office_sales = create_user(@genixo, "office_sales", "office@genixo.com")
    @tech = create_user(@genixo, "technician", "tech@genixo.com")
    @pm = create_user(@greystar, "property_manager", "pm@greystar.com")
    @am = create_user(@greystar, "area_manager", "am@greystar.com")
    @pm_mgr = create_user(@greystar, "pm_manager", "mgr@greystar.com")
    @sandal_pm = create_user(@sandalwood, "property_manager", "pm@sandalwood.com")

    # Properties
    @prop_greystar = Property.create!(name: "River Oaks", property_management_org: @greystar, mitigation_org: @genixo)
    @prop_sandalwood = Property.create!(name: "Sandalwood Apts", property_management_org: @sandalwood, mitigation_org: @genixo)

    # Property assignments — PM assigned to greystar property only
    PropertyAssignment.create!(property: @prop_greystar, user: @pm)
    PropertyAssignment.create!(property: @prop_greystar, user: @am)

    # Incidents
    @incident_greystar = Incident.create!(
      property: @prop_greystar, created_by_user: @manager,
      status: "active", project_type: "emergency_response", damage_type: "flood",
      description: "Greystar incident"
    )
    @incident_sandalwood = Incident.create!(
      property: @prop_sandalwood, created_by_user: @manager,
      status: "active", project_type: "mitigation_rfq", damage_type: "mold",
      description: "Sandalwood incident"
    )

    # Tech assigned to greystar incident only
    IncidentAssignment.create!(incident: @incident_greystar, user: @tech, assigned_by_user: @manager)
  end

  # --- Mitigation manager sees everything in their org ---

  test "manager sees all properties for their mitigation org" do
    login_as @manager
    get properties_path
    assert_response :success
  end

  test "manager sees both incidents across PM orgs" do
    login_as @manager
    get incident_path(@incident_greystar)
    assert_response :success

    get incident_path(@incident_sandalwood)
    assert_response :success
  end

  # --- Office/sales same as manager ---

  test "office_sales sees all properties and incidents" do
    login_as @office_sales
    get incident_path(@incident_greystar)
    assert_response :success

    get incident_path(@incident_sandalwood)
    assert_response :success
  end

  # --- Technician sees only assigned incidents ---

  test "technician sees assigned incident" do
    login_as @tech
    get incident_path(@incident_greystar)
    assert_response :success
  end

  test "technician cannot see unassigned incident" do
    login_as @tech
    get incident_path(@incident_sandalwood)
    assert_response :not_found
  end

  test "technician sees property through assigned incident" do
    login_as @tech
    get property_path(@prop_greystar)
    assert_response :success
  end

  test "technician cannot see property with no assigned incidents" do
    login_as @tech
    get property_path(@prop_sandalwood)
    assert_response :not_found
  end

  # --- PM user sees only assigned properties ---

  test "PM user sees assigned property" do
    login_as @pm
    get property_path(@prop_greystar)
    assert_response :success
  end

  test "PM user cannot see unassigned property" do
    login_as @pm
    get property_path(@prop_sandalwood)
    assert_response :not_found
  end

  test "PM user sees incidents on assigned property" do
    login_as @pm
    get incident_path(@incident_greystar)
    assert_response :success
  end

  test "PM user cannot see incidents on unassigned property" do
    login_as @pm
    get incident_path(@incident_sandalwood)
    assert_response :not_found
  end

  # --- Cross-org PM isolation ---

  test "Sandalwood PM cannot see Greystar property" do
    login_as @sandal_pm
    get property_path(@prop_greystar)
    assert_response :not_found
  end

  test "Sandalwood PM cannot see Greystar incident" do
    login_as @sandal_pm
    get incident_path(@incident_greystar)
    assert_response :not_found
  end

  # --- PM user with direct incident assignment (no property assignment) ---

  test "pm_manager sees incident via direct assignment even without property assignment" do
    IncidentAssignment.create!(incident: @incident_greystar, user: @pm_mgr, assigned_by_user: @manager)
    login_as @pm_mgr
    get incident_path(@incident_greystar)
    assert_response :success
  end

  test "pm_manager cannot see incident without any assignment" do
    login_as @pm_mgr
    get incident_path(@incident_greystar)
    assert_response :not_found
  end

  private

  def create_user(org, user_type, email)
    User.create!(
      organization: org,
      user_type: user_type,
      email_address: email,
      first_name: user_type.titleize.split.first,
      last_name: "Test",
      password: "password123"
    )
  end

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
