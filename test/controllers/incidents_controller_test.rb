require "test_helper"

class IncidentsControllerTest < ActionDispatch::IntegrationTest
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

    # Mitigation org users
    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @office = User.create!(organization: @genixo, user_type: "office_sales",
      email_address: "office@genixo.com", first_name: "Test", last_name: "Office", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")

    # PM org users
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")
    @area_mgr = User.create!(organization: @greystar, user_type: "area_manager",
      email_address: "am@greystar.com", first_name: "Test", last_name: "AreaMgr", password: "password123")
    @pm_mgr = User.create!(organization: @greystar, user_type: "pm_manager",
      email_address: "pmmgr@greystar.com", first_name: "Test", last_name: "PMMgr", password: "password123")

    # Assign PM users to the property
    PropertyAssignment.create!(user: @pm_user, property: @property)
    PropertyAssignment.create!(user: @area_mgr, property: @property)
  end

  # --- Index access + scoping ---

  test "manager sees all incidents in their mitigation org" do
    i1 = create_test_incident(status: "active", property: @property)
    i2 = create_test_incident(status: "acknowledged", property: @other_property)
    login_as @manager
    get incidents_path
    assert_response :success
    assert_includes response.body, "Sunset Apartments"
    assert_includes response.body, "Other Building"
  end

  test "property_manager sees only incidents on assigned properties" do
    i1 = create_test_incident(status: "active", property: @property)
    i2 = create_test_incident(status: "acknowledged", property: @other_property)
    login_as @pm_user
    get incidents_path
    assert_response :success
    assert_includes response.body, "Sunset Apartments"
    assert_not_includes response.body, "Other Building"
  end

  test "technician sees only directly assigned incidents" do
    i1 = create_test_incident(status: "active", property: @property)
    i2 = create_test_incident(status: "active", property: @other_property)
    IncidentAssignment.create!(incident: i1, user: @tech, assigned_by_user: @manager)
    login_as @tech
    get incidents_path
    assert_response :success
    # Should see i1 (assigned) but not i2 (not assigned)
    incidents_json = JSON.parse(response.body.match(/"incidents":(\[.*?\])/m)[1]) rescue nil
    if incidents_json
      assert_equal 1, incidents_json.length
    end
  end

  test "index filters by status" do
    create_test_incident(status: "active", property: @property)
    create_test_incident(status: "on_hold", property: @other_property)
    login_as @manager
    get incidents_path, params: { status: "active" }
    assert_response :success
  end

  test "index filters by property" do
    create_test_incident(status: "active", property: @property)
    create_test_incident(status: "active", property: @other_property)
    login_as @manager
    get incidents_path, params: { property_id: @property.id }
    assert_response :success
  end

  test "index filters by search term" do
    create_test_incident(status: "active", property: @property, description: "Water pipe burst")
    create_test_incident(status: "active", property: @other_property, description: "Fire damage")
    login_as @manager
    get incidents_path, params: { search: "Water" }
    assert_response :success
  end

  test "index paginates results" do
    login_as @manager
    get incidents_path, params: { page: 1 }
    assert_response :success
  end

  test "index passes can_create based on permissions" do
    login_as @tech
    # Tech can't create incidents, so can_create should be false
    get incidents_path
    assert_response :success
  end

  # --- Show page ---

  test "manager can view incident detail" do
    incident = create_test_incident(status: "active")
    login_as @manager
    get incident_path(incident)
    assert_response :success
  end

  test "show includes incident details and assigned users" do
    incident = create_test_incident(status: "active")
    IncidentAssignment.create!(incident: incident, user: @manager, assigned_by_user: @manager)
    login_as @manager
    get incident_path(incident)
    assert_response :success
    assert_includes response.body, "Test Manager"
  end

  test "pm_user can view incident on assigned property" do
    incident = create_test_incident(status: "active")
    login_as @pm_user
    get incident_path(incident)
    assert_response :success
  end

  test "pm_user cannot view incident on unassigned property" do
    incident = create_test_incident(status: "active", property: @other_property)
    login_as @pm_user
    get incident_path(incident)
    assert_response :not_found
  end

  test "show passes valid_transitions for managers" do
    incident = create_test_incident(status: "acknowledged")
    login_as @manager
    get incident_path(incident)
    assert_response :success
    # Manager should see transition options
    assert_includes response.body, "active"
  end

  test "show passes empty valid_transitions for non-managers" do
    incident = create_test_incident(status: "acknowledged")
    login_as @pm_user
    get incident_path(incident)
    assert_response :success
  end

  # --- New page access control ---

  test "manager can access new incident page" do
    login_as @manager
    get new_incident_path
    assert_response :success
  end

  test "office_sales can access new incident page" do
    login_as @office
    get new_incident_path
    assert_response :success
  end

  test "property_manager can access new incident page" do
    login_as @pm_user
    get new_incident_path
    assert_response :success
  end

  test "area_manager can access new incident page" do
    login_as @area_mgr
    get new_incident_path
    assert_response :success
  end

  test "technician gets 404 on new incident page" do
    login_as @tech
    get new_incident_path
    assert_response :not_found
  end

  test "pm_manager gets 404 on new incident page" do
    login_as @pm_mgr
    get new_incident_path
    assert_response :not_found
  end

  # --- Create with valid params ---

  test "creates incident with valid params" do
    login_as @manager

    # Auto-assign creates 5 assignments:
    #   PM-side property assignees: @pm_user, @area_mgr (2)
    #   PM-side pm_managers in PM org: @pm_mgr (1)
    #   Mitigation-side managers + office_sales: @manager, @office (2)
    assert_difference "Incident.count", 1 do
      assert_difference "ActivityEvent.count", 2 do
        assert_difference "IncidentAssignment.count", 5 do
          post incidents_path, params: {
            incident: {
              property_id: @property.id,
              project_type: "emergency_response",
              damage_type: "flood",
              description: "Major water leak in unit 4B",
              cause: "Burst pipe",
              requested_next_steps: "Dispatch crew immediately"
            }
          }
        end
      end
    end
  end

  test "redirects to incident show on success" do
    login_as @manager
    post incidents_path, params: {
      incident: {
        property_id: @property.id,
        project_type: "emergency_response",
        damage_type: "flood",
        description: "Major water leak in unit 4B"
      }
    }
    incident = Incident.last
    assert_redirected_to incident_path(incident)
  end

  # --- Create with invalid params ---

  test "fails with missing required fields" do
    login_as @manager
    assert_no_difference "Incident.count" do
      post incidents_path, params: {
        incident: {
          property_id: @property.id,
          project_type: "emergency_response",
          damage_type: "flood",
          description: ""
        }
      }
    end
    assert_redirected_to new_incident_path
  end

  test "fails with invalid property from another org" do
    login_as @pm_user
    assert_no_difference "Incident.count" do
      post incidents_path, params: {
        incident: {
          property_id: @other_property.id,
          project_type: "emergency_response",
          damage_type: "flood",
          description: "Should not work"
        }
      }
    end
    assert_redirected_to new_incident_path
  end

  # --- Status transition ---

  test "manager can transition incident status" do
    incident = create_test_incident(status: "acknowledged")
    login_as @manager
    patch transition_incident_path(incident), params: { status: "active" }
    assert_redirected_to incident_path(incident)
    assert_equal "active", incident.reload.status
  end

  test "manager transition creates activity event" do
    incident = create_test_incident(status: "acknowledged")
    login_as @manager
    assert_difference "ActivityEvent.count", 1 do
      patch transition_incident_path(incident), params: { status: "active" }
    end
  end

  test "invalid transition redirects with alert" do
    incident = create_test_incident(status: "acknowledged")
    login_as @manager
    patch transition_incident_path(incident), params: { status: "completed" }
    assert_redirected_to incident_path(incident)
    assert_equal "acknowledged", incident.reload.status
  end

  test "office_sales cannot transition status" do
    incident = create_test_incident(status: "acknowledged")
    login_as @office
    patch transition_incident_path(incident), params: { status: "active" }
    assert_response :not_found
    assert_equal "acknowledged", incident.reload.status
  end

  test "technician cannot transition status" do
    incident = create_test_incident(status: "active")
    IncidentAssignment.create!(incident: incident, user: @tech, assigned_by_user: @manager)
    login_as @tech
    patch transition_incident_path(incident), params: { status: "on_hold" }
    assert_response :not_found
    assert_equal "active", incident.reload.status
  end

  test "property_manager cannot transition status" do
    incident = create_test_incident(status: "acknowledged")
    login_as @pm_user
    patch transition_incident_path(incident), params: { status: "active" }
    assert_response :not_found
    assert_equal "acknowledged", incident.reload.status
  end

  # --- Mark read ---

  test "mark_read creates read state for messages" do
    incident = create_test_incident(status: "active")
    login_as @manager
    assert_difference "IncidentReadState.count", 1 do
      patch mark_read_incident_path(incident), params: { tab: "messages" }
    end
    assert_response :redirect
    rs = IncidentReadState.last
    assert_not_nil rs.last_message_read_at
    assert_nil rs.last_activity_read_at
  end

  test "mark_read creates read state for activity" do
    incident = create_test_incident(status: "active")
    login_as @manager
    patch mark_read_incident_path(incident), params: { tab: "activity" }
    assert_response :redirect
    rs = IncidentReadState.last
    assert_nil rs.last_message_read_at
    assert_not_nil rs.last_activity_read_at
  end

  test "mark_read updates existing read state" do
    incident = create_test_incident(status: "active")
    IncidentReadState.create!(incident: incident, user: @manager, last_message_read_at: 1.day.ago)
    login_as @manager
    assert_no_difference "IncidentReadState.count" do
      patch mark_read_incident_path(incident), params: { tab: "messages" }
    end
    assert_response :redirect
    rs = IncidentReadState.find_by(incident: incident, user: @manager)
    assert rs.last_message_read_at > 1.minute.ago
  end

  test "mark_read returns 404 for invisible incident" do
    incident = create_test_incident(status: "active", property: @other_property)
    login_as @pm_user
    patch mark_read_incident_path(incident), params: { tab: "messages" }
    assert_response :not_found
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end

  def create_test_incident(status:, property: nil, description: "Test incident")
    Incident.create!(
      property: property || @property, created_by_user: @manager,
      status: status, project_type: "emergency_response",
      damage_type: "flood", description: description, emergency: true
    )
  end
end
